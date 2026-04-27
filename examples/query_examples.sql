-- Common query patterns against the ticks hypertable and its continuous
-- aggregates.

-- Latest 100 ticks for a symbol.
SELECT time, price, volume
FROM ticks
WHERE symbol = 'AAPL'
ORDER BY time DESC
LIMIT 100;

-- Latest tick for every symbol (last-observation-carried-forward).
SELECT DISTINCT ON (symbol) symbol, time, price, volume
FROM ticks
ORDER BY symbol, time DESC;

-- 1-minute OHLCV bars for the past 24 hours from the continuous aggregate.
-- This is much cheaper than computing from raw ticks every time.
SELECT bucket, open, high, low, close, volume, tick_count
FROM ohlcv_1m
WHERE symbol = 'AAPL'
  AND bucket >= NOW() - INTERVAL '24 hours'
ORDER BY bucket DESC;

-- Realized volatility (per minute) from the 1-minute bars.
SELECT
    bucket,
    symbol,
    (high - low) / NULLIF(open, 0) AS range_pct,
    close
FROM ohlcv_1m
WHERE symbol = 'AAPL'
  AND bucket >= NOW() - INTERVAL '6 hours'
ORDER BY bucket DESC;

-- Number of ticks per minute for the last hour. Useful for spotting feed gaps.
SELECT
    time_bucket('1 minute', time) AS minute,
    symbol,
    count(*) AS tick_count
FROM ticks
WHERE time >= NOW() - INTERVAL '1 hour'
GROUP BY minute, symbol
ORDER BY minute DESC, symbol;

-- Storage breakdown: compressed vs uncompressed chunks.
SELECT
    chunk_schema,
    chunk_name,
    is_compressed,
    pg_size_pretty(total_bytes) AS total_size,
    pg_size_pretty(compressed_total_bytes) AS compressed_size
FROM chunks_detailed_size('ticks')
ORDER BY range_start DESC
LIMIT 10;
