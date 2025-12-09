-- PostgreSQL equivalent of [WebApi].UpdatePackageTypeFromJson
-- Converted from T-SQL to PL/pgSQL

CREATE OR REPLACE PROCEDURE webapi.update_package_type_from_json(
    p_package_type JSONB,
    p_package_type_id INTEGER,
    p_user_id INTEGER
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    UPDATE warehouse.package_types SET
        package_type_name = (p_package_type->>'PackageTypeName')::VARCHAR(50),
        last_edited_by = p_user_id
    WHERE package_type_id = p_package_type_id;
END;
$$;

COMMENT ON PROCEDURE webapi.update_package_type_from_json IS 'Updates a package type from JSON';
