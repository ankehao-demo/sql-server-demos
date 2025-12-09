-- PostgreSQL equivalent of [Website].SearchForCustomers
-- Converted from T-SQL to PL/pgSQL
-- Returns JSON result like SQL Server's FOR JSON AUTO

CREATE OR REPLACE FUNCTION website.search_for_customers(
    p_search_text VARCHAR(1000),
    p_maximum_rows_to_return INTEGER
)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_result JSON;
BEGIN
    SELECT json_build_object(
        'Customers',
        COALESCE(json_agg(
            json_build_object(
                'CustomerID', c.customer_id,
                'CustomerName', c.customer_name,
                'CityName', ct.city_name,
                'PhoneNumber', c.phone_number,
                'FaxNumber', c.fax_number,
                'PrimaryContactFullName', p.full_name,
                'PrimaryContactPreferredName', p.preferred_name
            )
        ), '[]'::json)
    ) INTO v_result
    FROM (
        SELECT c.customer_id, c.customer_name, c.phone_number, c.fax_number,
               c.delivery_city_id, c.primary_contact_person_id
        FROM sales.customers c
        LEFT JOIN application.people p ON c.primary_contact_person_id = p.person_id
        WHERE CONCAT(c.customer_name, ' ', COALESCE(p.full_name, ''), ' ', COALESCE(p.preferred_name, '')) 
              ILIKE '%' || p_search_text || '%'
        ORDER BY c.customer_name
        LIMIT p_maximum_rows_to_return
    ) c
    JOIN application.cities ct ON c.delivery_city_id = ct.city_id
    LEFT JOIN application.people p ON c.primary_contact_person_id = p.person_id;
    
    RETURN v_result;
END;
$$;

COMMENT ON FUNCTION website.search_for_customers IS 'Searches for customers by name and returns JSON result';
