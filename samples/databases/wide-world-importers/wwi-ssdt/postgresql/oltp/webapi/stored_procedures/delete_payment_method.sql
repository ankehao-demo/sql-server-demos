-- PostgreSQL equivalent of [WebApi].DeletePaymentMethod
-- Converted from T-SQL to PL/pgSQL

CREATE OR REPLACE PROCEDURE webapi.delete_payment_method(
    p_payment_method_id INTEGER
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    DELETE FROM application.payment_methods
    WHERE payment_method_id = p_payment_method_id;
END;
$$;

COMMENT ON PROCEDURE webapi.delete_payment_method IS 'Deletes a payment method by ID';
