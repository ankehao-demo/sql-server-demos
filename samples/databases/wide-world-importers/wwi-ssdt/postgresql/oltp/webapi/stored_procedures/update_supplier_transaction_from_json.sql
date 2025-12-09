-- PostgreSQL equivalent of [WebApi].UpdateSupplierTransactionFromJson
-- Converted from T-SQL to PL/pgSQL

CREATE OR REPLACE PROCEDURE webapi.update_supplier_transaction_from_json(
    p_supplier_transaction JSONB,
    p_supplier_transaction_id INTEGER,
    p_user_id INTEGER
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    UPDATE purchasing.supplier_transactions SET
        supplier_id = COALESCE((p_supplier_transaction->>'SupplierID')::INTEGER, supplier_id),
        transaction_type_id = COALESCE((p_supplier_transaction->>'TransactionTypeID')::INTEGER, transaction_type_id),
        purchase_order_id = (p_supplier_transaction->>'PurchaseOrderID')::INTEGER,
        payment_method_id = (p_supplier_transaction->>'PaymentMethodID')::INTEGER,
        supplier_invoice_number = (p_supplier_transaction->>'SupplierInvoiceNumber')::VARCHAR(20),
        transaction_date = COALESCE((p_supplier_transaction->>'TransactionDate')::DATE, transaction_date),
        amount_excluding_tax = COALESCE((p_supplier_transaction->>'AmountExcludingTax')::DECIMAL(18,2), amount_excluding_tax),
        tax_amount = COALESCE((p_supplier_transaction->>'TaxAmount')::DECIMAL(18,2), tax_amount),
        transaction_amount = COALESCE((p_supplier_transaction->>'TransactionAmount')::DECIMAL(18,2), transaction_amount),
        outstanding_balance = COALESCE((p_supplier_transaction->>'OutstandingBalance')::DECIMAL(18,2), outstanding_balance),
        finalization_date = (p_supplier_transaction->>'FinalizationDate')::DATE,
        is_finalized = (p_supplier_transaction->>'FinalizationDate') IS NOT NULL,
        last_edited_by = p_user_id
    WHERE supplier_transaction_id = p_supplier_transaction_id;
END;
$$;

COMMENT ON PROCEDURE webapi.update_supplier_transaction_from_json IS 'Updates a supplier transaction from JSON';
