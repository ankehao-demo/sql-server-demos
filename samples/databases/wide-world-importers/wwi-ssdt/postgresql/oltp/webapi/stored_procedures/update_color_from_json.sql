-- PostgreSQL equivalent of [WebApi].UpdateColorFromJson
-- Converted from T-SQL to PL/pgSQL

CREATE OR REPLACE PROCEDURE webapi.update_color_from_json(
    p_color JSONB,
    p_color_id INTEGER,
    p_user_id INTEGER
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    UPDATE warehouse.colors SET
        color_name = (p_color->>'ColorName')::VARCHAR(20),
        last_edited_by = p_user_id
    WHERE color_id = p_color_id;
END;
$$;

COMMENT ON PROCEDURE webapi.update_color_from_json IS 'Updates a color from JSON';
