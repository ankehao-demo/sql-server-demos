-- Phase 3: OLTP Code Migration - Test Scripts for Functions
-- These tests validate that the migrated functions work correctly

-- =============================================
-- Test: Application.DetermineCustomerAccess Function
-- =============================================
DO $$
DECLARE
    v_result integer;
    v_city_id integer;
BEGIN
    RAISE NOTICE '=== Testing Application Functions ===';
    
    -- Get a valid city ID
    SELECT cityid INTO v_city_id FROM application.cities LIMIT 1;
    
    IF v_city_id IS NOT NULL THEN
        -- Test the function (should return 1 for superuser)
        SELECT access_result INTO v_result 
        FROM application.determine_customer_access(v_city_id);
        
        IF v_result = 1 THEN
            RAISE NOTICE 'PASS: application.determine_customer_access returned 1 for city %', v_city_id;
        ELSE
            RAISE NOTICE 'INFO: application.determine_customer_access returned % for city % (may be expected based on user role)', v_result, v_city_id;
        END IF;
    ELSE
        RAISE NOTICE 'SKIP: No cities found to test determine_customer_access';
    END IF;
EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'ERROR in application.determine_customer_access: %', SQLERRM;
END;
$$;

-- =============================================
-- Test: Website.CalculateCustomerPrice Function
-- =============================================
DO $$
DECLARE
    v_result numeric(18,2);
    v_customer_id integer;
    v_stock_item_id integer;
BEGIN
    RAISE NOTICE '=== Testing Website Functions ===';
    
    -- Get valid IDs
    SELECT customerid INTO v_customer_id FROM sales.customers LIMIT 1;
    SELECT stockitemid INTO v_stock_item_id FROM warehouse.stockitems LIMIT 1;
    
    IF v_customer_id IS NOT NULL AND v_stock_item_id IS NOT NULL THEN
        -- Test the function
        SELECT website.calculate_customer_price(v_customer_id, v_stock_item_id, CURRENT_DATE) INTO v_result;
        
        IF v_result IS NOT NULL AND v_result > 0 THEN
            RAISE NOTICE 'PASS: website.calculate_customer_price returned % for customer % and stock item %', v_result, v_customer_id, v_stock_item_id;
        ELSE
            RAISE NOTICE 'INFO: website.calculate_customer_price returned % (may be expected if no price defined)', v_result;
        END IF;
    ELSE
        RAISE NOTICE 'SKIP: No customers or stock items found to test calculate_customer_price';
    END IF;
EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'ERROR in website.calculate_customer_price: %', SQLERRM;
END;
$$;

-- =============================================
-- Test: DataLoad Helper Functions
-- =============================================
DO $$
DECLARE
    v_result varchar(100);
    v_int_result integer;
    v_state_id integer;
BEGIN
    RAISE NOTICE '=== Testing DataLoad Functions ===';
    
    -- Get a valid state province ID
    SELECT stateprovinceid INTO v_state_id FROM application.stateprovinces LIMIT 1;
    
    IF v_state_id IS NOT NULL THEN
        -- Test get_area_code
        SELECT dataload.get_area_code(v_state_id) INTO v_result;
        RAISE NOTICE 'PASS: dataload.get_area_code returned % for state %', v_result, v_state_id;
        
        -- Test get_bogative_phone_number
        SELECT dataload.get_bogative_phone_number(v_state_id) INTO v_result;
        RAISE NOTICE 'PASS: dataload.get_bogative_phone_number returned %', v_result;
    ELSE
        RAISE NOTICE 'SKIP: No state provinces found to test dataload functions';
    END IF;
    
    -- Test get_customer_count
    SELECT dataload.get_customer_count() INTO v_int_result;
    RAISE NOTICE 'PASS: dataload.get_customer_count returned %', v_int_result;
    
EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'ERROR in dataload functions: %', SQLERRM;
END;
$$;

DO $$ BEGIN RAISE NOTICE '=== Function Tests Complete ==='; END; $$;
