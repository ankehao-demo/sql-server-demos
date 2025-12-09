-- Wide World Importers PostgreSQL Migration
-- Phase 2: OLTP Schema Migration
-- File: 001-test-schema.sql
-- Description: Test scripts to validate schema migration

-- Test 1: Verify all schemas exist
DO $$
DECLARE
    schema_count integer;
BEGIN
    SELECT COUNT(*) INTO schema_count
    FROM information_schema.schemata
    WHERE schema_name IN ('application', 'warehouse', 'sales', 'purchasing', 'sequences');
    
    IF schema_count = 5 THEN
        RAISE NOTICE 'TEST PASSED: All 5 schemas exist';
    ELSE
        RAISE EXCEPTION 'TEST FAILED: Expected 5 schemas, found %', schema_count;
    END IF;
END $$;

-- Test 2: Verify all sequences exist
DO $$
DECLARE
    seq_count integer;
    expected_count integer := 26;
BEGIN
    SELECT COUNT(*) INTO seq_count
    FROM information_schema.sequences
    WHERE sequence_schema = 'sequences';
    
    IF seq_count = expected_count THEN
        RAISE NOTICE 'TEST PASSED: All % sequences exist', expected_count;
    ELSE
        RAISE EXCEPTION 'TEST FAILED: Expected % sequences, found %', expected_count, seq_count;
    END IF;
END $$;

-- Test 3: Verify Application schema tables exist
DO $$
DECLARE
    table_count integer;
    expected_count integer := 9;
BEGIN
    SELECT COUNT(*) INTO table_count
    FROM information_schema.tables
    WHERE table_schema = 'application'
    AND table_type = 'BASE TABLE'
    AND table_name NOT LIKE '%_archive';
    
    IF table_count = expected_count THEN
        RAISE NOTICE 'TEST PASSED: All % Application tables exist', expected_count;
    ELSE
        RAISE EXCEPTION 'TEST FAILED: Expected % Application tables, found %', expected_count, table_count;
    END IF;
END $$;

-- Test 4: Verify Warehouse schema tables exist
DO $$
DECLARE
    table_count integer;
    expected_count integer := 9;
BEGIN
    SELECT COUNT(*) INTO table_count
    FROM information_schema.tables
    WHERE table_schema = 'warehouse'
    AND table_type = 'BASE TABLE'
    AND table_name NOT LIKE '%_archive';
    
    IF table_count = expected_count THEN
        RAISE NOTICE 'TEST PASSED: All % Warehouse tables exist', expected_count;
    ELSE
        RAISE EXCEPTION 'TEST FAILED: Expected % Warehouse tables, found %', expected_count, table_count;
    END IF;
END $$;

-- Test 5: Verify Sales schema tables exist
DO $$
DECLARE
    table_count integer;
    expected_count integer := 9;
BEGIN
    SELECT COUNT(*) INTO table_count
    FROM information_schema.tables
    WHERE table_schema = 'sales'
    AND table_type = 'BASE TABLE'
    AND table_name NOT LIKE '%_archive';
    
    IF table_count = expected_count THEN
        RAISE NOTICE 'TEST PASSED: All % Sales tables exist', expected_count;
    ELSE
        RAISE EXCEPTION 'TEST FAILED: Expected % Sales tables, found %', expected_count, table_count;
    END IF;
END $$;

-- Test 6: Verify Purchasing schema tables exist
DO $$
DECLARE
    table_count integer;
    expected_count integer := 5;
BEGIN
    SELECT COUNT(*) INTO table_count
    FROM information_schema.tables
    WHERE table_schema = 'purchasing'
    AND table_type = 'BASE TABLE'
    AND table_name NOT LIKE '%_archive';
    
    IF table_count = expected_count THEN
        RAISE NOTICE 'TEST PASSED: All % Purchasing tables exist', expected_count;
    ELSE
        RAISE EXCEPTION 'TEST FAILED: Expected % Purchasing tables, found %', expected_count, table_count;
    END IF;
END $$;

-- Test 7: Verify archive tables exist for temporal tables
DO $$
DECLARE
    archive_count integer;
    expected_count integer := 17;
BEGIN
    SELECT COUNT(*) INTO archive_count
    FROM information_schema.tables
    WHERE table_type = 'BASE TABLE'
    AND table_name LIKE '%_archive';
    
    IF archive_count = expected_count THEN
        RAISE NOTICE 'TEST PASSED: All % archive tables exist', expected_count;
    ELSE
        RAISE EXCEPTION 'TEST FAILED: Expected % archive tables, found %', expected_count, archive_count;
    END IF;
END $$;

-- Test 8: Verify temporal triggers exist
-- Note: Using pg_trigger instead of information_schema.triggers because the latter
-- counts each trigger event (INSERT, UPDATE, DELETE) separately
DO $$
DECLARE
    trigger_count integer;
    expected_count integer := 17;
BEGIN
    SELECT COUNT(DISTINCT tgname) INTO trigger_count
    FROM pg_trigger
    WHERE tgname LIKE 'tr_%_temporal'
    AND NOT tgisinternal;
    
    IF trigger_count = expected_count THEN
        RAISE NOTICE 'TEST PASSED: All % temporal triggers exist', expected_count;
    ELSE
        RAISE EXCEPTION 'TEST FAILED: Expected % temporal triggers, found %', expected_count, trigger_count;
    END IF;
END $$;

-- Test 9: Verify sequences are functional
DO $$
DECLARE
    next_val bigint;
BEGIN
    SELECT nextval('sequences.personid') INTO next_val;
    IF next_val IS NOT NULL THEN
        RAISE NOTICE 'TEST PASSED: Sequence sequences.personid is functional (value: %)', next_val;
    ELSE
        RAISE EXCEPTION 'TEST FAILED: Sequence sequences.personid returned NULL';
    END IF;
END $$;

-- Test 10: Verify foreign key constraints exist
DO $$
DECLARE
    fk_count integer;
BEGIN
    SELECT COUNT(*) INTO fk_count
    FROM information_schema.table_constraints
    WHERE constraint_type = 'FOREIGN KEY';
    
    IF fk_count > 50 THEN
        RAISE NOTICE 'TEST PASSED: % foreign key constraints exist', fk_count;
    ELSE
        RAISE EXCEPTION 'TEST FAILED: Expected more than 50 foreign key constraints, found %', fk_count;
    END IF;
END $$;

-- Test 11: Verify indexes exist
DO $$
DECLARE
    idx_count integer;
BEGIN
    SELECT COUNT(*) INTO idx_count
    FROM pg_indexes
    WHERE schemaname IN ('application', 'warehouse', 'sales', 'purchasing')
    AND indexname LIKE 'ix_%';
    
    IF idx_count > 80 THEN
        RAISE NOTICE 'TEST PASSED: % indexes exist', idx_count;
    ELSE
        RAISE EXCEPTION 'TEST FAILED: Expected more than 80 indexes, found %', idx_count;
    END IF;
END $$;

-- Test 12: Verify PostGIS extension is enabled
DO $$
DECLARE
    ext_exists boolean;
BEGIN
    SELECT EXISTS(SELECT 1 FROM pg_extension WHERE extname = 'postgis') INTO ext_exists;
    
    IF ext_exists THEN
        RAISE NOTICE 'TEST PASSED: PostGIS extension is enabled';
    ELSE
        RAISE EXCEPTION 'TEST FAILED: PostGIS extension is not enabled';
    END IF;
END $$;

-- Test 13: Verify geography columns exist
DO $$
DECLARE
    geo_count integer;
BEGIN
    SELECT COUNT(*) INTO geo_count
    FROM information_schema.columns
    WHERE udt_name = 'geography'
    AND table_schema IN ('application', 'warehouse', 'sales', 'purchasing');
    
    IF geo_count >= 5 THEN
        RAISE NOTICE 'TEST PASSED: % geography columns exist', geo_count;
    ELSE
        RAISE EXCEPTION 'TEST FAILED: Expected at least 5 geography columns, found %', geo_count;
    END IF;
END $$;

-- Summary
DO $$
BEGIN
    RAISE NOTICE '========================================';
    RAISE NOTICE 'All schema validation tests completed!';
    RAISE NOTICE '========================================';
END $$;
