# tick-archival-schema

TimescaleDB schema for tick-level market data archival. Hypertables, continuous aggregates, compression policies.

## What this is

A reference schema for storing high-frequency market data (trades, quotes) in PostgreSQL with the TimescaleDB extension. The schema covers:

- A hypertable partitioned by time, indexed for the most common access patterns
- Continuous aggregates pre-computing 1m, 5m, and 1h OHLCV bars
- Native columnar compression on chunks older than 7 days (10x-20x reduction)
- Optional 365-day retention policy

This is a starting point, not a finished product. You will adapt the schema to your specific data shape: more columns, different chunk size, different aggregation windows, different retention.

## Why TimescaleDB

For tick-level data, the alternatives are usually Parquet on object storage, KDB+, or a custom binary format. Each has trade-offs.

TimescaleDB sits in a useful middle ground: it speaks SQL, integrates with every existing PostgreSQL tool, handles late-arriving data correctly via continuous aggregates, and offers very good compression. For most retail and small-quant workloads — up to a few billion ticks — it is the simplest path that does not paint you into a corner.

If you are pushing 100B+ ticks or need sub-millisecond reads from a single-machine setup, look at KDB+, Arctic on object storage, or a custom solution. For everything else, TimescaleDB is hard to beat on operational simplicity.

## Layout

    schema/
      01_create_extension.sql       Install and verify the timescaledb extension.
      02_ticks_table.sql            Create the ticks hypertable and its indexes.
      03_continuous_aggregates.sql  1m, 5m, 1h OHLCV bars with auto-refresh.
      04_compression_policy.sql     Compression after 7 days, retention after 365.

    examples/
      insert_tick.sql               Single, bulk, and COPY insert patterns.
      query_examples.sql            Common queries: latest tick, OHLCV, storage stats.

    tools/
      csv_to_ticks.py               Stream a CSV file into ticks via COPY.

## Quick start

Apply the schema files in order:

    psql -d marketdata -f schema/01_create_extension.sql
    psql -d marketdata -f schema/02_ticks_table.sql
    psql -d marketdata -f schema/03_continuous_aggregates.sql
    psql -d marketdata -f schema/04_compression_policy.sql

Insert a tick:

    psql -d marketdata -f examples/insert_tick.sql

Query latest ticks and OHLCV bars:

    psql -d marketdata -f examples/query_examples.sql

Bulk import a CSV:

    pip install 'psycopg[binary]>=3.1'
    python tools/csv_to_ticks.py --csv ticks.csv --dsn postgresql://user@localhost/marketdata

## Design notes

### Hypertable chunk size

1-day chunks are a sensible default. Aim for chunks of 100-500 MB compressed. If your daily ingestion is much higher or lower, adjust chunk_time_interval in schema/02_ticks_table.sql.

### Numeric vs float

Prices are NUMERIC(18, 8), not FLOAT. Floats accumulate rounding errors that compound across aggregations. NUMERIC is exact and the cost is negligible for tick-level workloads.

### Continuous aggregates

The 1m, 5m, and 1h aggregates are independent. You can drop any of them or add new ones (15m, 4h, 1d) without touching the others. Refresh policies use start_offset to re-cover late-arriving ticks; tune to your feed's worst-case lag.

### Compression segmentby

segmentby = symbol means queries filtered by symbol scan only the relevant compressed segments. Without this, every query scans every symbol's data in a chunk. Critical for read performance once compression kicks in.

### Storage estimate

Rough estimate for liquid US equities:

- ~100 bytes per tick uncompressed (with L1 quote, JSONB raw_payload empty)
- ~5-10 bytes per tick compressed (10x-20x reduction)

For 1M ticks/day on 100 symbols (100M ticks/day), expect ~10 GB/day uncompressed, ~500 MB/day compressed.

## What this is not

- Not a guide to operating a production database. You still need backups, monitoring, replication, capacity planning.
- Not opinionated about your data shape. Multi-asset, multi-venue, options chains — adapt the schema accordingly.
- Not benchmarked against your specific workload. Numbers above are typical, not guaranteed.

## License

MIT.nano README.md
