-- Compression policy.
--
-- Native TimescaleDB columnar compression typically yields 10x-20x reduction
-- on tick data. We compress chunks older than 7 days. Hot data (last week)
-- stays uncompressed for fast inserts and updates; cold data (older than a
-- week) becomes read-mostly and benefits massively from compression.
--
-- segmentby groups rows that share the same value during compression. Setting
-- it to symbol means queries filtered by symbol scan only the relevant
-- compressed segments. Critical for performance.
--
-- orderby controls the order rows are stored within a compressed chunk.
-- Time DESC matches the most common access pattern (latest first).

ALTER TABLE ticks SET (
    timescaledb.compress,
    timescaledb.compress_segmentby = 'symbol',
    timescaledb.compress_orderby = 'time DESC'
);

SELECT add_compression_policy(
    'ticks',
    INTERVAL '7 days',
    if_not_exists => TRUE
);

-- Optional: data retention policy.
-- Drop chunks older than 365 days. Comment out if you want infinite retention.
SELECT add_retention_policy(
    'ticks',
    INTERVAL '365 days',
    if_not_exists => TRUE
);
