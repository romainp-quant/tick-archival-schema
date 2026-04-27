"""Stream a CSV file of ticks into PostgreSQL using COPY.

COPY is the fastest way to bulk-load data into PostgreSQL. This helper wraps
psycopg's copy_from for the common case of streaming a CSV file produced by
a market data exporter.

Usage:

    python csv_to_ticks.py --csv ticks.csv --dsn postgresql://user@localhost/marketdata

The CSV must have a header row matching the columns you want to populate.
Minimum required columns: time, symbol, price, volume.

Requires:

    pip install psycopg[binary]>=3.1
"""

from __future__ import annotations

import argparse
import csv
import sys
from pathlib import Path


def stream_csv_to_ticks(csv_path: Path, dsn: str, batch_size: int = 10_000) -> int:
    """Stream a CSV file into the ticks table using COPY.

    Returns the number of rows inserted.
    """
    try:
        import psycopg
    except ImportError as exc:
        raise RuntimeError(
            "psycopg is required. Install with: pip install 'psycopg[binary]>=3.1'"
        ) from exc

    with csv_path.open("r", newline="") as f:
        reader = csv.reader(f)
        header = next(reader)
        columns = ", ".join(header)

        with psycopg.connect(dsn) as conn:
            with conn.cursor() as cur:
                copy_sql = f"COPY ticks ({columns}) FROM STDIN WITH (FORMAT CSV)"
                with cur.copy(copy_sql) as copy:
                    rows_written = 0
                    batch: list[str] = []
                    for row in reader:
                        # Re-encode the row as CSV so COPY parses it cleanly.
                        batch.append(",".join(_csv_escape(v) for v in row))
                        if len(batch) >= batch_size:
                            copy.write("\n".join(batch) + "\n")
                            rows_written += len(batch)
                            batch.clear()
                    if batch:
                        copy.write("\n".join(batch) + "\n")
                        rows_written += len(batch)
            conn.commit()

    return rows_written


def _csv_escape(value: str) -> str:
    """Minimal CSV escaping for values that may contain commas or quotes."""
    if "," in value or '"' in value or "\n" in value:
        return '"' + value.replace('"', '""') + '"'
    return value


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__.split("\n", 1)[0])
    parser.add_argument("--csv", type=Path, required=True, help="Path to the CSV file")
    parser.add_argument("--dsn", required=True, help="PostgreSQL DSN")
    parser.add_argument(
        "--batch-size",
        type=int,
        default=10_000,
        help="Rows buffered before each flush to COPY (default: 10000)",
    )
    args = parser.parse_args()

    if not args.csv.exists():
        print(f"CSV file not found: {args.csv}", file=sys.stderr)
        return 1

    rows = stream_csv_to_ticks(args.csv, args.dsn, args.batch_size)
    print(f"Inserted {rows} rows into ticks.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
