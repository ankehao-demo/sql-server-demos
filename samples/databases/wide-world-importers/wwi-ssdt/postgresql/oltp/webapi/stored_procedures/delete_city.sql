-- PostgreSQL equivalent of [WebApi].DeleteCity
-- Converted from T-SQL to PL/pgSQL

CREATE OR REPLACE PROCEDURE webapi.delete_city(
    p_city_id INTEGER
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    DELETE FROM application.cities
    WHERE city_id = p_city_id;
END;
$$;

COMMENT ON PROCEDURE webapi.delete_city IS 'Deletes a city by ID';
