-- PostgreSQL equivalent of [DataLoadSimulation].UpdateCustomFields
-- Converted from T-SQL to PL/pgSQL

CREATE OR REPLACE PROCEDURE dataload_simulation.update_custom_fields(
    p_end_date DATE
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_staff_member_person_id INTEGER;
BEGIN
    -- Get a random staff member
    SELECT person_id INTO v_staff_member_person_id
    FROM application.people
    WHERE is_employee = true
    ORDER BY RANDOM()
    LIMIT 1;
    
    -- Update custom fields on people
    UPDATE application.people
    SET custom_fields = jsonb_build_object(
        'OtherLanguages', ARRAY['English'],
        'HireDate', to_char(valid_from, 'YYYY-MM-DD'),
        'Title', CASE 
            WHEN is_salesperson THEN 'Sales Representative'
            WHEN is_employee THEN 'Employee'
            ELSE 'Contact'
        END
    ),
    last_edited_by = v_staff_member_person_id,
    last_edited_when = NOW()
    WHERE custom_fields IS NULL
    AND valid_to = '9999-12-31 23:59:59.999999'::TIMESTAMP;
    
    -- Update custom fields on stock items
    UPDATE warehouse.stock_items
    SET custom_fields = jsonb_build_object(
        'CountryOfManufacture', 'USA',
        'ShelfLife', '365 days',
        'Tags', tags
    ),
    last_edited_by = v_staff_member_person_id,
    last_edited_when = NOW()
    WHERE custom_fields IS NULL
    AND valid_to = '9999-12-31 23:59:59.999999'::TIMESTAMP;
    
    RAISE NOTICE 'Custom fields updated';
END;
$$;

COMMENT ON PROCEDURE dataload_simulation.update_custom_fields IS 'Updates custom fields on people and stock items';
