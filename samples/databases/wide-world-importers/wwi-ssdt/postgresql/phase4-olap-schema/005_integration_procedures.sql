-- Wide World Importers PostgreSQL Migration
-- Phase 4: OLAP Schema Migration (WideWorldImportersDW)
-- Script 005: Integration Procedures for ETL
-- Migrated from SQL Server T-SQL to PostgreSQL PL/pgSQL

-- =============================================
-- Integration.GetLastETLCutoffTime Function
-- Gets the last ETL cutoff time for a table
-- =============================================
CREATE OR REPLACE FUNCTION integration.get_last_etl_cutoff_time(
    p_table_name VARCHAR(128)
)
RETURNS TIMESTAMP AS $$
DECLARE
    v_cutoff_time TIMESTAMP;
BEGIN
    SELECT cutoff_time INTO v_cutoff_time
    FROM integration.etl_cutoff
    WHERE table_name = p_table_name;
    
    IF v_cutoff_time IS NULL THEN
        v_cutoff_time := '2013-01-01 00:00:00'::TIMESTAMP;
    END IF;
    
    RETURN v_cutoff_time;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION integration.get_last_etl_cutoff_time(VARCHAR) IS 
'Gets the last ETL cutoff time for a table';

-- =============================================
-- Integration.GetLineageKey Function
-- Creates a new lineage record and returns the key
-- =============================================
CREATE OR REPLACE FUNCTION integration.get_lineage_key(
    p_table_name VARCHAR(128),
    p_cutoff_time TIMESTAMP
)
RETURNS INTEGER AS $$
DECLARE
    v_lineage_key INTEGER;
BEGIN
    INSERT INTO integration.lineage (
        data_load_started, table_name, data_load_completed, was_successful, source_system_cutoff_time
    )
    VALUES (
        clock_timestamp(), p_table_name, NULL, false, p_cutoff_time
    )
    RETURNING lineage_key INTO v_lineage_key;
    
    RETURN v_lineage_key;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION integration.get_lineage_key(VARCHAR, TIMESTAMP) IS 
'Creates a new lineage record and returns the key';

-- =============================================
-- Integration.MigrateStagedCityData Procedure
-- Migrates staged city data to the dimension table
-- =============================================
CREATE OR REPLACE PROCEDURE integration.migrate_staged_city_data(
    p_lineage_key INTEGER
)
LANGUAGE plpgsql AS $$
BEGIN
    -- Close out existing records that have changed
    UPDATE dimension.city dc
    SET valid_to = cs.valid_from
    FROM integration.city_staging cs
    WHERE dc.wwi_city_id = cs.wwi_city_id
    AND dc.valid_to = '9999-12-31 23:59:59.9999999'::TIMESTAMP
    AND (
        dc.city != cs.city OR
        dc.state_province != cs.state_province OR
        dc.country != cs.country OR
        dc.continent != cs.continent OR
        dc.sales_territory != cs.sales_territory OR
        dc.region != cs.region OR
        dc.subregion != cs.subregion OR
        dc.latest_recorded_population != cs.latest_recorded_population
    );
    
    -- Insert new and changed records
    INSERT INTO dimension.city (
        wwi_city_id, city, state_province, country, continent, sales_territory,
        region, subregion, location, latest_recorded_population, valid_from, valid_to, lineage_key
    )
    SELECT 
        cs.wwi_city_id, cs.city, cs.state_province, cs.country, cs.continent, cs.sales_territory,
        cs.region, cs.subregion, cs.location, cs.latest_recorded_population, cs.valid_from, cs.valid_to, p_lineage_key
    FROM integration.city_staging cs
    WHERE NOT EXISTS (
        SELECT 1 FROM dimension.city dc
        WHERE dc.wwi_city_id = cs.wwi_city_id
        AND dc.valid_to = '9999-12-31 23:59:59.9999999'::TIMESTAMP
        AND dc.city = cs.city
        AND dc.state_province = cs.state_province
        AND dc.country = cs.country
        AND dc.continent = cs.continent
        AND dc.sales_territory = cs.sales_territory
        AND dc.region = cs.region
        AND dc.subregion = cs.subregion
        AND dc.latest_recorded_population = cs.latest_recorded_population
    );
    
    -- Clear staging table
    TRUNCATE TABLE integration.city_staging;
END;
$$;

COMMENT ON PROCEDURE integration.migrate_staged_city_data(INTEGER) IS 
'Migrates staged city data to the dimension table using SCD Type 2';

-- =============================================
-- Integration.MigrateStagedCustomerData Procedure
-- Migrates staged customer data to the dimension table
-- =============================================
CREATE OR REPLACE PROCEDURE integration.migrate_staged_customer_data(
    p_lineage_key INTEGER
)
LANGUAGE plpgsql AS $$
BEGIN
    -- Close out existing records that have changed
    UPDATE dimension.customer dc
    SET valid_to = cs.valid_from
    FROM integration.customer_staging cs
    WHERE dc.wwi_customer_id = cs.wwi_customer_id
    AND dc.valid_to = '9999-12-31 23:59:59.9999999'::TIMESTAMP
    AND (
        dc.customer != cs.customer OR
        dc.bill_to_customer != cs.bill_to_customer OR
        dc.category != cs.category OR
        dc.buying_group != cs.buying_group OR
        dc.primary_contact != cs.primary_contact OR
        dc.postal_code != cs.postal_code
    );
    
    -- Insert new and changed records
    INSERT INTO dimension.customer (
        wwi_customer_id, customer, bill_to_customer, category, buying_group,
        primary_contact, postal_code, valid_from, valid_to, lineage_key
    )
    SELECT 
        cs.wwi_customer_id, cs.customer, cs.bill_to_customer, cs.category, cs.buying_group,
        cs.primary_contact, cs.postal_code, cs.valid_from, cs.valid_to, p_lineage_key
    FROM integration.customer_staging cs
    WHERE NOT EXISTS (
        SELECT 1 FROM dimension.customer dc
        WHERE dc.wwi_customer_id = cs.wwi_customer_id
        AND dc.valid_to = '9999-12-31 23:59:59.9999999'::TIMESTAMP
        AND dc.customer = cs.customer
        AND dc.bill_to_customer = cs.bill_to_customer
        AND dc.category = cs.category
        AND dc.buying_group = cs.buying_group
        AND dc.primary_contact = cs.primary_contact
        AND dc.postal_code = cs.postal_code
    );
    
    -- Clear staging table
    TRUNCATE TABLE integration.customer_staging;
END;
$$;

COMMENT ON PROCEDURE integration.migrate_staged_customer_data(INTEGER) IS 
'Migrates staged customer data to the dimension table using SCD Type 2';

-- =============================================
-- Integration.MigrateStagedEmployeeData Procedure
-- Migrates staged employee data to the dimension table
-- =============================================
CREATE OR REPLACE PROCEDURE integration.migrate_staged_employee_data(
    p_lineage_key INTEGER
)
LANGUAGE plpgsql AS $$
BEGIN
    -- Close out existing records that have changed
    UPDATE dimension.employee de
    SET valid_to = es.valid_from
    FROM integration.employee_staging es
    WHERE de.wwi_employee_id = es.wwi_employee_id
    AND de.valid_to = '9999-12-31 23:59:59.9999999'::TIMESTAMP
    AND (
        de.employee != es.employee OR
        de.preferred_name != es.preferred_name OR
        de.is_salesperson != es.is_salesperson
    );
    
    -- Insert new and changed records
    INSERT INTO dimension.employee (
        wwi_employee_id, employee, preferred_name, is_salesperson, photo,
        valid_from, valid_to, lineage_key
    )
    SELECT 
        es.wwi_employee_id, es.employee, es.preferred_name, es.is_salesperson, es.photo,
        es.valid_from, es.valid_to, p_lineage_key
    FROM integration.employee_staging es
    WHERE NOT EXISTS (
        SELECT 1 FROM dimension.employee de
        WHERE de.wwi_employee_id = es.wwi_employee_id
        AND de.valid_to = '9999-12-31 23:59:59.9999999'::TIMESTAMP
        AND de.employee = es.employee
        AND de.preferred_name = es.preferred_name
        AND de.is_salesperson = es.is_salesperson
    );
    
    -- Clear staging table
    TRUNCATE TABLE integration.employee_staging;
END;
$$;

COMMENT ON PROCEDURE integration.migrate_staged_employee_data(INTEGER) IS 
'Migrates staged employee data to the dimension table using SCD Type 2';

-- =============================================
-- Integration.MigrateStagedPaymentMethodData Procedure
-- Migrates staged payment method data to the dimension table
-- =============================================
CREATE OR REPLACE PROCEDURE integration.migrate_staged_payment_method_data(
    p_lineage_key INTEGER
)
LANGUAGE plpgsql AS $$
BEGIN
    -- Close out existing records that have changed
    UPDATE dimension.payment_method dpm
    SET valid_to = pms.valid_from
    FROM integration.payment_method_staging pms
    WHERE dpm.wwi_payment_method_id = pms.wwi_payment_method_id
    AND dpm.valid_to = '9999-12-31 23:59:59.9999999'::TIMESTAMP
    AND dpm.payment_method != pms.payment_method;
    
    -- Insert new and changed records
    INSERT INTO dimension.payment_method (
        wwi_payment_method_id, payment_method, valid_from, valid_to, lineage_key
    )
    SELECT 
        pms.wwi_payment_method_id, pms.payment_method, pms.valid_from, pms.valid_to, p_lineage_key
    FROM integration.payment_method_staging pms
    WHERE NOT EXISTS (
        SELECT 1 FROM dimension.payment_method dpm
        WHERE dpm.wwi_payment_method_id = pms.wwi_payment_method_id
        AND dpm.valid_to = '9999-12-31 23:59:59.9999999'::TIMESTAMP
        AND dpm.payment_method = pms.payment_method
    );
    
    -- Clear staging table
    TRUNCATE TABLE integration.payment_method_staging;
END;
$$;

COMMENT ON PROCEDURE integration.migrate_staged_payment_method_data(INTEGER) IS 
'Migrates staged payment method data to the dimension table using SCD Type 2';

-- =============================================
-- Integration.MigrateStagedStockItemData Procedure
-- Migrates staged stock item data to the dimension table
-- =============================================
CREATE OR REPLACE PROCEDURE integration.migrate_staged_stock_item_data(
    p_lineage_key INTEGER
)
LANGUAGE plpgsql AS $$
BEGIN
    -- Close out existing records that have changed
    UPDATE dimension.stock_item dsi
    SET valid_to = sis.valid_from
    FROM integration.stock_item_staging sis
    WHERE dsi.wwi_stock_item_id = sis.wwi_stock_item_id
    AND dsi.valid_to = '9999-12-31 23:59:59.9999999'::TIMESTAMP
    AND (
        dsi.stock_item != sis.stock_item OR
        dsi.color != sis.color OR
        dsi.selling_package != sis.selling_package OR
        dsi.buying_package != sis.buying_package OR
        dsi.brand != sis.brand OR
        dsi.size != sis.size OR
        dsi.lead_time_days != sis.lead_time_days OR
        dsi.quantity_per_outer != sis.quantity_per_outer OR
        dsi.is_chiller_stock != sis.is_chiller_stock OR
        dsi.tax_rate != sis.tax_rate OR
        dsi.unit_price != sis.unit_price
    );
    
    -- Insert new and changed records
    INSERT INTO dimension.stock_item (
        wwi_stock_item_id, stock_item, color, selling_package, buying_package, brand, size,
        lead_time_days, quantity_per_outer, is_chiller_stock, barcode, tax_rate, unit_price,
        recommended_retail_price, typical_weight_per_unit, photo, valid_from, valid_to, lineage_key
    )
    SELECT 
        sis.wwi_stock_item_id, sis.stock_item, sis.color, sis.selling_package, sis.buying_package, sis.brand, sis.size,
        sis.lead_time_days, sis.quantity_per_outer, sis.is_chiller_stock, sis.barcode, sis.tax_rate, sis.unit_price,
        sis.recommended_retail_price, sis.typical_weight_per_unit, sis.photo, sis.valid_from, sis.valid_to, p_lineage_key
    FROM integration.stock_item_staging sis
    WHERE NOT EXISTS (
        SELECT 1 FROM dimension.stock_item dsi
        WHERE dsi.wwi_stock_item_id = sis.wwi_stock_item_id
        AND dsi.valid_to = '9999-12-31 23:59:59.9999999'::TIMESTAMP
        AND dsi.stock_item = sis.stock_item
        AND dsi.color = sis.color
        AND dsi.selling_package = sis.selling_package
        AND dsi.buying_package = sis.buying_package
        AND dsi.brand = sis.brand
        AND dsi.size = sis.size
        AND dsi.lead_time_days = sis.lead_time_days
        AND dsi.quantity_per_outer = sis.quantity_per_outer
        AND dsi.is_chiller_stock = sis.is_chiller_stock
        AND dsi.tax_rate = sis.tax_rate
        AND dsi.unit_price = sis.unit_price
    );
    
    -- Clear staging table
    TRUNCATE TABLE integration.stock_item_staging;
END;
$$;

COMMENT ON PROCEDURE integration.migrate_staged_stock_item_data(INTEGER) IS 
'Migrates staged stock item data to the dimension table using SCD Type 2';

-- =============================================
-- Integration.MigrateStagedSupplierData Procedure
-- Migrates staged supplier data to the dimension table
-- =============================================
CREATE OR REPLACE PROCEDURE integration.migrate_staged_supplier_data(
    p_lineage_key INTEGER
)
LANGUAGE plpgsql AS $$
BEGIN
    -- Close out existing records that have changed
    UPDATE dimension.supplier ds
    SET valid_to = ss.valid_from
    FROM integration.supplier_staging ss
    WHERE ds.wwi_supplier_id = ss.wwi_supplier_id
    AND ds.valid_to = '9999-12-31 23:59:59.9999999'::TIMESTAMP
    AND (
        ds.supplier != ss.supplier OR
        ds.category != ss.category OR
        ds.primary_contact != ss.primary_contact OR
        ds.payment_days != ss.payment_days OR
        ds.postal_code != ss.postal_code
    );
    
    -- Insert new and changed records
    INSERT INTO dimension.supplier (
        wwi_supplier_id, supplier, category, primary_contact, supplier_reference,
        payment_days, postal_code, valid_from, valid_to, lineage_key
    )
    SELECT 
        ss.wwi_supplier_id, ss.supplier, ss.category, ss.primary_contact, ss.supplier_reference,
        ss.payment_days, ss.postal_code, ss.valid_from, ss.valid_to, p_lineage_key
    FROM integration.supplier_staging ss
    WHERE NOT EXISTS (
        SELECT 1 FROM dimension.supplier ds
        WHERE ds.wwi_supplier_id = ss.wwi_supplier_id
        AND ds.valid_to = '9999-12-31 23:59:59.9999999'::TIMESTAMP
        AND ds.supplier = ss.supplier
        AND ds.category = ss.category
        AND ds.primary_contact = ss.primary_contact
        AND ds.payment_days = ss.payment_days
        AND ds.postal_code = ss.postal_code
    );
    
    -- Clear staging table
    TRUNCATE TABLE integration.supplier_staging;
END;
$$;

COMMENT ON PROCEDURE integration.migrate_staged_supplier_data(INTEGER) IS 
'Migrates staged supplier data to the dimension table using SCD Type 2';

-- =============================================
-- Integration.MigrateStagedTransactionTypeData Procedure
-- Migrates staged transaction type data to the dimension table
-- =============================================
CREATE OR REPLACE PROCEDURE integration.migrate_staged_transaction_type_data(
    p_lineage_key INTEGER
)
LANGUAGE plpgsql AS $$
BEGIN
    -- Close out existing records that have changed
    UPDATE dimension.transaction_type dtt
    SET valid_to = tts.valid_from
    FROM integration.transaction_type_staging tts
    WHERE dtt.wwi_transaction_type_id = tts.wwi_transaction_type_id
    AND dtt.valid_to = '9999-12-31 23:59:59.9999999'::TIMESTAMP
    AND dtt.transaction_type != tts.transaction_type;
    
    -- Insert new and changed records
    INSERT INTO dimension.transaction_type (
        wwi_transaction_type_id, transaction_type, valid_from, valid_to, lineage_key
    )
    SELECT 
        tts.wwi_transaction_type_id, tts.transaction_type, tts.valid_from, tts.valid_to, p_lineage_key
    FROM integration.transaction_type_staging tts
    WHERE NOT EXISTS (
        SELECT 1 FROM dimension.transaction_type dtt
        WHERE dtt.wwi_transaction_type_id = tts.wwi_transaction_type_id
        AND dtt.valid_to = '9999-12-31 23:59:59.9999999'::TIMESTAMP
        AND dtt.transaction_type = tts.transaction_type
    );
    
    -- Clear staging table
    TRUNCATE TABLE integration.transaction_type_staging;
END;
$$;

COMMENT ON PROCEDURE integration.migrate_staged_transaction_type_data(INTEGER) IS 
'Migrates staged transaction type data to the dimension table using SCD Type 2';

-- =============================================
-- Integration.MigrateStagedMovementData Procedure
-- Migrates staged movement data to the fact table
-- =============================================
CREATE OR REPLACE PROCEDURE integration.migrate_staged_movement_data(
    p_lineage_key INTEGER
)
LANGUAGE plpgsql AS $$
BEGIN
    -- Update dimension keys in staging
    UPDATE integration.movement_staging ms
    SET stock_item_key = dsi.stock_item_key
    FROM dimension.stock_item dsi
    WHERE ms.wwi_stock_item_id = dsi.wwi_stock_item_id
    AND ms.last_modified_when >= dsi.valid_from
    AND ms.last_modified_when < dsi.valid_to;
    
    UPDATE integration.movement_staging ms
    SET customer_key = dc.customer_key
    FROM dimension.customer dc
    WHERE ms.wwi_customer_id = dc.wwi_customer_id
    AND ms.last_modified_when >= dc.valid_from
    AND ms.last_modified_when < dc.valid_to;
    
    UPDATE integration.movement_staging ms
    SET supplier_key = ds.supplier_key
    FROM dimension.supplier ds
    WHERE ms.wwi_supplier_id = ds.wwi_supplier_id
    AND ms.last_modified_when >= ds.valid_from
    AND ms.last_modified_when < ds.valid_to;
    
    UPDATE integration.movement_staging ms
    SET transaction_type_key = dtt.transaction_type_key
    FROM dimension.transaction_type dtt
    WHERE ms.wwi_transaction_type_id = dtt.wwi_transaction_type_id
    AND ms.last_modified_when >= dtt.valid_from
    AND ms.last_modified_when < dtt.valid_to;
    
    -- Insert into fact table
    INSERT INTO fact.movement (
        date_key, stock_item_key, customer_key, supplier_key, transaction_type_key,
        wwi_stock_item_transaction_id, wwi_invoice_id, wwi_purchase_order_id, quantity, lineage_key
    )
    SELECT 
        ms.date_key, ms.stock_item_key, ms.customer_key, ms.supplier_key, ms.transaction_type_key,
        ms.wwi_stock_item_transaction_id, ms.wwi_invoice_id, ms.wwi_purchase_order_id, ms.quantity, p_lineage_key
    FROM integration.movement_staging ms
    WHERE ms.stock_item_key IS NOT NULL
    AND ms.transaction_type_key IS NOT NULL;
    
    -- Clear staging table
    TRUNCATE TABLE integration.movement_staging;
END;
$$;

COMMENT ON PROCEDURE integration.migrate_staged_movement_data(INTEGER) IS 
'Migrates staged movement data to the fact table';

-- =============================================
-- Integration.MigrateStagedSaleData Procedure
-- Migrates staged sale data to the fact table
-- =============================================
CREATE OR REPLACE PROCEDURE integration.migrate_staged_sale_data(
    p_lineage_key INTEGER
)
LANGUAGE plpgsql AS $$
BEGIN
    -- Update dimension keys in staging
    UPDATE integration.sale_staging ss
    SET city_key = dc.city_key
    FROM dimension.city dc
    WHERE ss.wwi_city_id = dc.wwi_city_id
    AND ss.last_modified_when >= dc.valid_from
    AND ss.last_modified_when < dc.valid_to;
    
    UPDATE integration.sale_staging ss
    SET customer_key = dc.customer_key
    FROM dimension.customer dc
    WHERE ss.wwi_customer_id = dc.wwi_customer_id
    AND ss.last_modified_when >= dc.valid_from
    AND ss.last_modified_when < dc.valid_to;
    
    UPDATE integration.sale_staging ss
    SET bill_to_customer_key = dc.customer_key
    FROM dimension.customer dc
    WHERE ss.wwi_bill_to_customer_id = dc.wwi_customer_id
    AND ss.last_modified_when >= dc.valid_from
    AND ss.last_modified_when < dc.valid_to;
    
    UPDATE integration.sale_staging ss
    SET stock_item_key = dsi.stock_item_key
    FROM dimension.stock_item dsi
    WHERE ss.wwi_stock_item_id = dsi.wwi_stock_item_id
    AND ss.last_modified_when >= dsi.valid_from
    AND ss.last_modified_when < dsi.valid_to;
    
    UPDATE integration.sale_staging ss
    SET salesperson_key = de.employee_key
    FROM dimension.employee de
    WHERE ss.wwi_salesperson_id = de.wwi_employee_id
    AND ss.last_modified_when >= de.valid_from
    AND ss.last_modified_when < de.valid_to;
    
    -- Insert into fact table
    INSERT INTO fact.sale (
        city_key, customer_key, bill_to_customer_key, stock_item_key, invoice_date_key,
        delivery_date_key, salesperson_key, wwi_invoice_id, description, package, quantity,
        unit_price, tax_rate, total_excluding_tax, tax_amount, profit, total_including_tax,
        total_dry_items, total_chiller_items, lineage_key
    )
    SELECT 
        ss.city_key, ss.customer_key, ss.bill_to_customer_key, ss.stock_item_key, ss.invoice_date_key,
        ss.delivery_date_key, ss.salesperson_key, ss.wwi_invoice_id, ss.description, ss.package, ss.quantity,
        ss.unit_price, ss.tax_rate, ss.total_excluding_tax, ss.tax_amount, ss.profit, ss.total_including_tax,
        ss.total_dry_items, ss.total_chiller_items, p_lineage_key
    FROM integration.sale_staging ss
    WHERE ss.city_key IS NOT NULL
    AND ss.customer_key IS NOT NULL
    AND ss.bill_to_customer_key IS NOT NULL
    AND ss.stock_item_key IS NOT NULL
    AND ss.salesperson_key IS NOT NULL;
    
    -- Clear staging table
    TRUNCATE TABLE integration.sale_staging;
END;
$$;

COMMENT ON PROCEDURE integration.migrate_staged_sale_data(INTEGER) IS 
'Migrates staged sale data to the fact table';

-- =============================================
-- Integration.MigrateStagedOrderData Procedure
-- Migrates staged order data to the fact table
-- =============================================
CREATE OR REPLACE PROCEDURE integration.migrate_staged_order_data(
    p_lineage_key INTEGER
)
LANGUAGE plpgsql AS $$
BEGIN
    -- Update dimension keys in staging
    UPDATE integration.order_staging os
    SET city_key = dc.city_key
    FROM dimension.city dc
    WHERE os.wwi_city_id = dc.wwi_city_id
    AND os.last_modified_when >= dc.valid_from
    AND os.last_modified_when < dc.valid_to;
    
    UPDATE integration.order_staging os
    SET customer_key = dc.customer_key
    FROM dimension.customer dc
    WHERE os.wwi_customer_id = dc.wwi_customer_id
    AND os.last_modified_when >= dc.valid_from
    AND os.last_modified_when < dc.valid_to;
    
    UPDATE integration.order_staging os
    SET stock_item_key = dsi.stock_item_key
    FROM dimension.stock_item dsi
    WHERE os.wwi_stock_item_id = dsi.wwi_stock_item_id
    AND os.last_modified_when >= dsi.valid_from
    AND os.last_modified_when < dsi.valid_to;
    
    UPDATE integration.order_staging os
    SET salesperson_key = de.employee_key
    FROM dimension.employee de
    WHERE os.wwi_salesperson_id = de.wwi_employee_id
    AND os.last_modified_when >= de.valid_from
    AND os.last_modified_when < de.valid_to;
    
    UPDATE integration.order_staging os
    SET picker_key = de.employee_key
    FROM dimension.employee de
    WHERE os.wwi_picker_id = de.wwi_employee_id
    AND os.last_modified_when >= de.valid_from
    AND os.last_modified_when < de.valid_to;
    
    -- Insert into fact table
    INSERT INTO fact.order (
        city_key, customer_key, stock_item_key, order_date_key, picked_date_key,
        salesperson_key, picker_key, wwi_order_id, wwi_backorder_id, description, package,
        quantity, unit_price, tax_rate, total_excluding_tax, tax_amount, total_including_tax, lineage_key
    )
    SELECT 
        os.city_key, os.customer_key, os.stock_item_key, os.order_date_key, os.picked_date_key,
        os.salesperson_key, os.picker_key, os.wwi_order_id, os.wwi_backorder_id, os.description, os.package,
        os.quantity, os.unit_price, os.tax_rate, os.total_excluding_tax, os.tax_amount, os.total_including_tax, p_lineage_key
    FROM integration.order_staging os
    WHERE os.city_key IS NOT NULL
    AND os.customer_key IS NOT NULL
    AND os.stock_item_key IS NOT NULL
    AND os.salesperson_key IS NOT NULL;
    
    -- Clear staging table
    TRUNCATE TABLE integration.order_staging;
END;
$$;

COMMENT ON PROCEDURE integration.migrate_staged_order_data(INTEGER) IS 
'Migrates staged order data to the fact table';

-- =============================================
-- Integration.MigrateStagedPurchaseData Procedure
-- Migrates staged purchase data to the fact table
-- =============================================
CREATE OR REPLACE PROCEDURE integration.migrate_staged_purchase_data(
    p_lineage_key INTEGER
)
LANGUAGE plpgsql AS $$
BEGIN
    -- Update dimension keys in staging
    UPDATE integration.purchase_staging ps
    SET supplier_key = ds.supplier_key
    FROM dimension.supplier ds
    WHERE ps.wwi_supplier_id = ds.wwi_supplier_id
    AND ps.last_modified_when >= ds.valid_from
    AND ps.last_modified_when < ds.valid_to;
    
    UPDATE integration.purchase_staging ps
    SET stock_item_key = dsi.stock_item_key
    FROM dimension.stock_item dsi
    WHERE ps.wwi_stock_item_id = dsi.wwi_stock_item_id
    AND ps.last_modified_when >= dsi.valid_from
    AND ps.last_modified_when < dsi.valid_to;
    
    -- Insert into fact table
    INSERT INTO fact.purchase (
        date_key, supplier_key, stock_item_key, wwi_purchase_order_id, ordered_outers,
        ordered_quantity, received_outers, package, is_order_finalized, lineage_key
    )
    SELECT 
        ps.date_key, ps.supplier_key, ps.stock_item_key, ps.wwi_purchase_order_id, ps.ordered_outers,
        ps.ordered_quantity, ps.received_outers, ps.package, ps.is_order_finalized, p_lineage_key
    FROM integration.purchase_staging ps
    WHERE ps.supplier_key IS NOT NULL
    AND ps.stock_item_key IS NOT NULL;
    
    -- Clear staging table
    TRUNCATE TABLE integration.purchase_staging;
END;
$$;

COMMENT ON PROCEDURE integration.migrate_staged_purchase_data(INTEGER) IS 
'Migrates staged purchase data to the fact table';

-- =============================================
-- Integration.MigrateStagedTransactionData Procedure
-- Migrates staged transaction data to the fact table
-- =============================================
CREATE OR REPLACE PROCEDURE integration.migrate_staged_transaction_data(
    p_lineage_key INTEGER
)
LANGUAGE plpgsql AS $$
BEGIN
    -- Update dimension keys in staging
    UPDATE integration.transaction_staging ts
    SET customer_key = dc.customer_key
    FROM dimension.customer dc
    WHERE ts.wwi_customer_id = dc.wwi_customer_id
    AND ts.last_modified_when >= dc.valid_from
    AND ts.last_modified_when < dc.valid_to;
    
    UPDATE integration.transaction_staging ts
    SET bill_to_customer_key = dc.customer_key
    FROM dimension.customer dc
    WHERE ts.wwi_bill_to_customer_id = dc.wwi_customer_id
    AND ts.last_modified_when >= dc.valid_from
    AND ts.last_modified_when < dc.valid_to;
    
    UPDATE integration.transaction_staging ts
    SET supplier_key = ds.supplier_key
    FROM dimension.supplier ds
    WHERE ts.wwi_supplier_id = ds.wwi_supplier_id
    AND ts.last_modified_when >= ds.valid_from
    AND ts.last_modified_when < ds.valid_to;
    
    UPDATE integration.transaction_staging ts
    SET transaction_type_key = dtt.transaction_type_key
    FROM dimension.transaction_type dtt
    WHERE ts.wwi_transaction_type_id = dtt.wwi_transaction_type_id
    AND ts.last_modified_when >= dtt.valid_from
    AND ts.last_modified_when < dtt.valid_to;
    
    UPDATE integration.transaction_staging ts
    SET payment_method_key = dpm.payment_method_key
    FROM dimension.payment_method dpm
    WHERE ts.wwi_payment_method_id = dpm.wwi_payment_method_id
    AND ts.last_modified_when >= dpm.valid_from
    AND ts.last_modified_when < dpm.valid_to;
    
    -- Insert into fact table
    INSERT INTO fact.transaction (
        date_key, customer_key, bill_to_customer_key, supplier_key, transaction_type_key,
        payment_method_key, wwi_customer_transaction_id, wwi_supplier_transaction_id,
        wwi_invoice_id, wwi_purchase_order_id, supplier_invoice_number, total_excluding_tax,
        tax_amount, total_including_tax, outstanding_balance, is_finalized, lineage_key
    )
    SELECT 
        ts.date_key, ts.customer_key, ts.bill_to_customer_key, ts.supplier_key, ts.transaction_type_key,
        ts.payment_method_key, ts.wwi_customer_transaction_id, ts.wwi_supplier_transaction_id,
        ts.wwi_invoice_id, ts.wwi_purchase_order_id, ts.supplier_invoice_number, ts.total_excluding_tax,
        ts.tax_amount, ts.total_including_tax, ts.outstanding_balance, ts.is_finalized, p_lineage_key
    FROM integration.transaction_staging ts
    WHERE ts.transaction_type_key IS NOT NULL;
    
    -- Clear staging table
    TRUNCATE TABLE integration.transaction_staging;
END;
$$;

COMMENT ON PROCEDURE integration.migrate_staged_transaction_data(INTEGER) IS 
'Migrates staged transaction data to the fact table';

-- =============================================
-- Integration.MigrateStagedStockHoldingData Procedure
-- Migrates staged stock holding data to the fact table
-- =============================================
CREATE OR REPLACE PROCEDURE integration.migrate_staged_stock_holding_data(
    p_lineage_key INTEGER
)
LANGUAGE plpgsql AS $$
BEGIN
    -- Update dimension keys in staging
    UPDATE integration.stock_holding_staging shs
    SET stock_item_key = dsi.stock_item_key
    FROM dimension.stock_item dsi
    WHERE shs.wwi_stock_item_id = dsi.wwi_stock_item_id
    AND dsi.valid_to = '9999-12-31 23:59:59.9999999'::TIMESTAMP;
    
    -- Delete existing stock holding data (snapshot replacement)
    DELETE FROM fact.stock_holding;
    
    -- Insert into fact table
    INSERT INTO fact.stock_holding (
        stock_holding_key, stock_item_key, quantity_on_hand, bin_location,
        last_stocktake_quantity, last_cost_price, reorder_level, target_stock_level, lineage_key
    )
    SELECT 
        shs.stock_holding_staging_key, shs.stock_item_key, shs.quantity_on_hand, shs.bin_location,
        shs.last_stocktake_quantity, shs.last_cost_price, shs.reorder_level, shs.target_stock_level, p_lineage_key
    FROM integration.stock_holding_staging shs
    WHERE shs.stock_item_key IS NOT NULL;
    
    -- Clear staging table
    TRUNCATE TABLE integration.stock_holding_staging;
END;
$$;

COMMENT ON PROCEDURE integration.migrate_staged_stock_holding_data(INTEGER) IS 
'Migrates staged stock holding data to the fact table (snapshot replacement)';

-- =============================================
-- Integration.CompleteLineage Procedure
-- Marks a lineage record as complete
-- =============================================
CREATE OR REPLACE PROCEDURE integration.complete_lineage(
    p_lineage_key INTEGER,
    p_was_successful BOOLEAN
)
LANGUAGE plpgsql AS $$
BEGIN
    UPDATE integration.lineage
    SET data_load_completed = clock_timestamp(),
        was_successful = p_was_successful
    WHERE lineage_key = p_lineage_key;
    
    -- Update ETL cutoff if successful
    IF p_was_successful THEN
        INSERT INTO integration.etl_cutoff (table_name, cutoff_time)
        SELECT table_name, source_system_cutoff_time
        FROM integration.lineage
        WHERE lineage_key = p_lineage_key
        ON CONFLICT (table_name) DO UPDATE
        SET cutoff_time = EXCLUDED.cutoff_time;
    END IF;
END;
$$;

COMMENT ON PROCEDURE integration.complete_lineage(INTEGER, BOOLEAN) IS 
'Marks a lineage record as complete and updates ETL cutoff time';
