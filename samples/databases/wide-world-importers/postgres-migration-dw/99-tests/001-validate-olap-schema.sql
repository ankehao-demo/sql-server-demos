-- Wide World Importers DW PostgreSQL Migration
-- Phase 4: OLAP Schema Migration
-- File: 001-validate-olap-schema.sql
-- Description: Validation tests for the OLAP schema migration

-- =============================================
-- Test 1: Verify all schemas exist
-- =============================================
DO $$
DECLARE
    v_schema_count integer;
BEGIN
    SELECT COUNT(*) INTO v_schema_count
    FROM information_schema.schemata
    WHERE schema_name IN ('dimension', 'fact', 'integration');
    
    IF v_schema_count = 3 THEN
        RAISE NOTICE 'TEST PASSED: All 3 data warehouse schemas exist (dimension, fact, integration)';
    ELSE
        RAISE EXCEPTION 'TEST FAILED: Expected 3 schemas, found %', v_schema_count;
    END IF;
END $$;

-- =============================================
-- Test 2: Verify all dimension tables exist
-- =============================================
DO $$
DECLARE
    v_table_count integer;
    v_expected_tables text[] := ARRAY['city', 'customer', 'date', 'employee', 'payment_method', 'stock_item', 'supplier', 'transaction_type'];
    v_missing_tables text := '';
    v_table text;
BEGIN
    SELECT COUNT(*) INTO v_table_count
    FROM information_schema.tables
    WHERE table_schema = 'dimension'
    AND table_type = 'BASE TABLE';
    
    FOREACH v_table IN ARRAY v_expected_tables
    LOOP
        IF NOT EXISTS (
            SELECT 1 FROM information_schema.tables 
            WHERE table_schema = 'dimension' AND table_name = v_table
        ) THEN
            v_missing_tables := v_missing_tables || v_table || ', ';
        END IF;
    END LOOP;
    
    IF v_missing_tables = '' THEN
        RAISE NOTICE 'TEST PASSED: All 8 dimension tables exist';
    ELSE
        RAISE EXCEPTION 'TEST FAILED: Missing dimension tables: %', v_missing_tables;
    END IF;
END $$;

-- =============================================
-- Test 3: Verify all fact tables exist (including partitions)
-- =============================================
DO $$
DECLARE
    v_table_count integer;
    v_expected_tables text[] := ARRAY['sale', 'order', 'purchase', 'movement', 'transaction', 'stock_holding'];
    v_missing_tables text := '';
    v_table text;
BEGIN
    FOREACH v_table IN ARRAY v_expected_tables
    LOOP
        IF NOT EXISTS (
            SELECT 1 FROM information_schema.tables 
            WHERE table_schema = 'fact' AND table_name = v_table
        ) THEN
            v_missing_tables := v_missing_tables || v_table || ', ';
        END IF;
    END LOOP;
    
    IF v_missing_tables = '' THEN
        RAISE NOTICE 'TEST PASSED: All 6 fact tables exist';
    ELSE
        RAISE EXCEPTION 'TEST FAILED: Missing fact tables: %', v_missing_tables;
    END IF;
END $$;

-- =============================================
-- Test 4: Verify all staging tables exist
-- =============================================
DO $$
DECLARE
    v_expected_tables text[] := ARRAY[
        'city_staging', 'customer_staging', 'employee_staging', 
        'payment_method_staging', 'stock_item_staging', 'supplier_staging',
        'transaction_type_staging', 'sale_staging', 'order_staging',
        'purchase_staging', 'movement_staging', 'transaction_staging',
        'stock_holding_staging'
    ];
    v_missing_tables text := '';
    v_table text;
BEGIN
    FOREACH v_table IN ARRAY v_expected_tables
    LOOP
        IF NOT EXISTS (
            SELECT 1 FROM information_schema.tables 
            WHERE table_schema = 'integration' AND table_name = v_table
        ) THEN
            v_missing_tables := v_missing_tables || v_table || ', ';
        END IF;
    END LOOP;
    
    IF v_missing_tables = '' THEN
        RAISE NOTICE 'TEST PASSED: All 13 staging tables exist';
    ELSE
        RAISE EXCEPTION 'TEST FAILED: Missing staging tables: %', v_missing_tables;
    END IF;
END $$;

-- =============================================
-- Test 5: Verify integration tables exist
-- =============================================
DO $$
DECLARE
    v_lineage_exists boolean;
    v_etl_cutoff_exists boolean;
BEGIN
    SELECT EXISTS (
        SELECT 1 FROM information_schema.tables 
        WHERE table_schema = 'integration' AND table_name = 'lineage'
    ) INTO v_lineage_exists;
    
    SELECT EXISTS (
        SELECT 1 FROM information_schema.tables 
        WHERE table_schema = 'integration' AND table_name = 'etl_cutoff'
    ) INTO v_etl_cutoff_exists;
    
    IF v_lineage_exists AND v_etl_cutoff_exists THEN
        RAISE NOTICE 'TEST PASSED: Integration tables (lineage, etl_cutoff) exist';
    ELSE
        RAISE EXCEPTION 'TEST FAILED: Missing integration tables. lineage: %, etl_cutoff: %', v_lineage_exists, v_etl_cutoff_exists;
    END IF;
END $$;

-- =============================================
-- Test 6: Verify all sequences exist
-- =============================================
DO $$
DECLARE
    v_expected_sequences text[] := ARRAY[
        'city_key', 'customer_key', 'employee_key', 'lineage_key',
        'payment_method_key', 'stock_item_key', 'supplier_key', 'transaction_type_key'
    ];
    v_missing_sequences text := '';
    v_seq text;
BEGIN
    FOREACH v_seq IN ARRAY v_expected_sequences
    LOOP
        IF NOT EXISTS (
            SELECT 1 FROM information_schema.sequences 
            WHERE sequence_schema = 'sequences' AND sequence_name = v_seq
        ) THEN
            v_missing_sequences := v_missing_sequences || v_seq || ', ';
        END IF;
    END LOOP;
    
    IF v_missing_sequences = '' THEN
        RAISE NOTICE 'TEST PASSED: All 8 surrogate key sequences exist';
    ELSE
        RAISE EXCEPTION 'TEST FAILED: Missing sequences: %', v_missing_sequences;
    END IF;
END $$;

-- =============================================
-- Test 7: Verify dimension table structures
-- =============================================
DO $$
DECLARE
    v_city_columns integer;
    v_customer_columns integer;
    v_date_columns integer;
BEGIN
    SELECT COUNT(*) INTO v_city_columns
    FROM information_schema.columns
    WHERE table_schema = 'dimension' AND table_name = 'city';
    
    SELECT COUNT(*) INTO v_customer_columns
    FROM information_schema.columns
    WHERE table_schema = 'dimension' AND table_name = 'customer';
    
    SELECT COUNT(*) INTO v_date_columns
    FROM information_schema.columns
    WHERE table_schema = 'dimension' AND table_name = 'date';
    
    IF v_city_columns >= 13 AND v_customer_columns >= 11 AND v_date_columns >= 60 THEN
        RAISE NOTICE 'TEST PASSED: Dimension tables have expected column counts (city: %, customer: %, date: %)', v_city_columns, v_customer_columns, v_date_columns;
    ELSE
        RAISE EXCEPTION 'TEST FAILED: Dimension table column counts incorrect. city: % (expected >= 13), customer: % (expected >= 11), date: % (expected >= 60)', v_city_columns, v_customer_columns, v_date_columns;
    END IF;
END $$;

-- =============================================
-- Test 8: Verify fact table partitioning
-- =============================================
DO $$
DECLARE
    v_sale_partitions integer;
    v_order_partitions integer;
BEGIN
    SELECT COUNT(*) INTO v_sale_partitions
    FROM pg_inherits
    JOIN pg_class parent ON pg_inherits.inhparent = parent.oid
    JOIN pg_class child ON pg_inherits.inhrelid = child.oid
    JOIN pg_namespace ns ON parent.relnamespace = ns.oid
    WHERE ns.nspname = 'fact' AND parent.relname = 'sale';
    
    SELECT COUNT(*) INTO v_order_partitions
    FROM pg_inherits
    JOIN pg_class parent ON pg_inherits.inhparent = parent.oid
    JOIN pg_class child ON pg_inherits.inhrelid = child.oid
    JOIN pg_namespace ns ON parent.relnamespace = ns.oid
    WHERE ns.nspname = 'fact' AND parent.relname = 'order';
    
    IF v_sale_partitions >= 10 AND v_order_partitions >= 10 THEN
        RAISE NOTICE 'TEST PASSED: Fact tables are properly partitioned (sale: % partitions, order: % partitions)', v_sale_partitions, v_order_partitions;
    ELSE
        RAISE EXCEPTION 'TEST FAILED: Fact table partitioning incorrect. sale: % partitions (expected >= 10), order: % partitions (expected >= 10)', v_sale_partitions, v_order_partitions;
    END IF;
END $$;

-- =============================================
-- Test 9: Verify foreign key constraints on fact tables
-- =============================================
DO $$
DECLARE
    v_sale_fk_count integer;
    v_order_fk_count integer;
BEGIN
    SELECT COUNT(*) INTO v_sale_fk_count
    FROM information_schema.table_constraints
    WHERE table_schema = 'fact' AND table_name = 'sale' AND constraint_type = 'FOREIGN KEY';
    
    SELECT COUNT(*) INTO v_order_fk_count
    FROM information_schema.table_constraints
    WHERE table_schema = 'fact' AND table_name = 'order' AND constraint_type = 'FOREIGN KEY';
    
    IF v_sale_fk_count >= 5 AND v_order_fk_count >= 5 THEN
        RAISE NOTICE 'TEST PASSED: Fact tables have foreign key constraints (sale: %, order: %)', v_sale_fk_count, v_order_fk_count;
    ELSE
        RAISE EXCEPTION 'TEST FAILED: Fact table FK constraints incorrect. sale: % (expected >= 5), order: % (expected >= 5)', v_sale_fk_count, v_order_fk_count;
    END IF;
END $$;

-- =============================================
-- Test 10: Verify ETL cutoff initialization
-- =============================================
DO $$
DECLARE
    v_cutoff_count integer;
BEGIN
    SELECT COUNT(*) INTO v_cutoff_count
    FROM integration.etl_cutoff;
    
    IF v_cutoff_count >= 13 THEN
        RAISE NOTICE 'TEST PASSED: ETL cutoff table initialized with % entries', v_cutoff_count;
    ELSE
        RAISE EXCEPTION 'TEST FAILED: ETL cutoff table has % entries (expected >= 13)', v_cutoff_count;
    END IF;
END $$;

-- =============================================
-- Test 11: Verify surrogate key sequence functionality
-- =============================================
DO $$
DECLARE
    v_city_key integer;
    v_customer_key integer;
BEGIN
    SELECT nextval('sequences.city_key') INTO v_city_key;
    SELECT nextval('sequences.customer_key') INTO v_customer_key;
    
    IF v_city_key >= 1 AND v_customer_key >= 1 THEN
        RAISE NOTICE 'TEST PASSED: Surrogate key sequences are functional (city_key: %, customer_key: %)', v_city_key, v_customer_key;
    ELSE
        RAISE EXCEPTION 'TEST FAILED: Surrogate key sequences not working properly';
    END IF;
END $$;

-- =============================================
-- Test 12: Verify staging tables are UNLOGGED
-- =============================================
DO $$
DECLARE
    v_unlogged_count integer;
BEGIN
    SELECT COUNT(*) INTO v_unlogged_count
    FROM pg_class c
    JOIN pg_namespace n ON c.relnamespace = n.oid
    WHERE n.nspname = 'integration'
    AND c.relname LIKE '%_staging'
    AND c.relpersistence = 'u';
    
    IF v_unlogged_count >= 13 THEN
        RAISE NOTICE 'TEST PASSED: All % staging tables are UNLOGGED for performance', v_unlogged_count;
    ELSE
        RAISE EXCEPTION 'TEST FAILED: Only % staging tables are UNLOGGED (expected >= 13)', v_unlogged_count;
    END IF;
END $$;

-- =============================================
-- Summary
-- =============================================
DO $$
BEGIN
    RAISE NOTICE '============================================';
    RAISE NOTICE 'OLAP Schema Validation Complete';
    RAISE NOTICE 'All tests passed successfully!';
    RAISE NOTICE '============================================';
END $$;
