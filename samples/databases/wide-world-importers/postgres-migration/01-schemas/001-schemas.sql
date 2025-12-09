-- Wide World Importers PostgreSQL Migration
-- Phase 2: OLTP Schema Migration
-- Schema definitions

-- Create schemas to match SQL Server schema organization
CREATE SCHEMA IF NOT EXISTS application;
CREATE SCHEMA IF NOT EXISTS purchasing;
CREATE SCHEMA IF NOT EXISTS sales;
CREATE SCHEMA IF NOT EXISTS warehouse;
CREATE SCHEMA IF NOT EXISTS sequences;
