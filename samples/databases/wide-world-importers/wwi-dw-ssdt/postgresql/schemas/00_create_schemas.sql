-- Wide World Importers Data Warehouse - PostgreSQL Schema Migration
-- Phase 4: OLAP Schema Migration
-- This script creates the schemas for the data warehouse

-- Create schemas
CREATE SCHEMA IF NOT EXISTS dimension;
CREATE SCHEMA IF NOT EXISTS fact;
CREATE SCHEMA IF NOT EXISTS integration;
CREATE SCHEMA IF NOT EXISTS sequences;

-- Add schema comments
COMMENT ON SCHEMA dimension IS 'Dimension tables for the data warehouse star schema';
COMMENT ON SCHEMA fact IS 'Fact tables for the data warehouse star schema';
COMMENT ON SCHEMA integration IS 'ETL staging tables and lineage tracking';
COMMENT ON SCHEMA sequences IS 'Sequences for surrogate key generation';
