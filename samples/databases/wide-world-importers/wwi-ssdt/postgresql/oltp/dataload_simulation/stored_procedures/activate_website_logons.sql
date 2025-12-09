-- PostgreSQL equivalent of [DataLoadSimulation].ActivateWebsiteLogons
-- Converted from T-SQL to PL/pgSQL

CREATE OR REPLACE PROCEDURE dataload_simulation.activate_website_logons(
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
    v_logon_name VARCHAR(50);
    v_initial_password VARCHAR(40);
BEGIN
    -- Randomly select a few people to activate website logons
    FOR v_person_id, v_full_name IN
        SELECT person_id, full_name
        FROM application.people
        WHERE is_permitted_to_logon = false
        AND valid_to = '9999-12-31 23:59:59.999999'::TIMESTAMP
        ORDER BY RANDOM()
        LIMIT FLOOR(RANDOM() * 2)::INTEGER
    LOOP
        -- Generate logon name and password
        v_logon_name := LOWER(REPLACE(v_full_name, ' ', '.'));
        v_initial_password := 'Welcome' || FLOOR(RANDOM() * 1000)::TEXT || '!';
        
        -- Activate the logon
        UPDATE application.people
        SET is_permitted_to_logon = true,
            logon_name = v_logon_name,
            hashed_password = digest(v_initial_password || full_name, 'sha256'),
            user_preferences = (SELECT user_preferences FROM application.people WHERE person_id = 1),
            last_edited_when = p_starting_when
        WHERE person_id = v_person_id;
    END LOOP;
END;
$$;

COMMENT ON PROCEDURE dataload_simulation.activate_website_logons IS 'Simulates activation of website logons for random users';
