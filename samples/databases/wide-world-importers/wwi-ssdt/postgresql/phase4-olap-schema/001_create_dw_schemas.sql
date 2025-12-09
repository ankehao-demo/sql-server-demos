-- Wide World Importers PostgreSQL Migration
-- Phase 4: OLAP Schema Migration (WideWorldImportersDW)
-- Script 001: Create Data Warehouse Schemas and Extensions
-- Migrated from SQL Server to PostgreSQL

-- =============================================
-- Enable Required Extensions
-- =============================================
CREATE EXTENSION IF NOT EXISTS postgis;
CREATE EXTENSION IF NOT EXISTS pg_partman;

-- =============================================
-- Create Data Warehouse Schemas
-- =============================================

-- Dimension schema for dimension tables
CREATE SCHEMA IF NOT EXISTS dimension;
COMMENT ON SCHEMA dimension IS 'Contains dimension tables for the data warehouse star schema';

-- Fact schema for fact tables
CREATE SCHEMA IF NOT EXISTS fact;
COMMENT ON SCHEMA fact IS 'Contains fact tables for the data warehouse star schema';

-- Integration schema for ETL staging and procedures
CREATE SCHEMA IF NOT EXISTS integration;
COMMENT ON SCHEMA integration IS 'Contains staging tables and ETL procedures for data warehouse loading';

-- =============================================
-- Create Sequences for Surrogate Keys
-- =============================================

-- Dimension surrogate key sequences
CREATE SEQUENCE IF NOT EXISTS dimension.city_key_seq START WITH 1 INCREMENT BY 1 NO MINVALUE NO MAXVALUE CACHE 1;
CREATE SEQUENCE IF NOT EXISTS dimension.customer_key_seq START WITH 1 INCREMENT BY 1 NO MINVALUE NO MAXVALUE CACHE 1;
CREATE SEQUENCE IF NOT EXISTS dimension.employee_key_seq START WITH 1 INCREMENT BY 1 NO MINVALUE NO MAXVALUE CACHE 1;
CREATE SEQUENCE IF NOT EXISTS dimension.payment_method_key_seq START WITH 1 INCREMENT BY 1 NO MINVALUE NO MAXVALUE CACHE 1;
CREATE SEQUENCE IF NOT EXISTS dimension.stock_item_key_seq START WITH 1 INCREMENT BY 1 NO MINVALUE NO MAXVALUE CACHE 1;
CREATE SEQUENCE IF NOT EXISTS dimension.supplier_key_seq START WITH 1 INCREMENT BY 1 NO MINVALUE NO MAXVALUE CACHE 1;
CREATE SEQUENCE IF NOT EXISTS dimension.transaction_type_key_seq START WITH 1 INCREMENT BY 1 NO MINVALUE NO MAXVALUE CACHE 1;

-- Fact table sequences
CREATE SEQUENCE IF NOT EXISTS fact.movement_key_seq START WITH 1 INCREMENT BY 1 NO MINVALUE NO MAXVALUE CACHE 1;
CREATE SEQUENCE IF NOT EXISTS fact.order_key_seq START WITH 1 INCREMENT BY 1 NO MINVALUE NO MAXVALUE CACHE 1;
CREATE SEQUENCE IF NOT EXISTS fact.purchase_key_seq START WITH 1 INCREMENT BY 1 NO MINVALUE NO MAXVALUE CACHE 1;
CREATE SEQUENCE IF NOT EXISTS fact.sale_key_seq START WITH 1 INCREMENT BY 1 NO MINVALUE NO MAXVALUE CACHE 1;
CREATE SEQUENCE IF NOT EXISTS fact.transaction_key_seq START WITH 1 INCREMENT BY 1 NO MINVALUE NO MAXVALUE CACHE 1;

-- Integration lineage sequence
CREATE SEQUENCE IF NOT EXISTS integration.lineage_key_seq START WITH 1 INCREMENT BY 1 NO MINVALUE NO MAXVALUE CACHE 1;

COMMENT ON SEQUENCE dimension.city_key_seq IS 'Surrogate key sequence for City dimension';
COMMENT ON SEQUENCE dimension.customer_key_seq IS 'Surrogate key sequence for Customer dimension';
COMMENT ON SEQUENCE dimension.employee_key_seq IS 'Surrogate key sequence for Employee dimension';
COMMENT ON SEQUENCE dimension.payment_method_key_seq IS 'Surrogate key sequence for Payment Method dimension';
COMMENT ON SEQUENCE dimension.stock_item_key_seq IS 'Surrogate key sequence for Stock Item dimension';
COMMENT ON SEQUENCE dimension.supplier_key_seq IS 'Surrogate key sequence for Supplier dimension';
COMMENT ON SEQUENCE dimension.transaction_type_key_seq IS 'Surrogate key sequence for Transaction Type dimension';
COMMENT ON SEQUENCE fact.movement_key_seq IS 'Surrogate key sequence for Movement fact';
COMMENT ON SEQUENCE fact.order_key_seq IS 'Surrogate key sequence for Order fact';
COMMENT ON SEQUENCE fact.purchase_key_seq IS 'Surrogate key sequence for Purchase fact';
COMMENT ON SEQUENCE fact.sale_key_seq IS 'Surrogate key sequence for Sale fact';
COMMENT ON SEQUENCE fact.transaction_key_seq IS 'Surrogate key sequence for Transaction fact';
COMMENT ON SEQUENCE integration.lineage_key_seq IS 'Sequence for ETL lineage tracking';
