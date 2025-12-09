-- PostgreSQL equivalent of [DataLoadSimulation].AddSpecialDeals
-- Converted from T-SQL to PL/pgSQL

CREATE OR REPLACE PROCEDURE dataload_simulation.add_special_deals(
    p_current_date_time TIMESTAMP,
    p_starting_when TIMESTAMP,
    p_end_of_time TIMESTAMP,
    p_is_silent_mode BOOLEAN
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_staff_member_person_id INTEGER;
    v_special_deal_id INTEGER;
    v_stock_item_id INTEGER;
    v_customer_id INTEGER;
    v_buying_group_id INTEGER;
    v_customer_category_id INTEGER;
    v_deal_description VARCHAR(30);
    v_start_date DATE;
    v_end_date DATE;
    v_discount_amount DECIMAL(18,2);
    v_discount_percentage DECIMAL(18,3);
    v_unit_price DECIMAL(18,2);
    v_num_new_deals INTEGER;
    v_counter INTEGER := 0;
BEGIN
    -- Get a random staff member
    SELECT person_id INTO v_staff_member_person_id
    FROM application.people
    WHERE is_employee = true
    ORDER BY RANDOM()
    LIMIT 1;
    
    -- Randomly add 0-1 new special deals (rare event)
    v_num_new_deals := CASE WHEN RANDOM() < 0.05 THEN 1 ELSE 0 END;
    
    WHILE v_counter < v_num_new_deals LOOP
        -- Get next special deal ID
        v_special_deal_id := nextval('sequences.special_deal_id');
        
        -- Randomly select what type of deal this is
        -- Could be for a specific stock item, customer, buying group, or customer category
        v_stock_item_id := NULL;
        v_customer_id := NULL;
        v_buying_group_id := NULL;
        v_customer_category_id := NULL;
        
        CASE FLOOR(RANDOM() * 4)::INTEGER
            WHEN 0 THEN
                -- Stock item specific deal
                SELECT stock_item_id INTO v_stock_item_id
                FROM warehouse.stock_items
                WHERE valid_to = '9999-12-31 23:59:59.999999'::TIMESTAMP
                ORDER BY RANDOM()
                LIMIT 1;
            WHEN 1 THEN
                -- Customer specific deal
                SELECT customer_id INTO v_customer_id
                FROM sales.customers
                WHERE valid_to = '9999-12-31 23:59:59.999999'::TIMESTAMP
                ORDER BY RANDOM()
                LIMIT 1;
            WHEN 2 THEN
                -- Buying group deal
                SELECT buying_group_id INTO v_buying_group_id
                FROM sales.buying_groups
                WHERE valid_to = '9999-12-31 23:59:59.999999'::TIMESTAMP
                ORDER BY RANDOM()
                LIMIT 1;
            ELSE
                -- Customer category deal
                SELECT customer_category_id INTO v_customer_category_id
                FROM sales.customer_categories
                WHERE valid_to = '9999-12-31 23:59:59.999999'::TIMESTAMP
                ORDER BY RANDOM()
                LIMIT 1;
        END CASE;
        
        -- Set deal parameters
        v_deal_description := 'Special Deal ' || v_special_deal_id::TEXT;
        v_start_date := p_current_date_time::DATE;
        v_end_date := (p_current_date_time + INTERVAL '30 days')::DATE;
        
        -- Either discount amount or percentage, not both
        IF RANDOM() < 0.5 THEN
            v_discount_amount := ROUND((RANDOM() * 10 + 1)::DECIMAL(18,2), 2);
            v_discount_percentage := NULL;
            v_unit_price := NULL;
        ELSE
            v_discount_amount := NULL;
            v_discount_percentage := ROUND((RANDOM() * 20 + 5)::DECIMAL(18,3), 1);
            v_unit_price := NULL;
        END IF;
        
        -- Insert special deal
        INSERT INTO sales.special_deals (
            special_deal_id, stock_item_id, customer_id, buying_group_id,
            customer_category_id, stock_group_id, deal_description,
            start_date, end_date, discount_amount, discount_percentage,
            unit_price, last_edited_by, last_edited_when
        )
        VALUES (
            v_special_deal_id, v_stock_item_id, v_customer_id, v_buying_group_id,
            v_customer_category_id, NULL, v_deal_description,
            v_start_date, v_end_date, v_discount_amount, v_discount_percentage,
            v_unit_price, v_staff_member_person_id, p_starting_when
        );
        
        v_counter := v_counter + 1;
    END LOOP;
END;
$$;

COMMENT ON PROCEDURE dataload_simulation.add_special_deals IS 'Simulates adding new special deals';
