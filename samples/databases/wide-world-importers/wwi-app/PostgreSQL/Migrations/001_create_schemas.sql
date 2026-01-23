-- Wide World Importers PostgreSQL Migration
-- Script 001: Create Schemas
-- Migrated from SQL Server to PostgreSQL

-- Enable required extensions
CREATE EXTENSION IF NOT EXISTS postgis;           -- For spatial data (geography type)
CREATE EXTENSION IF NOT EXISTS pg_trgm;           -- For trigram-based text search
CREATE EXTENSION IF NOT EXISTS btree_gin;         -- For GIN indexes on scalar types

-- Create schemas matching SQL Server structure
CREATE SCHEMA IF NOT EXISTS application;
CREATE SCHEMA IF NOT EXISTS sales;
CREATE SCHEMA IF NOT EXISTS purchasing;
CREATE SCHEMA IF NOT EXISTS warehouse;
CREATE SCHEMA IF NOT EXISTS website;
CREATE SCHEMA IF NOT EXISTS dataloadsimulation;
CREATE SCHEMA IF NOT EXISTS integration;
CREATE SCHEMA IF NOT EXISTS webapi;

-- Add schema comments
COMMENT ON SCHEMA application IS 'Application-wide entities: People, Countries, Cities, Delivery/Payment Methods';
COMMENT ON SCHEMA sales IS 'Sales entities: Customers, Orders, Invoices, Transactions';
COMMENT ON SCHEMA purchasing IS 'Purchasing entities: Suppliers, Purchase Orders, Transactions';
COMMENT ON SCHEMA warehouse IS 'Warehouse entities: Stock Items, Colors, Package Types, Temperatures';
COMMENT ON SCHEMA website IS 'Website views and stored procedures for web interface';
COMMENT ON SCHEMA dataloadsimulation IS 'Data generation simulation procedures';
COMMENT ON SCHEMA integration IS 'Integration procedures for ETL operations';
COMMENT ON SCHEMA webapi IS 'WebAPI views for REST endpoints';
