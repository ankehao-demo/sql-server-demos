-- PostgreSQL equivalent of [WebApi].DeletePackageType
-- Converted from T-SQL to PL/pgSQL

CREATE OR REPLACE PROCEDURE webapi.delete_package_type(
    p_package_type_id INTEGER
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    DELETE FROM warehouse.package_types
    WHERE package_type_id = p_package_type_id;
END;
$$;

COMMENT ON PROCEDURE webapi.delete_package_type IS 'Deletes a package type by ID';
