-- PostgreSQL equivalent of [WebApi].UpdateDeliveryMethodFromJson
-- Converted from T-SQL to PL/pgSQL

CREATE OR REPLACE PROCEDURE webapi.update_delivery_method_from_json(
    p_delivery_method JSONB,
    p_delivery_method_id INTEGER,
    p_user_id INTEGER
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    UPDATE application.delivery_methods SET
        delivery_method_name = (p_delivery_method->>'DeliveryMethodName')::VARCHAR(50),
        last_edited_by = p_user_id
    WHERE delivery_method_id = p_delivery_method_id;
END;
$$;

COMMENT ON PROCEDURE webapi.update_delivery_method_from_json IS 'Updates a delivery method from JSON';
