-- PostgreSQL equivalent of [WebApi].UpdateCustomerTransactionFromJson
-- Converted from T-SQL to PL/pgSQL

CREATE OR REPLACE PROCEDURE webapi.update_customer_transaction_from_json(
    p_customer_transaction JSONB,
    p_customer_transaction_id INTEGER,
    p_user_id INTEGER
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    UPDATE sales.customer_transactions SET
        customer_id = COALESCE((p_customer_transaction->>'CustomerID')::INTEGER, customer_id),
        transaction_type_id = COALESCE((p_customer_transaction->>'TransactionTypeID')::INTEGER, transaction_type_id),
        invoice_id = (p_customer_transaction->>'InvoiceID')::INTEGER,
        payment_method_id = (p_customer_transaction->>'PaymentMethodID')::INTEGER,
        transaction_date = COALESCE((p_customer_transaction->>'TransactionDate')::DATE, transaction_date),
        amount_excluding_tax = COALESCE((p_customer_transaction->>'AmountExcludingTax')::DECIMAL(18,2), amount_excluding_tax),
        tax_amount = COALESCE((p_customer_transaction->>'TaxAmount')::DECIMAL(18,2), tax_amount),
        transaction_amount = COALESCE((p_customer_transaction->>'TransactionAmount')::DECIMAL(18,2), transaction_amount),
        outstanding_balance = COALESCE((p_customer_transaction->>'OutstandingBalance')::DECIMAL(18,2), outstanding_balance),
        finalization_date = (p_customer_transaction->>'FinalizationDate')::DATE,
        is_finalized = (p_customer_transaction->>'FinalizationDate') IS NOT NULL,
        last_edited_by = p_user_id
    WHERE customer_transaction_id = p_customer_transaction_id;
END;
$$;

COMMENT ON PROCEDURE webapi.update_customer_transaction_from_json IS 'Updates a customer transaction from JSON';
