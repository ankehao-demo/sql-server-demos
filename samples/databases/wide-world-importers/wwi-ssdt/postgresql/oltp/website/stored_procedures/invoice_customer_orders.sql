-- PostgreSQL equivalent of [Website].InvoiceCustomerOrders
-- Converted from T-SQL to PL/pgSQL

-- Create composite type for order ID list if not exists
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'order_id_list') THEN
        CREATE TYPE website.order_id_list AS (
            order_id INTEGER
        );
    END IF;
END $$;

CREATE OR REPLACE PROCEDURE website.invoice_customer_orders(
    p_orders_to_invoice INTEGER[],
    p_packed_by_person_id INTEGER,
    p_invoiced_by_person_id INTEGER
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_invoice_id INTEGER;
    v_order_id INTEGER;
    v_total_dry_items INTEGER;
    v_total_chiller_items INTEGER;
    v_stock_issue_type_id INTEGER;
    v_customer_invoice_type_id INTEGER;
BEGIN
    -- Create temporary table for invoices to generate
    CREATE TEMP TABLE IF NOT EXISTS temp_invoices_to_generate (
        order_id INTEGER PRIMARY KEY,
        invoice_id INTEGER NOT NULL,
        total_dry_items INTEGER NOT NULL,
        total_chiller_items INTEGER NOT NULL
    ) ON COMMIT DROP;
    
    TRUNCATE temp_invoices_to_generate;
    
    -- Get transaction type IDs
    SELECT transaction_type_id INTO v_stock_issue_type_id 
    FROM application.transaction_types 
    WHERE transaction_type_name = 'Stock Issue';
    
    SELECT transaction_type_id INTO v_customer_invoice_type_id 
    FROM application.transaction_types 
    WHERE transaction_type_name = 'Customer Invoice';
    
    BEGIN
        -- Check that all orders exist, have been fully picked, and not already invoiced
        -- Also allocate new invoice numbers
        INSERT INTO temp_invoices_to_generate (order_id, invoice_id, total_dry_items, total_chiller_items)
        SELECT 
            oti.order_id,
            nextval('sequences.invoice_id'),
            COALESCE((
                SELECT SUM(CASE WHEN si.is_chiller_stock THEN 0 ELSE 1 END)
                FROM sales.order_lines ol
                JOIN warehouse.stock_items si ON ol.stock_item_id = si.stock_item_id
                WHERE ol.order_id = oti.order_id
            ), 0),
            COALESCE((
                SELECT SUM(CASE WHEN si.is_chiller_stock THEN 1 ELSE 0 END)
                FROM sales.order_lines ol
                JOIN warehouse.stock_items si ON ol.stock_item_id = si.stock_item_id
                WHERE ol.order_id = oti.order_id
            ), 0)
        FROM unnest(p_orders_to_invoice) AS oti(order_id)
        JOIN sales.orders o ON oti.order_id = o.order_id
        WHERE NOT EXISTS (
            SELECT 1 FROM sales.invoices i WHERE i.order_id = oti.order_id
        )
        AND o.picking_completed_when IS NOT NULL;
        
        -- Check if any orders were not valid
        IF EXISTS (
            SELECT 1 FROM unnest(p_orders_to_invoice) AS oti(order_id)
            WHERE NOT EXISTS (
                SELECT 1 FROM temp_invoices_to_generate itg WHERE itg.order_id = oti.order_id
            )
        ) THEN
            RAISE NOTICE 'At least one order ID either does not exist, is not picked, or is already invoiced';
            RAISE EXCEPTION 'At least one orderID either does not exist, is not picked, or is already invoiced' 
                USING ERRCODE = '51000';
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
            NOW()::DATE, o.customer_purchase_order_number, false, NULL,
            NULL, c.delivery_address_line_1 || ', ' || c.delivery_address_line_2, NULL,
            itg.total_dry_items, itg.total_chiller_items, c.delivery_run, c.run_position,
            jsonb_build_object(
                'Events', jsonb_build_array(
                    jsonb_build_object(
                        'Event', 'Ready for collection',
                        'EventTime', to_char(NOW(), 'YYYY-MM-DD"T"HH24:MI:SS'),
                        'ConNote', 'EAN-125-' || (itg.invoice_id + 1050)::TEXT
                    )
                )
            ),
            p_invoiced_by_person_id, NOW()
        FROM temp_invoices_to_generate itg
        JOIN sales.orders o ON itg.order_id = o.order_id
        JOIN sales.customers c ON o.customer_id = c.customer_id
        JOIN sales.customers btc ON btc.customer_id = c.bill_to_customer_id;
        
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
            ROUND(ol.picked_quantity * ol.unit_price, 2)
                + ROUND(ol.picked_quantity * ol.unit_price * ol.tax_rate / 100.0, 2),
            p_invoiced_by_person_id, NOW()
        FROM temp_invoices_to_generate itg
        JOIN sales.order_lines ol ON itg.order_id = ol.order_id
        JOIN warehouse.stock_items si ON ol.stock_item_id = si.stock_item_id
        JOIN warehouse.stock_item_holdings sih ON si.stock_item_id = sih.stock_item_id
        ORDER BY ol.order_id, ol.order_line_id;
        
        -- Insert stock item transactions
        INSERT INTO warehouse.stock_item_transactions (
            stock_item_id, transaction_type_id, customer_id, invoice_id, supplier_id, purchase_order_id,
            transaction_occurred_when, quantity, last_edited_by, last_edited_when
        )
        SELECT 
            il.stock_item_id, v_stock_issue_type_id,
            i.customer_id, i.invoice_id, NULL, NULL,
            NOW(), 0 - il.quantity, p_invoiced_by_person_id, NOW()
        FROM temp_invoices_to_generate itg
        JOIN sales.invoice_lines il ON itg.invoice_id = il.invoice_id
        JOIN sales.invoices i ON il.invoice_id = i.invoice_id
        ORDER BY il.invoice_id, il.invoice_line_id;
        
        -- Update stock item holdings
        WITH stock_item_totals AS (
            SELECT il.stock_item_id, SUM(il.quantity) AS total_quantity
            FROM sales.invoice_lines il
            WHERE il.invoice_id IN (SELECT invoice_id FROM temp_invoices_to_generate)
            GROUP BY il.stock_item_id
        )
        UPDATE warehouse.stock_item_holdings sih
        SET quantity_on_hand = sih.quantity_on_hand - sit.total_quantity,
            last_edited_by = p_invoiced_by_person_id,
            last_edited_when = NOW()
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
            v_customer_invoice_type_id,
            itg.invoice_id,
            NULL,
            NOW()::DATE,
            (SELECT SUM(il.extended_price - il.tax_amount) FROM sales.invoice_lines il WHERE il.invoice_id = itg.invoice_id),
            (SELECT SUM(il.tax_amount) FROM sales.invoice_lines il WHERE il.invoice_id = itg.invoice_id),
            (SELECT SUM(il.extended_price) FROM sales.invoice_lines il WHERE il.invoice_id = itg.invoice_id),
            (SELECT SUM(il.extended_price) FROM sales.invoice_lines il WHERE il.invoice_id = itg.invoice_id),
            NULL,
            p_invoiced_by_person_id,
            NOW()
        FROM temp_invoices_to_generate itg
        JOIN sales.invoices i ON itg.invoice_id = i.invoice_id;
        
    EXCEPTION WHEN OTHERS THEN
        RAISE NOTICE 'Unable to invoice these orders';
        RAISE;
    END;
END;
$$;

COMMENT ON PROCEDURE website.invoice_customer_orders IS 'Creates invoices for picked orders';
