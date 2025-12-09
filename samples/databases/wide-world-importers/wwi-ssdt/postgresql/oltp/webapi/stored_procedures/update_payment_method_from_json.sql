-- PostgreSQL equivalent of [WebApi].UpdatePaymentMethodFromJson
-- Converted from T-SQL to PL/pgSQL

CREATE OR REPLACE PROCEDURE webapi.update_payment_method_from_json(
    p_payment_method JSONB,
    p_payment_method_id INTEGER,
    p_user_id INTEGER
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    UPDATE application.payment_methods SET
        payment_method_name = (p_payment_method->>'PaymentMethodName')::VARCHAR(50),
        last_edited_by = p_user_id
    WHERE payment_method_id = p_payment_method_id;
END;
$$;

COMMENT ON PROCEDURE webapi.update_payment_method_from_json IS 'Updates a payment method from JSON';
