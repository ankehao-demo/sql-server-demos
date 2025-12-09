-- PostgreSQL equivalent of [WebApi].UpdateInvoiceFromJson
-- Converted from T-SQL to PL/pgSQL

CREATE OR REPLACE PROCEDURE webapi.update_invoice_from_json(
    p_invoice JSONB,
    p_invoice_id INTEGER,
    p_user_id INTEGER
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    UPDATE sales.invoices SET
        customer_id = COALESCE((p_invoice->>'CustomerID')::INTEGER, customer_id),
        bill_to_customer_id = COALESCE((p_invoice->>'BillToCustomerID')::INTEGER, bill_to_customer_id),
        delivery_method_id = COALESCE((p_invoice->>'DeliveryMethodID')::INTEGER, delivery_method_id),
        contact_person_id = COALESCE((p_invoice->>'ContactPersonID')::INTEGER, contact_person_id),
        accounts_person_id = COALESCE((p_invoice->>'AccountsPersonID')::INTEGER, accounts_person_id),
        salesperson_person_id = COALESCE((p_invoice->>'SalespersonPersonID')::INTEGER, salesperson_person_id),
        packed_by_person_id = COALESCE((p_invoice->>'PackedByPersonID')::INTEGER, packed_by_person_id),
        invoice_date = COALESCE((p_invoice->>'InvoiceDate')::DATE, invoice_date),
        customer_purchase_order_number = (p_invoice->>'CustomerPurchaseOrderNumber')::VARCHAR(20),
        is_credit_note = COALESCE((p_invoice->>'IsCreditNote')::BOOLEAN, is_credit_note),
        total_dry_items = COALESCE((p_invoice->>'TotalDryItems')::INTEGER, total_dry_items),
        total_chiller_items = COALESCE((p_invoice->>'TotalChillerItems')::INTEGER, total_chiller_items),
        delivery_run = (p_invoice->>'DeliveryRun')::VARCHAR(5),
        run_position = (p_invoice->>'RunPosition')::VARCHAR(5),
        last_edited_by = p_user_id
    WHERE invoice_id = p_invoice_id;
END;
$$;

COMMENT ON PROCEDURE webapi.update_invoice_from_json IS 'Updates an invoice from JSON';
