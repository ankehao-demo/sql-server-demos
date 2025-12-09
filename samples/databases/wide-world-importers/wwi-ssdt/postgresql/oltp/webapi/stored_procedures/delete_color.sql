-- PostgreSQL equivalent of [WebApi].DeleteColor
-- Converted from T-SQL to PL/pgSQL

CREATE OR REPLACE PROCEDURE webapi.delete_color(
    p_color_id INTEGER
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    DELETE FROM warehouse.colors
    WHERE color_id = p_color_id;
END;
$$;

COMMENT ON PROCEDURE webapi.delete_color IS 'Deletes a color by ID';
