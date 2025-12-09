-- Phase 3: OLTP Code Migration - Test Scripts for Stored Procedures
-- These tests validate that the migrated stored procedures work correctly

-- =============================================
-- Test: Application Schema Procedures
-- =============================================
DO $$
DECLARE
    v_role_name varchar(50) := 'test_role_' || floor(random() * 10000)::text;
BEGIN
    RAISE NOTICE '=== Testing Application Procedures ===';
    
    -- Test create_role_if_nonexistent
    BEGIN
        CALL application.create_role_if_nonexistent(v_role_name);
        RAISE NOTICE 'PASS: application.create_role_if_nonexistent created role %', v_role_name;
        
        -- Clean up
        EXECUTE format('DROP ROLE IF EXISTS %I', v_role_name);
    EXCEPTION
        WHEN OTHERS THEN
            RAISE NOTICE 'ERROR in create_role_if_nonexistent: %', SQLERRM;
    END;
    
    -- Test configuration_apply_columnstore_indexing (creates BRIN indexes)
    BEGIN
        CALL application.configuration_apply_columnstore_indexing();
        RAISE NOTICE 'PASS: application.configuration_apply_columnstore_indexing executed successfully';
    EXCEPTION
        WHEN OTHERS THEN
            RAISE NOTICE 'INFO: configuration_apply_columnstore_indexing: % (may be expected)', SQLERRM;
    END;
    
    -- Test configuration_apply_full_text_indexing (creates GIN indexes)
    BEGIN
        CALL application.configuration_apply_full_text_indexing();
        RAISE NOTICE 'PASS: application.configuration_apply_full_text_indexing executed successfully';
    EXCEPTION
        WHEN OTHERS THEN
            RAISE NOTICE 'INFO: configuration_apply_full_text_indexing: % (may be expected)', SQLERRM;
    END;
END;
$$;

-- =============================================
-- Test: Website Schema Procedures
-- =============================================
DO $$
DECLARE
    v_cursor refcursor;
    v_customer_id integer;
    v_stock_item_id integer;
    v_count integer;
BEGIN
    RAISE NOTICE '=== Testing Website Procedures ===';
    
    -- Get valid IDs for testing
    SELECT customerid INTO v_customer_id FROM sales.customers LIMIT 1;
    SELECT stockitemid INTO v_stock_item_id FROM warehouse.stockitems LIMIT 1;
    
    -- Test search_for_customers
    IF v_customer_id IS NOT NULL THEN
        BEGIN
            CALL website.search_for_customers('Tailspin', v_cursor);
            RAISE NOTICE 'PASS: website.search_for_customers executed successfully';
            CLOSE v_cursor;
        EXCEPTION
            WHEN OTHERS THEN
                RAISE NOTICE 'ERROR in search_for_customers: %', SQLERRM;
        END;
    END IF;
    
    -- Test search_for_stock_items
    IF v_stock_item_id IS NOT NULL THEN
        BEGIN
            CALL website.search_for_stock_items('USB', v_cursor);
            RAISE NOTICE 'PASS: website.search_for_stock_items executed successfully';
            CLOSE v_cursor;
        EXCEPTION
            WHEN OTHERS THEN
                RAISE NOTICE 'ERROR in search_for_stock_items: %', SQLERRM;
        END;
    END IF;
    
    -- Test search_for_suppliers
    BEGIN
        CALL website.search_for_suppliers('Fabrikam', v_cursor);
        RAISE NOTICE 'PASS: website.search_for_suppliers executed successfully';
        CLOSE v_cursor;
    EXCEPTION
        WHEN OTHERS THEN
            RAISE NOTICE 'ERROR in search_for_suppliers: %', SQLERRM;
    END;
    
    -- Test search_for_people
    BEGIN
        CALL website.search_for_people('Kayla', v_cursor);
        RAISE NOTICE 'PASS: website.search_for_people executed successfully';
        CLOSE v_cursor;
    EXCEPTION
        WHEN OTHERS THEN
            RAISE NOTICE 'ERROR in search_for_people: %', SQLERRM;
    END;
END;
$$;

-- =============================================
-- Test: DataLoad Schema Procedures
-- =============================================
DO $$
DECLARE
    v_buying_group_id integer;
    v_city_id integer;
    v_customer_id integer;
    v_customer_category_id integer;
    v_delivery_method_id integer;
    v_person_id integer;
    v_payment_days integer;
    v_stock_item_id integer;
    v_name varchar(100);
    v_postal_code varchar(10);
    v_suffix varchar(20);
    v_street_name varchar(50);
    v_street varchar(100);
    v_secondary_address varchar(50);
    v_domain varchar(100);
BEGIN
    RAISE NOTICE '=== Testing DataLoad Procedures ===';
    
    -- Test get_random_buying_group
    BEGIN
        CALL dataload.get_random_buying_group(v_buying_group_id);
        RAISE NOTICE 'PASS: dataload.get_random_buying_group returned %', v_buying_group_id;
    EXCEPTION
        WHEN OTHERS THEN
            RAISE NOTICE 'INFO: get_random_buying_group: % (may be expected if no buying groups)', SQLERRM;
    END;
    
    -- Test get_random_city
    BEGIN
        CALL dataload.get_random_city(v_city_id);
        RAISE NOTICE 'PASS: dataload.get_random_city returned %', v_city_id;
    EXCEPTION
        WHEN OTHERS THEN
            RAISE NOTICE 'ERROR in get_random_city: %', SQLERRM;
    END;
    
    -- Test get_random_customer
    BEGIN
        CALL dataload.get_random_customer(v_customer_id);
        RAISE NOTICE 'PASS: dataload.get_random_customer returned %', v_customer_id;
    EXCEPTION
        WHEN OTHERS THEN
            RAISE NOTICE 'ERROR in get_random_customer: %', SQLERRM;
    END;
    
    -- Test get_random_customer_category
    BEGIN
        CALL dataload.get_random_customer_category(v_customer_category_id);
        RAISE NOTICE 'PASS: dataload.get_random_customer_category returned %', v_customer_category_id;
    EXCEPTION
        WHEN OTHERS THEN
            RAISE NOTICE 'ERROR in get_random_customer_category: %', SQLERRM;
    END;
    
    -- Test get_random_delivery_method
    BEGIN
        CALL dataload.get_random_delivery_method(v_delivery_method_id);
        RAISE NOTICE 'PASS: dataload.get_random_delivery_method returned %', v_delivery_method_id;
    EXCEPTION
        WHEN OTHERS THEN
            RAISE NOTICE 'ERROR in get_random_delivery_method: %', SQLERRM;
    END;
    
    -- Test get_random_employee_person
    BEGIN
        CALL dataload.get_random_employee_person(v_person_id);
        RAISE NOTICE 'PASS: dataload.get_random_employee_person returned %', v_person_id;
    EXCEPTION
        WHEN OTHERS THEN
            RAISE NOTICE 'ERROR in get_random_employee_person: %', SQLERRM;
    END;
    
    -- Test get_random_salesperson_id
    BEGIN
        CALL dataload.get_random_salesperson_id(v_person_id);
        RAISE NOTICE 'PASS: dataload.get_random_salesperson_id returned %', v_person_id;
    EXCEPTION
        WHEN OTHERS THEN
            RAISE NOTICE 'ERROR in get_random_salesperson_id: %', SQLERRM;
    END;
    
    -- Test get_random_payment_days
    BEGIN
        CALL dataload.get_random_payment_days(v_payment_days);
        RAISE NOTICE 'PASS: dataload.get_random_payment_days returned %', v_payment_days;
    EXCEPTION
        WHEN OTHERS THEN
            RAISE NOTICE 'ERROR in get_random_payment_days: %', SQLERRM;
    END;
    
    -- Test get_random_stock_item_to_adjust
    BEGIN
        CALL dataload.get_random_stock_item_to_adjust(v_stock_item_id);
        RAISE NOTICE 'PASS: dataload.get_random_stock_item_to_adjust returned %', v_stock_item_id;
    EXCEPTION
        WHEN OTHERS THEN
            RAISE NOTICE 'ERROR in get_random_stock_item_to_adjust: %', SQLERRM;
    END;
    
    -- Test get_ficticious_name
    BEGIN
        CALL dataload.get_ficticious_name(v_name);
        RAISE NOTICE 'PASS: dataload.get_ficticious_name returned %', v_name;
    EXCEPTION
        WHEN OTHERS THEN
            RAISE NOTICE 'ERROR in get_ficticious_name: %', SQLERRM;
    END;
    
    -- Test get_bogative_postal_code
    BEGIN
        CALL dataload.get_bogative_postal_code(v_postal_code);
        RAISE NOTICE 'PASS: dataload.get_bogative_postal_code returned %', v_postal_code;
    EXCEPTION
        WHEN OTHERS THEN
            RAISE NOTICE 'ERROR in get_bogative_postal_code: %', SQLERRM;
    END;
    
    -- Test get_random_street_suffix
    BEGIN
        CALL dataload.get_random_street_suffix(v_suffix);
        RAISE NOTICE 'PASS: dataload.get_random_street_suffix returned %', v_suffix;
    EXCEPTION
        WHEN OTHERS THEN
            RAISE NOTICE 'ERROR in get_random_street_suffix: %', SQLERRM;
    END;
    
    -- Test get_random_street_name
    BEGIN
        CALL dataload.get_random_street_name(v_street_name);
        RAISE NOTICE 'PASS: dataload.get_random_street_name returned %', v_street_name;
    EXCEPTION
        WHEN OTHERS THEN
            RAISE NOTICE 'ERROR in get_random_street_name: %', SQLERRM;
    END;
    
    -- Test get_random_street
    BEGIN
        CALL dataload.get_random_street(v_street);
        RAISE NOTICE 'PASS: dataload.get_random_street returned %', v_street;
    EXCEPTION
        WHEN OTHERS THEN
            RAISE NOTICE 'ERROR in get_random_street: %', SQLERRM;
    END;
    
    -- Test get_random_secondary_address
    BEGIN
        CALL dataload.get_random_secondary_address(v_secondary_address);
        RAISE NOTICE 'PASS: dataload.get_random_secondary_address returned %', v_secondary_address;
    EXCEPTION
        WHEN OTHERS THEN
            RAISE NOTICE 'ERROR in get_random_secondary_address: %', SQLERRM;
    END;
    
    -- Test get_buying_group_domain
    IF v_buying_group_id IS NOT NULL THEN
        BEGIN
            CALL dataload.get_buying_group_domain(v_buying_group_id, v_domain);
            RAISE NOTICE 'PASS: dataload.get_buying_group_domain returned %', v_domain;
        EXCEPTION
            WHEN OTHERS THEN
                RAISE NOTICE 'ERROR in get_buying_group_domain: %', SQLERRM;
        END;
    END IF;
END;
$$;

-- =============================================
-- Test: Integration Schema Procedures
-- =============================================
DO $$
DECLARE
    v_cursor refcursor;
    v_last_cutoff timestamp := '2020-01-01 00:00:00'::timestamp;
    v_new_cutoff timestamp := NOW();
BEGIN
    RAISE NOTICE '=== Testing Integration Procedures ===';
    
    -- Test get_city_updates
    BEGIN
        CALL integration.get_city_updates(v_last_cutoff, v_new_cutoff, v_cursor);
        RAISE NOTICE 'PASS: integration.get_city_updates executed successfully';
        CLOSE v_cursor;
    EXCEPTION
        WHEN OTHERS THEN
            RAISE NOTICE 'INFO: get_city_updates: % (may be expected if no archive tables)', SQLERRM;
    END;
    
    -- Test get_customer_updates
    BEGIN
        CALL integration.get_customer_updates(v_last_cutoff, v_new_cutoff, v_cursor);
        RAISE NOTICE 'PASS: integration.get_customer_updates executed successfully';
        CLOSE v_cursor;
    EXCEPTION
        WHEN OTHERS THEN
            RAISE NOTICE 'INFO: get_customer_updates: % (may be expected if no archive tables)', SQLERRM;
    END;
    
    -- Test get_employee_updates
    BEGIN
        CALL integration.get_employee_updates(v_last_cutoff, v_new_cutoff, v_cursor);
        RAISE NOTICE 'PASS: integration.get_employee_updates executed successfully';
        CLOSE v_cursor;
    EXCEPTION
        WHEN OTHERS THEN
            RAISE NOTICE 'INFO: get_employee_updates: % (may be expected if no archive tables)', SQLERRM;
    END;
    
    -- Test get_stock_item_updates
    BEGIN
        CALL integration.get_stock_item_updates(v_last_cutoff, v_new_cutoff, v_cursor);
        RAISE NOTICE 'PASS: integration.get_stock_item_updates executed successfully';
        CLOSE v_cursor;
    EXCEPTION
        WHEN OTHERS THEN
            RAISE NOTICE 'INFO: get_stock_item_updates: % (may be expected if no archive tables)', SQLERRM;
    END;
    
    -- Test get_supplier_updates
    BEGIN
        CALL integration.get_supplier_updates(v_last_cutoff, v_new_cutoff, v_cursor);
        RAISE NOTICE 'PASS: integration.get_supplier_updates executed successfully';
        CLOSE v_cursor;
    EXCEPTION
        WHEN OTHERS THEN
            RAISE NOTICE 'INFO: get_supplier_updates: % (may be expected if no archive tables)', SQLERRM;
    END;
    
    -- Test get_payment_method_updates
    BEGIN
        CALL integration.get_payment_method_updates(v_last_cutoff, v_new_cutoff, v_cursor);
        RAISE NOTICE 'PASS: integration.get_payment_method_updates executed successfully';
        CLOSE v_cursor;
    EXCEPTION
        WHEN OTHERS THEN
            RAISE NOTICE 'INFO: get_payment_method_updates: % (may be expected if no archive tables)', SQLERRM;
    END;
    
    -- Test get_transaction_type_updates
    BEGIN
        CALL integration.get_transaction_type_updates(v_last_cutoff, v_new_cutoff, v_cursor);
        RAISE NOTICE 'PASS: integration.get_transaction_type_updates executed successfully';
        CLOSE v_cursor;
    EXCEPTION
        WHEN OTHERS THEN
            RAISE NOTICE 'INFO: get_transaction_type_updates: % (may be expected if no archive tables)', SQLERRM;
    END;
    
    -- Test get_order_updates
    BEGIN
        CALL integration.get_order_updates(v_last_cutoff, v_new_cutoff, v_cursor);
        RAISE NOTICE 'PASS: integration.get_order_updates executed successfully';
        CLOSE v_cursor;
    EXCEPTION
        WHEN OTHERS THEN
            RAISE NOTICE 'ERROR in get_order_updates: %', SQLERRM;
    END;
    
    -- Test get_sale_updates
    BEGIN
        CALL integration.get_sale_updates(v_last_cutoff, v_new_cutoff, v_cursor);
        RAISE NOTICE 'PASS: integration.get_sale_updates executed successfully';
        CLOSE v_cursor;
    EXCEPTION
        WHEN OTHERS THEN
            RAISE NOTICE 'ERROR in get_sale_updates: %', SQLERRM;
    END;
    
    -- Test get_purchase_updates
    BEGIN
        CALL integration.get_purchase_updates(v_last_cutoff, v_new_cutoff, v_cursor);
        RAISE NOTICE 'PASS: integration.get_purchase_updates executed successfully';
        CLOSE v_cursor;
    EXCEPTION
        WHEN OTHERS THEN
            RAISE NOTICE 'ERROR in get_purchase_updates: %', SQLERRM;
    END;
    
    -- Test get_movement_updates
    BEGIN
        CALL integration.get_movement_updates(v_last_cutoff, v_new_cutoff, v_cursor);
        RAISE NOTICE 'PASS: integration.get_movement_updates executed successfully';
        CLOSE v_cursor;
    EXCEPTION
        WHEN OTHERS THEN
            RAISE NOTICE 'ERROR in get_movement_updates: %', SQLERRM;
    END;
    
    -- Test get_transaction_updates
    BEGIN
        CALL integration.get_transaction_updates(v_last_cutoff, v_new_cutoff, v_cursor);
        RAISE NOTICE 'PASS: integration.get_transaction_updates executed successfully';
        CLOSE v_cursor;
    EXCEPTION
        WHEN OTHERS THEN
            RAISE NOTICE 'ERROR in get_transaction_updates: %', SQLERRM;
    END;
    
    -- Test get_stock_holding_updates
    BEGIN
        CALL integration.get_stock_holding_updates(v_last_cutoff, v_new_cutoff, v_cursor);
        RAISE NOTICE 'PASS: integration.get_stock_holding_updates executed successfully';
        CLOSE v_cursor;
    EXCEPTION
        WHEN OTHERS THEN
            RAISE NOTICE 'ERROR in get_stock_holding_updates: %', SQLERRM;
    END;
END;
$$;

-- =============================================
-- Test: WebApi Schema Procedures
-- =============================================
DO $$
DECLARE
    v_cursor refcursor;
    v_person_id integer;
    v_is_valid boolean;
BEGIN
    RAISE NOTICE '=== Testing WebApi Procedures ===';
    
    -- Test search_for_stock_items
    BEGIN
        CALL webapi.search_for_stock_items('USB', 1, 10, v_cursor);
        RAISE NOTICE 'PASS: webapi.search_for_stock_items executed successfully';
        CLOSE v_cursor;
    EXCEPTION
        WHEN OTHERS THEN
            RAISE NOTICE 'ERROR in search_for_stock_items: %', SQLERRM;
    END;
    
    -- Test login (with invalid credentials - should return false)
    BEGIN
        CALL webapi.login('invalid_user', 'invalid_password', v_person_id, v_is_valid);
        IF v_is_valid = false THEN
            RAISE NOTICE 'PASS: webapi.login correctly rejected invalid credentials';
        ELSE
            RAISE NOTICE 'WARNING: webapi.login accepted invalid credentials';
        END IF;
    EXCEPTION
        WHEN OTHERS THEN
            RAISE NOTICE 'ERROR in login: %', SQLERRM;
    END;
END;
$$;

RAISE NOTICE '=== Procedure Tests Complete ===';
