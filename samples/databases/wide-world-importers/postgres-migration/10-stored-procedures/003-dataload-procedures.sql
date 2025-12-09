-- Phase 3: OLTP Code Migration - DataLoadSimulation Schema Stored Procedures
-- Converted from SQL Server T-SQL to PostgreSQL PL/pgSQL

-- First, create the DataLoad schema if it doesn't exist
CREATE SCHEMA IF NOT EXISTS dataload;

-- Create the SeasonVariation table for data load simulation
CREATE TABLE IF NOT EXISTS dataload.seasonvariation (
    year integer NOT NULL,
    season smallint NOT NULL,
    yearlyvariation double precision NOT NULL,
    seasonalvariation double precision NOT NULL,
    PRIMARY KEY (year, season)
);

-- =============================================
-- Procedure: DataLoadSimulation.GetRandomBuyingGroup
-- Description: Returns a random buying group ID
-- =============================================
CREATE OR REPLACE PROCEDURE dataload.get_random_buying_group(
    INOUT p_buying_group_id integer DEFAULT NULL
)
LANGUAGE plpgsql
AS $$
BEGIN
    SELECT buyinggroupid INTO p_buying_group_id
    FROM sales.buyinggroups
    ORDER BY random()
    LIMIT 1;
END;
$$;

-- =============================================
-- Procedure: DataLoadSimulation.GetRandomBuyingGroupNotInUse
-- Description: Returns a random buying group ID that is not currently in use
-- =============================================
CREATE OR REPLACE PROCEDURE dataload.get_random_buying_group_not_in_use(
    INOUT p_buying_group_id integer DEFAULT NULL
)
LANGUAGE plpgsql
AS $$
BEGIN
    SELECT bg.buyinggroupid INTO p_buying_group_id
    FROM sales.buyinggroups bg
    WHERE NOT EXISTS (
        SELECT 1 FROM sales.customers c WHERE c.buyinggroupid = bg.buyinggroupid
    )
    ORDER BY random()
    LIMIT 1;
END;
$$;

-- =============================================
-- Procedure: DataLoadSimulation.GetRandomCity
-- Description: Returns a random city ID
-- =============================================
CREATE OR REPLACE PROCEDURE dataload.get_random_city(
    INOUT p_city_id integer DEFAULT NULL
)
LANGUAGE plpgsql
AS $$
BEGIN
    SELECT cityid INTO p_city_id
    FROM application.cities
    ORDER BY random()
    LIMIT 1;
END;
$$;

-- =============================================
-- Procedure: DataLoadSimulation.GetRandomCustomer
-- Description: Returns a random customer ID
-- =============================================
CREATE OR REPLACE PROCEDURE dataload.get_random_customer(
    INOUT p_customer_id integer DEFAULT NULL
)
LANGUAGE plpgsql
AS $$
BEGIN
    SELECT customerid INTO p_customer_id
    FROM sales.customers
    ORDER BY random()
    LIMIT 1;
END;
$$;

-- =============================================
-- Procedure: DataLoadSimulation.GetRandomCustomerCategory
-- Description: Returns a random customer category ID
-- =============================================
CREATE OR REPLACE PROCEDURE dataload.get_random_customer_category(
    INOUT p_customer_category_id integer DEFAULT NULL
)
LANGUAGE plpgsql
AS $$
BEGIN
    SELECT customercategoryid INTO p_customer_category_id
    FROM sales.customercategories
    ORDER BY random()
    LIMIT 1;
END;
$$;

-- =============================================
-- Procedure: DataLoadSimulation.GetRandomDeliveryMethod
-- Description: Returns a random delivery method ID
-- =============================================
CREATE OR REPLACE PROCEDURE dataload.get_random_delivery_method(
    INOUT p_delivery_method_id integer DEFAULT NULL
)
LANGUAGE plpgsql
AS $$
BEGIN
    SELECT deliverymethodid INTO p_delivery_method_id
    FROM application.deliverymethods
    ORDER BY random()
    LIMIT 1;
END;
$$;

-- =============================================
-- Procedure: DataLoadSimulation.GetRandomEmployeePerson
-- Description: Returns a random employee person ID
-- =============================================
CREATE OR REPLACE PROCEDURE dataload.get_random_employee_person(
    INOUT p_person_id integer DEFAULT NULL
)
LANGUAGE plpgsql
AS $$
BEGIN
    SELECT personid INTO p_person_id
    FROM application.people
    WHERE isemployee = true
    ORDER BY random()
    LIMIT 1;
END;
$$;

-- =============================================
-- Procedure: DataLoadSimulation.GetRandomSalesPersonID
-- Description: Returns a random salesperson ID
-- =============================================
CREATE OR REPLACE PROCEDURE dataload.get_random_salesperson_id(
    INOUT p_person_id integer DEFAULT NULL
)
LANGUAGE plpgsql
AS $$
BEGIN
    SELECT personid INTO p_person_id
    FROM application.people
    WHERE issalesperson = true
    ORDER BY random()
    LIMIT 1;
END;
$$;

-- =============================================
-- Procedure: DataLoadSimulation.GetRandomPaymentDays
-- Description: Returns a random payment days value
-- =============================================
CREATE OR REPLACE PROCEDURE dataload.get_random_payment_days(
    INOUT p_payment_days integer DEFAULT NULL
)
LANGUAGE plpgsql
AS $$
BEGIN
    p_payment_days := CASE floor(random() * 4)::integer
        WHEN 0 THEN 7
        WHEN 1 THEN 14
        WHEN 2 THEN 30
        ELSE 60
    END;
END;
$$;

-- =============================================
-- Procedure: DataLoadSimulation.GetRandomStockItemToAdjust
-- Description: Returns a random stock item ID for adjustment
-- =============================================
CREATE OR REPLACE PROCEDURE dataload.get_random_stock_item_to_adjust(
    INOUT p_stock_item_id integer DEFAULT NULL
)
LANGUAGE plpgsql
AS $$
BEGIN
    SELECT stockitemid INTO p_stock_item_id
    FROM warehouse.stockitems
    ORDER BY random()
    LIMIT 1;
END;
$$;

-- =============================================
-- Procedure: DataLoadSimulation.GetFicticiousName
-- Description: Generates a fictitious name
-- =============================================
CREATE OR REPLACE PROCEDURE dataload.get_ficticious_name(
    INOUT p_name varchar(100) DEFAULT NULL
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_first_names text[] := ARRAY['James', 'John', 'Robert', 'Michael', 'William', 'David', 'Richard', 'Joseph', 'Thomas', 'Charles',
                                   'Mary', 'Patricia', 'Jennifer', 'Linda', 'Elizabeth', 'Barbara', 'Susan', 'Jessica', 'Sarah', 'Karen'];
    v_last_names text[] := ARRAY['Smith', 'Johnson', 'Williams', 'Brown', 'Jones', 'Garcia', 'Miller', 'Davis', 'Rodriguez', 'Martinez',
                                  'Hernandez', 'Lopez', 'Gonzalez', 'Wilson', 'Anderson', 'Thomas', 'Taylor', 'Moore', 'Jackson', 'Martin'];
BEGIN
    p_name := v_first_names[1 + floor(random() * array_length(v_first_names, 1))::integer] || ' ' ||
              v_last_names[1 + floor(random() * array_length(v_last_names, 1))::integer];
END;
$$;

-- =============================================
-- Procedure: DataLoadSimulation.GetBogativePostalCode
-- Description: Generates a fake postal code
-- =============================================
CREATE OR REPLACE PROCEDURE dataload.get_bogative_postal_code(
    INOUT p_postal_code varchar(10) DEFAULT NULL
)
LANGUAGE plpgsql
AS $$
BEGIN
    p_postal_code := lpad((floor(random() * 90000) + 10000)::text, 5, '0');
END;
$$;

-- =============================================
-- Procedure: DataLoadSimulation.GetRandomStreetSuffix
-- Description: Returns a random street suffix
-- =============================================
CREATE OR REPLACE PROCEDURE dataload.get_random_street_suffix(
    INOUT p_suffix varchar(20) DEFAULT NULL
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_suffixes text[] := ARRAY['Street', 'Avenue', 'Boulevard', 'Drive', 'Lane', 'Road', 'Way', 'Place', 'Court', 'Circle'];
BEGIN
    p_suffix := v_suffixes[1 + floor(random() * array_length(v_suffixes, 1))::integer];
END;
$$;

-- =============================================
-- Procedure: DataLoadSimulation.GetRandomStreetName
-- Description: Returns a random street name
-- =============================================
CREATE OR REPLACE PROCEDURE dataload.get_random_street_name(
    INOUT p_street_name varchar(50) DEFAULT NULL
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_names text[] := ARRAY['Main', 'Oak', 'Maple', 'Cedar', 'Pine', 'Elm', 'Washington', 'Lake', 'Hill', 'Park',
                            'First', 'Second', 'Third', 'Fourth', 'Fifth', 'Sixth', 'Seventh', 'Eighth', 'Ninth', 'Tenth'];
BEGIN
    p_street_name := v_names[1 + floor(random() * array_length(v_names, 1))::integer];
END;
$$;

-- =============================================
-- Procedure: DataLoadSimulation.GetRandomStreet
-- Description: Returns a random street address
-- =============================================
CREATE OR REPLACE PROCEDURE dataload.get_random_street(
    INOUT p_street varchar(100) DEFAULT NULL
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_street_name varchar(50);
    v_suffix varchar(20);
    v_number integer;
BEGIN
    CALL dataload.get_random_street_name(v_street_name);
    CALL dataload.get_random_street_suffix(v_suffix);
    v_number := floor(random() * 9999) + 1;
    
    p_street := v_number::text || ' ' || v_street_name || ' ' || v_suffix;
END;
$$;

-- =============================================
-- Procedure: DataLoadSimulation.GetRandomSecondaryAddress
-- Description: Returns a random secondary address (apt, suite, etc.)
-- =============================================
CREATE OR REPLACE PROCEDURE dataload.get_random_secondary_address(
    INOUT p_address varchar(50) DEFAULT NULL
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_types text[] := ARRAY['Apt', 'Suite', 'Unit', 'Floor', 'Building'];
BEGIN
    IF random() < 0.3 THEN
        p_address := v_types[1 + floor(random() * array_length(v_types, 1))::integer] || ' ' ||
                     (floor(random() * 999) + 1)::text;
    ELSE
        p_address := '';
    END IF;
END;
$$;

-- =============================================
-- Procedure: DataLoadSimulation.GetBuyingGroupDomain
-- Description: Returns the domain for a buying group
-- =============================================
CREATE OR REPLACE PROCEDURE dataload.get_buying_group_domain(
    p_buying_group_id integer,
    INOUT p_domain varchar(100) DEFAULT NULL
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_buying_group_name varchar(50);
BEGIN
    SELECT buyinggroupname INTO v_buying_group_name
    FROM sales.buyinggroups
    WHERE buyinggroupid = p_buying_group_id;
    
    IF v_buying_group_name IS NOT NULL THEN
        p_domain := lower(replace(v_buying_group_name, ' ', '')) || '.com';
    ELSE
        p_domain := 'example.com';
    END IF;
END;
$$;

-- =============================================
-- Procedure: DataLoadSimulation.DeactivateTemporalTablesBeforeDataLoad
-- Description: Disables temporal table triggers before data load
-- Note: In PostgreSQL, we disable the temporal triggers instead of SYSTEM_VERSIONING
-- =============================================
CREATE OR REPLACE PROCEDURE dataload.deactivate_temporal_tables_before_data_load()
LANGUAGE plpgsql
AS $$
BEGIN
    -- Remove row-level security if it exists
    BEGIN
        CALL application.configuration_remove_row_level_security();
    EXCEPTION WHEN OTHERS THEN
        RAISE NOTICE 'Row-level security not configured or already removed';
    END;
    
    -- Disable temporal triggers on all temporal tables
    -- Application schema
    ALTER TABLE application.cities DISABLE TRIGGER tr_application_cities_temporal;
    ALTER TABLE application.countries DISABLE TRIGGER tr_application_countries_temporal;
    ALTER TABLE application.deliverymethods DISABLE TRIGGER tr_application_deliverymethods_temporal;
    ALTER TABLE application.paymentmethods DISABLE TRIGGER tr_application_paymentmethods_temporal;
    ALTER TABLE application.people DISABLE TRIGGER tr_application_people_temporal;
    ALTER TABLE application.stateprovinces DISABLE TRIGGER tr_application_stateprovinces_temporal;
    ALTER TABLE application.transactiontypes DISABLE TRIGGER tr_application_transactiontypes_temporal;
    
    -- Purchasing schema
    ALTER TABLE purchasing.suppliercategories DISABLE TRIGGER tr_purchasing_suppliercategories_temporal;
    ALTER TABLE purchasing.suppliers DISABLE TRIGGER tr_purchasing_suppliers_temporal;
    
    -- Sales schema
    ALTER TABLE sales.buyinggroups DISABLE TRIGGER tr_sales_buyinggroups_temporal;
    ALTER TABLE sales.customercategories DISABLE TRIGGER tr_sales_customercategories_temporal;
    ALTER TABLE sales.customers DISABLE TRIGGER tr_sales_customers_temporal;
    
    -- Warehouse schema
    ALTER TABLE warehouse.coldroomtemperatures DISABLE TRIGGER tr_warehouse_coldroomtemperatures_temporal;
    ALTER TABLE warehouse.colors DISABLE TRIGGER tr_warehouse_colors_temporal;
    ALTER TABLE warehouse.packagetypes DISABLE TRIGGER tr_warehouse_packagetypes_temporal;
    ALTER TABLE warehouse.stockgroups DISABLE TRIGGER tr_warehouse_stockgroups_temporal;
    ALTER TABLE warehouse.stockitems DISABLE TRIGGER tr_warehouse_stockitems_temporal;
    
    RAISE NOTICE 'Temporal tables deactivated for data load';
EXCEPTION
    WHEN undefined_object THEN
        RAISE NOTICE 'Some temporal triggers do not exist - continuing';
    WHEN OTHERS THEN
        RAISE NOTICE 'Error deactivating temporal tables: %', SQLERRM;
END;
$$;

-- =============================================
-- Procedure: DataLoadSimulation.ReactivateTemporalTablesAfterDataLoad
-- Description: Re-enables temporal table triggers after data load
-- =============================================
CREATE OR REPLACE PROCEDURE dataload.reactivate_temporal_tables_after_data_load()
LANGUAGE plpgsql
AS $$
BEGIN
    -- Re-apply row-level security
    BEGIN
        CALL application.configuration_apply_row_level_security();
    EXCEPTION WHEN OTHERS THEN
        RAISE NOTICE 'Could not apply row-level security: %', SQLERRM;
    END;
    
    -- Enable temporal triggers on all temporal tables
    -- Application schema
    ALTER TABLE application.cities ENABLE TRIGGER tr_application_cities_temporal;
    ALTER TABLE application.countries ENABLE TRIGGER tr_application_countries_temporal;
    ALTER TABLE application.deliverymethods ENABLE TRIGGER tr_application_deliverymethods_temporal;
    ALTER TABLE application.paymentmethods ENABLE TRIGGER tr_application_paymentmethods_temporal;
    ALTER TABLE application.people ENABLE TRIGGER tr_application_people_temporal;
    ALTER TABLE application.stateprovinces ENABLE TRIGGER tr_application_stateprovinces_temporal;
    ALTER TABLE application.transactiontypes ENABLE TRIGGER tr_application_transactiontypes_temporal;
    
    -- Purchasing schema
    ALTER TABLE purchasing.suppliercategories ENABLE TRIGGER tr_purchasing_suppliercategories_temporal;
    ALTER TABLE purchasing.suppliers ENABLE TRIGGER tr_purchasing_suppliers_temporal;
    
    -- Sales schema
    ALTER TABLE sales.buyinggroups ENABLE TRIGGER tr_sales_buyinggroups_temporal;
    ALTER TABLE sales.customercategories ENABLE TRIGGER tr_sales_customercategories_temporal;
    ALTER TABLE sales.customers ENABLE TRIGGER tr_sales_customers_temporal;
    
    -- Warehouse schema
    ALTER TABLE warehouse.coldroomtemperatures ENABLE TRIGGER tr_warehouse_coldroomtemperatures_temporal;
    ALTER TABLE warehouse.colors ENABLE TRIGGER tr_warehouse_colors_temporal;
    ALTER TABLE warehouse.packagetypes ENABLE TRIGGER tr_warehouse_packagetypes_temporal;
    ALTER TABLE warehouse.stockgroups ENABLE TRIGGER tr_warehouse_stockgroups_temporal;
    ALTER TABLE warehouse.stockitems ENABLE TRIGGER tr_warehouse_stockitems_temporal;
    
    RAISE NOTICE 'Temporal tables reactivated after data load';
EXCEPTION
    WHEN undefined_object THEN
        RAISE NOTICE 'Some temporal triggers do not exist - continuing';
    WHEN OTHERS THEN
        RAISE NOTICE 'Error reactivating temporal tables: %', SQLERRM;
END;
$$;

-- =============================================
-- Procedure: DataLoadSimulation.PopulateDataToCurrentDate
-- Description: Main procedure to populate data from last order date to current date
-- =============================================
CREATE OR REPLACE PROCEDURE dataload.populate_data_to_current_date(
    p_average_number_of_customer_orders_per_day integer,
    p_saturday_percentage_of_normal_work_day integer,
    p_sunday_percentage_of_normal_work_day integer,
    p_is_silent_mode boolean DEFAULT false,
    p_are_dates_printed boolean DEFAULT true
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_current_maximum_date date;
    v_starting_date date;
    v_ending_date date;
BEGIN
    -- Get the current maximum order date or default to 2019-12-31
    SELECT COALESCE(MAX(orderdate), '2019-12-31'::date) INTO v_current_maximum_date
    FROM sales.orders;
    
    v_starting_date := v_current_maximum_date + INTERVAL '1 day';
    v_ending_date := (NOW() - INTERVAL '1 day')::date;
    
    IF v_starting_date > v_ending_date THEN
        RAISE NOTICE 'No data to populate - starting date % is after ending date %', v_starting_date, v_ending_date;
        RETURN;
    END IF;
    
    CALL dataload.daily_process_to_create_history(
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

-- =============================================
-- Procedure: DataLoadSimulation.PopulateDataTo180DaysAgo
-- Description: Populates data up to 180 days ago
-- =============================================
CREATE OR REPLACE PROCEDURE dataload.populate_data_to_180_days_ago(
    p_average_number_of_customer_orders_per_day integer,
    p_saturday_percentage_of_normal_work_day integer,
    p_sunday_percentage_of_normal_work_day integer,
    p_is_silent_mode boolean DEFAULT false,
    p_are_dates_printed boolean DEFAULT true
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_current_maximum_date date;
    v_starting_date date;
    v_ending_date date;
BEGIN
    SELECT COALESCE(MAX(orderdate), '2019-12-31'::date) INTO v_current_maximum_date
    FROM sales.orders;
    
    v_starting_date := v_current_maximum_date + INTERVAL '1 day';
    v_ending_date := (NOW() - INTERVAL '180 days')::date;
    
    IF v_starting_date > v_ending_date THEN
        RAISE NOTICE 'No data to populate';
        RETURN;
    END IF;
    
    CALL dataload.daily_process_to_create_history(
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

-- =============================================
-- Procedure: DataLoadSimulation.PopulateOneDayOfHistory
-- Description: Populates one day of history
-- =============================================
CREATE OR REPLACE PROCEDURE dataload.populate_one_day_of_history(
    p_date date,
    p_average_number_of_customer_orders_per_day integer,
    p_saturday_percentage_of_normal_work_day integer,
    p_sunday_percentage_of_normal_work_day integer,
    p_is_silent_mode boolean DEFAULT false,
    p_are_dates_printed boolean DEFAULT true
)
LANGUAGE plpgsql
AS $$
BEGIN
    CALL dataload.daily_process_to_create_history(
        p_start_date := p_date,
        p_end_date := p_date,
        p_average_number_of_customer_orders_per_day := p_average_number_of_customer_orders_per_day,
        p_saturday_percentage_of_normal_work_day := p_saturday_percentage_of_normal_work_day,
        p_sunday_percentage_of_normal_work_day := p_sunday_percentage_of_normal_work_day,
        p_update_custom_fields := false,
        p_is_silent_mode := p_is_silent_mode,
        p_are_dates_printed := p_are_dates_printed
    );
END;
$$;

-- =============================================
-- Procedure: DataLoadSimulation.DailyProcessToCreateHistory
-- Description: Main daily process to create historical data
-- =============================================
CREATE OR REPLACE PROCEDURE dataload.daily_process_to_create_history(
    p_start_date date,
    p_end_date date,
    p_average_number_of_customer_orders_per_day integer DEFAULT 30,
    p_saturday_percentage_of_normal_work_day integer DEFAULT 50,
    p_sunday_percentage_of_normal_work_day integer DEFAULT 0,
    p_update_custom_fields boolean DEFAULT false,
    p_is_silent_mode boolean DEFAULT false,
    p_are_dates_printed boolean DEFAULT true,
    p_min_yearly_growth_percent integer DEFAULT -5,
    p_max_yearly_growth_percent integer DEFAULT 15,
    p_min_seasonal_variation_percent integer DEFAULT -10,
    p_max_seasonal_variation_percent integer DEFAULT 30,
    p_max_daily_variation_percent integer DEFAULT 20
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_current_date_time timestamp;
    v_end_of_time timestamp := '9999-12-31 23:59:59.999999'::timestamp;
    v_starting_when timestamp;
    v_old_number_of_customer_orders integer;
    v_number_of_customer_orders integer;
    v_is_weekday boolean;
    v_is_saturday boolean;
    v_is_sunday boolean;
    v_is_monday boolean;
    v_weekday integer;
    v_date_message text;
    v_current_year integer;
    v_current_season smallint;
    v_yearly_variation double precision;
    v_seasonal_variation double precision;
    v_x double precision;
    v_season_effect double precision;
    v_yearly_effect double precision;
    v_daily_effect double precision;
BEGIN
    v_current_date_time := p_start_date::timestamp;
    
    -- Compute average number of customer orders from last year
    IF EXISTS (SELECT 1 FROM sales.orders) THEN
        SELECT AVG(order_count)::integer INTO v_old_number_of_customer_orders
        FROM (
            SELECT COUNT(*) AS order_count
            FROM sales.orders
            WHERE EXTRACT(YEAR FROM orderdate) = EXTRACT(YEAR FROM (SELECT MAX(orderdate) FROM sales.orders))
            AND EXTRACT(DOW FROM orderdate) NOT IN (0, 6)
            AND backorderorderid IS NULL
            GROUP BY orderdate
        ) t;
    ELSE
        v_old_number_of_customer_orders := p_average_number_of_customer_orders_per_day;
    END IF;
    
    IF v_old_number_of_customer_orders IS NULL OR v_old_number_of_customer_orders = 0 THEN
        v_old_number_of_customer_orders := p_average_number_of_customer_orders_per_day;
    END IF;
    
    -- Compute seasonal variation for each year
    v_current_year := EXTRACT(YEAR FROM p_start_date)::integer;
    WHILE v_current_year <= EXTRACT(YEAR FROM p_end_date)::integer LOOP
        v_current_season := 1;
        v_yearly_variation := 1 + (p_min_yearly_growth_percent + random() * (p_max_yearly_growth_percent - p_min_yearly_growth_percent)) / 100.0;
        
        WHILE v_current_season <= 4 LOOP
            IF NOT EXISTS (SELECT 1 FROM dataload.seasonvariation WHERE year = v_current_year AND season = v_current_season) THEN
                v_seasonal_variation := 1 + (p_min_seasonal_variation_percent + random() * (p_max_seasonal_variation_percent - p_min_seasonal_variation_percent)) / 100.0;
                IF v_current_season % 2 = 1 THEN
                    v_seasonal_variation := 1 / v_seasonal_variation;
                END IF;
                
                INSERT INTO dataload.seasonvariation (year, season, yearlyvariation, seasonalvariation)
                VALUES (v_current_year, v_current_season, v_yearly_variation, v_seasonal_variation);
            END IF;
            v_current_season := v_current_season + 1;
        END LOOP;
        v_current_year := v_current_year + 1;
    END LOOP;
    
    -- Deactivate temporal tables
    CALL dataload.deactivate_temporal_tables_before_data_load();
    
    -- Process each day
    WHILE v_current_date_time::date <= p_end_date LOOP
        v_date_message := 'Processing ' || to_char(v_current_date_time, 'Dy Mon DD, YYYY') ||
                          ' - ' || (p_end_date - v_current_date_time::date)::text || ' Days Remaining';
        
        IF p_are_dates_printed OR NOT p_is_silent_mode THEN
            RAISE NOTICE '%', v_date_message;
        END IF;
        
        -- Compute number of orders
        v_current_year := EXTRACT(YEAR FROM v_current_date_time)::integer;
        v_current_season := CEILING(EXTRACT(MONTH FROM v_current_date_time) / 3.0)::smallint;
        
        SELECT seasonalvariation, yearlyvariation INTO v_seasonal_variation, v_yearly_variation
        FROM dataload.seasonvariation
        WHERE year = v_current_year AND season = v_current_season;
        
        v_x := EXTRACT(DAY FROM v_current_date_time - make_date(v_current_year, (v_current_season * 3) - 2, 1)) / 90.0;
        IF v_x > 1 THEN v_x := 1; END IF;
        
        v_season_effect := (SIN(2 * 3.1415926 * (v_x - 0.25)) + 1) / 2;
        v_season_effect := ((v_seasonal_variation - 1) * v_season_effect) + 1;
        
        v_yearly_effect := 1 + (v_yearly_variation - 1) * (EXTRACT(DOY FROM v_current_date_time) / 183.0);
        
        v_daily_effect := random();
        IF v_daily_effect < 0.5 THEN v_daily_effect := 0 - v_daily_effect; END IF;
        v_daily_effect := 1 + v_daily_effect * (p_max_daily_variation_percent / 100.0);
        
        v_number_of_customer_orders := (v_old_number_of_customer_orders * v_daily_effect * v_season_effect * v_yearly_effect)::integer;
        
        -- Calculate day of week
        v_weekday := EXTRACT(DOW FROM v_current_date_time)::integer;
        v_is_saturday := (v_weekday = 6);
        v_is_sunday := (v_weekday = 0);
        v_is_monday := (v_weekday = 1);
        v_is_weekday := NOT (v_is_saturday OR v_is_sunday);
        
        -- Adjust orders for weekends
        IF v_is_saturday THEN
            v_number_of_customer_orders := (v_number_of_customer_orders * p_saturday_percentage_of_normal_work_day / 100)::integer;
        ELSIF v_is_sunday THEN
            v_number_of_customer_orders := (v_number_of_customer_orders * p_sunday_percentage_of_normal_work_day / 100)::integer;
        END IF;
        
        -- Process daily activities
        v_starting_when := v_current_date_time + INTERVAL '10 hours';
        
        IF NOT p_is_silent_mode THEN
            RAISE NOTICE '% - Creating % Customer Orders', v_date_message, v_number_of_customer_orders;
        END IF;
        
        -- Create customer orders
        CALL dataload.create_customer_orders(v_current_date_time::date, v_starting_when, v_end_of_time, v_number_of_customer_orders, p_is_silent_mode);
        
        -- Pick stock for orders
        v_starting_when := v_current_date_time + INTERVAL '11 hours';
        CALL dataload.pick_stock_for_customer_orders(v_current_date_time::date, v_starting_when, v_end_of_time, p_is_silent_mode);
        
        -- Invoice picked orders
        v_starting_when := v_current_date_time + INTERVAL '12 hours';
        CALL dataload.invoice_picked_orders(v_current_date_time::date, v_starting_when, v_end_of_time, p_is_silent_mode);
        
        -- Move to next day
        v_current_date_time := v_current_date_time + INTERVAL '1 day';
        
        -- Update baseline at year boundary
        IF EXTRACT(DAY FROM v_current_date_time) = 1 AND EXTRACT(MONTH FROM v_current_date_time) = 1 THEN
            v_old_number_of_customer_orders := (v_old_number_of_customer_orders * v_yearly_effect)::integer;
        END IF;
        
        COMMIT;
    END LOOP;
    
    -- Reactivate temporal tables
    CALL dataload.reactivate_temporal_tables_after_data_load();
    
EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'Error in daily process: %', SQLERRM;
        CALL dataload.reactivate_temporal_tables_after_data_load();
        RAISE;
END;
$$;

-- =============================================
-- Procedure: DataLoadSimulation.CreateCustomerOrders
-- Description: Creates customer orders for a given day
-- =============================================
CREATE OR REPLACE PROCEDURE dataload.create_customer_orders(
    p_current_date date,
    p_starting_when timestamp,
    p_end_of_time timestamp,
    p_number_of_orders integer,
    p_is_silent_mode boolean DEFAULT false
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_order_id integer;
    v_customer_id integer;
    v_salesperson_id integer;
    v_order_count integer := 0;
    v_stock_item_id integer;
    v_quantity integer;
    v_unit_price numeric(18,2);
    v_tax_rate numeric(18,3);
    v_order_time timestamp;
    v_contact_person_id integer;
    v_expected_delivery_date date;
BEGIN
    WHILE v_order_count < p_number_of_orders LOOP
        -- Get random customer
        SELECT customerid, primarycontactpersonid INTO v_customer_id, v_contact_person_id
        FROM sales.customers
        ORDER BY random()
        LIMIT 1;
        
        -- Get random salesperson
        SELECT personid INTO v_salesperson_id
        FROM application.people
        WHERE issalesperson = true
        ORDER BY random()
        LIMIT 1;
        
        -- Calculate order time with some randomness
        v_order_time := p_starting_when + (random() * INTERVAL '6 hours');
        v_expected_delivery_date := p_current_date + (floor(random() * 7) + 1)::integer;
        
        -- Get next order ID
        v_order_id := nextval('sequences.orderid');
        
        -- Insert order
        INSERT INTO sales.orders (
            orderid, customerid, salespersonpersonid, pickedbypersonid, contactpersonid,
            backorderorderid, orderdate, expecteddeliverydate, customerpurchaseordernumber,
            isundersupplybackordered, comments, deliveryinstructions, internalcomments,
            pickingcompletedwhen, lasteditedby, lasteditedwhen
        )
        VALUES (
            v_order_id, v_customer_id, v_salesperson_id, NULL, v_contact_person_id,
            NULL, p_current_date, v_expected_delivery_date, 'PO-' || v_order_id::text,
            false, NULL, NULL, NULL,
            NULL, 1, v_order_time
        );
        
        -- Add 1-5 order lines
        FOR i IN 1..floor(random() * 5 + 1)::integer LOOP
            SELECT si.stockitemid, si.unitprice, si.taxrate INTO v_stock_item_id, v_unit_price, v_tax_rate
            FROM warehouse.stockitems si
            ORDER BY random()
            LIMIT 1;
            
            v_quantity := floor(random() * 10 + 1)::integer;
            
            INSERT INTO sales.orderlines (
                orderid, stockitemid, description, packagetypeid, quantity, unitprice,
                taxrate, pickedquantity, pickingcompletedwhen, lasteditedby, lasteditedwhen
            )
            SELECT 
                v_order_id, v_stock_item_id, si.stockitemname, si.unitpackageid, v_quantity,
                v_unit_price, v_tax_rate, 0, NULL, 1, v_order_time
            FROM warehouse.stockitems si
            WHERE si.stockitemid = v_stock_item_id;
        END LOOP;
        
        v_order_count := v_order_count + 1;
    END LOOP;
END;
$$;

-- =============================================
-- Procedure: DataLoadSimulation.PickStockForCustomerOrders
-- Description: Picks stock for customer orders
-- =============================================
CREATE OR REPLACE PROCEDURE dataload.pick_stock_for_customer_orders(
    p_current_date date,
    p_starting_when timestamp,
    p_end_of_time timestamp,
    p_is_silent_mode boolean DEFAULT false
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_picker_id integer;
BEGIN
    -- Get a random picker
    SELECT personid INTO v_picker_id
    FROM application.people
    WHERE isemployee = true
    ORDER BY random()
    LIMIT 1;
    
    -- Update order lines to mark as picked
    UPDATE sales.orderlines ol
    SET pickedquantity = quantity,
        pickingcompletedwhen = p_starting_when + (random() * INTERVAL '2 hours'),
        lasteditedby = v_picker_id,
        lasteditedwhen = p_starting_when + (random() * INTERVAL '2 hours')
    FROM sales.orders o
    WHERE ol.orderid = o.orderid
    AND o.orderdate = p_current_date
    AND ol.pickingcompletedwhen IS NULL;
    
    -- Update orders to mark picking completed
    UPDATE sales.orders
    SET pickedbypersonid = v_picker_id,
        pickingcompletedwhen = p_starting_when + (random() * INTERVAL '2 hours'),
        lasteditedby = v_picker_id,
        lasteditedwhen = p_starting_when + (random() * INTERVAL '2 hours')
    WHERE orderdate = p_current_date
    AND pickingcompletedwhen IS NULL;
END;
$$;

-- =============================================
-- Procedure: DataLoadSimulation.InvoicePickedOrders
-- Description: Creates invoices for picked orders
-- =============================================
CREATE OR REPLACE PROCEDURE dataload.invoice_picked_orders(
    p_current_date date,
    p_starting_when timestamp,
    p_end_of_time timestamp,
    p_is_silent_mode boolean DEFAULT false
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_invoicer_id integer;
    v_packer_id integer;
    v_order_id integer;
    v_invoice_id integer;
    v_customer_id integer;
    v_bill_to_customer_id integer;
    v_delivery_method_id integer;
    v_contact_person_id integer;
    v_accounts_person_id integer;
    v_salesperson_id integer;
    v_total_dry_items integer;
    v_total_chiller_items integer;
    v_delivery_run varchar(5);
    v_run_position varchar(6);
    v_delivery_instructions text;
    v_stock_issue_type_id integer;
    v_customer_invoice_type_id integer;
    rec RECORD;
BEGIN
    -- Get random invoicer and packer
    SELECT personid INTO v_invoicer_id
    FROM application.people WHERE isemployee = true ORDER BY random() LIMIT 1;
    
    SELECT personid INTO v_packer_id
    FROM application.people WHERE isemployee = true ORDER BY random() LIMIT 1;
    
    -- Get transaction type IDs
    SELECT transactiontypeid INTO v_stock_issue_type_id
    FROM application.transactiontypes WHERE transactiontypename = 'Stock Issue';
    
    SELECT transactiontypeid INTO v_customer_invoice_type_id
    FROM application.transactiontypes WHERE transactiontypename = 'Customer Invoice';
    
    -- Process each picked order that hasn't been invoiced
    FOR rec IN 
        SELECT o.orderid, o.customerid, o.contactpersonid, o.salespersonpersonid,
               o.customerpurchaseordernumber,
               c.billtocustomerid, c.deliverymethodid, c.deliveryrun, c.runposition,
               c.deliveryaddressline1, c.deliveryaddressline2
        FROM sales.orders o
        INNER JOIN sales.customers c ON o.customerid = c.customerid
        WHERE o.orderdate = p_current_date
        AND o.pickingcompletedwhen IS NOT NULL
        AND NOT EXISTS (SELECT 1 FROM sales.invoices i WHERE i.orderid = o.orderid)
    LOOP
        v_invoice_id := nextval('sequences.invoiceid');
        
        -- Get accounts person from bill-to customer
        SELECT primarycontactpersonid INTO v_accounts_person_id
        FROM sales.customers WHERE customerid = rec.billtocustomerid;
        
        -- Calculate totals
        SELECT 
            COALESCE(SUM(CASE WHEN si.ischillerstock THEN 0 ELSE 1 END), 0),
            COALESCE(SUM(CASE WHEN si.ischillerstock THEN 1 ELSE 0 END), 0)
        INTO v_total_dry_items, v_total_chiller_items
        FROM sales.orderlines ol
        INNER JOIN warehouse.stockitems si ON ol.stockitemid = si.stockitemid
        WHERE ol.orderid = rec.orderid;
        
        -- Insert invoice
        INSERT INTO sales.invoices (
            invoiceid, customerid, billtocustomerid, orderid, deliverymethodid,
            contactpersonid, accountspersonid, salespersonpersonid, packedbypersonid,
            invoicedate, customerpurchaseordernumber, iscreditnote, creditnotereason,
            comments, deliveryinstructions, internalcomments, totaldryitems, totalchilleritems,
            deliveryrun, runposition, returneddeliverydata, lasteditedby, lasteditedwhen
        )
        VALUES (
            v_invoice_id, rec.customerid, rec.billtocustomerid, rec.orderid, rec.deliverymethodid,
            rec.contactpersonid, v_accounts_person_id, rec.salespersonpersonid, v_packer_id,
            p_current_date, rec.customerpurchaseordernumber, false, NULL,
            NULL, COALESCE(rec.deliveryaddressline1, '') || ', ' || COALESCE(rec.deliveryaddressline2, ''), NULL,
            v_total_dry_items, v_total_chiller_items, rec.deliveryrun, rec.runposition,
            jsonb_build_object('Events', jsonb_build_array(
                jsonb_build_object('Event', 'Ready for collection', 'EventTime', to_char(p_starting_when, 'YYYY-MM-DD"T"HH24:MI:SS'))
            )),
            v_invoicer_id, p_starting_when
        );
        
        -- Insert invoice lines
        INSERT INTO sales.invoicelines (
            invoiceid, stockitemid, description, packagetypeid, quantity, unitprice,
            taxrate, taxamount, lineprofit, extendedprice, lasteditedby, lasteditedwhen
        )
        SELECT 
            v_invoice_id, ol.stockitemid, ol.description, ol.packagetypeid,
            ol.pickedquantity, ol.unitprice, ol.taxrate,
            ROUND(ol.pickedquantity * ol.unitprice * ol.taxrate / 100.0, 2),
            ROUND(ol.pickedquantity * (ol.unitprice - COALESCE(sih.lastcostprice, 0)), 2),
            ROUND(ol.pickedquantity * ol.unitprice, 2) + ROUND(ol.pickedquantity * ol.unitprice * ol.taxrate / 100.0, 2),
            v_invoicer_id, p_starting_when
        FROM sales.orderlines ol
        INNER JOIN warehouse.stockitems si ON ol.stockitemid = si.stockitemid
        LEFT JOIN warehouse.stockitemholdings sih ON si.stockitemid = sih.stockitemid
        WHERE ol.orderid = rec.orderid;
        
        -- Insert stock transactions
        INSERT INTO warehouse.stockitemtransactions (
            stockitemid, transactiontypeid, customerid, invoiceid, supplierid,
            purchaseorderid, transactionoccurredwhen, quantity, lasteditedby, lasteditedwhen
        )
        SELECT 
            il.stockitemid, v_stock_issue_type_id, rec.customerid, v_invoice_id, NULL, NULL,
            p_starting_when, 0 - il.quantity, v_invoicer_id, p_starting_when
        FROM sales.invoicelines il
        WHERE il.invoiceid = v_invoice_id;
        
        -- Update stock holdings
        UPDATE warehouse.stockitemholdings sih
        SET quantityonhand = sih.quantityonhand - totals.total_quantity,
            lasteditedby = v_invoicer_id,
            lasteditedwhen = p_starting_when
        FROM (
            SELECT il.stockitemid, SUM(il.quantity) AS total_quantity
            FROM sales.invoicelines il
            WHERE il.invoiceid = v_invoice_id
            GROUP BY il.stockitemid
        ) totals
        WHERE sih.stockitemid = totals.stockitemid;
        
        -- Insert customer transaction
        INSERT INTO sales.customertransactions (
            customerid, transactiontypeid, invoiceid, paymentmethodid,
            transactiondate, amountexcludingtax, taxamount, transactionamount,
            outstandingbalance, finalizationdate, lasteditedby, lasteditedwhen
        )
        SELECT 
            rec.billtocustomerid, v_customer_invoice_type_id, v_invoice_id, NULL,
            p_current_date,
            SUM(il.extendedprice - il.taxamount),
            SUM(il.taxamount),
            SUM(il.extendedprice),
            SUM(il.extendedprice),
            NULL, v_invoicer_id, p_starting_when
        FROM sales.invoicelines il
        WHERE il.invoiceid = v_invoice_id
        GROUP BY il.invoiceid;
    END LOOP;
END;
$$;

COMMENT ON PROCEDURE dataload.populate_data_to_current_date(integer, integer, integer, boolean, boolean) IS 
'Main procedure to populate data from last order date to current date';

COMMENT ON PROCEDURE dataload.daily_process_to_create_history(date, date, integer, integer, integer, boolean, boolean, boolean, integer, integer, integer, integer, integer) IS 
'Main daily process to create historical data with seasonal and yearly variations';

COMMENT ON PROCEDURE dataload.deactivate_temporal_tables_before_data_load() IS 
'Disables temporal table triggers before data load';

COMMENT ON PROCEDURE dataload.reactivate_temporal_tables_after_data_load() IS 
'Re-enables temporal table triggers after data load';
