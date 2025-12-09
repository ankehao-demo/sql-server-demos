-- Wide World Importers DW PostgreSQL Migration
-- Phase 4: OLAP Schema Migration
-- File: 001-integration-tables.sql
-- Description: Create integration tables for ETL lineage tracking and cutoff management

-- =============================================
-- Integration.Lineage - ETL lineage tracking table
-- =============================================
CREATE TABLE integration.lineage (
    lineage_key integer NOT NULL DEFAULT nextval('sequences.lineage_key'),
    data_load_started timestamp NOT NULL,
    table_name varchar(128) NOT NULL,
    data_load_completed timestamp NULL,
    was_successful boolean NOT NULL,
    source_system_cutoff_time timestamp NOT NULL,
    CONSTRAINT pk_integration_lineage PRIMARY KEY (lineage_key)
);

COMMENT ON TABLE integration.lineage IS 'ETL lineage tracking for data warehouse loads';
COMMENT ON COLUMN integration.lineage.lineage_key IS 'DW key for lineage tracking';
COMMENT ON COLUMN integration.lineage.data_load_started IS 'Date and time when the data load started';
COMMENT ON COLUMN integration.lineage.table_name IS 'Name of the table being loaded';
COMMENT ON COLUMN integration.lineage.data_load_completed IS 'Date and time when the data load completed';
COMMENT ON COLUMN integration.lineage.was_successful IS 'Was the data load successful?';
COMMENT ON COLUMN integration.lineage.source_system_cutoff_time IS 'Cutoff time for the source system data';

-- =============================================
-- Integration.ETL_Cutoff - ETL cutoff time tracking table
-- =============================================
CREATE TABLE integration.etl_cutoff (
    table_name varchar(128) NOT NULL,
    cutoff_time timestamp NOT NULL,
    CONSTRAINT pk_integration_etl_cutoff PRIMARY KEY (table_name)
);

COMMENT ON TABLE integration.etl_cutoff IS 'ETL cutoff time tracking for incremental loads';
COMMENT ON COLUMN integration.etl_cutoff.table_name IS 'Name of the table for cutoff tracking';
COMMENT ON COLUMN integration.etl_cutoff.cutoff_time IS 'Last successful cutoff time for this table';

-- Initialize ETL cutoff times for all dimension and fact tables
INSERT INTO integration.etl_cutoff (table_name, cutoff_time) VALUES
    ('City', '2012-12-31 23:59:59'),
    ('Customer', '2012-12-31 23:59:59'),
    ('Employee', '2012-12-31 23:59:59'),
    ('Payment Method', '2012-12-31 23:59:59'),
    ('Stock Item', '2012-12-31 23:59:59'),
    ('Supplier', '2012-12-31 23:59:59'),
    ('Transaction Type', '2012-12-31 23:59:59'),
    ('Sale', '2012-12-31 23:59:59'),
    ('Order', '2012-12-31 23:59:59'),
    ('Purchase', '2012-12-31 23:59:59'),
    ('Movement', '2012-12-31 23:59:59'),
    ('Transaction', '2012-12-31 23:59:59'),
    ('Stock Holding', '2012-12-31 23:59:59');
