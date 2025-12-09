-- Wide World Importers PostgreSQL Migration
-- Phase 3: OLTP Code Migration
-- Script 004: Data Loading Simulation Procedures
-- Migrated from SQL Server T-SQL to PostgreSQL PL/pgSQL

-- =============================================
-- DataLoadSimulation.Configuration Table
-- Stores configuration for data loading simulation
-- =============================================
CREATE TABLE IF NOT EXISTS dataload_simulation.configuration (
    configuration_id SERIAL PRIMARY KEY,
    configuration_key VARCHAR(100) NOT NULL UNIQUE,
    configuration_value TEXT NOT NULL
);

-- Insert default configuration values
INSERT INTO dataload_simulation.configuration (configuration_key, configuration_value)
VALUES 
    ('DataLoadSimulationStartDate', '2013-01-01'),
    ('DataLoadSimulationEndDate', '2016-05-31'),
    ('AverageNumberOfCustomerOrdersPerDay', '60'),
    ('SaturdayPercentageOfNormalWorkDay', '50'),
    ('SundayPercentageOfNormalWorkDay', '0'),
    ('UpdateCustomerProbabilityPercent', '1'),
    ('UpdateSupplierProbabilityPercent', '1'),
    ('UpdateStockItemProbabilityPercent', '1'),
    ('OrderLineItemsPerOrder', '3'),
    ('ChanceOfCustomerPaymentPercent', '70'),
    ('PaymentDaysAfterInvoice', '14')
ON CONFLICT (configuration_key) DO NOTHING;

-- =============================================
-- DataLoadSimulation.GetConfigurationValue Function
-- Gets a configuration value
-- =============================================
CREATE OR REPLACE FUNCTION dataload_simulation.get_configuration_value(
    p_configuration_key VARCHAR(100)
)
RETURNS TEXT AS $$
DECLARE
    v_value TEXT;
BEGIN
    SELECT configuration_value INTO v_value
    FROM dataload_simulation.configuration
    WHERE configuration_key = p_configuration_key;
    
    RETURN v_value;
END;
$$ LANGUAGE plpgsql;

-- =============================================
-- DataLoadSimulation.GetRandomInteger Function
-- Returns a random integer between min and max (inclusive)
-- =============================================
CREATE OR REPLACE FUNCTION dataload_simulation.get_random_integer(
    p_min INTEGER,
    p_max INTEGER
)
RETURNS INTEGER AS $$
BEGIN
    RETURN floor(random() * (p_max - p_min + 1) + p_min)::INTEGER;
END;
$$ LANGUAGE plpgsql;

-- =============================================
-- DataLoadSimulation.GetRandomDecimal Function
-- Returns a random decimal between min and max
-- =============================================
CREATE OR REPLACE FUNCTION dataload_simulation.get_random_decimal(
    p_min NUMERIC,
    p_max NUMERIC
)
RETURNS NUMERIC AS $$
BEGIN
    RETURN random() * (p_max - p_min) + p_min;
END;
$$ LANGUAGE plpgsql;

-- =============================================
-- DataLoadSimulation.GetRandomCustomerID Function
-- Returns a random customer ID
-- =============================================
CREATE OR REPLACE FUNCTION dataload_simulation.get_random_customer_id()
RETURNS INTEGER AS $$
DECLARE
    v_customer_id INTEGER;
BEGIN
    SELECT customer_id INTO v_customer_id
    FROM sales.customers
    WHERE is_on_credit_hold = false
    ORDER BY random()
    LIMIT 1;
    
    RETURN v_customer_id;
END;
$$ LANGUAGE plpgsql;

-- =============================================
-- DataLoadSimulation.GetRandomStockItemID Function
-- Returns a random stock item ID
-- =============================================
CREATE OR REPLACE FUNCTION dataload_simulation.get_random_stock_item_id()
RETURNS INTEGER AS $$
DECLARE
    v_stock_item_id INTEGER;
BEGIN
    SELECT si.stock_item_id INTO v_stock_item_id
    FROM warehouse.stock_items si
    INNER JOIN warehouse.stock_item_holdings sih ON si.stock_item_id = sih.stock_item_id
    WHERE sih.quantity_on_hand > 0
    ORDER BY random()
    LIMIT 1;
    
    RETURN v_stock_item_id;
END;
$$ LANGUAGE plpgsql;

-- =============================================
-- DataLoadSimulation.GetRandomSupplierID Function
-- Returns a random supplier ID
-- =============================================
CREATE OR REPLACE FUNCTION dataload_simulation.get_random_supplier_id()
RETURNS INTEGER AS $$
DECLARE
    v_supplier_id INTEGER;
BEGIN
    SELECT supplier_id INTO v_supplier_id
    FROM purchasing.suppliers
    ORDER BY random()
    LIMIT 1;
    
    RETURN v_supplier_id;
END;
$$ LANGUAGE plpgsql;

-- =============================================
-- DataLoadSimulation.GetRandomPersonID Function
-- Returns a random person ID (employee)
-- =============================================
CREATE OR REPLACE FUNCTION dataload_simulation.get_random_person_id()
RETURNS INTEGER AS $$
DECLARE
    v_person_id INTEGER;
BEGIN
    SELECT person_id INTO v_person_id
    FROM application.people
    WHERE is_employee = true
    ORDER BY random()
    LIMIT 1;
    
    RETURN v_person_id;
END;
$$ LANGUAGE plpgsql;

-- =============================================
-- DataLoadSimulation.GetRandomSalespersonID Function
-- Returns a random salesperson ID
-- =============================================
CREATE OR REPLACE FUNCTION dataload_simulation.get_random_salesperson_id()
RETURNS INTEGER AS $$
DECLARE
    v_person_id INTEGER;
BEGIN
    SELECT person_id INTO v_person_id
    FROM application.people
    WHERE is_salesperson = true
    ORDER BY random()
    LIMIT 1;
    
    RETURN v_person_id;
END;
$$ LANGUAGE plpgsql;

-- =============================================
-- DataLoadSimulation.CreateCustomerOrder Procedure
-- Creates a customer order with random items
-- =============================================
CREATE OR REPLACE PROCEDURE dataload_simulation.create_customer_order(
    p_order_date DATE,
    p_user_id INTEGER
)
LANGUAGE plpgsql AS $$
DECLARE
    v_customer_id INTEGER;
    v_salesperson_id INTEGER;
    v_contact_person_id INTEGER;
    v_order_id INTEGER;
    v_stock_item_id INTEGER;
    v_quantity INTEGER;
    v_unit_price NUMERIC(18, 2);
    v_tax_rate NUMERIC(18, 3);
    v_order_line_count INTEGER;
    v_i INTEGER;
BEGIN
    -- Get random customer
    v_customer_id := dataload_simulation.get_random_customer_id();
    IF v_customer_id IS NULL THEN
        RETURN;
    END IF;
    
    -- Get random salesperson
    v_salesperson_id := dataload_simulation.get_random_salesperson_id();
    
    -- Get customer's primary contact
    SELECT primary_contact_person_id INTO v_contact_person_id
    FROM sales.customers
    WHERE customer_id = v_customer_id;
    
    -- Get next order ID
    v_order_id := nextval('sequences.order_id');
    
    -- Create order
    INSERT INTO sales.orders (
        order_id, customer_id, salesperson_person_id, picked_by_person_id,
        contact_person_id, backorder_order_id, order_date, expected_delivery_date,
        customer_purchase_order_number, is_undersupply_backordered, comments,
        delivery_instructions, internal_comments, picking_completed_when,
        last_edited_by, last_edited_when
    )
    VALUES (
        v_order_id, v_customer_id, v_salesperson_id, NULL,
        v_contact_person_id, NULL, p_order_date, p_order_date + INTERVAL '1 day',
        'PO-' || v_order_id::text, false, NULL, NULL, NULL, NULL,
        p_user_id, clock_timestamp()
    );
    
    -- Determine number of order lines
    v_order_line_count := dataload_simulation.get_random_integer(1, 5);
    
    -- Create order lines
    FOR v_i IN 1..v_order_line_count LOOP
        -- Get random stock item
        v_stock_item_id := dataload_simulation.get_random_stock_item_id();
        IF v_stock_item_id IS NULL THEN
            CONTINUE;
        END IF;
        
        -- Get stock item details
        SELECT unit_price, tax_rate INTO v_unit_price, v_tax_rate
        FROM warehouse.stock_items
        WHERE stock_item_id = v_stock_item_id;
        
        -- Random quantity
        v_quantity := dataload_simulation.get_random_integer(1, 10);
        
        -- Insert order line
        INSERT INTO sales.order_lines (
            order_id, stock_item_id, description, package_type_id,
            quantity, unit_price, tax_rate, picked_quantity, picking_completed_when,
            last_edited_by, last_edited_when
        )
        SELECT 
            v_order_id, v_stock_item_id, si.stock_item_name, si.unit_package_id,
            v_quantity, v_unit_price, v_tax_rate, 0, NULL,
            p_user_id, clock_timestamp()
        FROM warehouse.stock_items si
        WHERE si.stock_item_id = v_stock_item_id;
    END LOOP;
END;
$$;

COMMENT ON PROCEDURE dataload_simulation.create_customer_order(DATE, INTEGER) IS 
'Creates a customer order with random items for data simulation';

-- =============================================
-- DataLoadSimulation.PickStockForCustomerOrders Procedure
-- Picks stock for unpicked customer orders
-- =============================================
CREATE OR REPLACE PROCEDURE dataload_simulation.pick_stock_for_customer_orders(
    p_pick_date DATE,
    p_user_id INTEGER
)
LANGUAGE plpgsql AS $$
DECLARE
    v_order_record RECORD;
    v_order_line_record RECORD;
    v_picker_id INTEGER;
    v_available_quantity INTEGER;
    v_quantity_to_pick INTEGER;
BEGIN
    -- Get a random picker
    v_picker_id := dataload_simulation.get_random_person_id();
    
    -- Process unpicked orders
    FOR v_order_record IN 
        SELECT o.order_id
        FROM sales.orders o
        WHERE o.picking_completed_when IS NULL
        AND o.order_date <= p_pick_date
        ORDER BY o.order_date
        LIMIT 50
    LOOP
        -- Pick each order line
        FOR v_order_line_record IN
            SELECT ol.order_line_id, ol.stock_item_id, ol.quantity
            FROM sales.order_lines ol
            WHERE ol.order_id = v_order_record.order_id
            AND ol.picking_completed_when IS NULL
        LOOP
            -- Get available quantity
            SELECT quantity_on_hand INTO v_available_quantity
            FROM warehouse.stock_item_holdings
            WHERE stock_item_id = v_order_line_record.stock_item_id;
            
            -- Determine quantity to pick
            v_quantity_to_pick := LEAST(v_order_line_record.quantity, COALESCE(v_available_quantity, 0));
            
            IF v_quantity_to_pick > 0 THEN
                -- Update order line
                UPDATE sales.order_lines
                SET picked_quantity = v_quantity_to_pick,
                    picking_completed_when = clock_timestamp(),
                    last_edited_by = p_user_id,
                    last_edited_when = clock_timestamp()
                WHERE order_line_id = v_order_line_record.order_line_id;
            END IF;
        END LOOP;
        
        -- Check if all lines are picked
        IF NOT EXISTS (
            SELECT 1 FROM sales.order_lines
            WHERE order_id = v_order_record.order_id
            AND picking_completed_when IS NULL
        ) THEN
            -- Mark order as picked
            UPDATE sales.orders
            SET picked_by_person_id = v_picker_id,
                picking_completed_when = clock_timestamp(),
                last_edited_by = p_user_id,
                last_edited_when = clock_timestamp()
            WHERE order_id = v_order_record.order_id;
        END IF;
    END LOOP;
END;
$$;

COMMENT ON PROCEDURE dataload_simulation.pick_stock_for_customer_orders(DATE, INTEGER) IS 
'Picks stock for unpicked customer orders';

-- =============================================
-- DataLoadSimulation.InvoicePickedOrders Procedure
-- Creates invoices for picked orders
-- =============================================
CREATE OR REPLACE PROCEDURE dataload_simulation.invoice_picked_orders(
    p_invoice_date DATE,
    p_user_id INTEGER
)
LANGUAGE plpgsql AS $$
DECLARE
    v_order_ids INTEGER[];
    v_packer_id INTEGER;
BEGIN
    -- Get a random packer
    v_packer_id := dataload_simulation.get_random_person_id();
    
    -- Get picked orders that haven't been invoiced
    SELECT ARRAY_AGG(o.order_id) INTO v_order_ids
    FROM sales.orders o
    WHERE o.picking_completed_when IS NOT NULL
    AND NOT EXISTS (SELECT 1 FROM sales.invoices i WHERE i.order_id = o.order_id)
    LIMIT 50;
    
    -- Invoice the orders
    IF v_order_ids IS NOT NULL AND array_length(v_order_ids, 1) > 0 THEN
        CALL website.invoice_customer_orders(v_order_ids, v_packer_id, p_user_id);
    END IF;
END;
$$;

COMMENT ON PROCEDURE dataload_simulation.invoice_picked_orders(DATE, INTEGER) IS 
'Creates invoices for picked orders';

-- =============================================
-- DataLoadSimulation.ProcessCustomerPayments Procedure
-- Processes customer payments for outstanding invoices
-- =============================================
CREATE OR REPLACE PROCEDURE dataload_simulation.process_customer_payments(
    p_payment_date DATE,
    p_user_id INTEGER
)
LANGUAGE plpgsql AS $$
DECLARE
    v_transaction_record RECORD;
    v_payment_method_id INTEGER;
BEGIN
    -- Get a payment method
    SELECT payment_method_id INTO v_payment_method_id
    FROM application.payment_methods
    WHERE payment_method_name = 'EFT'
    LIMIT 1;
    
    IF v_payment_method_id IS NULL THEN
        SELECT payment_method_id INTO v_payment_method_id
        FROM application.payment_methods
        LIMIT 1;
    END IF;
    
    -- Process outstanding transactions
    FOR v_transaction_record IN
        SELECT ct.customer_transaction_id, ct.customer_id, ct.transaction_amount, ct.outstanding_balance
        FROM sales.customer_transactions ct
        WHERE ct.outstanding_balance > 0
        AND ct.transaction_date <= p_payment_date - INTERVAL '14 days'
        AND random() < 0.7
        LIMIT 50
    LOOP
        -- Insert payment transaction
        INSERT INTO sales.customer_transactions (
            customer_id, transaction_type_id, invoice_id, payment_method_id,
            transaction_date, amount_excluding_tax, tax_amount, transaction_amount,
            outstanding_balance, finalization_date, last_edited_by, last_edited_when
        )
        SELECT 
            v_transaction_record.customer_id,
            (SELECT transaction_type_id FROM application.transaction_types WHERE transaction_type_name = 'Customer Payment Received'),
            NULL,
            v_payment_method_id,
            p_payment_date,
            0 - v_transaction_record.outstanding_balance,
            0,
            0 - v_transaction_record.outstanding_balance,
            0,
            p_payment_date,
            p_user_id,
            clock_timestamp();
        
        -- Update original transaction
        UPDATE sales.customer_transactions
        SET outstanding_balance = 0,
            finalization_date = p_payment_date,
            last_edited_by = p_user_id,
            last_edited_when = clock_timestamp()
        WHERE customer_transaction_id = v_transaction_record.customer_transaction_id;
    END LOOP;
END;
$$;

COMMENT ON PROCEDURE dataload_simulation.process_customer_payments(DATE, INTEGER) IS 
'Processes customer payments for outstanding invoices';

-- =============================================
-- DataLoadSimulation.CreatePurchaseOrders Procedure
-- Creates purchase orders to replenish stock
-- =============================================
CREATE OR REPLACE PROCEDURE dataload_simulation.create_purchase_orders(
    p_order_date DATE,
    p_user_id INTEGER
)
LANGUAGE plpgsql AS $$
DECLARE
    v_stock_item_record RECORD;
    v_purchase_order_id INTEGER;
    v_supplier_id INTEGER;
    v_contact_person_id INTEGER;
    v_delivery_method_id INTEGER;
BEGIN
    -- Find stock items that need replenishment
    FOR v_stock_item_record IN
        SELECT si.stock_item_id, si.supplier_id, si.unit_price, si.tax_rate,
               sih.quantity_on_hand, sih.reorder_level, sih.target_stock_level
        FROM warehouse.stock_items si
        INNER JOIN warehouse.stock_item_holdings sih ON si.stock_item_id = sih.stock_item_id
        WHERE sih.quantity_on_hand < sih.reorder_level
        LIMIT 10
    LOOP
        -- Get supplier details
        SELECT s.supplier_id, s.primary_contact_person_id, s.delivery_method_id
        INTO v_supplier_id, v_contact_person_id, v_delivery_method_id
        FROM purchasing.suppliers s
        WHERE s.supplier_id = v_stock_item_record.supplier_id;
        
        -- Get next purchase order ID
        v_purchase_order_id := nextval('sequences.purchase_order_id');
        
        -- Create purchase order
        INSERT INTO purchasing.purchase_orders (
            purchase_order_id, supplier_id, order_date, delivery_method_id,
            contact_person_id, expected_delivery_date, supplier_reference,
            is_order_finalized, comments, internal_comments,
            last_edited_by, last_edited_when
        )
        VALUES (
            v_purchase_order_id, v_supplier_id, p_order_date, v_delivery_method_id,
            v_contact_person_id, p_order_date + INTERVAL '7 days', 'PO-' || v_purchase_order_id::text,
            false, NULL, NULL,
            p_user_id, clock_timestamp()
        );
        
        -- Create purchase order line
        INSERT INTO purchasing.purchase_order_lines (
            purchase_order_id, stock_item_id, ordered_outers, description,
            received_outers, package_type_id, expected_unit_price_per_outer,
            last_receipt_date, is_order_line_finalized, last_edited_by, last_edited_when
        )
        SELECT 
            v_purchase_order_id, v_stock_item_record.stock_item_id,
            v_stock_item_record.target_stock_level - v_stock_item_record.quantity_on_hand,
            si.stock_item_name, 0, si.outer_package_id, si.unit_price,
            NULL, false, p_user_id, clock_timestamp()
        FROM warehouse.stock_items si
        WHERE si.stock_item_id = v_stock_item_record.stock_item_id;
    END LOOP;
END;
$$;

COMMENT ON PROCEDURE dataload_simulation.create_purchase_orders(DATE, INTEGER) IS 
'Creates purchase orders to replenish stock';

-- =============================================
-- DataLoadSimulation.ReceivePurchaseOrders Procedure
-- Receives purchase orders and updates stock
-- =============================================
CREATE OR REPLACE PROCEDURE dataload_simulation.receive_purchase_orders(
    p_receive_date DATE,
    p_user_id INTEGER
)
LANGUAGE plpgsql AS $$
DECLARE
    v_po_line_record RECORD;
BEGIN
    -- Process purchase order lines that are due
    FOR v_po_line_record IN
        SELECT pol.purchase_order_line_id, pol.purchase_order_id, pol.stock_item_id,
               pol.ordered_outers, pol.expected_unit_price_per_outer,
               po.supplier_id
        FROM purchasing.purchase_order_lines pol
        INNER JOIN purchasing.purchase_orders po ON pol.purchase_order_id = po.purchase_order_id
        WHERE pol.is_order_line_finalized = false
        AND po.expected_delivery_date <= p_receive_date
        LIMIT 50
    LOOP
        -- Update purchase order line
        UPDATE purchasing.purchase_order_lines
        SET received_outers = ordered_outers,
            last_receipt_date = p_receive_date,
            is_order_line_finalized = true,
            last_edited_by = p_user_id,
            last_edited_when = clock_timestamp()
        WHERE purchase_order_line_id = v_po_line_record.purchase_order_line_id;
        
        -- Update stock item holdings
        UPDATE warehouse.stock_item_holdings
        SET quantity_on_hand = quantity_on_hand + v_po_line_record.ordered_outers,
            last_cost_price = v_po_line_record.expected_unit_price_per_outer,
            last_edited_by = p_user_id,
            last_edited_when = clock_timestamp()
        WHERE stock_item_id = v_po_line_record.stock_item_id;
        
        -- Insert stock item transaction
        INSERT INTO warehouse.stock_item_transactions (
            stock_item_id, transaction_type_id, customer_id, invoice_id,
            supplier_id, purchase_order_id, transaction_occurred_when,
            quantity, last_edited_by, last_edited_when
        )
        SELECT 
            v_po_line_record.stock_item_id,
            (SELECT transaction_type_id FROM application.transaction_types WHERE transaction_type_name = 'Stock Receipt'),
            NULL, NULL,
            v_po_line_record.supplier_id, v_po_line_record.purchase_order_id,
            clock_timestamp(), v_po_line_record.ordered_outers,
            p_user_id, clock_timestamp();
        
        -- Insert supplier transaction
        INSERT INTO purchasing.supplier_transactions (
            supplier_id, transaction_type_id, purchase_order_id, payment_method_id,
            supplier_invoice_number, transaction_date, amount_excluding_tax,
            tax_amount, transaction_amount, outstanding_balance, finalization_date,
            last_edited_by, last_edited_when
        )
        SELECT 
            v_po_line_record.supplier_id,
            (SELECT transaction_type_id FROM application.transaction_types WHERE transaction_type_name = 'Supplier Invoice'),
            v_po_line_record.purchase_order_id, NULL,
            'SI-' || v_po_line_record.purchase_order_id::text, p_receive_date,
            v_po_line_record.ordered_outers * v_po_line_record.expected_unit_price_per_outer,
            v_po_line_record.ordered_outers * v_po_line_record.expected_unit_price_per_outer * 0.1,
            v_po_line_record.ordered_outers * v_po_line_record.expected_unit_price_per_outer * 1.1,
            v_po_line_record.ordered_outers * v_po_line_record.expected_unit_price_per_outer * 1.1,
            NULL, p_user_id, clock_timestamp();
    END LOOP;
    
    -- Finalize purchase orders where all lines are received
    UPDATE purchasing.purchase_orders po
    SET is_order_finalized = true,
        last_edited_by = p_user_id,
        last_edited_when = clock_timestamp()
    WHERE NOT EXISTS (
        SELECT 1 FROM purchasing.purchase_order_lines pol
        WHERE pol.purchase_order_id = po.purchase_order_id
        AND pol.is_order_line_finalized = false
    )
    AND po.is_order_finalized = false;
END;
$$;

COMMENT ON PROCEDURE dataload_simulation.receive_purchase_orders(DATE, INTEGER) IS 
'Receives purchase orders and updates stock';

-- =============================================
-- DataLoadSimulation.RecordColdRoomTemperatures Procedure
-- Records cold room temperature readings
-- =============================================
CREATE OR REPLACE PROCEDURE dataload_simulation.record_cold_room_temperatures(
    p_record_date DATE,
    p_user_id INTEGER
)
LANGUAGE plpgsql AS $$
DECLARE
    v_sensor_number INTEGER;
    v_temperature NUMERIC(10, 2);
    v_hour INTEGER;
BEGIN
    -- Record temperatures for each sensor throughout the day
    FOR v_sensor_number IN 1..4 LOOP
        FOR v_hour IN 0..23 LOOP
            -- Generate random temperature between 3.0 and 5.0 degrees
            v_temperature := dataload_simulation.get_random_decimal(3.0, 5.0);
            
            INSERT INTO warehouse.cold_room_temperatures (
                cold_room_sensor_number, recorded_when, temperature
            )
            VALUES (
                v_sensor_number,
                p_record_date + (v_hour || ' hours')::INTERVAL,
                v_temperature
            );
        END LOOP;
    END LOOP;
END;
$$;

COMMENT ON PROCEDURE dataload_simulation.record_cold_room_temperatures(DATE, INTEGER) IS 
'Records cold room temperature readings for simulation';

-- =============================================
-- DataLoadSimulation.PopulateDataToCurrentDate Procedure
-- Main procedure to populate data from start date to current date
-- =============================================
CREATE OR REPLACE PROCEDURE dataload_simulation.populate_data_to_current_date(
    p_start_date DATE DEFAULT '2013-01-01',
    p_end_date DATE DEFAULT CURRENT_DATE,
    p_user_id INTEGER DEFAULT 1
)
LANGUAGE plpgsql AS $$
DECLARE
    v_current_date DATE;
    v_day_of_week INTEGER;
    v_orders_to_create INTEGER;
    v_i INTEGER;
BEGIN
    -- Deactivate temporal tables for bulk load
    CALL dataload_simulation.deactivate_temporal_tables();
    
    v_current_date := p_start_date;
    
    WHILE v_current_date <= p_end_date LOOP
        -- Get day of week (0 = Sunday, 6 = Saturday)
        v_day_of_week := EXTRACT(DOW FROM v_current_date)::INTEGER;
        
        -- Determine number of orders based on day of week
        v_orders_to_create := CASE v_day_of_week
            WHEN 0 THEN 0  -- Sunday
            WHEN 6 THEN 30 -- Saturday
            ELSE 60        -- Weekday
        END;
        
        -- Create customer orders
        FOR v_i IN 1..v_orders_to_create LOOP
            CALL dataload_simulation.create_customer_order(v_current_date, p_user_id);
        END LOOP;
        
        -- Pick stock for orders
        CALL dataload_simulation.pick_stock_for_customer_orders(v_current_date, p_user_id);
        
        -- Invoice picked orders
        CALL dataload_simulation.invoice_picked_orders(v_current_date, p_user_id);
        
        -- Process customer payments
        CALL dataload_simulation.process_customer_payments(v_current_date, p_user_id);
        
        -- Create purchase orders for low stock
        IF v_day_of_week NOT IN (0, 6) THEN
            CALL dataload_simulation.create_purchase_orders(v_current_date, p_user_id);
        END IF;
        
        -- Receive purchase orders
        CALL dataload_simulation.receive_purchase_orders(v_current_date, p_user_id);
        
        -- Record cold room temperatures
        CALL dataload_simulation.record_cold_room_temperatures(v_current_date, p_user_id);
        
        -- Move to next day
        v_current_date := v_current_date + INTERVAL '1 day';
        
        -- Commit periodically to avoid long transactions
        IF EXTRACT(DAY FROM v_current_date) = 1 THEN
            RAISE NOTICE 'Processed data up to %', v_current_date;
        END IF;
    END LOOP;
    
    -- Reactivate temporal tables
    CALL dataload_simulation.reactivate_temporal_tables();
    
    RAISE NOTICE 'Data population completed from % to %', p_start_date, p_end_date;
END;
$$;

COMMENT ON PROCEDURE dataload_simulation.populate_data_to_current_date(DATE, DATE, INTEGER) IS 
'Main procedure to populate data from start date to end date for simulation';
