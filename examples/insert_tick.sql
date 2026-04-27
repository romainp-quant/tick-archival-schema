-- Inserting ticks: single rows and bulk inserts.
--
-- For real ingestion, prefer COPY (orders of magnitude faster than INSERT)
-- or batched INSERT with a multi-row VALUES clause.

-- Single tick (trade only).
INSERT INTO ticks (time, symbol, price, volume)
VALUES (NOW(), 'AAPL', 175.42, 100);

-- Single tick with full L1 quote.
INSERT INTO ticks (time, symbol, price, volume, bid_price, ask_price, bid_size, ask_size, venue)
VALUES (NOW(), 'AAPL', 175.42, 100, 175.41, 175.43, 500, 600, 'NASDAQ');

-- Bulk insert (preferred over many single INSERTs).
INSERT INTO ticks (time, symbol, price, volume) VALUES
    (NOW() - INTERVAL '3 seconds', 'AAPL', 175.40, 50),
    (NOW() - INTERVAL '2 seconds', 'AAPL', 175.41, 75),
    (NOW() - INTERVAL '1 second',  'AAPL', 175.42, 100);

-- For very large imports (millions of rows), use COPY from a CSV file.
-- See tools/csv_to_ticks.py for a Python helper that streams CSV to COPY.
--
-- Example shell command:
--
--     psql -d marketdata -c "\COPY ticks (time, symbol, price, volume) FROM 'ticks.csv' CSV HEADER"
