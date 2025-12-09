-- Wide World Importers PostgreSQL Migration
-- Phase 3: OLTP Code Migration
-- Script 002: Website Stored Procedures
-- Migrated from SQL Server T-SQL to PostgreSQL PL/pgSQL

-- =============================================
-- Custom Types for Procedure Parameters
-- (Replacing SQL Server Table-Valued Parameters)
-- =============================================

-- Type for order ID list
CREATE TYPE website.order_id_list AS (
    order_id INTEGER
);

-- Type for order list
CREATE TYPE website.order_list AS (
    order_id INTEGER,
    customer_id INTEGER,
    contact_person_id INTEGER,
    expected_delivery_date DATE,
    customer_purchase_order_number VARCHAR(20),
    is_undersupply_backordered BOOLEAN,
    comments TEXT,
    delivery_instructions TEXT
);

-- Type for order line list
CREATE TYPE website.order_line_list AS (
    order_id INTEGER,
    stock_item_id INTEGER,
    description VARCHAR(100),
    quantity INTEGER
);

-- Type for sensor data list
CREATE TYPE website.sensor_data_list AS (
    sensor_data_list_id INTEGER,
    cold_room_sensor_number INTEGER,
    recorded_when TIMESTAMP,
    temperature NUMERIC(10, 2)
);

-- =============================================
-- Website.InvoiceCustomerOrders Procedure
-- Creates invoices for picked customer orders
-- =============================================
CREATE OR REPLACE PROCEDURE website.invoice_customer_orders(
    p_orders_to_invoice INTEGER[],
    p_packed_by_person_id INTEGER,
    p_invoiced_by_person_id INTEGER
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_order_id INTEGER;
    v_invoice_id INTEGER;
    v_total_dry_items INTEGER;
    v_total_chiller_items INTEGER;
    v_customer_id INTEGER;
    v_bill_to_customer_id INTEGER;
    v_delivery_method_id INTEGER;
    v_contact_person_id INTEGER;
    v_accounts_person_id INTEGER;
    v_salesperson_person_id INTEGER;
    v_customer_purchase_order_number VARCHAR(20);
    v_delivery_address_line_1 VARCHAR(60);
    v_delivery_address_line_2 VARCHAR(60);
    v_delivery_run VARCHAR(5);
    v_run_position VARCHAR(5);
    v_returned_delivery_data TEXT;
BEGIN
    -- Create temporary table for invoices to generate
    CREATE TEMP TABLE IF NOT EXISTS invoices_to_generate (
        order_id INTEGER PRIMARY KEY,
        invoice_id INTEGER NOT NULL,
        total_dry_items INTEGER NOT NULL,
        total_chiller_items INTEGER NOT NULL
    ) ON COMMIT DROP;
    
    -- Check that all orders exist, have been fully picked, and not already invoiced
    -- Also allocate new invoice numbers
    FOREACH v_order_id IN ARRAY p_orders_to_invoice
    LOOP
        -- Check if order exists, is picked, and not already invoiced
        IF EXISTS (
            SELECT 1 FROM sales.orders o
            WHERE o.order_id = v_order_id
            AND o.picking_completed_when IS NOT NULL
            AND NOT EXISTS (SELECT 1 FROM sales.invoices i WHERE i.order_id = v_order_id)
        ) THEN
            -- Get next invoice ID
            v_invoice_id := nextval('sequences.invoice_id');
            
            -- Calculate dry and chiller items
            SELECT 
                COALESCE(SUM(CASE WHEN si.is_chiller_stock THEN 0 ELSE 1 END), 0),
                COALESCE(SUM(CASE WHEN si.is_chiller_stock THEN 1 ELSE 0 END), 0)
            INTO v_total_dry_items, v_total_chiller_items
            FROM sales.order_lines ol
            INNER JOIN warehouse.stock_items si ON ol.stock_item_id = si.stock_item_id
            WHERE ol.order_id = v_order_id;
            
            INSERT INTO invoices_to_generate (order_id, invoice_id, total_dry_items, total_chiller_items)
            VALUES (v_order_id, v_invoice_id, v_total_dry_items, v_total_chiller_items);
        END IF;
    END LOOP;
    
    -- Check if any orders were not valid
    IF (SELECT COUNT(*) FROM unnest(p_orders_to_invoice) AS oid WHERE NOT EXISTS (SELECT 1 FROM invoices_to_generate itg WHERE itg.order_id = oid)) > 0 THEN
        RAISE EXCEPTION 'At least one order ID either does not exist, is not picked, or is already invoiced';
    END IF;
    
    -- Insert invoices
    INSERT INTO sales.invoices (
        invoice_id, customer_id, bill_to_customer_id, order_id, delivery_method_id,
        contact_person_id, accounts_person_id, salesperson_person_id, packed_by_person_id,
        invoice_date, customer_purchase_order_number, is_credit_note, credit_note_reason,
        comments, delivery_instructions, internal_comments, total_dry_items, total_chiller_items,
        delivery_run, run_position, returned_delivery_data, last_edited_by, last_edited_when
    )
    SELECT 
        itg.invoice_id, c.customer_id, c.bill_to_customer_id, itg.order_id, c.delivery_method_id,
        o.contact_person_id, btc.primary_contact_person_id, o.salesperson_person_id, p_packed_by_person_id,
        CURRENT_DATE, o.customer_purchase_order_number, false, NULL,
        NULL, c.delivery_address_line_1 || ', ' || COALESCE(c.delivery_address_line_2, ''), NULL,
        itg.total_dry_items, itg.total_chiller_items, c.delivery_run, c.run_position,
        jsonb_build_object(
            'Events', jsonb_build_array(
                jsonb_build_object(
                    'Event', 'Ready for collection',
                    'EventTime', to_char(clock_timestamp(), 'YYYY-MM-DD"T"HH24:MI:SS'),
                    'ConNote', 'EAN-125-' || (itg.invoice_id + 1050)::text
                )
            )
        )::text,
        p_invoiced_by_person_id, clock_timestamp()
    FROM invoices_to_generate itg
    INNER JOIN sales.orders o ON itg.order_id = o.order_id
    INNER JOIN sales.customers c ON o.customer_id = c.customer_id
    INNER JOIN sales.customers btc ON btc.customer_id = c.bill_to_customer_id;
    
    -- Insert invoice lines
    INSERT INTO sales.invoice_lines (
        invoice_id, stock_item_id, description, package_type_id,
        quantity, unit_price, tax_rate, tax_amount, line_profit, extended_price,
        last_edited_by, last_edited_when
    )
    SELECT 
        itg.invoice_id, ol.stock_item_id, ol.description, ol.package_type_id,
        ol.picked_quantity, ol.unit_price, ol.tax_rate,
        ROUND(ol.picked_quantity * ol.unit_price * ol.tax_rate / 100.0, 2),
        ROUND(ol.picked_quantity * (ol.unit_price - sih.last_cost_price), 2),
        ROUND(ol.picked_quantity * ol.unit_price, 2) + ROUND(ol.picked_quantity * ol.unit_price * ol.tax_rate / 100.0, 2),
        p_invoiced_by_person_id, clock_timestamp()
    FROM invoices_to_generate itg
    INNER JOIN sales.order_lines ol ON itg.order_id = ol.order_id
    INNER JOIN warehouse.stock_items si ON ol.stock_item_id = si.stock_item_id
    INNER JOIN warehouse.stock_item_holdings sih ON si.stock_item_id = sih.stock_item_id
    ORDER BY ol.order_id, ol.order_line_id;
    
    -- Insert stock item transactions
    INSERT INTO warehouse.stock_item_transactions (
        stock_item_id, transaction_type_id, customer_id, invoice_id, supplier_id, purchase_order_id,
        transaction_occurred_when, quantity, last_edited_by, last_edited_when
    )
    SELECT 
        il.stock_item_id, 
        (SELECT transaction_type_id FROM application.transaction_types WHERE transaction_type_name = 'Stock Issue'),
        i.customer_id, i.invoice_id, NULL, NULL,
        clock_timestamp(), 0 - il.quantity, p_invoiced_by_person_id, clock_timestamp()
    FROM invoices_to_generate itg
    INNER JOIN sales.invoice_lines il ON itg.invoice_id = il.invoice_id
    INNER JOIN sales.invoices i ON il.invoice_id = i.invoice_id
    ORDER BY il.invoice_id, il.invoice_line_id;
    
    -- Update stock item holdings
    WITH stock_item_totals AS (
        SELECT il.stock_item_id, SUM(il.quantity) AS total_quantity
        FROM sales.invoice_lines il
        WHERE il.invoice_id IN (SELECT invoice_id FROM invoices_to_generate)
        GROUP BY il.stock_item_id
    )
    UPDATE warehouse.stock_item_holdings sih
    SET quantity_on_hand = sih.quantity_on_hand - sit.total_quantity,
        last_edited_by = p_invoiced_by_person_id,
        last_edited_when = clock_timestamp()
    FROM stock_item_totals sit
    WHERE sih.stock_item_id = sit.stock_item_id;
    
    -- Insert customer transactions
    INSERT INTO sales.customer_transactions (
        customer_id, transaction_type_id, invoice_id, payment_method_id,
        transaction_date, amount_excluding_tax, tax_amount, transaction_amount,
        outstanding_balance, finalization_date, last_edited_by, last_edited_when
    )
    SELECT 
        i.bill_to_customer_id,
        (SELECT transaction_type_id FROM application.transaction_types WHERE transaction_type_name = 'Customer Invoice'),
        itg.invoice_id,
        NULL,
        CURRENT_DATE,
        (SELECT SUM(il.extended_price - il.tax_amount) FROM sales.invoice_lines il WHERE il.invoice_id = itg.invoice_id),
        (SELECT SUM(il.tax_amount) FROM sales.invoice_lines il WHERE il.invoice_id = itg.invoice_id),
        (SELECT SUM(il.extended_price) FROM sales.invoice_lines il WHERE il.invoice_id = itg.invoice_id),
        (SELECT SUM(il.extended_price) FROM sales.invoice_lines il WHERE il.invoice_id = itg.invoice_id),
        NULL,
        p_invoiced_by_person_id,
        clock_timestamp()
    FROM invoices_to_generate itg
    INNER JOIN sales.invoices i ON itg.invoice_id = i.invoice_id;
    
    -- Clean up
    DROP TABLE IF EXISTS invoices_to_generate;
    
EXCEPTION
    WHEN OTHERS THEN
        DROP TABLE IF EXISTS invoices_to_generate;
        RAISE EXCEPTION 'Unable to invoice these orders: %', SQLERRM;
END;
$$;

COMMENT ON PROCEDURE website.invoice_customer_orders(INTEGER[], INTEGER, INTEGER) IS 
'Creates invoices for picked customer orders';

-- =============================================
-- Website.InsertCustomerOrders Procedure
-- Inserts new customer orders
-- =============================================
CREATE OR REPLACE PROCEDURE website.insert_customer_orders(
    p_orders website.order_list[],
    p_order_lines website.order_line_list[],
    p_user_id INTEGER
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_order website.order_list;
    v_order_line website.order_line_list;
    v_new_order_id INTEGER;
BEGIN
    -- Process each order
    FOREACH v_order IN ARRAY p_orders
    LOOP
        -- Get next order ID
        v_new_order_id := nextval('sequences.order_id');
        
        -- Insert the order
        INSERT INTO sales.orders (
            order_id, customer_id, salesperson_person_id, picked_by_person_id,
            contact_person_id, backorder_order_id, order_date, expected_delivery_date,
            customer_purchase_order_number, is_undersupply_backordered, comments,
            delivery_instructions, internal_comments, picking_completed_when,
            last_edited_by, last_edited_when
        )
        VALUES (
            v_new_order_id, v_order.customer_id, p_user_id, NULL,
            v_order.contact_person_id, NULL, CURRENT_DATE, v_order.expected_delivery_date,
            v_order.customer_purchase_order_number, v_order.is_undersupply_backordered,
            v_order.comments, v_order.delivery_instructions, NULL, NULL,
            p_user_id, clock_timestamp()
        );
        
        -- Insert order lines for this order
        FOREACH v_order_line IN ARRAY p_order_lines
        LOOP
            IF v_order_line.order_id = v_order.order_id THEN
                INSERT INTO sales.order_lines (
                    order_id, stock_item_id, description, package_type_id,
                    quantity, unit_price, tax_rate, picked_quantity, picking_completed_when,
                    last_edited_by, last_edited_when
                )
                SELECT 
                    v_new_order_id, v_order_line.stock_item_id, v_order_line.description,
                    si.unit_package_id, v_order_line.quantity,
                    website.calculate_customer_price(v_order.customer_id, v_order_line.stock_item_id, CURRENT_DATE),
                    si.tax_rate, 0, NULL, p_user_id, clock_timestamp()
                FROM warehouse.stock_items si
                WHERE si.stock_item_id = v_order_line.stock_item_id;
            END IF;
        END LOOP;
    END LOOP;
END;
$$;

COMMENT ON PROCEDURE website.insert_customer_orders(website.order_list[], website.order_line_list[], INTEGER) IS 
'Inserts new customer orders with their order lines';

-- =============================================
-- Website.SearchForPeople Procedure
-- Searches for people by name
-- =============================================
CREATE OR REPLACE FUNCTION website.search_for_people(
    p_search_text VARCHAR(1000),
    p_max_rows_to_return INTEGER DEFAULT 10
)
RETURNS TABLE (
    person_id INTEGER,
    full_name VARCHAR(50),
    preferred_name VARCHAR(50),
    is_permitted_to_logon BOOLEAN,
    logon_name VARCHAR(256),
    is_employee BOOLEAN,
    is_salesperson BOOLEAN,
    phone_number VARCHAR(20),
    fax_number VARCHAR(20),
    email_address VARCHAR(256)
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        p.person_id,
        p.full_name,
        p.preferred_name,
        p.is_permitted_to_logon,
        p.logon_name,
        p.is_employee,
        p.is_salesperson,
        p.phone_number,
        p.fax_number,
        p.email_address
    FROM application.people p
    WHERE p.search_name ILIKE '%' || p_search_text || '%'
       OR p.full_name ILIKE '%' || p_search_text || '%'
       OR p.preferred_name ILIKE '%' || p_search_text || '%'
    ORDER BY p.full_name
    LIMIT p_max_rows_to_return;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION website.search_for_people(VARCHAR, INTEGER) IS 
'Searches for people by name using pattern matching';

-- =============================================
-- Website.SearchForSuppliers Procedure
-- Searches for suppliers by name
-- =============================================
CREATE OR REPLACE FUNCTION website.search_for_suppliers(
    p_search_text VARCHAR(1000),
    p_max_rows_to_return INTEGER DEFAULT 10
)
RETURNS TABLE (
    supplier_id INTEGER,
    supplier_name VARCHAR(100),
    supplier_category_name VARCHAR(50),
    primary_contact VARCHAR(50),
    phone_number VARCHAR(20),
    fax_number VARCHAR(20),
    website_url VARCHAR(256)
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        s.supplier_id,
        s.supplier_name,
        sc.supplier_category_name,
        p.full_name AS primary_contact,
        s.phone_number,
        s.fax_number,
        s.website_url
    FROM purchasing.suppliers s
    INNER JOIN purchasing.supplier_categories sc ON s.supplier_category_id = sc.supplier_category_id
    INNER JOIN application.people p ON s.primary_contact_person_id = p.person_id
    WHERE s.supplier_name ILIKE '%' || p_search_text || '%'
    ORDER BY s.supplier_name
    LIMIT p_max_rows_to_return;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION website.search_for_suppliers(VARCHAR, INTEGER) IS 
'Searches for suppliers by name using pattern matching';

-- =============================================
-- Website.SearchForCustomers Procedure
-- Searches for customers by name
-- =============================================
CREATE OR REPLACE FUNCTION website.search_for_customers(
    p_search_text VARCHAR(1000),
    p_max_rows_to_return INTEGER DEFAULT 10
)
RETURNS TABLE (
    customer_id INTEGER,
    customer_name VARCHAR(100),
    customer_category_name VARCHAR(50),
    primary_contact VARCHAR(50),
    phone_number VARCHAR(20),
    fax_number VARCHAR(20),
    website_url VARCHAR(256),
    delivery_city VARCHAR(50)
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        c.customer_id,
        c.customer_name,
        cc.customer_category_name,
        p.full_name AS primary_contact,
        c.phone_number,
        c.fax_number,
        c.website_url,
        ct.city_name AS delivery_city
    FROM sales.customers c
    INNER JOIN sales.customer_categories cc ON c.customer_category_id = cc.customer_category_id
    INNER JOIN application.people p ON c.primary_contact_person_id = p.person_id
    INNER JOIN application.cities ct ON c.delivery_city_id = ct.city_id
    WHERE c.customer_name ILIKE '%' || p_search_text || '%'
    ORDER BY c.customer_name
    LIMIT p_max_rows_to_return;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION website.search_for_customers(VARCHAR, INTEGER) IS 
'Searches for customers by name using pattern matching';

-- =============================================
-- Website.SearchForStockItems Procedure
-- Searches for stock items by name
-- =============================================
CREATE OR REPLACE FUNCTION website.search_for_stock_items(
    p_search_text VARCHAR(1000),
    p_max_rows_to_return INTEGER DEFAULT 10
)
RETURNS TABLE (
    stock_item_id INTEGER,
    stock_item_name VARCHAR(100),
    supplier_name VARCHAR(100),
    color_name VARCHAR(20),
    brand VARCHAR(50),
    size VARCHAR(20),
    unit_price NUMERIC(18, 2),
    recommended_retail_price NUMERIC(18, 2),
    quantity_on_hand INTEGER
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        si.stock_item_id,
        si.stock_item_name,
        s.supplier_name,
        c.color_name,
        si.brand,
        si.size,
        si.unit_price,
        si.recommended_retail_price,
        sih.quantity_on_hand
    FROM warehouse.stock_items si
    INNER JOIN purchasing.suppliers s ON si.supplier_id = s.supplier_id
    LEFT JOIN warehouse.colors c ON si.color_id = c.color_id
    INNER JOIN warehouse.stock_item_holdings sih ON si.stock_item_id = sih.stock_item_id
    WHERE si.stock_item_name ILIKE '%' || p_search_text || '%'
       OR si.search_details ILIKE '%' || p_search_text || '%'
    ORDER BY si.stock_item_name
    LIMIT p_max_rows_to_return;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION website.search_for_stock_items(VARCHAR, INTEGER) IS 
'Searches for stock items by name using pattern matching';

-- =============================================
-- Website.SearchForStockItemsByTags Procedure
-- Searches for stock items by tags
-- =============================================
CREATE OR REPLACE FUNCTION website.search_for_stock_items_by_tags(
    p_search_tag VARCHAR(100),
    p_max_rows_to_return INTEGER DEFAULT 10
)
RETURNS TABLE (
    stock_item_id INTEGER,
    stock_item_name VARCHAR(100),
    supplier_name VARCHAR(100),
    color_name VARCHAR(20),
    brand VARCHAR(50),
    size VARCHAR(20),
    unit_price NUMERIC(18, 2),
    recommended_retail_price NUMERIC(18, 2),
    quantity_on_hand INTEGER
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        si.stock_item_id,
        si.stock_item_name,
        s.supplier_name,
        c.color_name,
        si.brand,
        si.size,
        si.unit_price,
        si.recommended_retail_price,
        sih.quantity_on_hand
    FROM warehouse.stock_items si
    INNER JOIN purchasing.suppliers s ON si.supplier_id = s.supplier_id
    LEFT JOIN warehouse.colors c ON si.color_id = c.color_id
    INNER JOIN warehouse.stock_item_holdings sih ON si.stock_item_id = sih.stock_item_id
    WHERE si.tags @> jsonb_build_array(p_search_tag)
       OR si.tags::text ILIKE '%' || p_search_tag || '%'
    ORDER BY si.stock_item_name
    LIMIT p_max_rows_to_return;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION website.search_for_stock_items_by_tags(VARCHAR, INTEGER) IS 
'Searches for stock items by tags using JSON containment';

-- =============================================
-- Website.RecordVehicleTemperature Procedure
-- Records vehicle temperature readings
-- =============================================
CREATE OR REPLACE PROCEDURE website.record_vehicle_temperature(
    p_vehicle_registration VARCHAR(20),
    p_chiller_sensor_number INTEGER,
    p_recorded_when TIMESTAMP,
    p_temperature NUMERIC(10, 2),
    p_full_sensor_data VARCHAR(1000) DEFAULT NULL,
    p_is_compressed BOOLEAN DEFAULT FALSE,
    p_compressed_sensor_data BYTEA DEFAULT NULL
)
LANGUAGE plpgsql AS $$
BEGIN
    INSERT INTO warehouse.vehicle_temperatures (
        vehicle_registration, chiller_sensor_number, recorded_when, temperature,
        full_sensor_data, is_compressed, compressed_sensor_data
    )
    VALUES (
        p_vehicle_registration, p_chiller_sensor_number, p_recorded_when, p_temperature,
        p_full_sensor_data, p_is_compressed, p_compressed_sensor_data
    );
END;
$$;

COMMENT ON PROCEDURE website.record_vehicle_temperature(VARCHAR, INTEGER, TIMESTAMP, NUMERIC, VARCHAR, BOOLEAN, BYTEA) IS 
'Records a vehicle temperature reading';

-- =============================================
-- Website.RecordColdRoomTemperatures Procedure
-- Records cold room temperature readings
-- =============================================
CREATE OR REPLACE PROCEDURE website.record_cold_room_temperatures(
    p_sensor_readings website.sensor_data_list[]
)
LANGUAGE plpgsql AS $$
DECLARE
    v_reading website.sensor_data_list;
BEGIN
    FOREACH v_reading IN ARRAY p_sensor_readings
    LOOP
        INSERT INTO warehouse.cold_room_temperatures (
            cold_room_sensor_number, recorded_when, temperature
        )
        VALUES (
            v_reading.cold_room_sensor_number, v_reading.recorded_when, v_reading.temperature
        );
    END LOOP;
END;
$$;

COMMENT ON PROCEDURE website.record_cold_room_temperatures(website.sensor_data_list[]) IS 
'Records multiple cold room temperature readings';

-- =============================================
-- Website.ActivateWebsiteLogon Procedure
-- Activates website logon for a person
-- =============================================
CREATE OR REPLACE PROCEDURE website.activate_website_logon(
    p_person_id INTEGER,
    p_logon_name VARCHAR(256),
    p_initial_password VARCHAR(256)
)
LANGUAGE plpgsql AS $$
DECLARE
    v_hashed_password BYTEA;
BEGIN
    -- Hash the password using SHA-256
    v_hashed_password := digest(p_initial_password, 'sha256');
    
    -- Update the person record
    UPDATE application.people
    SET is_permitted_to_logon = true,
        logon_name = p_logon_name,
        hashed_password = v_hashed_password,
        last_edited_by = p_person_id
    WHERE person_id = p_person_id;
    
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Person with ID % not found', p_person_id;
    END IF;
END;
$$;

COMMENT ON PROCEDURE website.activate_website_logon(INTEGER, VARCHAR, VARCHAR) IS 
'Activates website logon for a person with initial password';

-- =============================================
-- Website.ChangePassword Procedure
-- Changes password for a person
-- =============================================
CREATE OR REPLACE PROCEDURE website.change_password(
    p_person_id INTEGER,
    p_old_password VARCHAR(256),
    p_new_password VARCHAR(256)
)
LANGUAGE plpgsql AS $$
DECLARE
    v_current_hashed_password BYTEA;
    v_old_hashed_password BYTEA;
    v_new_hashed_password BYTEA;
BEGIN
    -- Get current hashed password
    SELECT hashed_password INTO v_current_hashed_password
    FROM application.people
    WHERE person_id = p_person_id;
    
    IF v_current_hashed_password IS NULL THEN
        RAISE EXCEPTION 'Person with ID % not found or has no password set', p_person_id;
    END IF;
    
    -- Hash the old password
    v_old_hashed_password := digest(p_old_password, 'sha256');
    
    -- Verify old password
    IF v_current_hashed_password != v_old_hashed_password THEN
        RAISE EXCEPTION 'Current password is incorrect';
    END IF;
    
    -- Hash the new password
    v_new_hashed_password := digest(p_new_password, 'sha256');
    
    -- Update the password
    UPDATE application.people
    SET hashed_password = v_new_hashed_password,
        last_edited_by = p_person_id
    WHERE person_id = p_person_id;
END;
$$;

COMMENT ON PROCEDURE website.change_password(INTEGER, VARCHAR, VARCHAR) IS 
'Changes password for a person after verifying the old password';
