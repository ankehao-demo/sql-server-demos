-- PostgreSQL equivalent of [WebApi].DeleteStateProvince
-- Converted from T-SQL to PL/pgSQL

CREATE OR REPLACE PROCEDURE webapi.delete_state_province(
    p_state_province_id INTEGER
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    DELETE FROM application.state_provinces
    WHERE state_province_id = p_state_province_id;
END;
$$;

COMMENT ON PROCEDURE webapi.delete_state_province IS 'Deletes a state/province by ID';
