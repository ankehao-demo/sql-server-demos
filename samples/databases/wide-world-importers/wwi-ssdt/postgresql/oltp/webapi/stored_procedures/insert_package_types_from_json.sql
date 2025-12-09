-- PostgreSQL equivalent of [WebApi].InsertPackageTypesFromJson
-- Converted from T-SQL to PL/pgSQL

CREATE OR REPLACE FUNCTION webapi.insert_package_types_from_json(
    p_package_types JSONB,
    p_user_id INTEGER
)
RETURNS TABLE (package_type_id INTEGER)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    RETURN QUERY
    INSERT INTO warehouse.package_types(package_type_name, last_edited_by)
    SELECT 
        (item->>'PackageTypeName')::VARCHAR(50),
        p_user_id
    FROM jsonb_array_elements(p_package_types) AS item
    RETURNING warehouse.package_types.package_type_id;
END;
$$;

COMMENT ON FUNCTION webapi.insert_package_types_from_json IS 'Inserts package types from JSON array and returns inserted IDs';
