-- Wide World Importers DW PostgreSQL Migration
-- Phase 5: ETL and Analytics Migration
-- File: 003-fact-migration-procedures.sql
-- Description: Migration procedures for fact tables (Sale, Order, Purchase, Movement, Transaction, Stock Holding)

-- =============================================
-- Procedure: integration.migrate_staged_sale_data
-- Description: Migrates staged sale data to the Sale fact table
-- =============================================
CREATE OR REPLACE PROCEDURE integration.migrate_staged_sale_data()
LANGUAGE plpgsql
AS $$
DECLARE
    v_lineage_key integer;
BEGIN
    SELECT lineage_key INTO v_lineage_key
    FROM integration.lineage
    WHERE table_name = 'Sale'
    AND data_load_completed IS NULL
    ORDER BY lineage_key DESC
    LIMIT 1;
    
    IF v_lineage_key IS NULL THEN
        RAISE EXCEPTION 'No pending lineage record found for Sale';
    END IF;
    
    -- Find the dimension keys required
    UPDATE integration.sale_staging s
    SET city_key = COALESCE((
            SELECT c.city_key
            FROM dimension.city c
            WHERE c.wwi_city_id = s.wwi_city_id
            AND s.last_modified_when > c.valid_from
            AND s.last_modified_when <= c.valid_to
            ORDER BY c.valid_from
            LIMIT 1
        ), 0),
        customer_key = COALESCE((
            SELECT c.customer_key
            FROM dimension.customer c
            WHERE c.wwi_customer_id = s.wwi_customer_id
            AND s.last_modified_when > c.valid_from
            AND s.last_modified_when <= c.valid_to
            ORDER BY c.valid_from
            LIMIT 1
        ), 0),
        bill_to_customer_key = COALESCE((
            SELECT c.customer_key
            FROM dimension.customer c
            WHERE c.wwi_customer_id = s.wwi_bill_to_customer_id
            AND s.last_modified_when > c.valid_from
            AND s.last_modified_when <= c.valid_to
            ORDER BY c.valid_from
            LIMIT 1
        ), 0),
        stock_item_key = COALESCE((
            SELECT si.stock_item_key
            FROM dimension.stock_item si
            WHERE si.wwi_stock_item_id = s.wwi_stock_item_id
            AND s.last_modified_when > si.valid_from
            AND s.last_modified_when <= si.valid_to
            ORDER BY si.valid_from
            LIMIT 1
        ), 0),
        salesperson_key = COALESCE((
            SELECT e.employee_key
            FROM dimension.employee e
            WHERE e.wwi_employee_id = s.wwi_salesperson_id
            AND s.last_modified_when > e.valid_from
            AND s.last_modified_when <= e.valid_to
            ORDER BY e.valid_from
            LIMIT 1
        ), 0);
    
    -- Remove any existing entries for these invoices
    DELETE FROM fact.sale f
    WHERE f.wwi_invoice_id IN (SELECT wwi_invoice_id FROM integration.sale_staging);
    
    -- Insert all current details for these invoices
    INSERT INTO fact.sale (
        city_key, customer_key, bill_to_customer_key, stock_item_key,
        invoice_date_key, delivery_date_key, salesperson_key, wwi_invoice_id,
        description, package, quantity, unit_price, tax_rate,
        total_excluding_tax, tax_amount, profit, total_including_tax,
        total_dry_items, total_chiller_items, lineage_key
    )
    SELECT 
        city_key, customer_key, bill_to_customer_key, stock_item_key,
        invoice_date_key, delivery_date_key, salesperson_key, wwi_invoice_id,
        description, package, quantity, unit_price, tax_rate,
        total_excluding_tax, tax_amount, profit, total_including_tax,
        total_dry_items, total_chiller_items, v_lineage_key
    FROM integration.sale_staging;
    
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
    WHERE table_name = 'Sale';
END;
$$;

COMMENT ON PROCEDURE integration.migrate_staged_sale_data() IS 
'Migrates staged sale data to the Sale fact table with dimension key lookups';

-- =============================================
-- Procedure: integration.migrate_staged_order_data
-- Description: Migrates staged order data to the Order fact table
-- =============================================
CREATE OR REPLACE PROCEDURE integration.migrate_staged_order_data()
LANGUAGE plpgsql
AS $$
DECLARE
    v_lineage_key integer;
BEGIN
    SELECT lineage_key INTO v_lineage_key
    FROM integration.lineage
    WHERE table_name = 'Order'
    AND data_load_completed IS NULL
    ORDER BY lineage_key DESC
    LIMIT 1;
    
    IF v_lineage_key IS NULL THEN
        RAISE EXCEPTION 'No pending lineage record found for Order';
    END IF;
    
    -- Find the dimension keys required
    UPDATE integration.order_staging o
    SET city_key = COALESCE((
            SELECT c.city_key
            FROM dimension.city c
            WHERE c.wwi_city_id = o.wwi_city_id
            AND o.last_modified_when > c.valid_from
            AND o.last_modified_when <= c.valid_to
            ORDER BY c.valid_from
            LIMIT 1
        ), 0),
        customer_key = COALESCE((
            SELECT c.customer_key
            FROM dimension.customer c
            WHERE c.wwi_customer_id = o.wwi_customer_id
            AND o.last_modified_when > c.valid_from
            AND o.last_modified_when <= c.valid_to
            ORDER BY c.valid_from
            LIMIT 1
        ), 0),
        stock_item_key = COALESCE((
            SELECT si.stock_item_key
            FROM dimension.stock_item si
            WHERE si.wwi_stock_item_id = o.wwi_stock_item_id
            AND o.last_modified_when > si.valid_from
            AND o.last_modified_when <= si.valid_to
            ORDER BY si.valid_from
            LIMIT 1
        ), 0),
        salesperson_key = COALESCE((
            SELECT e.employee_key
            FROM dimension.employee e
            WHERE e.wwi_employee_id = o.wwi_salesperson_id
            AND o.last_modified_when > e.valid_from
            AND o.last_modified_when <= e.valid_to
            ORDER BY e.valid_from
            LIMIT 1
        ), 0),
        picker_key = COALESCE((
            SELECT e.employee_key
            FROM dimension.employee e
            WHERE e.wwi_employee_id = o.wwi_picker_id
            AND o.last_modified_when > e.valid_from
            AND o.last_modified_when <= e.valid_to
            ORDER BY e.valid_from
            LIMIT 1
        ), 0);
    
    -- Use MERGE-like logic (INSERT ON CONFLICT UPDATE)
    INSERT INTO fact.order (
        city_key, customer_key, stock_item_key, order_date_key, picked_date_key,
        salesperson_key, picker_key, wwi_order_id, wwi_backorder_id,
        description, package, quantity, unit_price, tax_rate,
        total_excluding_tax, tax_amount, total_including_tax, lineage_key
    )
    SELECT 
        city_key, customer_key, stock_item_key, order_date_key, picked_date_key,
        salesperson_key, picker_key, wwi_order_id, wwi_backorder_id,
        description, package, quantity, unit_price, tax_rate,
        total_excluding_tax, tax_amount, total_including_tax, v_lineage_key
    FROM integration.order_staging
    ON CONFLICT (wwi_order_id) DO UPDATE SET
        city_key = EXCLUDED.city_key,
        customer_key = EXCLUDED.customer_key,
        stock_item_key = EXCLUDED.stock_item_key,
        order_date_key = EXCLUDED.order_date_key,
        picked_date_key = EXCLUDED.picked_date_key,
        salesperson_key = EXCLUDED.salesperson_key,
        picker_key = EXCLUDED.picker_key,
        wwi_backorder_id = EXCLUDED.wwi_backorder_id,
        description = EXCLUDED.description,
        package = EXCLUDED.package,
        quantity = EXCLUDED.quantity,
        unit_price = EXCLUDED.unit_price,
        tax_rate = EXCLUDED.tax_rate,
        total_excluding_tax = EXCLUDED.total_excluding_tax,
        tax_amount = EXCLUDED.tax_amount,
        total_including_tax = EXCLUDED.total_including_tax,
        lineage_key = EXCLUDED.lineage_key;
    
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
    WHERE table_name = 'Order';
END;
$$;

COMMENT ON PROCEDURE integration.migrate_staged_order_data() IS 
'Migrates staged order data to the Order fact table with dimension key lookups';

-- =============================================
-- Procedure: integration.migrate_staged_purchase_data
-- Description: Migrates staged purchase data to the Purchase fact table
-- =============================================
CREATE OR REPLACE PROCEDURE integration.migrate_staged_purchase_data()
LANGUAGE plpgsql
AS $$
DECLARE
    v_lineage_key integer;
BEGIN
    SELECT lineage_key INTO v_lineage_key
    FROM integration.lineage
    WHERE table_name = 'Purchase'
    AND data_load_completed IS NULL
    ORDER BY lineage_key DESC
    LIMIT 1;
    
    IF v_lineage_key IS NULL THEN
        RAISE EXCEPTION 'No pending lineage record found for Purchase';
    END IF;
    
    -- Find the dimension keys required
    UPDATE integration.purchase_staging p
    SET supplier_key = COALESCE((
            SELECT s.supplier_key
            FROM dimension.supplier s
            WHERE s.wwi_supplier_id = p.wwi_supplier_id
            AND p.last_modified_when > s.valid_from
            AND p.last_modified_when <= s.valid_to
            ORDER BY s.valid_from
            LIMIT 1
        ), 0),
        stock_item_key = COALESCE((
            SELECT si.stock_item_key
            FROM dimension.stock_item si
            WHERE si.wwi_stock_item_id = p.wwi_stock_item_id
            AND p.last_modified_when > si.valid_from
            AND p.last_modified_when <= si.valid_to
            ORDER BY si.valid_from
            LIMIT 1
        ), 0);
    
    -- Use MERGE-like logic
    INSERT INTO fact.purchase (
        date_key, supplier_key, stock_item_key, wwi_purchase_order_id,
        ordered_outers, ordered_quantity, received_outers, package,
        is_order_finalized, lineage_key
    )
    SELECT 
        date_key, supplier_key, stock_item_key, wwi_purchase_order_id,
        ordered_outers, ordered_quantity, received_outers, package,
        is_order_finalized, v_lineage_key
    FROM integration.purchase_staging
    ON CONFLICT (wwi_purchase_order_id, stock_item_key) DO UPDATE SET
        date_key = EXCLUDED.date_key,
        supplier_key = EXCLUDED.supplier_key,
        ordered_outers = EXCLUDED.ordered_outers,
        ordered_quantity = EXCLUDED.ordered_quantity,
        received_outers = EXCLUDED.received_outers,
        package = EXCLUDED.package,
        is_order_finalized = EXCLUDED.is_order_finalized,
        lineage_key = EXCLUDED.lineage_key;
    
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
    WHERE table_name = 'Purchase';
END;
$$;

COMMENT ON PROCEDURE integration.migrate_staged_purchase_data() IS 
'Migrates staged purchase data to the Purchase fact table with dimension key lookups';

-- =============================================
-- Procedure: integration.migrate_staged_movement_data
-- Description: Migrates staged movement data to the Movement fact table
-- =============================================
CREATE OR REPLACE PROCEDURE integration.migrate_staged_movement_data()
LANGUAGE plpgsql
AS $$
DECLARE
    v_lineage_key integer;
BEGIN
    SELECT lineage_key INTO v_lineage_key
    FROM integration.lineage
    WHERE table_name = 'Movement'
    AND data_load_completed IS NULL
    ORDER BY lineage_key DESC
    LIMIT 1;
    
    IF v_lineage_key IS NULL THEN
        RAISE EXCEPTION 'No pending lineage record found for Movement';
    END IF;
    
    -- Find the dimension keys required
    UPDATE integration.movement_staging m
    SET stock_item_key = COALESCE((
            SELECT si.stock_item_key
            FROM dimension.stock_item si
            WHERE si.wwi_stock_item_id = m.wwi_stock_item_id
            AND m.last_modified_when > si.valid_from
            AND m.last_modified_when <= si.valid_to
            ORDER BY si.valid_from
            LIMIT 1
        ), 0),
        customer_key = COALESCE((
            SELECT c.customer_key
            FROM dimension.customer c
            WHERE c.wwi_customer_id = m.wwi_customer_id
            AND m.last_modified_when > c.valid_from
            AND m.last_modified_when <= c.valid_to
            ORDER BY c.valid_from
            LIMIT 1
        ), 0),
        supplier_key = COALESCE((
            SELECT s.supplier_key
            FROM dimension.supplier s
            WHERE s.wwi_supplier_id = m.wwi_supplier_id
            AND m.last_modified_when > s.valid_from
            AND m.last_modified_when <= s.valid_to
            ORDER BY s.valid_from
            LIMIT 1
        ), 0),
        transaction_type_key = COALESCE((
            SELECT tt.transaction_type_key
            FROM dimension.transaction_type tt
            WHERE tt.wwi_transaction_type_id = m.wwi_transaction_type_id
            AND m.last_modified_when > tt.valid_from
            AND m.last_modified_when <= tt.valid_to
            ORDER BY tt.valid_from
            LIMIT 1
        ), 0);
    
    -- Use MERGE-like logic
    INSERT INTO fact.movement (
        date_key, stock_item_key, customer_key, supplier_key, transaction_type_key,
        wwi_stock_item_transaction_id, wwi_invoice_id, wwi_purchase_order_id,
        quantity, lineage_key
    )
    SELECT 
        date_key, stock_item_key, customer_key, supplier_key, transaction_type_key,
        wwi_stock_item_transaction_id, wwi_invoice_id, wwi_purchase_order_id,
        quantity, v_lineage_key
    FROM integration.movement_staging
    ON CONFLICT (wwi_stock_item_transaction_id) DO UPDATE SET
        date_key = EXCLUDED.date_key,
        stock_item_key = EXCLUDED.stock_item_key,
        customer_key = EXCLUDED.customer_key,
        supplier_key = EXCLUDED.supplier_key,
        transaction_type_key = EXCLUDED.transaction_type_key,
        wwi_invoice_id = EXCLUDED.wwi_invoice_id,
        wwi_purchase_order_id = EXCLUDED.wwi_purchase_order_id,
        quantity = EXCLUDED.quantity,
        lineage_key = EXCLUDED.lineage_key;
    
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
    WHERE table_name = 'Movement';
END;
$$;

COMMENT ON PROCEDURE integration.migrate_staged_movement_data() IS 
'Migrates staged movement data to the Movement fact table with dimension key lookups';

-- =============================================
-- Procedure: integration.migrate_staged_transaction_data
-- Description: Migrates staged transaction data to the Transaction fact table
-- =============================================
CREATE OR REPLACE PROCEDURE integration.migrate_staged_transaction_data()
LANGUAGE plpgsql
AS $$
DECLARE
    v_lineage_key integer;
BEGIN
    SELECT lineage_key INTO v_lineage_key
    FROM integration.lineage
    WHERE table_name = 'Transaction'
    AND data_load_completed IS NULL
    ORDER BY lineage_key DESC
    LIMIT 1;
    
    IF v_lineage_key IS NULL THEN
        RAISE EXCEPTION 'No pending lineage record found for Transaction';
    END IF;
    
    -- Find the dimension keys required
    UPDATE integration.transaction_staging t
    SET customer_key = COALESCE((
            SELECT c.customer_key
            FROM dimension.customer c
            WHERE c.wwi_customer_id = t.wwi_customer_id
            AND t.last_modified_when > c.valid_from
            AND t.last_modified_when <= c.valid_to
            ORDER BY c.valid_from
            LIMIT 1
        ), 0),
        bill_to_customer_key = COALESCE((
            SELECT c.customer_key
            FROM dimension.customer c
            WHERE c.wwi_customer_id = t.wwi_bill_to_customer_id
            AND t.last_modified_when > c.valid_from
            AND t.last_modified_when <= c.valid_to
            ORDER BY c.valid_from
            LIMIT 1
        ), 0),
        supplier_key = COALESCE((
            SELECT s.supplier_key
            FROM dimension.supplier s
            WHERE s.wwi_supplier_id = t.wwi_supplier_id
            AND t.last_modified_when > s.valid_from
            AND t.last_modified_when <= s.valid_to
            ORDER BY s.valid_from
            LIMIT 1
        ), 0),
        transaction_type_key = COALESCE((
            SELECT tt.transaction_type_key
            FROM dimension.transaction_type tt
            WHERE tt.wwi_transaction_type_id = t.wwi_transaction_type_id
            AND t.last_modified_when > tt.valid_from
            AND t.last_modified_when <= tt.valid_to
            ORDER BY tt.valid_from
            LIMIT 1
        ), 0),
        payment_method_key = COALESCE((
            SELECT pm.payment_method_key
            FROM dimension.payment_method pm
            WHERE pm.wwi_payment_method_id = t.wwi_payment_method_id
            AND t.last_modified_when > pm.valid_from
            AND t.last_modified_when <= pm.valid_to
            ORDER BY pm.valid_from
            LIMIT 1
        ), 0);
    
    -- Use MERGE-like logic for customer transactions
    INSERT INTO fact.transaction (
        date_key, customer_key, bill_to_customer_key, supplier_key,
        transaction_type_key, payment_method_key, wwi_customer_transaction_id,
        wwi_supplier_transaction_id, wwi_invoice_id, wwi_purchase_order_id,
        supplier_invoice_number, total_excluding_tax, tax_amount,
        total_including_tax, outstanding_balance, is_finalized, lineage_key
    )
    SELECT 
        date_key, customer_key, bill_to_customer_key, supplier_key,
        transaction_type_key, payment_method_key, wwi_customer_transaction_id,
        wwi_supplier_transaction_id, wwi_invoice_id, wwi_purchase_order_id,
        supplier_invoice_number, total_excluding_tax, tax_amount,
        total_including_tax, outstanding_balance, is_finalized, v_lineage_key
    FROM integration.transaction_staging
    ON CONFLICT (wwi_customer_transaction_id, wwi_supplier_transaction_id) DO UPDATE SET
        date_key = EXCLUDED.date_key,
        customer_key = EXCLUDED.customer_key,
        bill_to_customer_key = EXCLUDED.bill_to_customer_key,
        supplier_key = EXCLUDED.supplier_key,
        transaction_type_key = EXCLUDED.transaction_type_key,
        payment_method_key = EXCLUDED.payment_method_key,
        wwi_invoice_id = EXCLUDED.wwi_invoice_id,
        wwi_purchase_order_id = EXCLUDED.wwi_purchase_order_id,
        supplier_invoice_number = EXCLUDED.supplier_invoice_number,
        total_excluding_tax = EXCLUDED.total_excluding_tax,
        tax_amount = EXCLUDED.tax_amount,
        total_including_tax = EXCLUDED.total_including_tax,
        outstanding_balance = EXCLUDED.outstanding_balance,
        is_finalized = EXCLUDED.is_finalized,
        lineage_key = EXCLUDED.lineage_key;
    
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
    WHERE table_name = 'Transaction';
END;
$$;

COMMENT ON PROCEDURE integration.migrate_staged_transaction_data() IS 
'Migrates staged transaction data to the Transaction fact table with dimension key lookups';

-- =============================================
-- Procedure: integration.migrate_staged_stock_holding_data
-- Description: Migrates staged stock holding data to the Stock Holding fact table
-- =============================================
CREATE OR REPLACE PROCEDURE integration.migrate_staged_stock_holding_data()
LANGUAGE plpgsql
AS $$
DECLARE
    v_lineage_key integer;
BEGIN
    SELECT lineage_key INTO v_lineage_key
    FROM integration.lineage
    WHERE table_name = 'Stock Holding'
    AND data_load_completed IS NULL
    ORDER BY lineage_key DESC
    LIMIT 1;
    
    IF v_lineage_key IS NULL THEN
        RAISE EXCEPTION 'No pending lineage record found for Stock Holding';
    END IF;
    
    -- Find the dimension keys required
    UPDATE integration.stock_holding_staging sh
    SET stock_item_key = COALESCE((
            SELECT si.stock_item_key
            FROM dimension.stock_item si
            WHERE si.wwi_stock_item_id = sh.wwi_stock_item_id
            AND sh.last_modified_when > si.valid_from
            AND sh.last_modified_when <= si.valid_to
            ORDER BY si.valid_from
            LIMIT 1
        ), 0);
    
    -- Truncate and reload (stock holding is a snapshot)
    TRUNCATE TABLE fact.stock_holding;
    
    INSERT INTO fact.stock_holding (
        stock_item_key, quantity_on_hand, bin_location,
        last_stocktake_quantity, last_cost_price, reorder_level,
        target_stock_level, lineage_key
    )
    SELECT 
        stock_item_key, quantity_on_hand, bin_location,
        last_stocktake_quantity, last_cost_price, reorder_level,
        target_stock_level, v_lineage_key
    FROM integration.stock_holding_staging;
    
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
    WHERE table_name = 'Stock Holding';
END;
$$;

COMMENT ON PROCEDURE integration.migrate_staged_stock_holding_data() IS 
'Migrates staged stock holding data to the Stock Holding fact table (snapshot reload)';
