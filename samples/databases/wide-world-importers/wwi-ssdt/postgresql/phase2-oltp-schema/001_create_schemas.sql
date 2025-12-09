-- Wide World Importers PostgreSQL Migration
-- Phase 2: OLTP Schema Migration
-- Script 001: Create Schemas
-- Migrated from SQL Server to PostgreSQL

-- Enable required extensions
CREATE EXTENSION IF NOT EXISTS postgis;
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS pg_trgm;

-- Create schemas (equivalent to SQL Server schemas)
CREATE SCHEMA IF NOT EXISTS application;
CREATE SCHEMA IF NOT EXISTS sales;
CREATE SCHEMA IF NOT EXISTS purchasing;
CREATE SCHEMA IF NOT EXISTS warehouse;
CREATE SCHEMA IF NOT EXISTS website;
CREATE SCHEMA IF NOT EXISTS dataload_simulation;
CREATE SCHEMA IF NOT EXISTS integration;
CREATE SCHEMA IF NOT EXISTS sequences;
CREATE SCHEMA IF NOT EXISTS webapi;

-- Add schema comments
COMMENT ON SCHEMA application IS 'Application-wide tables and configuration';
COMMENT ON SCHEMA sales IS 'Sales-related tables including customers, orders, and invoices';
COMMENT ON SCHEMA purchasing IS 'Purchasing-related tables including suppliers and purchase orders';
COMMENT ON SCHEMA warehouse IS 'Warehouse-related tables including stock items and inventory';
COMMENT ON SCHEMA website IS 'Website-related views and procedures';
COMMENT ON SCHEMA dataload_simulation IS 'Data load simulation procedures for generating test data';
COMMENT ON SCHEMA integration IS 'Integration procedures for ETL processes';
COMMENT ON SCHEMA sequences IS 'Sequence management procedures';
COMMENT ON SCHEMA webapi IS 'Web API views for application access';
