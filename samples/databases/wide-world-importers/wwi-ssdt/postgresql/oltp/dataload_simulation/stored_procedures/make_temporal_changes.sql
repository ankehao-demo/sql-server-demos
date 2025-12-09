-- PostgreSQL equivalent of [DataLoadSimulation].MakeTemporalChanges
-- Converted from T-SQL to PL/pgSQL
-- Note: PostgreSQL uses trigger-based temporal tables instead of SQL Server's SYSTEM_VERSIONING

CREATE OR REPLACE PROCEDURE dataload_simulation.make_temporal_changes(
    p_current_date_time TIMESTAMP,
    p_starting_when TIMESTAMP,
    p_end_of_time TIMESTAMP,
    p_is_silent_mode BOOLEAN
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_staff_member_person_id INTEGER;
    v_person_id INTEGER;
    v_customer_id INTEGER;
    v_supplier_id INTEGER;
    v_city_id INTEGER;
BEGIN
    -- Get a random staff member
    SELECT person_id INTO v_staff_member_person_id
    FROM application.people
    WHERE is_employee = true
    ORDER BY RANDOM()
    LIMIT 1;
    
    -- Randomly make changes to temporal tables (rare events)
    
    -- Update a random person's phone number (5% chance)
    IF RANDOM() < 0.05 THEN
        SELECT person_id INTO v_person_id
        FROM application.people
        WHERE valid_to = '9999-12-31 23:59:59.999999'::TIMESTAMP
        AND is_system_user = false
        ORDER BY RANDOM()
        LIMIT 1;
        
        IF v_person_id IS NOT NULL THEN
            UPDATE application.people
            SET phone_number = dataload_simulation.get_bogative_phone_number('555'),
                last_edited_by = v_staff_member_person_id,
                last_edited_when = p_starting_when
            WHERE person_id = v_person_id;
        END IF;
    END IF;
    
    -- Update a random customer's credit limit (3% chance)
    IF RANDOM() < 0.03 THEN
        SELECT customer_id INTO v_customer_id
        FROM sales.customers
        WHERE valid_to = '9999-12-31 23:59:59.999999'::TIMESTAMP
        ORDER BY RANDOM()
        LIMIT 1;
        
        IF v_customer_id IS NOT NULL THEN
            UPDATE sales.customers
            SET credit_limit = credit_limit * (1 + (RANDOM() * 0.2 - 0.1)),
                last_edited_by = v_staff_member_person_id,
                last_edited_when = p_starting_when
            WHERE customer_id = v_customer_id;
        END IF;
    END IF;
    
    -- Update a random supplier's payment days (2% chance)
    IF RANDOM() < 0.02 THEN
        SELECT supplier_id INTO v_supplier_id
        FROM purchasing.suppliers
        WHERE valid_to = '9999-12-31 23:59:59.999999'::TIMESTAMP
        ORDER BY RANDOM()
        LIMIT 1;
        
        IF v_supplier_id IS NOT NULL THEN
            UPDATE purchasing.suppliers
            SET payment_days = (ARRAY[7, 14, 30, 60])[FLOOR(RANDOM() * 4 + 1)::INTEGER],
                last_edited_by = v_staff_member_person_id,
                last_edited_when = p_starting_when
            WHERE supplier_id = v_supplier_id;
        END IF;
    END IF;
END;
$$;

COMMENT ON PROCEDURE dataload_simulation.make_temporal_changes IS 'Simulates random changes to temporal tables';
