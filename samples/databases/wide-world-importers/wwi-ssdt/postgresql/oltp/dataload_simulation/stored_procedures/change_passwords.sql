-- PostgreSQL equivalent of [DataLoadSimulation].ChangePasswords
-- Converted from T-SQL to PL/pgSQL

CREATE OR REPLACE PROCEDURE dataload_simulation.change_passwords(
    p_current_date_time TIMESTAMP,
    p_starting_when TIMESTAMP,
    p_end_of_time TIMESTAMP,
    p_is_silent_mode BOOLEAN
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_person_id INTEGER;
    v_full_name VARCHAR(50);
    v_new_password VARCHAR(40);
BEGIN
    -- Randomly select a few people to change passwords
    FOR v_person_id, v_full_name IN
        SELECT person_id, full_name
        FROM application.people
        WHERE is_permitted_to_logon = true
        AND valid_to = '9999-12-31 23:59:59.999999'::TIMESTAMP
        ORDER BY RANDOM()
        LIMIT FLOOR(RANDOM() * 3)::INTEGER
    LOOP
        -- Generate a random password
        v_new_password := 'Pass' || FLOOR(RANDOM() * 10000)::TEXT || '!';
        
        -- Update the password
        UPDATE application.people
        SET hashed_password = digest(v_new_password || full_name, 'sha256'),
            last_edited_when = p_starting_when
        WHERE person_id = v_person_id;
    END LOOP;
END;
$$;

COMMENT ON PROCEDURE dataload_simulation.change_passwords IS 'Simulates password changes for random users';
