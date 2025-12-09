-- PostgreSQL equivalent of [Integration].GetCustomerUpdates
-- Converted from T-SQL to PL/pgSQL

CREATE OR REPLACE FUNCTION integration.get_customer_updates(
    p_last_cutoff TIMESTAMP,
    p_new_cutoff TIMESTAMP
)
RETURNS TABLE (
    wwi_customer_id INTEGER,
    customer VARCHAR(100),
    bill_to_customer VARCHAR(100),
    category VARCHAR(50),
    buying_group VARCHAR(50),
    primary_contact VARCHAR(50),
    postal_code VARCHAR(10),
    valid_from TIMESTAMP,
    valid_to TIMESTAMP
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_end_of_time TIMESTAMP := '9999-12-31 23:59:59.999999'::TIMESTAMP;
    v_initial_load_date DATE := '2020-01-01'::DATE;
BEGIN
    CREATE TEMP TABLE temp_customer_changes (
        wwi_customer_id INTEGER,
        customer VARCHAR(100),
        bill_to_customer VARCHAR(100),
        category VARCHAR(50),
        buying_group VARCHAR(50),
        primary_contact VARCHAR(50),
        postal_code VARCHAR(10),
        valid_from TIMESTAMP,
        valid_to TIMESTAMP
    ) ON COMMIT DROP;
    
    -- Find buying group changes
    INSERT INTO temp_customer_changes
    SELECT c.customer_id, c.customer_name, bt.customer_name, cc.customer_category_name,
           bg.buying_group_name, p.full_name, c.delivery_postal_code,
           bg.valid_from, NULL::TIMESTAMP
    FROM sales.buying_groups_archive bg
    JOIN sales.customers c ON c.buying_group_id = bg.buying_group_id
    JOIN sales.customer_categories cc ON c.customer_category_id = cc.customer_category_id
    JOIN sales.customers bt ON c.bill_to_customer_id = bt.customer_id
    JOIN application.people p ON c.primary_contact_person_id = p.person_id
    WHERE bg.valid_from > p_last_cutoff
    AND bg.valid_from <= p_new_cutoff
    AND bg.valid_from::DATE <> v_initial_load_date;
    
    INSERT INTO temp_customer_changes
    SELECT c.customer_id, c.customer_name, bt.customer_name, cc.customer_category_name,
           bg.buying_group_name, p.full_name, c.delivery_postal_code,
           bg.valid_from, NULL::TIMESTAMP
    FROM sales.buying_groups bg
    JOIN sales.customers c ON c.buying_group_id = bg.buying_group_id
    JOIN sales.customer_categories cc ON c.customer_category_id = cc.customer_category_id
    JOIN sales.customers bt ON c.bill_to_customer_id = bt.customer_id
    JOIN application.people p ON c.primary_contact_person_id = p.person_id
    WHERE bg.valid_from > p_last_cutoff
    AND bg.valid_from <= p_new_cutoff
    AND bg.valid_from::DATE <> v_initial_load_date;
    
    -- Find customer category changes
    INSERT INTO temp_customer_changes
    SELECT c.customer_id, c.customer_name, bt.customer_name, cc.customer_category_name,
           bg.buying_group_name, p.full_name, c.delivery_postal_code,
           cc.valid_from, NULL::TIMESTAMP
    FROM sales.customer_categories_archive cc
    JOIN sales.customers c ON c.customer_category_id = cc.customer_category_id
    LEFT JOIN sales.buying_groups bg ON c.buying_group_id = bg.buying_group_id
    JOIN sales.customers bt ON c.bill_to_customer_id = bt.customer_id
    JOIN application.people p ON c.primary_contact_person_id = p.person_id
    WHERE cc.valid_from > p_last_cutoff
    AND cc.valid_from <= p_new_cutoff
    AND cc.valid_from::DATE <> v_initial_load_date;
    
    INSERT INTO temp_customer_changes
    SELECT c.customer_id, c.customer_name, bt.customer_name, cc.customer_category_name,
           bg.buying_group_name, p.full_name, c.delivery_postal_code,
           cc.valid_from, NULL::TIMESTAMP
    FROM sales.customer_categories cc
    JOIN sales.customers c ON c.customer_category_id = cc.customer_category_id
    LEFT JOIN sales.buying_groups bg ON c.buying_group_id = bg.buying_group_id
    JOIN sales.customers bt ON c.bill_to_customer_id = bt.customer_id
    JOIN application.people p ON c.primary_contact_person_id = p.person_id
    WHERE cc.valid_from > p_last_cutoff
    AND cc.valid_from <= p_new_cutoff
    AND cc.valid_from::DATE <> v_initial_load_date;
    
    -- Find customer changes
    INSERT INTO temp_customer_changes
    SELECT c.customer_id, c.customer_name, bt.customer_name, cc.customer_category_name,
           bg.buying_group_name, p.full_name, c.delivery_postal_code,
           c.valid_from, NULL::TIMESTAMP
    FROM sales.customers_archive c
    JOIN sales.customer_categories cc ON c.customer_category_id = cc.customer_category_id
    LEFT JOIN sales.buying_groups bg ON c.buying_group_id = bg.buying_group_id
    JOIN sales.customers bt ON c.bill_to_customer_id = bt.customer_id
    JOIN application.people p ON c.primary_contact_person_id = p.person_id
    WHERE c.valid_from > p_last_cutoff
    AND c.valid_from <= p_new_cutoff;
    
    INSERT INTO temp_customer_changes
    SELECT c.customer_id, c.customer_name, bt.customer_name, cc.customer_category_name,
           bg.buying_group_name, p.full_name, c.delivery_postal_code,
           c.valid_from, NULL::TIMESTAMP
    FROM sales.customers c
    JOIN sales.customer_categories cc ON c.customer_category_id = cc.customer_category_id
    LEFT JOIN sales.buying_groups bg ON c.buying_group_id = bg.buying_group_id
    JOIN sales.customers bt ON c.bill_to_customer_id = bt.customer_id
    JOIN application.people p ON c.primary_contact_person_id = p.person_id
    WHERE c.valid_from > p_last_cutoff
    AND c.valid_from <= p_new_cutoff;
    
    CREATE INDEX ON temp_customer_changes (wwi_customer_id, valid_from);
    
    UPDATE temp_customer_changes cc
    SET valid_to = COALESCE(
        (SELECT MIN(cc2.valid_from) 
         FROM temp_customer_changes cc2
         WHERE cc2.wwi_customer_id = cc.wwi_customer_id
         AND cc2.valid_from > cc.valid_from),
        v_end_of_time
    );
    
    RETURN QUERY
    SELECT cc.wwi_customer_id, cc.customer, cc.bill_to_customer, cc.category,
           cc.buying_group, cc.primary_contact, cc.postal_code,
           cc.valid_from, cc.valid_to
    FROM temp_customer_changes cc
    ORDER BY cc.valid_from;
END;
$$;

COMMENT ON FUNCTION integration.get_customer_updates IS 'Returns customer dimension updates for ETL processing';
