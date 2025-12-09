-- Wide World Importers PostgreSQL Migration
-- Phase 2: OLTP Schema Migration
-- File: 001-create-schemas.sql
-- Description: Create all database schemas

-- Enable PostGIS extension for geography/geometry support
CREATE EXTENSION IF NOT EXISTS postgis;

-- Create schemas
CREATE SCHEMA IF NOT EXISTS application;
CREATE SCHEMA IF NOT EXISTS warehouse;
CREATE SCHEMA IF NOT EXISTS sales;
CREATE SCHEMA IF NOT EXISTS purchasing;
CREATE SCHEMA IF NOT EXISTS sequences;

-- Grant usage on schemas (adjust as needed for your security requirements)
-- GRANT USAGE ON SCHEMA application TO public;
-- GRANT USAGE ON SCHEMA warehouse TO public;
-- GRANT USAGE ON SCHEMA sales TO public;
-- GRANT USAGE ON SCHEMA purchasing TO public;
-- GRANT USAGE ON SCHEMA sequences TO public;
