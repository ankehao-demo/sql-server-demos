-- Wide World Importers DW PostgreSQL Migration
-- Phase 5: ETL and Analytics Migration
-- File: 001-helper-procedures.sql
-- Description: Helper procedures for ETL operations (GetLineageKey, GetLastETLCutoffTime, PopulateDateDimensionForYear)

-- =============================================
-- Procedure: integration.get_last_etl_cutoff_time
-- Description: Gets the last ETL cutoff time for a given table
-- =============================================
CREATE OR REPLACE FUNCTION integration.get_last_etl_cutoff_time(
    p_table_name varchar(128)
)
RETURNS timestamp
LANGUAGE plpgsql
AS $$
DECLARE
    v_cutoff_time timestamp;
BEGIN
    SELECT cutoff_time INTO v_cutoff_time
    FROM integration.etl_cutoff
    WHERE table_name = p_table_name;
    
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Invalid ETL table name: %', p_table_name;
    END IF;
    
    RETURN v_cutoff_time;
END;
$$;

COMMENT ON FUNCTION integration.get_last_etl_cutoff_time(varchar) IS 
'Gets the last ETL cutoff time for a given table';

-- =============================================
-- Procedure: integration.get_lineage_key
-- Description: Creates a new lineage record and returns the lineage key
-- =============================================
CREATE OR REPLACE FUNCTION integration.get_lineage_key(
    p_table_name varchar(128),
    p_new_cutoff_time timestamp
)
RETURNS integer
LANGUAGE plpgsql
AS $$
DECLARE
    v_lineage_key integer;
    v_data_load_started timestamp := CURRENT_TIMESTAMP;
BEGIN
    INSERT INTO integration.lineage (
        data_load_started,
        table_name,
        data_load_completed,
        was_successful,
        source_system_cutoff_time
    )
    VALUES (
        v_data_load_started,
        p_table_name,
        NULL,
        false,
        p_new_cutoff_time
    )
    RETURNING lineage_key INTO v_lineage_key;
    
    RETURN v_lineage_key;
END;
$$;

COMMENT ON FUNCTION integration.get_lineage_key(varchar, timestamp) IS 
'Creates a new lineage record and returns the lineage key for ETL tracking';

-- =============================================
-- Function: integration.generate_date_dimension_columns
-- Description: Generates all columns for a single date in the date dimension
-- =============================================
CREATE OR REPLACE FUNCTION integration.generate_date_dimension_columns(
    p_date date
)
RETURNS TABLE (
    date_value date,
    date_key integer,
    day_number integer,
    day_name varchar(10),
    day_of_year varchar(10),
    day_of_year_number integer,
    day_of_week varchar(10),
    day_of_week_number integer,
    week_of_year varchar(10),
    month_name varchar(10),
    short_month varchar(3),
    quarter_name varchar(10),
    half_of_year varchar(20),
    beginning_of_month date,
    beginning_of_quarter date,
    beginning_of_half_year date,
    beginning_of_year date,
    beginning_of_month_label varchar(40),
    beginning_of_month_label_short varchar(40),
    beginning_of_quarter_label varchar(40),
    beginning_of_quarter_label_short varchar(40),
    beginning_of_half_year_label varchar(40),
    beginning_of_half_year_label_short varchar(40),
    beginning_of_year_label varchar(40),
    beginning_of_year_label_short varchar(40),
    calendar_day_label varchar(40),
    calendar_day_label_short varchar(40),
    calendar_week_number integer,
    calendar_week_label varchar(40),
    calendar_month_number integer,
    calendar_month_label varchar(40),
    calendar_month_year_label varchar(40),
    calendar_quarter_number integer,
    calendar_quarter_label varchar(40),
    calendar_quarter_year_label varchar(40),
    calendar_half_of_year_number integer,
    calendar_half_of_year_label varchar(40),
    calendar_year_half_of_year_label varchar(40),
    calendar_year integer,
    calendar_year_label varchar(40),
    fiscal_month_number integer,
    fiscal_month_label varchar(40),
    fiscal_quarter_number integer,
    fiscal_quarter_label varchar(40),
    fiscal_half_of_year_number integer,
    fiscal_half_of_year_label varchar(40),
    fiscal_year integer,
    fiscal_year_label varchar(40),
    date_key_int integer,
    year_week_key integer,
    year_month_key integer,
    year_quarter_key integer,
    year_half_of_year_key integer,
    year_key integer,
    beginning_of_month_key integer,
    beginning_of_quarter_key integer,
    beginning_of_half_year_key integer,
    beginning_of_year_key integer,
    fiscal_year_month_key integer,
    fiscal_year_quarter_key integer,
    fiscal_year_half_of_year_key integer,
    iso_week_number integer
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_year integer := EXTRACT(YEAR FROM p_date);
    v_month integer := EXTRACT(MONTH FROM p_date);
    v_day integer := EXTRACT(DAY FROM p_date);
    v_quarter integer := EXTRACT(QUARTER FROM p_date);
    v_day_of_week integer := EXTRACT(DOW FROM p_date);
    v_day_of_year integer := EXTRACT(DOY FROM p_date);
    v_week_of_year integer := EXTRACT(WEEK FROM p_date);
    v_iso_week integer := EXTRACT(ISOYEAR FROM p_date);
    v_half_of_year integer;
    v_fiscal_month integer;
    v_fiscal_quarter integer;
    v_fiscal_half integer;
    v_fiscal_year integer;
    v_beginning_of_month date;
    v_beginning_of_quarter date;
    v_beginning_of_half_year date;
    v_beginning_of_year date;
BEGIN
    -- Calculate half of year
    v_half_of_year := CASE WHEN v_month <= 6 THEN 1 ELSE 2 END;
    
    -- Calculate fiscal periods (assuming fiscal year starts July 1)
    v_fiscal_month := CASE WHEN v_month >= 7 THEN v_month - 6 ELSE v_month + 6 END;
    v_fiscal_quarter := CASE 
        WHEN v_month IN (7, 8, 9) THEN 1
        WHEN v_month IN (10, 11, 12) THEN 2
        WHEN v_month IN (1, 2, 3) THEN 3
        ELSE 4
    END;
    v_fiscal_half := CASE WHEN v_month >= 7 THEN 1 ELSE 2 END;
    v_fiscal_year := CASE WHEN v_month >= 7 THEN v_year + 1 ELSE v_year END;
    
    -- Calculate beginning dates
    v_beginning_of_month := DATE_TRUNC('month', p_date)::date;
    v_beginning_of_quarter := DATE_TRUNC('quarter', p_date)::date;
    v_beginning_of_half_year := CASE 
        WHEN v_month <= 6 THEN make_date(v_year, 1, 1)
        ELSE make_date(v_year, 7, 1)
    END;
    v_beginning_of_year := DATE_TRUNC('year', p_date)::date;
    
    RETURN QUERY SELECT
        p_date,
        (v_year * 10000 + v_month * 100 + v_day)::integer,
        v_day,
        TO_CHAR(p_date, 'Day'),
        'Day ' || v_day_of_year::text,
        v_day_of_year,
        TO_CHAR(p_date, 'Day'),
        v_day_of_week + 1,
        'Week ' || v_week_of_year::text,
        TO_CHAR(p_date, 'Month'),
        TO_CHAR(p_date, 'Mon'),
        'Q' || v_quarter::text,
        CASE WHEN v_half_of_year = 1 THEN 'First Half' ELSE 'Second Half' END,
        v_beginning_of_month,
        v_beginning_of_quarter,
        v_beginning_of_half_year,
        v_beginning_of_year,
        TO_CHAR(v_beginning_of_month, 'Month DD, YYYY'),
        TO_CHAR(v_beginning_of_month, 'Mon DD, YYYY'),
        TO_CHAR(v_beginning_of_quarter, 'Month DD, YYYY'),
        TO_CHAR(v_beginning_of_quarter, 'Mon DD, YYYY'),
        TO_CHAR(v_beginning_of_half_year, 'Month DD, YYYY'),
        TO_CHAR(v_beginning_of_half_year, 'Mon DD, YYYY'),
        TO_CHAR(v_beginning_of_year, 'Month DD, YYYY'),
        TO_CHAR(v_beginning_of_year, 'Mon DD, YYYY'),
        TO_CHAR(p_date, 'Month DD, YYYY'),
        TO_CHAR(p_date, 'Mon DD, YYYY'),
        v_week_of_year,
        'CY' || v_year::text || '-W' || LPAD(v_week_of_year::text, 2, '0'),
        v_month,
        TO_CHAR(p_date, 'Month'),
        TO_CHAR(p_date, 'Mon YYYY'),
        v_quarter,
        'Q' || v_quarter::text,
        'CY' || v_year::text || '-Q' || v_quarter::text,
        v_half_of_year,
        'H' || v_half_of_year::text,
        'CY' || v_year::text || '-H' || v_half_of_year::text,
        v_year,
        'CY' || v_year::text,
        v_fiscal_month,
        'FM' || v_fiscal_month::text,
        v_fiscal_quarter,
        'FQ' || v_fiscal_quarter::text,
        v_fiscal_half,
        'FH' || v_fiscal_half::text,
        v_fiscal_year,
        'FY' || v_fiscal_year::text,
        (v_year * 10000 + v_month * 100 + v_day)::integer,
        (v_year * 100 + v_week_of_year)::integer,
        (v_year * 100 + v_month)::integer,
        (v_year * 10 + v_quarter)::integer,
        (v_year * 10 + v_half_of_year)::integer,
        v_year,
        (EXTRACT(YEAR FROM v_beginning_of_month) * 10000 + EXTRACT(MONTH FROM v_beginning_of_month) * 100 + EXTRACT(DAY FROM v_beginning_of_month))::integer,
        (EXTRACT(YEAR FROM v_beginning_of_quarter) * 10000 + EXTRACT(MONTH FROM v_beginning_of_quarter) * 100 + EXTRACT(DAY FROM v_beginning_of_quarter))::integer,
        (EXTRACT(YEAR FROM v_beginning_of_half_year) * 10000 + EXTRACT(MONTH FROM v_beginning_of_half_year) * 100 + EXTRACT(DAY FROM v_beginning_of_half_year))::integer,
        (EXTRACT(YEAR FROM v_beginning_of_year) * 10000 + EXTRACT(MONTH FROM v_beginning_of_year) * 100 + EXTRACT(DAY FROM v_beginning_of_year))::integer,
        (v_fiscal_year * 100 + v_fiscal_month)::integer,
        (v_fiscal_year * 10 + v_fiscal_quarter)::integer,
        (v_fiscal_year * 10 + v_fiscal_half)::integer,
        EXTRACT(WEEK FROM p_date)::integer;
END;
$$;

COMMENT ON FUNCTION integration.generate_date_dimension_columns(date) IS 
'Generates all columns for a single date in the date dimension';

-- =============================================
-- Procedure: integration.populate_date_dimension_for_year
-- Description: Populates the date dimension for a given year
-- =============================================
CREATE OR REPLACE PROCEDURE integration.populate_date_dimension_for_year(
    p_year_number integer
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_date_counter date;
    v_end_date date;
BEGIN
    v_date_counter := make_date(p_year_number, 1, 1);
    v_end_date := make_date(p_year_number, 12, 31);
    
    WHILE v_date_counter <= v_end_date LOOP
        IF NOT EXISTS (SELECT 1 FROM dimension.date WHERE date = v_date_counter) THEN
            INSERT INTO dimension.date (
                date, date_key, day_number, day, day_of_year, day_of_year_number,
                day_of_week, day_of_week_number, week_of_year, month, short_month,
                quarter, half_of_year, beginning_of_month, beginning_of_quarter,
                beginning_of_half_year, beginning_of_year, beginning_of_month_label,
                beginning_of_month_label_short, beginning_of_quarter_label,
                beginning_of_quarter_label_short, beginning_of_half_year_label,
                beginning_of_half_year_label_short, beginning_of_year_label,
                beginning_of_year_label_short, calendar_day_label, calendar_day_label_short,
                calendar_week_number, calendar_week_label, calendar_month_number,
                calendar_month_label, calendar_month_year_label, calendar_quarter_number,
                calendar_quarter_label, calendar_quarter_year_label, calendar_half_of_year_number,
                calendar_half_of_year_label, calendar_year_half_of_year_label, calendar_year,
                calendar_year_label, fiscal_month_number, fiscal_month_label,
                fiscal_quarter_number, fiscal_quarter_label, fiscal_half_of_year_number,
                fiscal_half_of_year_label, fiscal_year, fiscal_year_label,
                iso_week_number
            )
            SELECT 
                date_value, date_key, day_number, day_name, day_of_year, day_of_year_number,
                day_of_week, day_of_week_number, week_of_year, month_name, short_month,
                quarter_name, half_of_year, beginning_of_month, beginning_of_quarter,
                beginning_of_half_year, beginning_of_year, beginning_of_month_label,
                beginning_of_month_label_short, beginning_of_quarter_label,
                beginning_of_quarter_label_short, beginning_of_half_year_label,
                beginning_of_half_year_label_short, beginning_of_year_label,
                beginning_of_year_label_short, calendar_day_label, calendar_day_label_short,
                calendar_week_number, calendar_week_label, calendar_month_number,
                calendar_month_label, calendar_month_year_label, calendar_quarter_number,
                calendar_quarter_label, calendar_quarter_year_label, calendar_half_of_year_number,
                calendar_half_of_year_label, calendar_year_half_of_year_label, calendar_year,
                calendar_year_label, fiscal_month_number, fiscal_month_label,
                fiscal_quarter_number, fiscal_quarter_label, fiscal_half_of_year_number,
                fiscal_half_of_year_label, fiscal_year, fiscal_year_label,
                iso_week_number
            FROM integration.generate_date_dimension_columns(v_date_counter);
        END IF;
        
        v_date_counter := v_date_counter + INTERVAL '1 day';
    END LOOP;
END;
$$;

COMMENT ON PROCEDURE integration.populate_date_dimension_for_year(integer) IS 
'Populates the date dimension for a given year';
