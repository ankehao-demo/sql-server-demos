-- PostgreSQL equivalent of [DataLoadSimulation].AddCustomers
-- Converted from T-SQL to PL/pgSQL

CREATE OR REPLACE PROCEDURE dataload_simulation.add_customers(
    p_current_date_time TIMESTAMP,
    p_starting_when TIMESTAMP,
    p_end_of_time TIMESTAMP,
    p_is_silent_mode BOOLEAN
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_staff_member_person_id INTEGER;
    v_customer_id INTEGER;
    v_person_id INTEGER;
    v_customer_name VARCHAR(100);
    v_bill_to_customer_id INTEGER;
    v_customer_category_id INTEGER;
    v_buying_group_id INTEGER;
    v_primary_contact_person_id INTEGER;
    v_delivery_method_id INTEGER;
    v_delivery_city_id INTEGER;
    v_postal_city_id INTEGER;
    v_credit_limit DECIMAL(18,2);
    v_account_opened_date DATE;
    v_standard_discount_percentage DECIMAL(18,3);
    v_payment_days INTEGER;
    v_phone_number VARCHAR(20);
    v_fax_number VARCHAR(20);
    v_website_url VARCHAR(256);
    v_delivery_address_line_1 VARCHAR(60);
    v_delivery_address_line_2 VARCHAR(60);
    v_delivery_postal_code VARCHAR(10);
    v_postal_address_line_1 VARCHAR(60);
    v_postal_address_line_2 VARCHAR(60);
    v_postal_postal_code VARCHAR(10);
    v_num_new_customers INTEGER;
    v_counter INTEGER := 0;
BEGIN
    -- Get a random staff member
    SELECT person_id INTO v_staff_member_person_id
    FROM application.people
    WHERE is_employee = true
    ORDER BY RANDOM()
    LIMIT 1;
    
    -- Randomly add 0-2 new customers
    v_num_new_customers := FLOOR(RANDOM() * 3)::INTEGER;
    
    WHILE v_counter < v_num_new_customers LOOP
        -- Get next customer ID
        v_customer_id := nextval('sequences.customer_id');
        
        -- Get next person ID for the contact
        v_person_id := nextval('sequences.person_id');
        
        -- Generate customer data
        v_customer_name := 'New Customer ' || v_customer_id::TEXT;
        
        -- Get random category, buying group, delivery method, city
        CALL dataload_simulation.get_random_customer_category(v_customer_category_id);
        CALL dataload_simulation.get_random_buying_group(v_buying_group_id);
        CALL dataload_simulation.get_random_delivery_method(v_delivery_method_id);
        CALL dataload_simulation.get_random_city(v_delivery_city_id);
        v_postal_city_id := v_delivery_city_id;
        
        -- Generate contact person
        INSERT INTO application.people (
            person_id, full_name, preferred_name, search_name, is_permitted_to_logon,
            logon_name, is_external_logon_provider, hashed_password, is_system_user,
            is_employee, is_salesperson, user_preferences, phone_number, fax_number,
            email_address, photo, custom_fields, other_languages,
            last_edited_by, valid_from, valid_to
        )
        VALUES (
            v_person_id, 'Contact for ' || v_customer_name, 'Contact', 
            LOWER('contact ' || v_customer_name), false,
            NULL, false, NULL, false,
            false, false, NULL, 
            dataload_simulation.get_bogative_phone_number('555'),
            dataload_simulation.get_bogative_phone_number('555'),
            LOWER(REPLACE(v_customer_name, ' ', '.')) || '@example.com',
            NULL, NULL, NULL,
            v_staff_member_person_id, p_starting_when, '9999-12-31 23:59:59.999999'::TIMESTAMP
        );
        
        v_primary_contact_person_id := v_person_id;
        
        -- Set default values
        v_credit_limit := 1000 + FLOOR(RANDOM() * 9000)::DECIMAL(18,2);
        v_account_opened_date := p_current_date_time::DATE;
        v_standard_discount_percentage := FLOOR(RANDOM() * 5)::DECIMAL(18,3);
        CALL dataload_simulation.get_random_payment_days(v_payment_days);
        v_phone_number := dataload_simulation.get_bogative_phone_number('555');
        v_fax_number := dataload_simulation.get_bogative_phone_number('555');
        v_website_url := 'http://www.' || LOWER(REPLACE(v_customer_name, ' ', '')) || '.com';
        v_delivery_address_line_1 := FLOOR(RANDOM() * 9999 + 1)::TEXT || ' Main Street';
        v_delivery_address_line_2 := 'Suite ' || FLOOR(RANDOM() * 999 + 1)::TEXT;
        v_delivery_postal_code := LPAD(FLOOR(RANDOM() * 99999)::TEXT, 5, '0');
        v_postal_address_line_1 := v_delivery_address_line_1;
        v_postal_address_line_2 := v_delivery_address_line_2;
        v_postal_postal_code := v_delivery_postal_code;
        
        -- Insert customer
        INSERT INTO sales.customers (
            customer_id, customer_name, bill_to_customer_id, customer_category_id,
            buying_group_id, primary_contact_person_id, alternate_contact_person_id,
            delivery_method_id, delivery_city_id, postal_city_id, credit_limit,
            account_opened_date, standard_discount_percentage, is_statement_sent,
            is_on_credit_hold, payment_days, phone_number, fax_number, delivery_run,
            run_position, website_url, delivery_address_line_1, delivery_address_line_2,
            delivery_postal_code, delivery_location, postal_address_line_1,
            postal_address_line_2, postal_postal_code, last_edited_by,
            valid_from, valid_to
        )
        VALUES (
            v_customer_id, v_customer_name, v_customer_id, v_customer_category_id,
            v_buying_group_id, v_primary_contact_person_id, NULL,
            v_delivery_method_id, v_delivery_city_id, v_postal_city_id, v_credit_limit,
            v_account_opened_date, v_standard_discount_percentage, false,
            false, v_payment_days, v_phone_number, v_fax_number, NULL,
            NULL, v_website_url, v_delivery_address_line_1, v_delivery_address_line_2,
            v_delivery_postal_code, NULL, v_postal_address_line_1,
            v_postal_address_line_2, v_postal_postal_code, v_staff_member_person_id,
            p_starting_when, '9999-12-31 23:59:59.999999'::TIMESTAMP
        );
        
        v_counter := v_counter + 1;
    END LOOP;
END;
$$;

COMMENT ON PROCEDURE dataload_simulation.add_customers IS 'Simulates adding new customers';
