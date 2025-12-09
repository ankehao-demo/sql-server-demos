-- PostgreSQL equivalent of [WebApi].DeleteDeliveryMethod
-- Converted from T-SQL to PL/pgSQL

CREATE OR REPLACE PROCEDURE webapi.delete_delivery_method(
    p_delivery_method_id INTEGER
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    DELETE FROM application.delivery_methods
    WHERE delivery_method_id = p_delivery_method_id;
END;
$$;

COMMENT ON PROCEDURE webapi.delete_delivery_method IS 'Deletes a delivery method by ID';
