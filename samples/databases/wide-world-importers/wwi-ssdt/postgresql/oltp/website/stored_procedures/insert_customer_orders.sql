-- PostgreSQL equivalent of [Website].InsertCustomerOrders
-- Converted from T-SQL to PL/pgSQL
-- Uses composite types instead of table-valued parameters

-- First, create the composite types if they don't exist
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'order_list') THEN
        CREATE TYPE website.order_list AS (
            order_reference INTEGER,
            customer_id INTEGER,
            contact_person_id INTEGER,
            expected_delivery_date DATE,
            customer_purchase_order_number VARCHAR(20),
            is_undersupply_backordered BOOLEAN,
            comments TEXT,
            delivery_instructions TEXT
        );
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'order_line_list') THEN
        CREATE TYPE website.order_line_list AS (
            order_reference INTEGER,
            stock_item_id INTEGER,
            description VARCHAR(100),
            quantity INTEGER
        );
    END IF;
END $$;

CREATE OR REPLACE PROCEDURE website.insert_customer_orders(
    p_orders website.order_list[],
    p_order_lines website.order_line_list[],
    p_orders_created_by_person_id INTEGER,
    p_salesperson_person_id INTEGER
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_order RECORD;
    v_order_line RECORD;
    v_order_id INTEGER;
    v_orders_to_generate INTEGER[][] := ARRAY[]::INTEGER[][];
    v_order_ref INTEGER;
    v_new_order_id INTEGER;
BEGIN
    -- Create temporary table to store order reference to order ID mapping
    CREATE TEMP TABLE IF NOT EXISTS temp_orders_to_generate (
        order_reference INTEGER PRIMARY KEY,
        order_id INTEGER NOT NULL
    ) ON COMMIT DROP;
    
    TRUNCATE temp_orders_to_generate;
    
    -- Generate order IDs for each order
    FOR v_order IN SELECT * FROM unnest(p_orders)
    LOOP
        v_new_order_id := nextval('sequences.order_id');
        INSERT INTO temp_orders_to_generate (order_reference, order_id)
        VALUES (v_order.order_reference, v_new_order_id);
    END LOOP;
    
    BEGIN
        -- Insert orders
        INSERT INTO sales.orders (
            order_id, customer_id, salesperson_person_id, picked_by_person_id, 
            contact_person_id, backorder_order_id, order_date,
            expected_delivery_date, customer_purchase_order_number, 
            is_undersupply_backordered, comments, delivery_instructions, 
            internal_comments, picking_completed_when, last_edited_by, last_edited_when
        )
        SELECT 
            otg.order_id, o.customer_id, p_salesperson_person_id, NULL, 
            o.contact_person_id, NULL, NOW()::DATE,
            o.expected_delivery_date, o.customer_purchase_order_number, 
            o.is_undersupply_backordered, o.comments, o.delivery_instructions, 
            NULL, NULL, p_orders_created_by_person_id, NOW()
        FROM temp_orders_to_generate otg
        JOIN unnest(p_orders) o ON otg.order_reference = o.order_reference;
        
        -- Insert order lines
        INSERT INTO sales.order_lines (
            order_id, stock_item_id, description, package_type_id, quantity, 
            unit_price, tax_rate, picked_quantity, picking_completed_when, 
            last_edited_by, last_edited_when
        )
        SELECT 
            otg.order_id, ol.stock_item_id, ol.description, si.unit_package_id, ol.quantity,
            website.calculate_customer_price(o.customer_id, ol.stock_item_id, NOW()),
            si.tax_rate, 0, NULL, p_orders_created_by_person_id, NOW()
        FROM temp_orders_to_generate otg
        JOIN unnest(p_order_lines) ol ON otg.order_reference = ol.order_reference
        JOIN unnest(p_orders) o ON ol.order_reference = o.order_reference
        JOIN warehouse.stock_items si ON ol.stock_item_id = si.stock_item_id;
        
    EXCEPTION WHEN OTHERS THEN
        RAISE NOTICE 'Unable to create the customer orders.';
        RAISE;
    END;
END;
$$;

COMMENT ON PROCEDURE website.insert_customer_orders IS 'Inserts customer orders with order lines using composite type arrays';

-- Alternative version using JSONB for easier calling from applications
CREATE OR REPLACE PROCEDURE website.insert_customer_orders_json(
    p_orders JSONB,
    p_order_lines JSONB,
    p_orders_created_by_person_id INTEGER,
    p_salesperson_person_id INTEGER
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_order RECORD;
    v_new_order_id INTEGER;
BEGIN
    -- Create temporary table to store order reference to order ID mapping
    CREATE TEMP TABLE IF NOT EXISTS temp_orders_to_generate (
        order_reference INTEGER PRIMARY KEY,
        order_id INTEGER NOT NULL
    ) ON COMMIT DROP;
    
    TRUNCATE temp_orders_to_generate;
    
    -- Generate order IDs for each order
    FOR v_order IN 
        SELECT * FROM jsonb_to_recordset(p_orders) AS x(
            order_reference INTEGER,
            customer_id INTEGER,
            contact_person_id INTEGER,
            expected_delivery_date DATE,
            customer_purchase_order_number VARCHAR(20),
            is_undersupply_backordered BOOLEAN,
            comments TEXT,
            delivery_instructions TEXT
        )
    LOOP
        v_new_order_id := nextval('sequences.order_id');
        INSERT INTO temp_orders_to_generate (order_reference, order_id)
        VALUES (v_order.order_reference, v_new_order_id);
    END LOOP;
    
    BEGIN
        -- Insert orders
        INSERT INTO sales.orders (
            order_id, customer_id, salesperson_person_id, picked_by_person_id, 
            contact_person_id, backorder_order_id, order_date,
            expected_delivery_date, customer_purchase_order_number, 
            is_undersupply_backordered, comments, delivery_instructions, 
            internal_comments, picking_completed_when, last_edited_by, last_edited_when
        )
        SELECT 
            otg.order_id, o.customer_id, p_salesperson_person_id, NULL, 
            o.contact_person_id, NULL, NOW()::DATE,
            o.expected_delivery_date, o.customer_purchase_order_number, 
            o.is_undersupply_backordered, o.comments, o.delivery_instructions, 
            NULL, NULL, p_orders_created_by_person_id, NOW()
        FROM temp_orders_to_generate otg
        JOIN jsonb_to_recordset(p_orders) AS o(
            order_reference INTEGER,
            customer_id INTEGER,
            contact_person_id INTEGER,
            expected_delivery_date DATE,
            customer_purchase_order_number VARCHAR(20),
            is_undersupply_backordered BOOLEAN,
            comments TEXT,
            delivery_instructions TEXT
        ) ON otg.order_reference = o.order_reference;
        
        -- Insert order lines
        INSERT INTO sales.order_lines (
            order_id, stock_item_id, description, package_type_id, quantity, 
            unit_price, tax_rate, picked_quantity, picking_completed_when, 
            last_edited_by, last_edited_when
        )
        SELECT 
            otg.order_id, ol.stock_item_id, ol.description, si.unit_package_id, ol.quantity,
            website.calculate_customer_price(o.customer_id, ol.stock_item_id, NOW()),
            si.tax_rate, 0, NULL, p_orders_created_by_person_id, NOW()
        FROM temp_orders_to_generate otg
        JOIN jsonb_to_recordset(p_order_lines) AS ol(
            order_reference INTEGER,
            stock_item_id INTEGER,
            description VARCHAR(100),
            quantity INTEGER
        ) ON otg.order_reference = ol.order_reference
        JOIN jsonb_to_recordset(p_orders) AS o(
            order_reference INTEGER,
            customer_id INTEGER,
            contact_person_id INTEGER,
            expected_delivery_date DATE,
            customer_purchase_order_number VARCHAR(20),
            is_undersupply_backordered BOOLEAN,
            comments TEXT,
            delivery_instructions TEXT
        ) ON ol.order_reference = o.order_reference
        JOIN warehouse.stock_items si ON ol.stock_item_id = si.stock_item_id;
        
    EXCEPTION WHEN OTHERS THEN
        RAISE NOTICE 'Unable to create the customer orders.';
        RAISE;
    END;
END;
$$;

COMMENT ON PROCEDURE website.insert_customer_orders_json IS 'Inserts customer orders with order lines using JSONB input';
