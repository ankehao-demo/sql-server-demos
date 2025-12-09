-- Wide World Importers Data Warehouse - PostgreSQL Schema Migration
-- Phase 4: OLAP Schema Migration
-- Integration: Lineage and ETL Cutoff tables
-- Note: These tables track ETL data load history

-- ETL Cutoff table - tracks the last successful load time for each table
CREATE TABLE integration.etl_cutoff (
    table_name      VARCHAR(128) NOT NULL,
    cutoff_time     TIMESTAMP NOT NULL,

    CONSTRAINT pk_integration_etl_cutoff PRIMARY KEY (table_name)
);

COMMENT ON TABLE integration.etl_cutoff IS 'ETL Cutoff Times';
COMMENT ON COLUMN integration.etl_cutoff.table_name IS 'Table name';
COMMENT ON COLUMN integration.etl_cutoff.cutoff_time IS 'Time up to which data has been loaded';

-- Lineage table - tracks data load attempts and their status
CREATE TABLE integration.lineage (
    lineage_key                 INTEGER NOT NULL DEFAULT nextval('sequences.lineage_key'),
    data_load_started           TIMESTAMP NOT NULL,
    table_name                  VARCHAR(128) NOT NULL,
    data_load_completed         TIMESTAMP,
    was_successful              BOOLEAN NOT NULL,
    source_system_cutoff_time   TIMESTAMP NOT NULL,

    CONSTRAINT pk_integration_lineage PRIMARY KEY (lineage_key)
);

COMMENT ON TABLE integration.lineage IS 'Details of data load attempts';
COMMENT ON COLUMN integration.lineage.lineage_key IS 'DW key for lineage data';
COMMENT ON COLUMN integration.lineage.data_load_started IS 'Time when the data load attempt began';
COMMENT ON COLUMN integration.lineage.table_name IS 'Name of the table for this data load event';
COMMENT ON COLUMN integration.lineage.data_load_completed IS 'Time when the data load attempt completed (successfully or not)';
COMMENT ON COLUMN integration.lineage.was_successful IS 'Was the attempt successful?';
COMMENT ON COLUMN integration.lineage.source_system_cutoff_time IS 'Time that rows from the source system were loaded up until';
