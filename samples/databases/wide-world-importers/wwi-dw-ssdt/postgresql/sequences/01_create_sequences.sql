-- Wide World Importers Data Warehouse - PostgreSQL Schema Migration
-- Phase 4: OLAP Schema Migration
-- This script creates the sequences for surrogate key generation

-- City dimension surrogate key sequence
CREATE SEQUENCE IF NOT EXISTS sequences.city_key
    AS INTEGER
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

COMMENT ON SEQUENCE sequences.city_key IS 'Surrogate key sequence for City dimension';

-- Customer dimension surrogate key sequence
CREATE SEQUENCE IF NOT EXISTS sequences.customer_key
    AS INTEGER
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

COMMENT ON SEQUENCE sequences.customer_key IS 'Surrogate key sequence for Customer dimension';

-- Employee dimension surrogate key sequence
CREATE SEQUENCE IF NOT EXISTS sequences.employee_key
    AS INTEGER
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

COMMENT ON SEQUENCE sequences.employee_key IS 'Surrogate key sequence for Employee dimension';

-- Payment Method dimension surrogate key sequence
CREATE SEQUENCE IF NOT EXISTS sequences.payment_method_key
    AS INTEGER
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

COMMENT ON SEQUENCE sequences.payment_method_key IS 'Surrogate key sequence for Payment Method dimension';

-- Stock Item dimension surrogate key sequence
CREATE SEQUENCE IF NOT EXISTS sequences.stock_item_key
    AS INTEGER
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

COMMENT ON SEQUENCE sequences.stock_item_key IS 'Surrogate key sequence for Stock Item dimension';

-- Supplier dimension surrogate key sequence
CREATE SEQUENCE IF NOT EXISTS sequences.supplier_key
    AS INTEGER
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

COMMENT ON SEQUENCE sequences.supplier_key IS 'Surrogate key sequence for Supplier dimension';

-- Transaction Type dimension surrogate key sequence
CREATE SEQUENCE IF NOT EXISTS sequences.transaction_type_key
    AS INTEGER
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

COMMENT ON SEQUENCE sequences.transaction_type_key IS 'Surrogate key sequence for Transaction Type dimension';

-- Lineage tracking surrogate key sequence
CREATE SEQUENCE IF NOT EXISTS sequences.lineage_key
    AS INTEGER
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

COMMENT ON SEQUENCE sequences.lineage_key IS 'Surrogate key sequence for ETL lineage tracking';
