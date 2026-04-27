-- Tick-level market data table.
--
-- Design choices:
--
-- * Hypertable partitioned by time (daily chunks). 1 day is a sensible default
--   for most market-data workloads. Tune chunk_time_interval based on your
--   ingestion rate: aim for chunks of 100-500 MB compressed.
--
-- * symbol is part of the primary key so multiple instruments coexist in the
--   same table. For very high cardinality (10k+ symbols), consider sharding
--   by symbol with a hash-partitioned hypertable instead.
--
-- * price stored as numeric(18, 8). Floats are tempting but introduce rounding
--   errors that compound across aggregations. numeric is exact.
--
-- * volume stored as bigint. Adapt to numeric if you handle fractional volumes
--   (crypto, FX in some venues).
--
-- * Optional bid_price / ask_price / bid_size / ask_size for L1 quotes. Drop
--   if you only ingest trades. Keep nullable so trades and quotes can share
--   the table.

CREATE TABLE IF NOT EXISTS ticks (
    time         TIMESTAMPTZ      NOT NULL,
    symbol       TEXT             NOT NULL,
    price        NUMERIC(18, 8)   NOT NULL,
    volume       BIGINT           NOT NULL DEFAULT 0,
    bid_price    NUMERIC(18, 8),
    ask_price    NUMERIC(18, 8),
    bid_size     BIGINT,
    ask_size     BIGINT,
    venue        TEXT,
    raw_payload  JSONB
);

-- Convert to hypertable. 1-day chunks. Adjust if your ingestion is much higher
-- or lower than ~1M rows per symbol per day.
SELECT create_hypertable(
    'ticks',
    'time',
    chunk_time_interval => INTERVAL '1 day',
    if_not_exists => TRUE
);

-- Indexes optimized for the most common access patterns.
-- Primary lookup: latest N ticks for a symbol.
CREATE INDEX IF NOT EXISTS idx_ticks_symbol_time
    ON ticks (symbol, time DESC);

-- Secondary: time-range queries across all symbols (rare, but useful for
-- cross-asset analytics).
CREATE INDEX IF NOT EXISTS idx_ticks_time
    ON ticks (time DESC);
