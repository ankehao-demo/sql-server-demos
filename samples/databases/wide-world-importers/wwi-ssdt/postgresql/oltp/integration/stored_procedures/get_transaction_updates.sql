-- PostgreSQL equivalent of [Integration].GetTransactionUpdates
-- Converted from T-SQL to PL/pgSQL

CREATE OR REPLACE FUNCTION integration.get_transaction_updates(
    p_last_cutoff TIMESTAMP,
    p_new_cutoff TIMESTAMP
)
RETURNS TABLE (
    wwi_customer_transaction_id INTEGER,
    wwi_customer_id INTEGER,
    wwi_bill_to_customer_id INTEGER,
    wwi_supplier_transaction_id INTEGER,
    wwi_supplier_id INTEGER,
    wwi_transaction_type_id INTEGER,
    wwi_payment_method_id INTEGER,
    wwi_invoice_id INTEGER,
    wwi_purchase_order_id INTEGER,
    supplier_invoice_number VARCHAR(20),
    total_excluding_tax DECIMAL(18,2),
    tax_amount DECIMAL(18,2),
    total_including_tax DECIMAL(18,2),
    outstanding_balance DECIMAL(18,2),
    is_finalized BOOLEAN,
    transaction_date DATE,
    last_modified_when TIMESTAMP
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    -- Return customer transactions
    RETURN QUERY
    SELECT ct.customer_transaction_id,
           ct.customer_id,
           c.bill_to_customer_id,
           NULL::INTEGER,
           NULL::INTEGER,
           ct.transaction_type_id,
           ct.payment_method_id,
           ct.invoice_id,
           NULL::INTEGER,
           NULL::VARCHAR(20),
           ct.amount_excluding_tax,
           ct.tax_amount,
           ct.transaction_amount,
           ct.outstanding_balance,
           ct.finalization_date IS NOT NULL,
           ct.transaction_date,
           ct.last_edited_when
    FROM sales.customer_transactions ct
    JOIN sales.customers c ON ct.customer_id = c.customer_id
    WHERE ct.last_edited_when > p_last_cutoff
    AND ct.last_edited_when <= p_new_cutoff
    
    UNION ALL
    
    -- Return supplier transactions
    SELECT NULL::INTEGER,
           NULL::INTEGER,
           NULL::INTEGER,
           st.supplier_transaction_id,
           st.supplier_id,
           st.transaction_type_id,
           st.payment_method_id,
           NULL::INTEGER,
           st.purchase_order_id,
           st.supplier_invoice_number,
           st.amount_excluding_tax,
           st.tax_amount,
           st.transaction_amount,
           st.outstanding_balance,
           st.finalization_date IS NOT NULL,
           st.transaction_date,
           st.last_edited_when
    FROM purchasing.supplier_transactions st
    WHERE st.last_edited_when > p_last_cutoff
    AND st.last_edited_when <= p_new_cutoff
    
    ORDER BY last_modified_when;
END;
$$;

COMMENT ON FUNCTION integration.get_transaction_updates IS 'Returns transaction fact updates for ETL processing';
