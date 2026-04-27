-- TimescaleDB extension setup.
--
-- Run this once per database. Requires PostgreSQL 14+ and the timescaledb
-- extension installed at the OS level. On Debian/Ubuntu:
--
--     apt install timescaledb-2-postgresql-14
--     timescaledb-tune
--
-- After installation, the extension must also be added to shared_preload_libraries
-- in postgresql.conf. The CREATE EXTENSION statement below assumes that step
-- has already been done.

CREATE EXTENSION IF NOT EXISTS timescaledb CASCADE;

-- Verify the extension is loaded.
SELECT extversion FROM pg_extension WHERE extname = 'timescaledb';
