-- PostgreSQL equivalent of [DataLoadSimulation].DailyProcessToCreateHistory
-- Converted from T-SQL to PL/pgSQL
-- This is the main procedure that orchestrates daily data generation

CREATE OR REPLACE PROCEDURE dataload_simulation.daily_process_to_create_history(
    p_start_date DATE,
    p_end_date DATE,
    p_average_number_of_customer_orders_per_day INTEGER DEFAULT 30,
    p_saturday_percentage_of_normal_work_day INTEGER DEFAULT 25,
    p_sunday_percentage_of_normal_work_day INTEGER DEFAULT 0,
    p_update_custom_fields BOOLEAN DEFAULT false,
    p_is_silent_mode BOOLEAN DEFAULT false,
    p_are_dates_printed BOOLEAN DEFAULT true,
    p_min_yearly_growth_percent INTEGER DEFAULT -5,
    p_max_yearly_growth_percent INTEGER DEFAULT 15,
    p_min_seasonal_variation_percent INTEGER DEFAULT -10,
    p_max_seasonal_variation_percent INTEGER DEFAULT 30,
    p_max_daily_variation_percent INTEGER DEFAULT 20
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_current_date_time TIMESTAMP := p_start_date::TIMESTAMP;
    v_end_of_time TIMESTAMP := '9999-12-31 23:59:59.999999'::TIMESTAMP;
    v_starting_when TIMESTAMP;
    v_old_number_of_customer_orders INTEGER;
    v_number_of_customer_orders INTEGER;
    v_is_weekday BOOLEAN;
    v_is_saturday BOOLEAN;
    v_is_sunday BOOLEAN;
    v_is_monday BOOLEAN;
    v_weekday INTEGER;
    v_date_message TEXT;
    v_current_year INTEGER;
    v_current_season INTEGER;
    v_yearly_variation FLOAT;
    v_seasonal_variation FLOAT;
    v_x FLOAT;
    v_season_effect FLOAT;
    v_yearly_effect FLOAT;
    v_daily_effect FLOAT;
BEGIN
    -- Verify whether orders exist, and if so, compute the avg number of customer orders in the last year
    IF EXISTS (SELECT 1 FROM sales.orders) THEN
        SELECT AVG(order_count)::INTEGER
        INTO v_old_number_of_customer_orders
        FROM (
            SELECT COUNT(*) AS order_count 
            FROM sales.orders
            WHERE EXTRACT(YEAR FROM order_date) = (SELECT EXTRACT(YEAR FROM MAX(order_date)) FROM sales.orders)
            AND EXTRACT(DOW FROM order_date) NOT IN (0, 6)
            AND backorder_order_id IS NULL
            GROUP BY order_date
        ) t;
    ELSE
        v_old_number_of_customer_orders := p_average_number_of_customer_orders_per_day;
    END IF;
    
    -- Compute actual seasonal variation
    v_current_year := EXTRACT(YEAR FROM p_start_date)::INTEGER;
    WHILE v_current_year <= EXTRACT(YEAR FROM p_end_date) LOOP
        v_current_season := 1;
        -- Compute new yearly variation for each year
        v_yearly_variation := 1 + (p_min_yearly_growth_percent + RANDOM() * (p_max_yearly_growth_percent - p_min_yearly_growth_percent)) / 100;
        
        WHILE v_current_season <= 4 LOOP
            IF NOT EXISTS (
                SELECT 1 FROM dataload_simulation.season_variation 
                WHERE year = v_current_year AND season = v_current_season
            ) THEN
                -- Compute seasonal variation
                v_seasonal_variation := 1 + (p_min_seasonal_variation_percent + RANDOM() * (p_max_seasonal_variation_percent - p_min_seasonal_variation_percent)) / 100;
                IF v_current_season % 2 = 1 THEN
                    v_seasonal_variation := 1 / v_seasonal_variation;
                END IF;
                
                INSERT INTO dataload_simulation.season_variation (year, season, yearly_variation, seasonal_variation)
                VALUES (v_current_year, v_current_season, v_yearly_variation, v_seasonal_variation);
            END IF;
            v_current_season := v_current_season + 1;
        END LOOP;
        v_current_year := v_current_year + 1;
    END LOOP;
    
    -- Deactivate temporal tables before data load
    CALL dataload_simulation.deactivate_temporal_tables_before_data_load();
    
    BEGIN
        WHILE v_current_date_time::DATE <= p_end_date LOOP
            v_date_message := 'Processing ' 
                || to_char(v_current_date_time, 'Dy')
                || ' '
                || to_char(v_current_date_time, 'Mon DD, YYYY')
                || ' '
                || (p_end_date - v_current_date_time::DATE)::TEXT
                || ' Days Remaining';
            
            IF p_are_dates_printed OR NOT p_is_silent_mode THEN
                RAISE NOTICE '%', v_date_message;
            END IF;
            
            -- Compute number of orders to process
            v_current_year := EXTRACT(YEAR FROM v_current_date_time)::INTEGER;
            v_current_season := CEIL(EXTRACT(MONTH FROM v_current_date_time) / 3.0)::INTEGER;
            
            SELECT seasonal_variation, yearly_variation
            INTO v_seasonal_variation, v_yearly_variation
            FROM dataload_simulation.season_variation
            WHERE year = v_current_year AND season = v_current_season;
            
            v_x := (v_current_date_time::DATE - make_date(v_current_year, (v_current_season * 3) - 2, 1))::FLOAT / 90;
            IF v_x > 1 THEN
                v_x := 1;
            END IF;
            
            -- Compute location on seasonal bell curve
            v_season_effect := (SIN(2 * 3.1415926 * (v_x - 0.25)) + 1) / 2;
            v_season_effect := ((v_seasonal_variation - 1) * v_season_effect) + 1;
            
            -- Compute effect of yearly growth on day at hand
            v_yearly_effect := 1 + (v_yearly_variation - 1) * ((v_current_date_time::DATE - make_date(v_current_year - 1, 12, 31))::FLOAT / 183);
            
            v_daily_effect := RANDOM();
            IF v_daily_effect < 0.5 THEN
                v_daily_effect := 0 - v_daily_effect;
            END IF;
            v_daily_effect := 1 + v_daily_effect * (p_max_daily_variation_percent::FLOAT / 100);
            
            v_number_of_customer_orders := (v_old_number_of_customer_orders * v_daily_effect * v_season_effect * v_yearly_effect)::INTEGER;
            
            -- Calculate the days of the week
            v_weekday := EXTRACT(DOW FROM v_current_date_time)::INTEGER;
            v_is_saturday := (v_weekday = 6);
            v_is_sunday := (v_weekday = 0);
            v_is_monday := (v_weekday = 1);
            v_is_weekday := NOT (v_is_saturday OR v_is_sunday);
            
            -- Purchase orders (weekdays only)
            IF v_is_weekday THEN
                IF NOT p_is_silent_mode THEN
                    RAISE NOTICE '% - Receiving Purchase Orders', v_date_message;
                END IF;
                v_starting_when := v_current_date_time + INTERVAL '7 hours';
                CALL dataload_simulation.receive_purchase_orders(v_current_date_time, v_starting_when, v_end_of_time, p_is_silent_mode);
            END IF;
            
            -- Password changes
            IF NOT p_is_silent_mode THEN
                RAISE NOTICE '% - Changing Passwords', v_date_message;
            END IF;
            v_starting_when := v_current_date_time + INTERVAL '8 hours';
            CALL dataload_simulation.change_passwords(v_current_date_time, v_starting_when, v_end_of_time, p_is_silent_mode);
            
            -- Activate new website users
            IF NOT p_is_silent_mode THEN
                RAISE NOTICE '% - Activating Website Logins', v_date_message;
            END IF;
            v_starting_when := v_current_date_time + INTERVAL '8 hours 10 minutes';
            CALL dataload_simulation.activate_website_logons(v_current_date_time, v_starting_when, v_end_of_time, p_is_silent_mode);
            
            -- Payments to suppliers (Mondays only)
            IF v_is_monday THEN
                IF NOT p_is_silent_mode THEN
                    RAISE NOTICE '% - Paying Suppliers', v_date_message;
                END IF;
                v_starting_when := v_current_date_time + INTERVAL '9 hours';
                CALL dataload_simulation.pay_suppliers(v_current_date_time, v_starting_when, v_end_of_time, p_is_silent_mode);
            END IF;
            
            -- Customer orders received
            v_starting_when := v_current_date_time + INTERVAL '10 hours';
            v_number_of_customer_orders := CASE 
                WHEN v_is_saturday THEN FLOOR(v_number_of_customer_orders * p_saturday_percentage_of_normal_work_day / 100)
                WHEN v_is_sunday THEN FLOOR(v_number_of_customer_orders * p_sunday_percentage_of_normal_work_day / 100)
                ELSE v_number_of_customer_orders
            END;
            
            IF NOT p_is_silent_mode THEN
                RAISE NOTICE '% - Creating Customer Orders', v_date_message;
            END IF;
            CALL dataload_simulation.create_customer_orders(v_current_date_time, v_starting_when, v_end_of_time, v_number_of_customer_orders, p_is_silent_mode);
            
            -- Pick any customer orders that can be picked
            IF NOT p_is_silent_mode THEN
                RAISE NOTICE '% - Picking Stock for Customer Orders', v_date_message;
            END IF;
            v_starting_when := v_current_date_time + INTERVAL '11 hours';
            CALL dataload_simulation.pick_stock_for_customer_orders(v_current_date_time, v_starting_when, v_end_of_time, p_is_silent_mode);
            
            -- Process any payments from customers (weekdays only)
            IF v_is_weekday THEN
                IF NOT p_is_silent_mode THEN
                    RAISE NOTICE '% - Process Customer Payments', v_date_message;
                END IF;
                v_starting_when := v_current_date_time + INTERVAL '11 hours 30 minutes';
                CALL dataload_simulation.process_customer_payments(v_current_date_time, v_starting_when, v_end_of_time, p_is_silent_mode);
            END IF;
            
            -- Invoice orders that have been fully picked
            IF NOT p_is_silent_mode THEN
                RAISE NOTICE '% - Invoice Picked Orders', v_date_message;
            END IF;
            v_starting_when := v_current_date_time + INTERVAL '12 hours';
            CALL dataload_simulation.invoice_picked_orders(v_current_date_time, v_starting_when, v_end_of_time, p_is_silent_mode);
            
            -- Place supplier orders (weekdays only)
            IF v_is_weekday THEN
                IF NOT p_is_silent_mode THEN
                    RAISE NOTICE '% - Placing Supplier Orders', v_date_message;
                END IF;
                v_starting_when := v_current_date_time + INTERVAL '13 hours';
                CALL dataload_simulation.place_supplier_orders(v_current_date_time, v_starting_when, v_end_of_time, p_is_silent_mode);
            END IF;
            
            -- End of quarter stock take
            IF (EXTRACT(MONTH FROM v_current_date_time) = 1 AND EXTRACT(DAY FROM v_current_date_time) = 31)
                OR (EXTRACT(MONTH FROM v_current_date_time) = 4 AND EXTRACT(DAY FROM v_current_date_time) = 30)
                OR (EXTRACT(MONTH FROM v_current_date_time) = 7 AND EXTRACT(DAY FROM v_current_date_time) = 31)
                OR (EXTRACT(MONTH FROM v_current_date_time) = 10 AND EXTRACT(DAY FROM v_current_date_time) = 31)
            THEN
                IF NOT p_is_silent_mode THEN
                    RAISE NOTICE '% - Performing Stock Take', v_date_message;
                END IF;
                v_starting_when := v_current_date_time + INTERVAL '14 hours';
                CALL dataload_simulation.perform_stocktake(v_current_date_time, v_starting_when, v_end_of_time, p_is_silent_mode);
            END IF;
            
            -- Record invoice deliveries
            IF NOT p_is_silent_mode THEN
                RAISE NOTICE '% - Recording Invoice Deliveries', v_date_message;
            END IF;
            v_starting_when := v_current_date_time + INTERVAL '7 hours';
            CALL dataload_simulation.record_invoice_deliveries(v_current_date_time, v_starting_when, v_end_of_time, p_is_silent_mode);
            
            -- Add customers (weekdays only)
            IF v_is_weekday THEN
                IF NOT p_is_silent_mode THEN
                    RAISE NOTICE '% - Adding Customers', v_date_message;
                END IF;
                v_starting_when := v_current_date_time + INTERVAL '15 hours';
                CALL dataload_simulation.add_customers(v_current_date_time, v_starting_when, v_end_of_time, p_is_silent_mode);
            END IF;
            
            -- Add stock items
            IF NOT p_is_silent_mode THEN
                RAISE NOTICE '% - Adding Stock Items', v_date_message;
            END IF;
            v_starting_when := v_current_date_time + INTERVAL '16 hours';
            CALL dataload_simulation.add_stock_items(v_current_date_time, v_starting_when, v_end_of_time, p_is_silent_mode);
            
            -- Add special deals
            IF NOT p_is_silent_mode THEN
                RAISE NOTICE '% - Adding Special Deals', v_date_message;
            END IF;
            v_starting_when := v_current_date_time + INTERVAL '16 hours';
            CALL dataload_simulation.add_special_deals(v_current_date_time, v_starting_when, v_end_of_time, p_is_silent_mode);
            
            -- Temporal changes
            IF NOT p_is_silent_mode THEN
                RAISE NOTICE '% - Making Temporal Changes', v_date_message;
            END IF;
            v_starting_when := v_current_date_time + INTERVAL '16 hours';
            CALL dataload_simulation.make_temporal_changes(v_current_date_time, v_starting_when, v_end_of_time, p_is_silent_mode);
            
            -- Record delivery van temperatures (from 2022 onwards)
            IF v_current_date_time >= '2022-01-01'::TIMESTAMP THEN
                IF NOT p_is_silent_mode THEN
                    RAISE NOTICE '% - Recording Delivery Van Temperatures', v_date_message;
                END IF;
                v_starting_when := v_current_date_time + INTERVAL '7 hours';
                CALL dataload_simulation.record_delivery_van_temperatures(300, 2, v_current_date_time, v_starting_when, p_is_silent_mode);
            END IF;
            
            -- Record cold room temperatures (from late 2021 onwards)
            IF v_current_date_time >= '2021-12-20'::TIMESTAMP THEN
                IF NOT p_is_silent_mode THEN
                    RAISE NOTICE '% - Recording Cold Room Temperatures', v_date_message;
                END IF;
                CALL dataload_simulation.record_cold_room_temperatures(3600, 40, v_current_date_time, v_end_of_time, p_is_silent_mode);
            END IF;
            
            IF NOT p_is_silent_mode THEN
                RAISE NOTICE ' ';
            END IF;
            
            v_current_date_time := v_current_date_time + INTERVAL '1 day';
            
            -- If rolling over the year, re-baseline order count
            IF EXTRACT(DAY FROM v_current_date_time) = 1 AND EXTRACT(MONTH FROM v_current_date_time) = 1 THEN
                v_old_number_of_customer_orders := (v_old_number_of_customer_orders * v_yearly_effect)::INTEGER;
            END IF;
        END LOOP;
        
        IF NOT p_is_silent_mode THEN
            RAISE NOTICE 'Updating Custom Fields';
        END IF;
        IF p_update_custom_fields THEN
            CALL dataload_simulation.update_custom_fields(p_end_date);
        END IF;
        
        IF NOT p_is_silent_mode THEN
            RAISE NOTICE 'Reactivating Temporal Tables After Data Load';
        END IF;
        CALL dataload_simulation.reactivate_temporal_tables_after_data_load();
        
        IF NOT p_is_silent_mode THEN
            RAISE NOTICE 'Reseeding All Sequences';
        END IF;
        CALL sequences.reseed_all_sequences();
        
        -- Ensure RLS is applied
        IF NOT p_is_silent_mode THEN
            RAISE NOTICE 'Applying Row Level Security';
        END IF;
        CALL application.configuration_apply_row_level_security();
        
        IF NOT p_is_silent_mode THEN
            RAISE NOTICE 'Done Creating Wide World Importers Data History';
        END IF;
        
    EXCEPTION WHEN OTHERS THEN
        RAISE NOTICE 'Error Detected. Error: %', SQLERRM;
        RAISE NOTICE 'Attempting cleanup before throwing.';
        
        RAISE NOTICE 'Reactivating Temporal Tables After Data Load';
        CALL dataload_simulation.reactivate_temporal_tables_after_data_load();
        
        RAISE NOTICE 'Reseeding All Sequences';
        CALL sequences.reseed_all_sequences();
        
        RAISE NOTICE 'Applying Row Level Security';
        CALL application.configuration_apply_row_level_security();
        
        RAISE;
    END;
END;
$$;

COMMENT ON PROCEDURE dataload_simulation.daily_process_to_create_history IS 'Main procedure that orchestrates daily data generation for the Wide World Importers database';
