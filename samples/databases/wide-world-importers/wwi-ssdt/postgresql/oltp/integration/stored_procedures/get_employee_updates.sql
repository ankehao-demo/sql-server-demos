-- PostgreSQL equivalent of [Integration].GetEmployeeUpdates
-- Converted from T-SQL to PL/pgSQL

CREATE OR REPLACE FUNCTION integration.get_employee_updates(
    p_last_cutoff TIMESTAMP,
    p_new_cutoff TIMESTAMP
)
RETURNS TABLE (
    wwi_employee_id INTEGER,
    employee VARCHAR(50),
    preferred_name VARCHAR(50),
    is_salesperson BOOLEAN,
    photo BYTEA,
    valid_from TIMESTAMP,
    valid_to TIMESTAMP
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_end_of_time TIMESTAMP := '9999-12-31 23:59:59.999999'::TIMESTAMP;
BEGIN
    CREATE TEMP TABLE temp_employee_changes (
        wwi_employee_id INTEGER,
        employee VARCHAR(50),
        preferred_name VARCHAR(50),
        is_salesperson BOOLEAN,
        photo BYTEA,
        valid_from TIMESTAMP,
        valid_to TIMESTAMP
    ) ON COMMIT DROP;
    
    -- Find employee changes from archive
    INSERT INTO temp_employee_changes
    SELECT p.person_id, p.full_name, p.preferred_name, p.is_salesperson,
           p.photo, p.valid_from, NULL::TIMESTAMP
    FROM application.people_archive p
    WHERE p.is_employee = true
    AND p.valid_from > p_last_cutoff
    AND p.valid_from <= p_new_cutoff;
    
    -- Find employee changes from current table
    INSERT INTO temp_employee_changes
    SELECT p.person_id, p.full_name, p.preferred_name, p.is_salesperson,
           p.photo, p.valid_from, NULL::TIMESTAMP
    FROM application.people p
    WHERE p.is_employee = true
    AND p.valid_from > p_last_cutoff
    AND p.valid_from <= p_new_cutoff;
    
    CREATE INDEX ON temp_employee_changes (wwi_employee_id, valid_from);
    
    UPDATE temp_employee_changes ec
    SET valid_to = COALESCE(
        (SELECT MIN(ec2.valid_from) 
         FROM temp_employee_changes ec2
         WHERE ec2.wwi_employee_id = ec.wwi_employee_id
         AND ec2.valid_from > ec.valid_from),
        v_end_of_time
    );
    
    RETURN QUERY
    SELECT ec.wwi_employee_id, ec.employee, ec.preferred_name, ec.is_salesperson,
           ec.photo, ec.valid_from, ec.valid_to
    FROM temp_employee_changes ec
    ORDER BY ec.valid_from;
END;
$$;

COMMENT ON FUNCTION integration.get_employee_updates IS 'Returns employee dimension updates for ETL processing';
