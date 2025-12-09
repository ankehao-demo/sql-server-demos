-- Wide World Importers DW PostgreSQL Migration
-- Phase 4: OLAP Schema Migration
-- File: 001-create-schemas.sql
-- Description: Create all data warehouse schemas

-- Enable PostGIS extension for geography/geometry support (if not already enabled)
CREATE EXTENSION IF NOT EXISTS postgis;

-- Create data warehouse schemas
CREATE SCHEMA IF NOT EXISTS dimension;
CREATE SCHEMA IF NOT EXISTS fact;
CREATE SCHEMA IF NOT EXISTS integration;

-- Note: sequences schema already exists from OLTP migration
-- CREATE SCHEMA IF NOT EXISTS sequences;

-- Add comments to schemas
COMMENT ON SCHEMA dimension IS 'Data warehouse dimension tables for star schema';
COMMENT ON SCHEMA fact IS 'Data warehouse fact tables for star schema';
COMMENT ON SCHEMA integration IS 'ETL staging tables and lineage tracking for data warehouse';
