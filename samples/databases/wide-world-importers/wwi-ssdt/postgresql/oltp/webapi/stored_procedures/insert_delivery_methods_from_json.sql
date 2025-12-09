-- PostgreSQL equivalent of [WebApi].InsertDeliveryMethodsFromJson
-- Converted from T-SQL to PL/pgSQL

CREATE OR REPLACE FUNCTION webapi.insert_delivery_methods_from_json(
    p_delivery_methods JSONB,
    p_user_id INTEGER
)
RETURNS TABLE (delivery_method_id INTEGER)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    RETURN QUERY
    INSERT INTO application.delivery_methods(delivery_method_name, last_edited_by)
    SELECT 
        (item->>'DeliveryMethodName')::VARCHAR(50),
        p_user_id
    FROM jsonb_array_elements(p_delivery_methods) AS item
    RETURNING application.delivery_methods.delivery_method_id;
END;
$$;

COMMENT ON FUNCTION webapi.insert_delivery_methods_from_json IS 'Inserts delivery methods from JSON array and returns inserted IDs';
