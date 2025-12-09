-- PostgreSQL equivalent of [DataLoadSimulation].PopulateDataToCurrentDate
-- Converted from T-SQL to PL/pgSQL
-- This is the critical procedure that generates data from January 2013 to current date

CREATE OR REPLACE PROCEDURE dataload_simulation.populate_data_to_current_date(
    p_average_number_of_customer_orders_per_day INTEGER,
    p_saturday_percentage_of_normal_work_day INTEGER,
    p_sunday_percentage_of_normal_work_day INTEGER,
    p_is_silent_mode BOOLEAN,
    p_are_dates_printed BOOLEAN
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_current_maximum_date DATE;
    v_starting_date DATE;
    v_ending_date DATE;
BEGIN
    -- Get the current maximum order date or default to 2019-12-31
    SELECT COALESCE(MAX(order_date), '2019-12-31'::DATE)
    INTO v_current_maximum_date
    FROM sales.orders;
    
    v_starting_date := v_current_maximum_date + INTERVAL '1 day';
    v_ending_date := (NOW() - INTERVAL '1 day')::DATE;
    
    -- Call the daily process to create history
    CALL dataload_simulation.daily_process_to_create_history(
        p_start_date := v_starting_date,
        p_end_date := v_ending_date,
        p_average_number_of_customer_orders_per_day := p_average_number_of_customer_orders_per_day,
        p_saturday_percentage_of_normal_work_day := p_saturday_percentage_of_normal_work_day,
        p_sunday_percentage_of_normal_work_day := p_sunday_percentage_of_normal_work_day,
        p_update_custom_fields := false,
        p_is_silent_mode := p_is_silent_mode,
        p_are_dates_printed := p_are_dates_printed
    );
END;
$$;

COMMENT ON PROCEDURE dataload_simulation.populate_data_to_current_date IS 'Generates simulated data from the last order date to the current date';
