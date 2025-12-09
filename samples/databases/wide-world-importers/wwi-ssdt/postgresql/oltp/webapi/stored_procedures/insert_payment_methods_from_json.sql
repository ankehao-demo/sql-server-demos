-- PostgreSQL equivalent of [WebApi].InsertPaymentMethodsFromJson
-- Converted from T-SQL to PL/pgSQL

CREATE OR REPLACE FUNCTION webapi.insert_payment_methods_from_json(
    p_payment_methods JSONB,
    p_user_id INTEGER
)
RETURNS TABLE (payment_method_id INTEGER)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    RETURN QUERY
    INSERT INTO application.payment_methods(payment_method_name, last_edited_by)
    SELECT 
        (item->>'PaymentMethodName')::VARCHAR(50),
        p_user_id
    FROM jsonb_array_elements(p_payment_methods) AS item
    RETURNING application.payment_methods.payment_method_id;
END;
$$;

COMMENT ON FUNCTION webapi.insert_payment_methods_from_json IS 'Inserts payment methods from JSON array and returns inserted IDs';
