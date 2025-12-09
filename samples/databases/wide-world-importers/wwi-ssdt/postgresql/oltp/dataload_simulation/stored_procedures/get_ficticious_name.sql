-- PostgreSQL equivalent of [DataLoadSimulation].GetFicticiousName
-- Converted from T-SQL to PL/pgSQL

CREATE OR REPLACE PROCEDURE dataload_simulation.get_ficticious_name(
    INOUT p_ficticious_name VARCHAR(100)
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_first_names TEXT[] := ARRAY[
        'James', 'John', 'Robert', 'Michael', 'William', 'David', 'Richard', 'Joseph',
        'Thomas', 'Charles', 'Christopher', 'Daniel', 'Matthew', 'Anthony', 'Mark',
        'Mary', 'Patricia', 'Jennifer', 'Linda', 'Barbara', 'Elizabeth', 'Susan',
        'Jessica', 'Sarah', 'Karen', 'Nancy', 'Lisa', 'Betty', 'Margaret', 'Sandra'
    ];
    v_last_names TEXT[] := ARRAY[
        'Smith', 'Johnson', 'Williams', 'Brown', 'Jones', 'Garcia', 'Miller', 'Davis',
        'Rodriguez', 'Martinez', 'Hernandez', 'Lopez', 'Gonzalez', 'Wilson', 'Anderson',
        'Thomas', 'Taylor', 'Moore', 'Jackson', 'Martin', 'Lee', 'Perez', 'Thompson',
        'White', 'Harris', 'Sanchez', 'Clark', 'Ramirez', 'Lewis', 'Robinson'
    ];
    v_first_name VARCHAR(50);
    v_last_name VARCHAR(50);
BEGIN
    v_first_name := v_first_names[FLOOR(RANDOM() * array_length(v_first_names, 1) + 1)::INTEGER];
    v_last_name := v_last_names[FLOOR(RANDOM() * array_length(v_last_names, 1) + 1)::INTEGER];
    
    p_ficticious_name := v_first_name || ' ' || v_last_name;
END;
$$;

COMMENT ON PROCEDURE dataload_simulation.get_ficticious_name IS 'Generates a random fictitious person name';
