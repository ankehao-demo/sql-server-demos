-- Wide World Importers PostgreSQL Migration
-- Script 008: Create Stored Procedures (converted to PostgreSQL functions)
-- Migrated from SQL Server to PostgreSQL using PL/pgSQL

-- Note: SQL Server stored procedures are converted to PostgreSQL functions
-- Key differences:
-- - SQL Server PROCEDURE -> PostgreSQL FUNCTION
-- - SQL Server EXECUTE AS OWNER -> PostgreSQL SECURITY DEFINER
-- - SQL Server SET NOCOUNT ON -> Not needed in PostgreSQL
-- - SQL Server XACT_ABORT -> Use EXCEPTION handling
-- - SQL Server table-valued parameters -> PostgreSQL arrays or temp tables
-- - SQL Server SYSDATETIME() -> PostgreSQL CURRENT_TIMESTAMP
-- - SQL Server FOR JSON AUTO -> PostgreSQL json_agg/json_build_object

-- Create custom types for table-valued parameters
CREATE TYPE website.order_item AS (
    order_reference INTEGER,
    customer_id INTEGER,
    contact_person_id INTEGER,
    expected_delivery_date DATE,
    customer_purchase_order_number VARCHAR(20),
    is_undersupply_backordered BOOLEAN,
    comments TEXT,
    delivery_instructions TEXT
);

CREATE TYPE website.order_line_item AS (
    order_reference INTEGER,
    stock_item_id INTEGER,
    description VARCHAR(100),
    quantity INTEGER
);

CREATE TYPE website.order_id_item AS (
    order_id INTEGER
);

CREATE TYPE website.sensor_data_item AS (
    sensor_data_list_id INTEGER,
    cold_room_sensor_number INTEGER,
    recorded_when TIMESTAMP(6),
    temperature NUMERIC(10, 2)
);

-- Function: Calculate Customer Price
-- Calculates the price for a customer based on special deals
CREATE OR REPLACE FUNCTION website.calculate_customer_price(
    p_customer_id INTEGER,
    p_stock_item_id INTEGER,
    p_pricing_date DATE
)
RETURNS NUMERIC(18, 2)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_calculated_price NUMERIC(18, 2);
    v_unit_price NUMERIC(18, 2);
    v_lowest_unit_price NUMERIC(18, 2);
    v_highest_discount_amount NUMERIC(18, 2);
    v_highest_discount_percentage NUMERIC(18, 3);
    v_buying_group_id INTEGER;
    v_customer_category_id INTEGER;
BEGIN
    -- Get customer details
    SELECT buying_group_id, customer_category_id
    INTO v_buying_group_id, v_customer_category_id
    FROM sales.customers
    WHERE customer_id = p_customer_id;

    -- Get base unit price
    SELECT unit_price INTO v_unit_price
    FROM warehouse.stock_items
    WHERE stock_item_id = p_stock_item_id;

    v_calculated_price := v_unit_price;

    -- Check for special deals with unit price override
    SELECT MIN(sd.unit_price) INTO v_lowest_unit_price
    FROM sales.special_deals sd
    WHERE sd.unit_price IS NOT NULL
      AND p_pricing_date BETWEEN sd.start_date AND sd.end_date
      AND (sd.stock_item_id IS NULL OR sd.stock_item_id = p_stock_item_id)
      AND (sd.customer_id IS NULL OR sd.customer_id = p_customer_id)
      AND (sd.buying_group_id IS NULL OR sd.buying_group_id = v_buying_group_id)
      AND (sd.customer_category_id IS NULL OR sd.customer_category_id = v_customer_category_id);

    IF v_lowest_unit_price IS NOT NULL AND v_lowest_unit_price < v_calculated_price THEN
        v_calculated_price := v_lowest_unit_price;
    END IF;

    -- Check for discount amount deals
    SELECT MAX(sd.discount_amount) INTO v_highest_discount_amount
    FROM sales.special_deals sd
    WHERE sd.discount_amount IS NOT NULL
      AND p_pricing_date BETWEEN sd.start_date AND sd.end_date
      AND (sd.stock_item_id IS NULL OR sd.stock_item_id = p_stock_item_id)
      AND (sd.customer_id IS NULL OR sd.customer_id = p_customer_id)
      AND (sd.buying_group_id IS NULL OR sd.buying_group_id = v_buying_group_id)
      AND (sd.customer_category_id IS NULL OR sd.customer_category_id = v_customer_category_id);

    IF v_highest_discount_amount IS NOT NULL THEN
        v_calculated_price := v_calculated_price - v_highest_discount_amount;
    END IF;

    -- Check for discount percentage deals
    SELECT MAX(sd.discount_percentage) INTO v_highest_discount_percentage
    FROM sales.special_deals sd
    WHERE sd.discount_percentage IS NOT NULL
      AND p_pricing_date BETWEEN sd.start_date AND sd.end_date
      AND (sd.stock_item_id IS NULL OR sd.stock_item_id = p_stock_item_id)
      AND (sd.customer_id IS NULL OR sd.customer_id = p_customer_id)
      AND (sd.buying_group_id IS NULL OR sd.buying_group_id = v_buying_group_id)
      AND (sd.customer_category_id IS NULL OR sd.customer_category_id = v_customer_category_id);

    IF v_highest_discount_percentage IS NOT NULL THEN
        v_calculated_price := v_calculated_price * (1 - v_highest_discount_percentage / 100);
    END IF;

    -- Ensure price is not negative
    IF v_calculated_price < 0 THEN
        v_calculated_price := 0;
    END IF;

    RETURN ROUND(v_calculated_price, 2);
END;
$$;

-- Function: Search For Customers
-- Returns customer search results as JSON
CREATE OR REPLACE FUNCTION website.search_for_customers(
    p_search_text VARCHAR(1000),
    p_maximum_rows_to_return INTEGER
)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_result JSON;
BEGIN
    SELECT json_build_object('Customers', json_agg(customer_data))
    INTO v_result
    FROM (
        SELECT 
            c.customer_id AS "CustomerID",
            c.customer_name AS "CustomerName",
            ct.city_name AS "CityName",
            c.phone_number AS "PhoneNumber",
            c.fax_number AS "FaxNumber",
            p.full_name AS "PrimaryContactFullName",
            p.preferred_name AS "PrimaryContactPreferredName"
        FROM sales.customers AS c
        INNER JOIN application.cities AS ct ON c.delivery_city_id = ct.city_id
        LEFT OUTER JOIN application.people AS p ON c.primary_contact_person_id = p.person_id
        WHERE (c.customer_name || ' ' || COALESCE(p.full_name, '') || ' ' || COALESCE(p.preferred_name, '')) 
              ILIKE '%' || p_search_text || '%'
        ORDER BY c.customer_name
        LIMIT p_maximum_rows_to_return
    ) AS customer_data;

    RETURN COALESCE(v_result, '{"Customers": []}');
END;
$$;

-- Function: Search For People
-- Returns people search results as JSON
CREATE OR REPLACE FUNCTION website.search_for_people(
    p_search_text VARCHAR(1000),
    p_maximum_rows_to_return INTEGER
)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_result JSON;
BEGIN
    SELECT json_build_object('People', json_agg(people_data))
    INTO v_result
    FROM (
        SELECT 
            p.person_id AS "PersonID",
            p.full_name AS "FullName",
            p.preferred_name AS "PreferredName",
            p.is_permitted_to_logon AS "IsPermittedToLogon",
            p.logon_name AS "LogonName",
            p.is_external_logon_provider AS "IsExternalLogonProvider",
            p.is_system_user AS "IsSystemUser",
            p.is_employee AS "IsEmployee",
            p.is_salesperson AS "IsSalesperson",
            p.phone_number AS "PhoneNumber",
            p.fax_number AS "FaxNumber",
            p.email_address AS "EmailAddress"
        FROM application.people AS p
        WHERE p.search_name ILIKE '%' || p_search_text || '%'
        ORDER BY p.full_name
        LIMIT p_maximum_rows_to_return
    ) AS people_data;

    RETURN COALESCE(v_result, '{"People": []}');
END;
$$;

-- Function: Search For Stock Items
-- Returns stock item search results as JSON
CREATE OR REPLACE FUNCTION website.search_for_stock_items(
    p_search_text VARCHAR(1000),
    p_maximum_rows_to_return INTEGER
)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_result JSON;
BEGIN
    SELECT json_build_object('StockItems', json_agg(stock_data))
    INTO v_result
    FROM (
        SELECT 
            si.stock_item_id AS "StockItemID",
            si.stock_item_name AS "StockItemName"
        FROM warehouse.stock_items AS si
        WHERE si.search_details ILIKE '%' || p_search_text || '%'
        ORDER BY si.stock_item_name
        LIMIT p_maximum_rows_to_return
    ) AS stock_data;

    RETURN COALESCE(v_result, '{"StockItems": []}');
END;
$$;

-- Function: Search For Stock Items By Tags
-- Returns stock items matching JSON tags
CREATE OR REPLACE FUNCTION website.search_for_stock_items_by_tags(
    p_search_tag VARCHAR(100)
)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_result JSON;
BEGIN
    SELECT json_build_object('StockItems', json_agg(stock_data))
    INTO v_result
    FROM (
        SELECT 
            si.stock_item_id AS "StockItemID",
            si.stock_item_name AS "StockItemName"
        FROM warehouse.stock_items AS si
        WHERE si.custom_fields IS NOT NULL
          AND si.custom_fields->'Tags' @> to_jsonb(p_search_tag)
        ORDER BY si.stock_item_name
    ) AS stock_data;

    RETURN COALESCE(v_result, '{"StockItems": []}');
END;
$$;

-- Function: Search For Suppliers
-- Returns supplier search results as JSON
CREATE OR REPLACE FUNCTION website.search_for_suppliers(
    p_search_text VARCHAR(1000),
    p_maximum_rows_to_return INTEGER
)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_result JSON;
BEGIN
    SELECT json_build_object('Suppliers', json_agg(supplier_data))
    INTO v_result
    FROM (
        SELECT 
            s.supplier_id AS "SupplierID",
            s.supplier_name AS "SupplierName",
            sc.supplier_category_name AS "SupplierCategoryName",
            pp.full_name AS "PrimaryContactFullName",
            pp.preferred_name AS "PrimaryContactPreferredName",
            s.phone_number AS "PhoneNumber",
            s.fax_number AS "FaxNumber"
        FROM purchasing.suppliers AS s
        INNER JOIN purchasing.supplier_categories AS sc ON s.supplier_category_id = sc.supplier_category_id
        LEFT OUTER JOIN application.people AS pp ON s.primary_contact_person_id = pp.person_id
        WHERE (s.supplier_name || ' ' || COALESCE(pp.full_name, '') || ' ' || COALESCE(pp.preferred_name, '')) 
              ILIKE '%' || p_search_text || '%'
        ORDER BY s.supplier_name
        LIMIT p_maximum_rows_to_return
    ) AS supplier_data;

    RETURN COALESCE(v_result, '{"Suppliers": []}');
END;
$$;

-- Function: Record Cold Room Temperatures
-- Records temperature sensor readings using upsert logic
CREATE OR REPLACE FUNCTION website.record_cold_room_temperatures(
    p_sensor_readings website.sensor_data_item[]
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_reading website.sensor_data_item;
BEGIN
    FOREACH v_reading IN ARRAY p_sensor_readings
    LOOP
        -- Use INSERT ... ON CONFLICT for upsert behavior
        INSERT INTO warehouse.cold_room_temperatures 
            (cold_room_sensor_number, recorded_when, temperature)
        VALUES 
            (v_reading.cold_room_sensor_number, v_reading.recorded_when, v_reading.temperature)
        ON CONFLICT (cold_room_sensor_number) 
        DO UPDATE SET 
            recorded_when = EXCLUDED.recorded_when,
            temperature = EXCLUDED.temperature;
    END LOOP;
EXCEPTION
    WHEN OTHERS THEN
        RAISE EXCEPTION 'Unable to apply the sensor data: %', SQLERRM;
END;
$$;

-- Function: Record Vehicle Temperature
-- Records a single vehicle temperature reading
CREATE OR REPLACE FUNCTION website.record_vehicle_temperature(
    p_vehicle_registration VARCHAR(20),
    p_chiller_sensor_number INTEGER,
    p_recorded_when TIMESTAMP(6),
    p_temperature NUMERIC(10, 2),
    p_full_sensor_data TEXT DEFAULT NULL
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    INSERT INTO warehouse.vehicle_temperatures
        (vehicle_registration, chiller_sensor_number, recorded_when, temperature, full_sensor_data)
    VALUES
        (p_vehicle_registration, p_chiller_sensor_number, p_recorded_when, p_temperature, p_full_sensor_data);
EXCEPTION
    WHEN OTHERS THEN
        RAISE EXCEPTION 'Unable to record vehicle temperature: %', SQLERRM;
END;
$$;

-- Function: Activate Website Logon
-- Activates a website logon for a person
CREATE OR REPLACE FUNCTION website.activate_website_logon(
    p_person_id INTEGER,
    p_logon_name VARCHAR(256),
    p_initial_password VARCHAR(256)
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_hashed_password BYTEA;
BEGIN
    -- Hash the password using pgcrypto (requires extension)
    -- Note: In production, use a proper password hashing library
    v_hashed_password := digest(p_initial_password, 'sha256');

    UPDATE application.people
    SET is_permitted_to_logon = TRUE,
        logon_name = p_logon_name,
        hashed_password = v_hashed_password,
        is_external_logon_provider = FALSE
    WHERE person_id = p_person_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Person with ID % not found', p_person_id;
    END IF;
END;
$$;

-- Function: Change Password
-- Changes a user's password
CREATE OR REPLACE FUNCTION website.change_password(
    p_person_id INTEGER,
    p_old_password VARCHAR(256),
    p_new_password VARCHAR(256)
)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_current_hash BYTEA;
    v_old_hash BYTEA;
    v_new_hash BYTEA;
BEGIN
    -- Get current password hash
    SELECT hashed_password INTO v_current_hash
    FROM application.people
    WHERE person_id = p_person_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Person with ID % not found', p_person_id;
    END IF;

    -- Hash the old password for comparison
    v_old_hash := digest(p_old_password, 'sha256');

    -- Verify old password
    IF v_current_hash IS NULL OR v_current_hash != v_old_hash THEN
        RETURN FALSE;
    END IF;

    -- Hash and set new password
    v_new_hash := digest(p_new_password, 'sha256');

    UPDATE application.people
    SET hashed_password = v_new_hash
    WHERE person_id = p_person_id;

    RETURN TRUE;
END;
$$;

-- Function: Insert Customer Orders
-- Inserts new customer orders with order lines
CREATE OR REPLACE FUNCTION website.insert_customer_orders(
    p_orders website.order_item[],
    p_order_lines website.order_line_item[],
    p_orders_created_by_person_id INTEGER,
    p_salesperson_person_id INTEGER
)
RETURNS INTEGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_order website.order_item;
    v_order_line website.order_line_item;
    v_order_id INTEGER;
    v_orders_map JSONB := '{}';
BEGIN
    -- Process each order
    FOREACH v_order IN ARRAY p_orders
    LOOP
        -- Get next order ID
        v_order_id := nextval('sales.order_id_seq');
        
        -- Store mapping of order_reference to order_id
        v_orders_map := v_orders_map || jsonb_build_object(v_order.order_reference::TEXT, v_order_id);

        -- Insert the order
        INSERT INTO sales.orders
            (order_id, customer_id, salesperson_person_id, picked_by_person_id, contact_person_id,
             backorder_order_id, order_date, expected_delivery_date, customer_purchase_order_number,
             is_undersupply_backordered, comments, delivery_instructions, internal_comments,
             picking_completed_when, last_edited_by, last_edited_when)
        VALUES
            (v_order_id, v_order.customer_id, p_salesperson_person_id, NULL, v_order.contact_person_id,
             NULL, CURRENT_DATE, v_order.expected_delivery_date, v_order.customer_purchase_order_number,
             v_order.is_undersupply_backordered, v_order.comments, v_order.delivery_instructions, NULL,
             NULL, p_orders_created_by_person_id, CURRENT_TIMESTAMP);
    END LOOP;

    -- Process each order line
    FOREACH v_order_line IN ARRAY p_order_lines
    LOOP
        v_order_id := (v_orders_map->>v_order_line.order_reference::TEXT)::INTEGER;

        INSERT INTO sales.order_lines
            (order_id, stock_item_id, description, package_type_id, quantity, unit_price,
             tax_rate, picked_quantity, picking_completed_when, last_edited_by, last_edited_when)
        SELECT 
            v_order_id,
            v_order_line.stock_item_id,
            v_order_line.description,
            si.unit_package_id,
            v_order_line.quantity,
            website.calculate_customer_price(
                (SELECT customer_id FROM sales.orders WHERE order_id = v_order_id),
                v_order_line.stock_item_id,
                CURRENT_DATE
            ),
            si.tax_rate,
            0,
            NULL,
            p_orders_created_by_person_id,
            CURRENT_TIMESTAMP
        FROM warehouse.stock_items si
        WHERE si.stock_item_id = v_order_line.stock_item_id;
    END LOOP;

    RETURN 0;
EXCEPTION
    WHEN OTHERS THEN
        RAISE EXCEPTION 'Unable to create the customer orders: %', SQLERRM;
END;
$$;

-- Function: Invoice Customer Orders
-- Creates invoices for picked orders
CREATE OR REPLACE FUNCTION website.invoice_customer_orders(
    p_orders_to_invoice INTEGER[],
    p_packed_by_person_id INTEGER,
    p_invoiced_by_person_id INTEGER
)
RETURNS INTEGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_order_id INTEGER;
    v_invoice_id INTEGER;
    v_total_dry_items INTEGER;
    v_total_chiller_items INTEGER;
    v_stock_issue_type_id INTEGER;
    v_customer_invoice_type_id INTEGER;
BEGIN
    -- Get transaction type IDs
    SELECT transaction_type_id INTO v_stock_issue_type_id
    FROM application.transaction_types
    WHERE transaction_type_name = 'Stock Issue';

    SELECT transaction_type_id INTO v_customer_invoice_type_id
    FROM application.transaction_types
    WHERE transaction_type_name = 'Customer Invoice';

    -- Process each order
    FOREACH v_order_id IN ARRAY p_orders_to_invoice
    LOOP
        -- Check if order exists, is picked, and not already invoiced
        IF NOT EXISTS (
            SELECT 1 FROM sales.orders o
            WHERE o.order_id = v_order_id
              AND o.picking_completed_when IS NOT NULL
              AND NOT EXISTS (SELECT 1 FROM sales.invoices i WHERE i.order_id = v_order_id)
        ) THEN
            RAISE EXCEPTION 'Order % either does not exist, is not picked, or is already invoiced', v_order_id;
        END IF;

        -- Calculate totals
        SELECT 
            COALESCE(SUM(CASE WHEN NOT si.is_chiller_stock THEN 1 ELSE 0 END), 0),
            COALESCE(SUM(CASE WHEN si.is_chiller_stock THEN 1 ELSE 0 END), 0)
        INTO v_total_dry_items, v_total_chiller_items
        FROM sales.order_lines ol
        INNER JOIN warehouse.stock_items si ON ol.stock_item_id = si.stock_item_id
        WHERE ol.order_id = v_order_id;

        -- Get next invoice ID
        v_invoice_id := nextval('sales.invoice_id_seq');

        -- Create invoice
        INSERT INTO sales.invoices
            (invoice_id, customer_id, bill_to_customer_id, order_id, delivery_method_id,
             contact_person_id, accounts_person_id, salesperson_person_id, packed_by_person_id,
             invoice_date, customer_purchase_order_number, is_credit_note, credit_note_reason,
             comments, delivery_instructions, internal_comments, total_dry_items, total_chiller_items,
             delivery_run, run_position, returned_delivery_data, last_edited_by, last_edited_when)
        SELECT 
            v_invoice_id, c.customer_id, c.bill_to_customer_id, v_order_id, c.delivery_method_id,
            o.contact_person_id, btc.primary_contact_person_id, o.salesperson_person_id, p_packed_by_person_id,
            CURRENT_DATE, o.customer_purchase_order_number, FALSE, NULL,
            NULL, c.delivery_address_line_1 || ', ' || COALESCE(c.delivery_address_line_2, ''), NULL,
            v_total_dry_items, v_total_chiller_items, c.delivery_run, c.run_position,
            jsonb_build_object('Events', jsonb_build_array(
                jsonb_build_object(
                    'Event', 'Ready for collection',
                    'EventTime', to_char(CURRENT_TIMESTAMP, 'YYYY-MM-DD"T"HH24:MI:SS'),
                    'ConNote', 'EAN-125-' || (v_invoice_id + 1050)::TEXT
                )
            ))::TEXT,
            p_invoiced_by_person_id, CURRENT_TIMESTAMP
        FROM sales.orders o
        INNER JOIN sales.customers c ON o.customer_id = c.customer_id
        INNER JOIN sales.customers btc ON btc.customer_id = c.bill_to_customer_id
        WHERE o.order_id = v_order_id;

        -- Create invoice lines
        INSERT INTO sales.invoice_lines
            (invoice_id, stock_item_id, description, package_type_id, quantity, unit_price,
             tax_rate, tax_amount, line_profit, extended_price, last_edited_by, last_edited_when)
        SELECT 
            v_invoice_id, ol.stock_item_id, ol.description, ol.package_type_id,
            ol.picked_quantity, ol.unit_price, ol.tax_rate,
            ROUND(ol.picked_quantity * ol.unit_price * ol.tax_rate / 100.0, 2),
            ROUND(ol.picked_quantity * (ol.unit_price - sih.last_cost_price), 2),
            ROUND(ol.picked_quantity * ol.unit_price, 2) + ROUND(ol.picked_quantity * ol.unit_price * ol.tax_rate / 100.0, 2),
            p_invoiced_by_person_id, CURRENT_TIMESTAMP
        FROM sales.order_lines ol
        INNER JOIN warehouse.stock_items si ON ol.stock_item_id = si.stock_item_id
        INNER JOIN warehouse.stock_item_holdings sih ON si.stock_item_id = sih.stock_item_id
        WHERE ol.order_id = v_order_id
        ORDER BY ol.order_line_id;

        -- Create stock item transactions
        INSERT INTO warehouse.stock_item_transactions
            (stock_item_id, transaction_type_id, customer_id, invoice_id, supplier_id,
             purchase_order_id, transaction_occurred_when, quantity, last_edited_by, last_edited_when)
        SELECT 
            il.stock_item_id, v_stock_issue_type_id, i.customer_id, i.invoice_id, NULL,
            NULL, CURRENT_TIMESTAMP, -il.quantity, p_invoiced_by_person_id, CURRENT_TIMESTAMP
        FROM sales.invoice_lines il
        INNER JOIN sales.invoices i ON il.invoice_id = i.invoice_id
        WHERE il.invoice_id = v_invoice_id
        ORDER BY il.invoice_line_id;

        -- Update stock item holdings
        UPDATE warehouse.stock_item_holdings sih
        SET quantity_on_hand = sih.quantity_on_hand - il.quantity,
            last_edited_by = p_invoiced_by_person_id,
            last_edited_when = CURRENT_TIMESTAMP
        FROM sales.invoice_lines il
        WHERE il.invoice_id = v_invoice_id
          AND sih.stock_item_id = il.stock_item_id;

        -- Create customer transaction
        INSERT INTO sales.customer_transactions
            (customer_id, transaction_type_id, invoice_id, payment_method_id,
             transaction_date, amount_excluding_tax, tax_amount, transaction_amount,
             outstanding_balance, finalization_date, last_edited_by, last_edited_when)
        SELECT 
            i.bill_to_customer_id, v_customer_invoice_type_id, v_invoice_id, NULL,
            CURRENT_DATE,
            (SELECT SUM(il2.extended_price - il2.tax_amount) FROM sales.invoice_lines il2 WHERE il2.invoice_id = v_invoice_id),
            (SELECT SUM(il2.tax_amount) FROM sales.invoice_lines il2 WHERE il2.invoice_id = v_invoice_id),
            (SELECT SUM(il2.extended_price) FROM sales.invoice_lines il2 WHERE il2.invoice_id = v_invoice_id),
            (SELECT SUM(il2.extended_price) FROM sales.invoice_lines il2 WHERE il2.invoice_id = v_invoice_id),
            NULL, p_invoiced_by_person_id, CURRENT_TIMESTAMP
        FROM sales.invoices i
        WHERE i.invoice_id = v_invoice_id;
    END LOOP;

    RETURN 0;
EXCEPTION
    WHEN OTHERS THEN
        RAISE EXCEPTION 'Unable to invoice these orders: %', SQLERRM;
END;
$$;

-- Add comments for documentation
COMMENT ON FUNCTION website.calculate_customer_price IS 'Calculates the selling price for a customer based on special deals';
COMMENT ON FUNCTION website.search_for_customers IS 'Searches for customers by name and returns JSON results';
COMMENT ON FUNCTION website.search_for_people IS 'Searches for people by name and returns JSON results';
COMMENT ON FUNCTION website.search_for_stock_items IS 'Searches for stock items by name/description and returns JSON results';
COMMENT ON FUNCTION website.search_for_stock_items_by_tags IS 'Searches for stock items by JSON tags and returns JSON results';
COMMENT ON FUNCTION website.search_for_suppliers IS 'Searches for suppliers by name and returns JSON results';
COMMENT ON FUNCTION website.record_cold_room_temperatures IS 'Records cold room temperature sensor readings';
COMMENT ON FUNCTION website.record_vehicle_temperature IS 'Records a vehicle temperature reading';
COMMENT ON FUNCTION website.activate_website_logon IS 'Activates website logon for a person';
COMMENT ON FUNCTION website.change_password IS 'Changes a user password after verifying the old password';
COMMENT ON FUNCTION website.insert_customer_orders IS 'Inserts new customer orders with order lines';
COMMENT ON FUNCTION website.invoice_customer_orders IS 'Creates invoices for picked customer orders';
