-- PostgreSQL equivalent of [DataLoadSimulation].PopulateOneDayOfHistory
-- Converted from T-SQL to PL/pgSQL

CREATE OR REPLACE PROCEDURE dataload_simulation.populate_one_day_of_history(
    p_average_number_of_customer_orders_per_day INTEGER DEFAULT 30,
    p_saturday_percentage_of_normal_work_day INTEGER DEFAULT 25,
    p_sunday_percentage_of_normal_work_day INTEGER DEFAULT 0,
    p_is_silent_mode BOOLEAN DEFAULT false,
    p_are_dates_printed BOOLEAN DEFAULT true
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_current_maximum_date DATE;
    v_starting_date DATE;
BEGIN
    -- Get the current maximum order date or default to 2019-12-31
    SELECT COALESCE(MAX(order_date), '2019-12-31'::DATE)
    INTO v_current_maximum_date
    FROM sales.orders;
    
    v_starting_date := v_current_maximum_date + INTERVAL '1 day';
    
    -- Call the daily process to create history for just one day
    CALL dataload_simulation.daily_process_to_create_history(
        p_start_date := v_starting_date,
        p_end_date := v_starting_date,
        p_average_number_of_customer_orders_per_day := p_average_number_of_customer_orders_per_day,
        p_saturday_percentage_of_normal_work_day := p_saturday_percentage_of_normal_work_day,
        p_sunday_percentage_of_normal_work_day := p_sunday_percentage_of_normal_work_day,
        p_update_custom_fields := false,
        p_is_silent_mode := p_is_silent_mode,
        p_are_dates_printed := p_are_dates_printed
    );
END;
$$;

COMMENT ON PROCEDURE dataload_simulation.populate_one_day_of_history IS 'Generates simulated data for one day after the last order date';
