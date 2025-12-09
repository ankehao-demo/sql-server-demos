-- PostgreSQL equivalent of [Website].SearchForSuppliers
-- Converted from T-SQL to PL/pgSQL
-- Returns JSON result like SQL Server's FOR JSON AUTO

CREATE OR REPLACE FUNCTION website.search_for_suppliers(
    p_search_text VARCHAR(1000),
    p_maximum_rows_to_return INTEGER
)
RETURNS JSON
LANGUAGE plpgsql
AS $$
DECLARE
    v_result JSON;
BEGIN
    SELECT json_build_object(
        'Suppliers',
        COALESCE(json_agg(
            json_build_object(
                'SupplierID', s.supplier_id,
                'SupplierName', s.supplier_name,
                'CityName', c.city_name,
                'PhoneNumber', s.phone_number,
                'FaxNumber', s.fax_number,
                'PrimaryContactFullName', p.full_name,
                'PrimaryContactPreferredName', p.preferred_name
            )
        ), '[]'::json)
    ) INTO v_result
    FROM (
        SELECT s.supplier_id, s.supplier_name, s.phone_number, s.fax_number,
               s.delivery_city_id, s.primary_contact_person_id
        FROM purchasing.suppliers s
        LEFT JOIN application.people p ON s.primary_contact_person_id = p.person_id
        WHERE CONCAT(s.supplier_name, ' ', COALESCE(p.full_name, ''), ' ', COALESCE(p.preferred_name, '')) 
              ILIKE '%' || p_search_text || '%'
        ORDER BY s.supplier_name
        LIMIT p_maximum_rows_to_return
    ) s
    JOIN application.cities c ON s.delivery_city_id = c.city_id
    LEFT JOIN application.people p ON s.primary_contact_person_id = p.person_id;
    
    RETURN v_result;
END;
$$;

COMMENT ON FUNCTION website.search_for_suppliers IS 'Searches for suppliers by name and returns JSON result';
