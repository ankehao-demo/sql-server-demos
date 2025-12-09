-- PostgreSQL equivalent of [DataLoadSimulation].PaySuppliers
-- Converted from T-SQL to PL/pgSQL

CREATE OR REPLACE PROCEDURE dataload_simulation.pay_suppliers(
    p_current_date_time TIMESTAMP,
    p_starting_when TIMESTAMP,
    p_end_of_time TIMESTAMP,
    p_is_silent_mode BOOLEAN
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_staff_member_person_id INTEGER;
    v_supplier_payment_type_id INTEGER;
    v_eft_payment_method_id INTEGER;
    v_supplier_id INTEGER;
    v_outstanding_balance DECIMAL(18,2);
BEGIN
    -- Get a random staff member
    SELECT person_id INTO v_staff_member_person_id
    FROM application.people
    WHERE is_employee = true
    ORDER BY RANDOM()
    LIMIT 1;
    
    -- Get transaction type ID for supplier payment
    SELECT transaction_type_id INTO v_supplier_payment_type_id
    FROM application.transaction_types
    WHERE transaction_type_name = 'Supplier Payment Issued';
    
    -- Get EFT payment method ID
    SELECT payment_method_id INTO v_eft_payment_method_id
    FROM application.payment_methods
    WHERE payment_method_name = 'EFT';
    
    -- Process payments for suppliers with outstanding balances
    FOR v_supplier_id, v_outstanding_balance IN
        SELECT supplier_id, SUM(outstanding_balance) AS total_outstanding
        FROM purchasing.supplier_transactions
        WHERE outstanding_balance > 0
        AND finalization_date IS NULL
        GROUP BY supplier_id
        HAVING SUM(outstanding_balance) > 0
    LOOP
        -- Insert payment transaction
        INSERT INTO purchasing.supplier_transactions (
            supplier_id, transaction_type_id, purchase_order_id, payment_method_id,
            supplier_invoice_number, transaction_date, amount_excluding_tax,
            tax_amount, transaction_amount, outstanding_balance,
            finalization_date, last_edited_by, last_edited_when
        )
        VALUES (
            v_supplier_id, v_supplier_payment_type_id, NULL, v_eft_payment_method_id,
            NULL, p_current_date_time::DATE, 0 - v_outstanding_balance,
            0, 0 - v_outstanding_balance, 0,
            p_current_date_time::DATE, v_staff_member_person_id, p_starting_when
        );
        
        -- Update outstanding balances to zero
        UPDATE purchasing.supplier_transactions
        SET outstanding_balance = 0,
            finalization_date = p_current_date_time::DATE,
            last_edited_by = v_staff_member_person_id,
            last_edited_when = p_starting_when
        WHERE supplier_id = v_supplier_id
        AND outstanding_balance > 0
        AND finalization_date IS NULL;
    END LOOP;
END;
$$;

COMMENT ON PROCEDURE dataload_simulation.pay_suppliers IS 'Simulates payment of supplier invoices';
