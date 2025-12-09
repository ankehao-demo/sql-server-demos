-- PostgreSQL equivalent of [Website].SearchForPeople
-- Converted from T-SQL to PL/pgSQL
-- Returns JSON result like SQL Server's FOR JSON AUTO

CREATE OR REPLACE FUNCTION website.search_for_people(
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
        'People',
        COALESCE(json_agg(
            json_build_object(
                'PersonID', p.person_id,
                'FullName', p.full_name,
                'PreferredName', p.preferred_name,
                'Relationship', 
                    CASE 
                        WHEN p.is_salesperson THEN 'Salesperson'
                        WHEN p.is_employee THEN 'Employee'
                        WHEN c.customer_id IS NOT NULL THEN 'Customer'
                        WHEN sp.supplier_id IS NOT NULL THEN 'Supplier'
                        WHEN sa.supplier_id IS NOT NULL THEN 'Supplier'
                    END,
                'Company', COALESCE(c.customer_name, sp.supplier_name, sa.supplier_name, 'WWI')
            )
        ), '[]'::json)
    ) INTO v_result
    FROM (
        SELECT p.person_id, p.full_name, p.preferred_name, p.is_salesperson, p.is_employee
        FROM application.people p
        WHERE p.search_name ILIKE '%' || p_search_text || '%'
        ORDER BY p.full_name
        LIMIT p_maximum_rows_to_return
    ) p
    LEFT JOIN sales.customers c ON c.primary_contact_person_id = p.person_id
    LEFT JOIN purchasing.suppliers sp ON sp.primary_contact_person_id = p.person_id
    LEFT JOIN purchasing.suppliers sa ON sa.alternate_contact_person_id = p.person_id;
    
    RETURN v_result;
END;
$$;

COMMENT ON FUNCTION website.search_for_people IS 'Searches for people by name and returns JSON result with relationship info';
