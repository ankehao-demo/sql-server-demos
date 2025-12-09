-- PostgreSQL equivalent of [DataLoadSimulation].InvoicePickedOrders
-- Converted from T-SQL to PL/pgSQL

CREATE OR REPLACE PROCEDURE dataload_simulation.invoice_picked_orders(
    p_current_date_time TIMESTAMP,
    p_starting_when TIMESTAMP,
    p_end_of_time TIMESTAMP,
    p_is_silent_mode BOOLEAN
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_invoicer_person_id INTEGER;
    v_packer_person_id INTEGER;
    v_order_id INTEGER;
    v_invoice_id INTEGER;
    v_customer_id INTEGER;
    v_bill_to_customer_id INTEGER;
    v_delivery_method_id INTEGER;
    v_contact_person_id INTEGER;
    v_salesperson_person_id INTEGER;
    v_customer_purchase_order_number VARCHAR(20);
    v_delivery_address_line_1 VARCHAR(60);
    v_delivery_address_line_2 VARCHAR(60);
    v_delivery_run VARCHAR(5);
    v_run_position VARCHAR(5);
    v_total_dry_items INTEGER;
    v_total_chiller_items INTEGER;
    v_stock_issue_type_id INTEGER;
    v_customer_invoice_type_id INTEGER;
    order_cursor CURSOR FOR
        SELECT o.order_id, o.customer_id, o.contact_person_id, 
               o.salesperson_person_id, o.customer_purchase_order_number
        FROM sales.orders o
        WHERE o.picking_completed_when IS NOT NULL
        AND NOT EXISTS (
            SELECT 1 FROM sales.invoices i WHERE i.order_id = o.order_id
        );
BEGIN
    -- Get random staff members
    SELECT person_id INTO v_invoicer_person_id
    FROM application.people
    WHERE is_employee = true
    ORDER BY RANDOM()
    LIMIT 1;
    
    SELECT person_id INTO v_packer_person_id
    FROM application.people
    WHERE is_employee = true
    ORDER BY RANDOM()
    LIMIT 1;
    
    -- Get transaction type IDs
    SELECT transaction_type_id INTO v_stock_issue_type_id
    FROM application.transaction_types
    WHERE transaction_type_name = 'Stock Issue';
    
    SELECT transaction_type_id INTO v_customer_invoice_type_id
    FROM application.transaction_types
    WHERE transaction_type_name = 'Customer Invoice';
    
    -- Process each picked order
    OPEN order_cursor;
    
    LOOP
        FETCH order_cursor INTO v_order_id, v_customer_id, v_contact_person_id,
              v_salesperson_person_id, v_customer_purchase_order_number;
        EXIT WHEN NOT FOUND;
        
        -- Get customer details
        SELECT c.bill_to_customer_id, c.delivery_method_id,
               c.delivery_address_line_1, c.delivery_address_line_2,
               c.delivery_run, c.run_position
        INTO v_bill_to_customer_id, v_delivery_method_id,
             v_delivery_address_line_1, v_delivery_address_line_2,
             v_delivery_run, v_run_position
        FROM sales.customers c
        WHERE c.customer_id = v_customer_id;
        
        -- Calculate item counts
        SELECT COALESCE(SUM(CASE WHEN si.is_chiller_stock THEN 0 ELSE 1 END), 0),
               COALESCE(SUM(CASE WHEN si.is_chiller_stock THEN 1 ELSE 0 END), 0)
        INTO v_total_dry_items, v_total_chiller_items
        FROM sales.order_lines ol
        JOIN warehouse.stock_items si ON ol.stock_item_id = si.stock_item_id
        WHERE ol.order_id = v_order_id;
        
        -- Get next invoice ID
        v_invoice_id := nextval('sequences.invoice_id');
        
        -- Insert invoice
        INSERT INTO sales.invoices (
            invoice_id, customer_id, bill_to_customer_id, order_id, delivery_method_id,
            contact_person_id, accounts_person_id, salesperson_person_id, packed_by_person_id,
            invoice_date, customer_purchase_order_number, is_credit_note, credit_note_reason,
            comments, delivery_instructions, internal_comments, total_dry_items, total_chiller_items,
            delivery_run, run_position, returned_delivery_data, last_edited_by, last_edited_when
        )
        SELECT v_invoice_id, v_customer_id, v_bill_to_customer_id, v_order_id, v_delivery_method_id,
               v_contact_person_id, btc.primary_contact_person_id, v_salesperson_person_id, v_packer_person_id,
               p_current_date_time::DATE, v_customer_purchase_order_number, false, NULL,
               NULL, COALESCE(v_delivery_address_line_1, '') || ', ' || COALESCE(v_delivery_address_line_2, ''), 
               NULL, v_total_dry_items, v_total_chiller_items,
               v_delivery_run, v_run_position,
               jsonb_build_object('Events', jsonb_build_array(
                   jsonb_build_object(
                       'Event', 'Ready for collection',
                       'EventTime', to_char(p_starting_when, 'YYYY-MM-DD"T"HH24:MI:SS'),
                       'ConNote', 'EAN-125-' || (v_invoice_id + 1050)::TEXT
                   )
               )),
               v_invoicer_person_id, p_starting_when
        FROM sales.customers btc
        WHERE btc.customer_id = v_bill_to_customer_id;
        
        -- Insert invoice lines
        INSERT INTO sales.invoice_lines (
            invoice_id, stock_item_id, description, package_type_id,
            quantity, unit_price, tax_rate, tax_amount, line_profit, extended_price,
            last_edited_by, last_edited_when
        )
        SELECT v_invoice_id, ol.stock_item_id, ol.description, ol.package_type_id,
               ol.picked_quantity, ol.unit_price, ol.tax_rate,
               ROUND(ol.picked_quantity * ol.unit_price * ol.tax_rate / 100.0, 2),
               ROUND(ol.picked_quantity * (ol.unit_price - sih.last_cost_price), 2),
               ROUND(ol.picked_quantity * ol.unit_price, 2)
                   + ROUND(ol.picked_quantity * ol.unit_price * ol.tax_rate / 100.0, 2),
               v_invoicer_person_id, p_starting_when
        FROM sales.order_lines ol
        JOIN warehouse.stock_items si ON ol.stock_item_id = si.stock_item_id
        JOIN warehouse.stock_item_holdings sih ON si.stock_item_id = sih.stock_item_id
        WHERE ol.order_id = v_order_id
        ORDER BY ol.order_line_id;
        
        -- Insert stock item transactions
        INSERT INTO warehouse.stock_item_transactions (
            stock_item_id, transaction_type_id, customer_id, invoice_id, 
            supplier_id, purchase_order_id, transaction_occurred_when, 
            quantity, last_edited_by, last_edited_when
        )
        SELECT il.stock_item_id, v_stock_issue_type_id,
               v_customer_id, v_invoice_id, NULL, NULL,
               p_starting_when, 0 - il.quantity, v_invoicer_person_id, p_starting_when
        FROM sales.invoice_lines il
        WHERE il.invoice_id = v_invoice_id
        ORDER BY il.invoice_line_id;
        
        -- Update stock item holdings
        UPDATE warehouse.stock_item_holdings sih
        SET quantity_on_hand = sih.quantity_on_hand - il.quantity,
            last_edited_by = v_invoicer_person_id,
            last_edited_when = p_starting_when
        FROM sales.invoice_lines il
        WHERE sih.stock_item_id = il.stock_item_id
        AND il.invoice_id = v_invoice_id;
        
        -- Insert customer transaction
        INSERT INTO sales.customer_transactions (
            customer_id, transaction_type_id, invoice_id, payment_method_id,
            transaction_date, amount_excluding_tax, tax_amount, transaction_amount,
            outstanding_balance, finalization_date, last_edited_by, last_edited_when
        )
        SELECT v_bill_to_customer_id, v_customer_invoice_type_id, v_invoice_id, NULL,
               p_current_date_time::DATE,
               SUM(il.extended_price - il.tax_amount),
               SUM(il.tax_amount),
               SUM(il.extended_price),
               SUM(il.extended_price),
               NULL, v_invoicer_person_id, p_starting_when
        FROM sales.invoice_lines il
        WHERE il.invoice_id = v_invoice_id;
    END LOOP;
    
    CLOSE order_cursor;
END;
$$;

COMMENT ON PROCEDURE dataload_simulation.invoice_picked_orders IS 'Creates invoices for picked orders during data simulation';
