-- Continuous aggregates: pre-computed OHLCV bars over the raw ticks.
--
-- TimescaleDB maintains these incrementally. Querying a bar from the aggregate
-- is much cheaper than recomputing from raw ticks every time. The trade-off
-- is storage and a small refresh lag.
--
-- We define three time resolutions: 1 minute, 5 minutes, 1 hour. Add or remove
-- to fit your strategies.

-- 1-minute OHLCV bars.
CREATE MATERIALIZED VIEW IF NOT EXISTS ohlcv_1m
WITH (timescaledb.continuous) AS
SELECT
    time_bucket('1 minute', time) AS bucket,
    symbol,
    first(price, time)   AS open,
    max(price)           AS high,
    min(price)           AS low,
    last(price, time)    AS close,
    sum(volume)          AS volume,
    count(*)             AS tick_count
FROM ticks
GROUP BY bucket, symbol
WITH NO DATA;

-- 5-minute OHLCV bars.
CREATE MATERIALIZED VIEW IF NOT EXISTS ohlcv_5m
WITH (timescaledb.continuous) AS
SELECT
    time_bucket('5 minutes', time) AS bucket,
    symbol,
    first(price, time)   AS open,
    max(price)           AS high,
    min(price)           AS low,
    last(price, time)    AS close,
    sum(volume)          AS volume,
    count(*)             AS tick_count
FROM ticks
GROUP BY bucket, symbol
WITH NO DATA;

-- 1-hour OHLCV bars.
CREATE MATERIALIZED VIEW IF NOT EXISTS ohlcv_1h
WITH (timescaledb.continuous) AS
SELECT
    time_bucket('1 hour', time) AS bucket,
    symbol,
    first(price, time)   AS open,
    max(price)           AS high,
    min(price)           AS low,
    last(price, time)    AS close,
    sum(volume)          AS volume,
    count(*)             AS tick_count
FROM ticks
GROUP BY bucket, symbol
WITH NO DATA;

-- Refresh policies. The aggregates auto-refresh in the background.
-- start_offset controls how far back to recompute (covers late-arriving ticks).
-- end_offset prevents refreshing the very latest data while it's still in flux.

SELECT add_continuous_aggregate_policy(
    'ohlcv_1m',
    start_offset => INTERVAL '3 hours',
    end_offset   => INTERVAL '1 minute',
    schedule_interval => INTERVAL '1 minute',
    if_not_exists => TRUE
);

SELECT add_continuous_aggregate_policy(
    'ohlcv_5m',
    start_offset => INTERVAL '6 hours',
    end_offset   => INTERVAL '5 minutes',
    schedule_interval => INTERVAL '5 minutes',
    if_not_exists => TRUE
);

SELECT add_continuous_aggregate_policy(
    'ohlcv_1h',
    start_offset => INTERVAL '1 day',
    end_offset   => INTERVAL '1 hour',
    schedule_interval => INTERVAL '15 minutes',
    if_not_exists => TRUE
);
