-- PostgreSQL equivalent of [WebApi].InsertColorsFromJson
-- Converted from T-SQL to PL/pgSQL

CREATE OR REPLACE FUNCTION webapi.insert_colors_from_json(
    p_colors JSONB,
    p_user_id INTEGER
)
RETURNS TABLE (color_id INTEGER)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    RETURN QUERY
    INSERT INTO warehouse.colors(color_name, last_edited_by)
    SELECT 
        (item->>'ColorName')::VARCHAR(20),
        p_user_id
    FROM jsonb_array_elements(p_colors) AS item
    RETURNING warehouse.colors.color_id;
END;
$$;

COMMENT ON FUNCTION webapi.insert_colors_from_json IS 'Inserts colors from JSON array and returns inserted IDs';
