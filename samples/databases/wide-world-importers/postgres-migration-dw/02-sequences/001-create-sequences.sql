-- Wide World Importers DW PostgreSQL Migration
-- Phase 4: OLAP Schema Migration
-- File: 001-create-sequences.sql
-- Description: Create sequences for surrogate keys in dimension tables

-- City dimension surrogate key sequence
CREATE SEQUENCE IF NOT EXISTS sequences.city_key
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

-- Customer dimension surrogate key sequence
CREATE SEQUENCE IF NOT EXISTS sequences.customer_key
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

-- Employee dimension surrogate key sequence
CREATE SEQUENCE IF NOT EXISTS sequences.employee_key
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

-- Lineage key sequence for ETL tracking
CREATE SEQUENCE IF NOT EXISTS sequences.lineage_key
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

-- Payment method dimension surrogate key sequence
CREATE SEQUENCE IF NOT EXISTS sequences.payment_method_key
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

-- Stock item dimension surrogate key sequence
CREATE SEQUENCE IF NOT EXISTS sequences.stock_item_key
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

-- Supplier dimension surrogate key sequence
CREATE SEQUENCE IF NOT EXISTS sequences.supplier_key
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

-- Transaction type dimension surrogate key sequence
CREATE SEQUENCE IF NOT EXISTS sequences.transaction_type_key
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

-- Add comments
COMMENT ON SEQUENCE sequences.city_key IS 'Surrogate key sequence for City dimension';
COMMENT ON SEQUENCE sequences.customer_key IS 'Surrogate key sequence for Customer dimension';
COMMENT ON SEQUENCE sequences.employee_key IS 'Surrogate key sequence for Employee dimension';
COMMENT ON SEQUENCE sequences.lineage_key IS 'Sequence for ETL lineage tracking';
COMMENT ON SEQUENCE sequences.payment_method_key IS 'Surrogate key sequence for Payment Method dimension';
COMMENT ON SEQUENCE sequences.stock_item_key IS 'Surrogate key sequence for Stock Item dimension';
COMMENT ON SEQUENCE sequences.supplier_key IS 'Surrogate key sequence for Supplier dimension';
COMMENT ON SEQUENCE sequences.transaction_type_key IS 'Surrogate key sequence for Transaction Type dimension';
