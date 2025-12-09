-- Wide World Importers PostgreSQL Migration
-- Phase 2: OLTP Schema Migration
-- Application.Logs table (non-temporal, originally had columnstore index)

CREATE TABLE application.logs (
    message VARCHAR(4000) NOT NULL,
    level VARCHAR(16) NOT NULL,
    event_time TIMESTAMP NOT NULL,
    log_event TEXT NULL
);

-- Note: PostgreSQL doesn't have columnstore indexes like SQL Server
-- For analytical queries on this table, consider using BRIN indexes or partitioning
CREATE INDEX ix_application_logs_event_time ON application.logs(event_time);
CREATE INDEX ix_application_logs_level ON application.logs(level);
