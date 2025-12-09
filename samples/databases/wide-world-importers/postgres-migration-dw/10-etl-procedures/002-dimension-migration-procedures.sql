-- Wide World Importers DW PostgreSQL Migration
-- Phase 5: ETL and Analytics Migration
-- File: 002-dimension-migration-procedures.sql
-- Description: Migration procedures for dimension tables (City, Customer, Employee, Payment Method, Stock Item, Supplier, Transaction Type)

-- =============================================
-- Procedure: integration.migrate_staged_city_data
-- Description: Migrates staged city data to the City dimension
-- =============================================
CREATE OR REPLACE PROCEDURE integration.migrate_staged_city_data()
LANGUAGE plpgsql
AS $$
DECLARE
    v_end_of_time timestamp := '9999-12-31 23:59:59.999999'::timestamp;
    v_lineage_key integer;
BEGIN
    -- Get the lineage key for this load
    SELECT lineage_key INTO v_lineage_key
    FROM integration.lineage
    WHERE table_name = 'City'
    AND data_load_completed IS NULL
    ORDER BY lineage_key DESC
    LIMIT 1;
    
    IF v_lineage_key IS NULL THEN
        RAISE EXCEPTION 'No pending lineage record found for City';
    END IF;
    
    -- Close off existing records that are being updated
    WITH rows_to_close_off AS (
        SELECT wwi_city_id, MIN(valid_from) AS valid_from
        FROM integration.city_staging
        GROUP BY wwi_city_id
    )
    UPDATE dimension.city c
    SET valid_to = rtco.valid_from
    FROM rows_to_close_off rtco
    WHERE c.wwi_city_id = rtco.wwi_city_id
    AND c.valid_to = v_end_of_time;
    
    -- Insert new records from staging
    INSERT INTO dimension.city (
        wwi_city_id, city, state_province, country, continent,
        sales_territory, region, subregion, location,
        latest_recorded_population, valid_from, valid_to, lineage_key
    )
    SELECT 
        wwi_city_id, city, state_province, country, continent,
        sales_territory, region, subregion, location,
        latest_recorded_population, valid_from, valid_to, v_lineage_key
    FROM integration.city_staging;
    
    -- Update lineage record
    UPDATE integration.lineage
    SET data_load_completed = CURRENT_TIMESTAMP,
        was_successful = true
    WHERE lineage_key = v_lineage_key;
    
    -- Update ETL cutoff time
    UPDATE integration.etl_cutoff
    SET cutoff_time = (
        SELECT source_system_cutoff_time
        FROM integration.lineage
        WHERE lineage_key = v_lineage_key
    )
    WHERE table_name = 'City';
END;
$$;

COMMENT ON PROCEDURE integration.migrate_staged_city_data() IS 
'Migrates staged city data to the City dimension with SCD Type 2 handling';

-- =============================================
-- Procedure: integration.migrate_staged_customer_data
-- Description: Migrates staged customer data to the Customer dimension
-- =============================================
CREATE OR REPLACE PROCEDURE integration.migrate_staged_customer_data()
LANGUAGE plpgsql
AS $$
DECLARE
    v_end_of_time timestamp := '9999-12-31 23:59:59.999999'::timestamp;
    v_lineage_key integer;
BEGIN
    SELECT lineage_key INTO v_lineage_key
    FROM integration.lineage
    WHERE table_name = 'Customer'
    AND data_load_completed IS NULL
    ORDER BY lineage_key DESC
    LIMIT 1;
    
    IF v_lineage_key IS NULL THEN
        RAISE EXCEPTION 'No pending lineage record found for Customer';
    END IF;
    
    -- Close off existing records
    WITH rows_to_close_off AS (
        SELECT wwi_customer_id, MIN(valid_from) AS valid_from
        FROM integration.customer_staging
        GROUP BY wwi_customer_id
    )
    UPDATE dimension.customer c
    SET valid_to = rtco.valid_from
    FROM rows_to_close_off rtco
    WHERE c.wwi_customer_id = rtco.wwi_customer_id
    AND c.valid_to = v_end_of_time;
    
    -- Insert new records
    INSERT INTO dimension.customer (
        wwi_customer_id, customer, bill_to_customer, category,
        buying_group, primary_contact, postal_code,
        valid_from, valid_to, lineage_key
    )
    SELECT 
        wwi_customer_id, customer, bill_to_customer, category,
        buying_group, primary_contact, postal_code,
        valid_from, valid_to, v_lineage_key
    FROM integration.customer_staging;
    
    UPDATE integration.lineage
    SET data_load_completed = CURRENT_TIMESTAMP,
        was_successful = true
    WHERE lineage_key = v_lineage_key;
    
    UPDATE integration.etl_cutoff
    SET cutoff_time = (
        SELECT source_system_cutoff_time
        FROM integration.lineage
        WHERE lineage_key = v_lineage_key
    )
    WHERE table_name = 'Customer';
END;
$$;

COMMENT ON PROCEDURE integration.migrate_staged_customer_data() IS 
'Migrates staged customer data to the Customer dimension with SCD Type 2 handling';

-- =============================================
-- Procedure: integration.migrate_staged_employee_data
-- Description: Migrates staged employee data to the Employee dimension
-- =============================================
CREATE OR REPLACE PROCEDURE integration.migrate_staged_employee_data()
LANGUAGE plpgsql
AS $$
DECLARE
    v_end_of_time timestamp := '9999-12-31 23:59:59.999999'::timestamp;
    v_lineage_key integer;
BEGIN
    SELECT lineage_key INTO v_lineage_key
    FROM integration.lineage
    WHERE table_name = 'Employee'
    AND data_load_completed IS NULL
    ORDER BY lineage_key DESC
    LIMIT 1;
    
    IF v_lineage_key IS NULL THEN
        RAISE EXCEPTION 'No pending lineage record found for Employee';
    END IF;
    
    -- Close off existing records
    WITH rows_to_close_off AS (
        SELECT wwi_employee_id, MIN(valid_from) AS valid_from
        FROM integration.employee_staging
        GROUP BY wwi_employee_id
    )
    UPDATE dimension.employee e
    SET valid_to = rtco.valid_from
    FROM rows_to_close_off rtco
    WHERE e.wwi_employee_id = rtco.wwi_employee_id
    AND e.valid_to = v_end_of_time;
    
    -- Insert new records
    INSERT INTO dimension.employee (
        wwi_employee_id, employee, preferred_name, is_salesperson,
        photo, valid_from, valid_to, lineage_key
    )
    SELECT 
        wwi_employee_id, employee, preferred_name, is_salesperson,
        photo, valid_from, valid_to, v_lineage_key
    FROM integration.employee_staging;
    
    UPDATE integration.lineage
    SET data_load_completed = CURRENT_TIMESTAMP,
        was_successful = true
    WHERE lineage_key = v_lineage_key;
    
    UPDATE integration.etl_cutoff
    SET cutoff_time = (
        SELECT source_system_cutoff_time
        FROM integration.lineage
        WHERE lineage_key = v_lineage_key
    )
    WHERE table_name = 'Employee';
END;
$$;

COMMENT ON PROCEDURE integration.migrate_staged_employee_data() IS 
'Migrates staged employee data to the Employee dimension with SCD Type 2 handling';

-- =============================================
-- Procedure: integration.migrate_staged_payment_method_data
-- Description: Migrates staged payment method data to the Payment Method dimension
-- =============================================
CREATE OR REPLACE PROCEDURE integration.migrate_staged_payment_method_data()
LANGUAGE plpgsql
AS $$
DECLARE
    v_end_of_time timestamp := '9999-12-31 23:59:59.999999'::timestamp;
    v_lineage_key integer;
BEGIN
    SELECT lineage_key INTO v_lineage_key
    FROM integration.lineage
    WHERE table_name = 'Payment Method'
    AND data_load_completed IS NULL
    ORDER BY lineage_key DESC
    LIMIT 1;
    
    IF v_lineage_key IS NULL THEN
        RAISE EXCEPTION 'No pending lineage record found for Payment Method';
    END IF;
    
    -- Close off existing records
    WITH rows_to_close_off AS (
        SELECT wwi_payment_method_id, MIN(valid_from) AS valid_from
        FROM integration.payment_method_staging
        GROUP BY wwi_payment_method_id
    )
    UPDATE dimension.payment_method pm
    SET valid_to = rtco.valid_from
    FROM rows_to_close_off rtco
    WHERE pm.wwi_payment_method_id = rtco.wwi_payment_method_id
    AND pm.valid_to = v_end_of_time;
    
    -- Insert new records
    INSERT INTO dimension.payment_method (
        wwi_payment_method_id, payment_method,
        valid_from, valid_to, lineage_key
    )
    SELECT 
        wwi_payment_method_id, payment_method,
        valid_from, valid_to, v_lineage_key
    FROM integration.payment_method_staging;
    
    UPDATE integration.lineage
    SET data_load_completed = CURRENT_TIMESTAMP,
        was_successful = true
    WHERE lineage_key = v_lineage_key;
    
    UPDATE integration.etl_cutoff
    SET cutoff_time = (
        SELECT source_system_cutoff_time
        FROM integration.lineage
        WHERE lineage_key = v_lineage_key
    )
    WHERE table_name = 'Payment Method';
END;
$$;

COMMENT ON PROCEDURE integration.migrate_staged_payment_method_data() IS 
'Migrates staged payment method data to the Payment Method dimension with SCD Type 2 handling';

-- =============================================
-- Procedure: integration.migrate_staged_stock_item_data
-- Description: Migrates staged stock item data to the Stock Item dimension
-- =============================================
CREATE OR REPLACE PROCEDURE integration.migrate_staged_stock_item_data()
LANGUAGE plpgsql
AS $$
DECLARE
    v_end_of_time timestamp := '9999-12-31 23:59:59.999999'::timestamp;
    v_lineage_key integer;
BEGIN
    SELECT lineage_key INTO v_lineage_key
    FROM integration.lineage
    WHERE table_name = 'Stock Item'
    AND data_load_completed IS NULL
    ORDER BY lineage_key DESC
    LIMIT 1;
    
    IF v_lineage_key IS NULL THEN
        RAISE EXCEPTION 'No pending lineage record found for Stock Item';
    END IF;
    
    -- Close off existing records
    WITH rows_to_close_off AS (
        SELECT wwi_stock_item_id, MIN(valid_from) AS valid_from
        FROM integration.stock_item_staging
        GROUP BY wwi_stock_item_id
    )
    UPDATE dimension.stock_item si
    SET valid_to = rtco.valid_from
    FROM rows_to_close_off rtco
    WHERE si.wwi_stock_item_id = rtco.wwi_stock_item_id
    AND si.valid_to = v_end_of_time;
    
    -- Insert new records
    INSERT INTO dimension.stock_item (
        wwi_stock_item_id, stock_item, color, selling_package,
        buying_package, brand, size, lead_time_days, quantity_per_outer,
        is_chiller_stock, barcode, tax_rate, unit_price,
        recommended_retail_price, typical_weight_per_unit, photo,
        valid_from, valid_to, lineage_key
    )
    SELECT 
        wwi_stock_item_id, stock_item, color, selling_package,
        buying_package, brand, size, lead_time_days, quantity_per_outer,
        is_chiller_stock, barcode, tax_rate, unit_price,
        recommended_retail_price, typical_weight_per_unit, photo,
        valid_from, valid_to, v_lineage_key
    FROM integration.stock_item_staging;
    
    UPDATE integration.lineage
    SET data_load_completed = CURRENT_TIMESTAMP,
        was_successful = true
    WHERE lineage_key = v_lineage_key;
    
    UPDATE integration.etl_cutoff
    SET cutoff_time = (
        SELECT source_system_cutoff_time
        FROM integration.lineage
        WHERE lineage_key = v_lineage_key
    )
    WHERE table_name = 'Stock Item';
END;
$$;

COMMENT ON PROCEDURE integration.migrate_staged_stock_item_data() IS 
'Migrates staged stock item data to the Stock Item dimension with SCD Type 2 handling';

-- =============================================
-- Procedure: integration.migrate_staged_supplier_data
-- Description: Migrates staged supplier data to the Supplier dimension
-- =============================================
CREATE OR REPLACE PROCEDURE integration.migrate_staged_supplier_data()
LANGUAGE plpgsql
AS $$
DECLARE
    v_end_of_time timestamp := '9999-12-31 23:59:59.999999'::timestamp;
    v_lineage_key integer;
BEGIN
    SELECT lineage_key INTO v_lineage_key
    FROM integration.lineage
    WHERE table_name = 'Supplier'
    AND data_load_completed IS NULL
    ORDER BY lineage_key DESC
    LIMIT 1;
    
    IF v_lineage_key IS NULL THEN
        RAISE EXCEPTION 'No pending lineage record found for Supplier';
    END IF;
    
    -- Close off existing records
    WITH rows_to_close_off AS (
        SELECT wwi_supplier_id, MIN(valid_from) AS valid_from
        FROM integration.supplier_staging
        GROUP BY wwi_supplier_id
    )
    UPDATE dimension.supplier s
    SET valid_to = rtco.valid_from
    FROM rows_to_close_off rtco
    WHERE s.wwi_supplier_id = rtco.wwi_supplier_id
    AND s.valid_to = v_end_of_time;
    
    -- Insert new records
    INSERT INTO dimension.supplier (
        wwi_supplier_id, supplier, category, primary_contact,
        supplier_reference, payment_days, postal_code,
        valid_from, valid_to, lineage_key
    )
    SELECT 
        wwi_supplier_id, supplier, category, primary_contact,
        supplier_reference, payment_days, postal_code,
        valid_from, valid_to, v_lineage_key
    FROM integration.supplier_staging;
    
    UPDATE integration.lineage
    SET data_load_completed = CURRENT_TIMESTAMP,
        was_successful = true
    WHERE lineage_key = v_lineage_key;
    
    UPDATE integration.etl_cutoff
    SET cutoff_time = (
        SELECT source_system_cutoff_time
        FROM integration.lineage
        WHERE lineage_key = v_lineage_key
    )
    WHERE table_name = 'Supplier';
END;
$$;

COMMENT ON PROCEDURE integration.migrate_staged_supplier_data() IS 
'Migrates staged supplier data to the Supplier dimension with SCD Type 2 handling';

-- =============================================
-- Procedure: integration.migrate_staged_transaction_type_data
-- Description: Migrates staged transaction type data to the Transaction Type dimension
-- =============================================
CREATE OR REPLACE PROCEDURE integration.migrate_staged_transaction_type_data()
LANGUAGE plpgsql
AS $$
DECLARE
    v_end_of_time timestamp := '9999-12-31 23:59:59.999999'::timestamp;
    v_lineage_key integer;
BEGIN
    SELECT lineage_key INTO v_lineage_key
    FROM integration.lineage
    WHERE table_name = 'Transaction Type'
    AND data_load_completed IS NULL
    ORDER BY lineage_key DESC
    LIMIT 1;
    
    IF v_lineage_key IS NULL THEN
        RAISE EXCEPTION 'No pending lineage record found for Transaction Type';
    END IF;
    
    -- Close off existing records
    WITH rows_to_close_off AS (
        SELECT wwi_transaction_type_id, MIN(valid_from) AS valid_from
        FROM integration.transaction_type_staging
        GROUP BY wwi_transaction_type_id
    )
    UPDATE dimension.transaction_type tt
    SET valid_to = rtco.valid_from
    FROM rows_to_close_off rtco
    WHERE tt.wwi_transaction_type_id = rtco.wwi_transaction_type_id
    AND tt.valid_to = v_end_of_time;
    
    -- Insert new records
    INSERT INTO dimension.transaction_type (
        wwi_transaction_type_id, transaction_type,
        valid_from, valid_to, lineage_key
    )
    SELECT 
        wwi_transaction_type_id, transaction_type,
        valid_from, valid_to, v_lineage_key
    FROM integration.transaction_type_staging;
    
    UPDATE integration.lineage
    SET data_load_completed = CURRENT_TIMESTAMP,
        was_successful = true
    WHERE lineage_key = v_lineage_key;
    
    UPDATE integration.etl_cutoff
    SET cutoff_time = (
        SELECT source_system_cutoff_time
        FROM integration.lineage
        WHERE lineage_key = v_lineage_key
    )
    WHERE table_name = 'Transaction Type';
END;
$$;

COMMENT ON PROCEDURE integration.migrate_staged_transaction_type_data() IS 
'Migrates staged transaction type data to the Transaction Type dimension with SCD Type 2 handling';
