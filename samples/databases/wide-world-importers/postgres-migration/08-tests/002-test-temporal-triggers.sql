-- Wide World Importers PostgreSQL Migration
-- Phase 2: OLTP Schema Migration
-- File: 002-test-temporal-triggers.sql
-- Description: Test scripts to validate temporal table trigger functionality

-- Note: These tests should be run after the schema is created and some test data is inserted
-- The tests verify that temporal triggers correctly maintain history in archive tables

-- Test 1: Test INSERT trigger on warehouse.colors
-- Verify that ValidFrom and ValidTo are set correctly on INSERT
DO $$
DECLARE
    test_id integer;
    valid_from timestamp;
    valid_to timestamp;
BEGIN
    -- Insert a test record
    INSERT INTO warehouse.colors (colorname, lasteditedby)
    VALUES ('Test Color', 1)
    RETURNING colorid, validfrom, validto INTO test_id, valid_from, valid_to;
    
    -- Verify ValidFrom is set to current timestamp (within 1 second)
    IF valid_from IS NOT NULL AND valid_from >= CURRENT_TIMESTAMP - INTERVAL '1 second' THEN
        RAISE NOTICE 'TEST PASSED: INSERT trigger sets ValidFrom correctly';
    ELSE
        RAISE EXCEPTION 'TEST FAILED: INSERT trigger did not set ValidFrom correctly';
    END IF;
    
    -- Verify ValidTo is set to infinity
    IF valid_to = '9999-12-31 23:59:59.999999'::timestamp THEN
        RAISE NOTICE 'TEST PASSED: INSERT trigger sets ValidTo to infinity';
    ELSE
        RAISE EXCEPTION 'TEST FAILED: INSERT trigger did not set ValidTo to infinity';
    END IF;
    
    -- Clean up
    DELETE FROM warehouse.colors WHERE colorid = test_id;
END $$;

-- Test 2: Test UPDATE trigger on warehouse.colors
-- Verify that old record is copied to archive and ValidFrom is updated
DO $$
DECLARE
    test_id integer;
    original_valid_from timestamp;
    new_valid_from timestamp;
    archive_count integer;
BEGIN
    -- Insert a test record
    INSERT INTO warehouse.colors (colorname, lasteditedby)
    VALUES ('Test Color Update', 1)
    RETURNING colorid, validfrom INTO test_id, original_valid_from;
    
    -- Wait a moment to ensure timestamp difference
    PERFORM pg_sleep(0.1);
    
    -- Update the record
    UPDATE warehouse.colors
    SET colorname = 'Test Color Updated'
    WHERE colorid = test_id
    RETURNING validfrom INTO new_valid_from;
    
    -- Verify ValidFrom was updated
    IF new_valid_from > original_valid_from THEN
        RAISE NOTICE 'TEST PASSED: UPDATE trigger updates ValidFrom';
    ELSE
        RAISE EXCEPTION 'TEST FAILED: UPDATE trigger did not update ValidFrom';
    END IF;
    
    -- Verify old record was copied to archive
    SELECT COUNT(*) INTO archive_count
    FROM warehouse.colors_archive
    WHERE colorid = test_id;
    
    IF archive_count = 1 THEN
        RAISE NOTICE 'TEST PASSED: UPDATE trigger copies old record to archive';
    ELSE
        RAISE EXCEPTION 'TEST FAILED: UPDATE trigger did not copy old record to archive (count: %)', archive_count;
    END IF;
    
    -- Clean up
    DELETE FROM warehouse.colors WHERE colorid = test_id;
    DELETE FROM warehouse.colors_archive WHERE colorid = test_id;
END $$;

-- Test 3: Test DELETE trigger on warehouse.colors
-- Verify that deleted record is copied to archive
DO $$
DECLARE
    test_id integer;
    archive_count integer;
BEGIN
    -- Insert a test record
    INSERT INTO warehouse.colors (colorname, lasteditedby)
    VALUES ('Test Color Delete', 1)
    RETURNING colorid INTO test_id;
    
    -- Delete the record
    DELETE FROM warehouse.colors WHERE colorid = test_id;
    
    -- Verify record was copied to archive
    SELECT COUNT(*) INTO archive_count
    FROM warehouse.colors_archive
    WHERE colorid = test_id;
    
    IF archive_count >= 1 THEN
        RAISE NOTICE 'TEST PASSED: DELETE trigger copies record to archive';
    ELSE
        RAISE EXCEPTION 'TEST FAILED: DELETE trigger did not copy record to archive';
    END IF;
    
    -- Clean up
    DELETE FROM warehouse.colors_archive WHERE colorid = test_id;
END $$;

-- Test 4: Test multiple updates create multiple archive records
DO $$
DECLARE
    test_id integer;
    archive_count integer;
BEGIN
    -- Insert a test record
    INSERT INTO warehouse.colors (colorname, lasteditedby)
    VALUES ('Test Color Multi', 1)
    RETURNING colorid INTO test_id;
    
    -- Perform multiple updates
    PERFORM pg_sleep(0.1);
    UPDATE warehouse.colors SET colorname = 'Test Color Multi 1' WHERE colorid = test_id;
    
    PERFORM pg_sleep(0.1);
    UPDATE warehouse.colors SET colorname = 'Test Color Multi 2' WHERE colorid = test_id;
    
    PERFORM pg_sleep(0.1);
    UPDATE warehouse.colors SET colorname = 'Test Color Multi 3' WHERE colorid = test_id;
    
    -- Verify 3 archive records exist
    SELECT COUNT(*) INTO archive_count
    FROM warehouse.colors_archive
    WHERE colorid = test_id;
    
    IF archive_count = 3 THEN
        RAISE NOTICE 'TEST PASSED: Multiple updates create multiple archive records (count: %)', archive_count;
    ELSE
        RAISE EXCEPTION 'TEST FAILED: Expected 3 archive records, found %', archive_count;
    END IF;
    
    -- Clean up
    DELETE FROM warehouse.colors WHERE colorid = test_id;
    DELETE FROM warehouse.colors_archive WHERE colorid = test_id;
END $$;

-- Test 5: Verify archive ValidTo is set correctly
DO $$
DECLARE
    test_id integer;
    archive_valid_to timestamp;
    current_ts timestamp;
BEGIN
    -- Insert a test record
    INSERT INTO warehouse.colors (colorname, lasteditedby)
    VALUES ('Test Color ValidTo', 1)
    RETURNING colorid INTO test_id;
    
    -- Wait and update
    PERFORM pg_sleep(0.1);
    current_ts := CURRENT_TIMESTAMP;
    UPDATE warehouse.colors SET colorname = 'Test Color ValidTo Updated' WHERE colorid = test_id;
    
    -- Check archive ValidTo
    SELECT validto INTO archive_valid_to
    FROM warehouse.colors_archive
    WHERE colorid = test_id
    ORDER BY validto DESC
    LIMIT 1;
    
    -- ValidTo should be close to current timestamp (within 1 second)
    IF archive_valid_to IS NOT NULL AND archive_valid_to >= current_ts - INTERVAL '1 second' THEN
        RAISE NOTICE 'TEST PASSED: Archive ValidTo is set to update timestamp';
    ELSE
        RAISE EXCEPTION 'TEST FAILED: Archive ValidTo is not set correctly';
    END IF;
    
    -- Clean up
    DELETE FROM warehouse.colors WHERE colorid = test_id;
    DELETE FROM warehouse.colors_archive WHERE colorid = test_id;
END $$;

-- Summary
DO $$
BEGIN
    RAISE NOTICE '========================================';
    RAISE NOTICE 'All temporal trigger tests completed!';
    RAISE NOTICE '========================================';
END $$;
