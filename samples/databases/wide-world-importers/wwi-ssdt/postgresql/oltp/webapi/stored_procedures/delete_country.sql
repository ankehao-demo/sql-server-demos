-- PostgreSQL equivalent of [WebApi].DeleteCountry
-- Converted from T-SQL to PL/pgSQL

CREATE OR REPLACE PROCEDURE webapi.delete_country(
    p_country_id INTEGER
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    DELETE FROM application.countries
    WHERE country_id = p_country_id;
END;
$$;

COMMENT ON PROCEDURE webapi.delete_country IS 'Deletes a country by ID';
