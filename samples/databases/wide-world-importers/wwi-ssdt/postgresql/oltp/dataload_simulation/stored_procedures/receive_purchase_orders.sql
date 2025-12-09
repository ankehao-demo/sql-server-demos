-- PostgreSQL equivalent of [DataLoadSimulation].ReceivePurchaseOrders
-- Converted from T-SQL to PL/pgSQL
-- Uses PostgreSQL cursor instead of SQL Server cursor

CREATE OR REPLACE PROCEDURE dataload_simulation.receive_purchase_orders(
    p_current_date_time TIMESTAMP,
    p_starting_when TIMESTAMP,
    p_end_of_time TIMESTAMP,
    p_is_silent_mode BOOLEAN
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_staff_member_person_id INTEGER;
    v_purchase_order_id INTEGER;
    v_supplier_id INTEGER;
    v_total_excluding_tax DECIMAL(18,2);
    v_total_including_tax DECIMAL(18,2);
    v_stock_receipt_type_id INTEGER;
    v_supplier_invoice_type_id INTEGER;
    v_eft_payment_method_id INTEGER;
    purchase_order_cursor CURSOR FOR
        SELECT purchase_order_id, supplier_id
        FROM purchasing.purchase_orders po
        WHERE po.is_order_finalized = false
        AND po.expected_delivery_date >= p_starting_when::DATE;
BEGIN
    -- Get a random staff member
    SELECT person_id INTO v_staff_member_person_id
    FROM application.people
    WHERE is_employee = true
    ORDER BY RANDOM()
    LIMIT 1;
    
    -- Get transaction type IDs
    SELECT transaction_type_id INTO v_stock_receipt_type_id
    FROM application.transaction_types
    WHERE transaction_type_name = 'Stock Receipt';
    
    SELECT transaction_type_id INTO v_supplier_invoice_type_id
    FROM application.transaction_types
    WHERE transaction_type_name = 'Supplier Invoice';
    
    SELECT payment_method_id INTO v_eft_payment_method_id
    FROM application.payment_methods
    WHERE payment_method_name = 'EFT';
    
    -- Process each purchase order
    OPEN purchase_order_cursor;
    
    LOOP
        FETCH purchase_order_cursor INTO v_purchase_order_id, v_supplier_id;
        EXIT WHEN NOT FOUND;
        
        -- Update purchase order lines as received
        UPDATE purchasing.purchase_order_lines
        SET received_outers = ordered_outers,
            is_order_line_finalized = true,
            last_receipt_date = p_starting_when::DATE,
            last_edited_by = v_staff_member_person_id,
            last_edited_when = p_starting_when
        WHERE purchase_order_id = v_purchase_order_id;
        
        -- Update stock item holdings
        UPDATE warehouse.stock_item_holdings sih
        SET quantity_on_hand = sih.quantity_on_hand + (pol.received_outers * si.quantity_per_outer),
            last_edited_by = v_staff_member_person_id,
            last_edited_when = p_starting_when
        FROM purchasing.purchase_order_lines pol
        JOIN warehouse.stock_items si ON sih.stock_item_id = si.stock_item_id
        WHERE sih.stock_item_id = pol.stock_item_id
        AND pol.purchase_order_id = v_purchase_order_id;
        
        -- Insert stock item transactions
        INSERT INTO warehouse.stock_item_transactions (
            stock_item_id, transaction_type_id, customer_id, invoice_id, 
            supplier_id, purchase_order_id, transaction_occurred_when, 
            quantity, last_edited_by, last_edited_when
        )
        SELECT pol.stock_item_id, v_stock_receipt_type_id,
               NULL, NULL, v_supplier_id, pol.purchase_order_id,
               p_starting_when, pol.received_outers * si.quantity_per_outer, 
               v_staff_member_person_id, p_starting_when
        FROM purchasing.purchase_order_lines pol
        JOIN warehouse.stock_items si ON pol.stock_item_id = si.stock_item_id
        WHERE pol.purchase_order_id = v_purchase_order_id;
        
        -- Mark purchase order as finalized
        UPDATE purchasing.purchase_orders
        SET is_order_finalized = true,
            last_edited_by = v_staff_member_person_id,
            last_edited_when = p_starting_when
        WHERE purchase_order_id = v_purchase_order_id;
        
        -- Calculate totals
        SELECT SUM(ROUND(pol.ordered_outers * pol.expected_unit_price_per_outer, 2)),
               SUM(ROUND(pol.ordered_outers * pol.expected_unit_price_per_outer, 2))
               + SUM(ROUND(pol.ordered_outers * pol.expected_unit_price_per_outer * si.tax_rate / 100.0, 2))
        INTO v_total_excluding_tax, v_total_including_tax
        FROM purchasing.purchase_order_lines pol
        JOIN warehouse.stock_items si ON pol.stock_item_id = si.stock_item_id
        WHERE pol.purchase_order_id = v_purchase_order_id;
        
        -- Insert supplier transaction
        INSERT INTO purchasing.supplier_transactions (
            supplier_id, transaction_type_id, purchase_order_id, payment_method_id,
            supplier_invoice_number, transaction_date, amount_excluding_tax,
            tax_amount, transaction_amount, outstanding_balance,
            finalization_date, last_edited_by, last_edited_when
        )
        VALUES (
            v_supplier_id, v_supplier_invoice_type_id,
            v_purchase_order_id, v_eft_payment_method_id,
            CEIL(RANDOM() * 10000)::TEXT, p_starting_when::DATE, v_total_excluding_tax,
            v_total_including_tax - v_total_excluding_tax, v_total_including_tax, v_total_including_tax,
            NULL, v_staff_member_person_id, p_starting_when
        );
    END LOOP;
    
    CLOSE purchase_order_cursor;
END;
$$;

COMMENT ON PROCEDURE dataload_simulation.receive_purchase_orders IS 'Processes receipt of purchase orders for data simulation';
