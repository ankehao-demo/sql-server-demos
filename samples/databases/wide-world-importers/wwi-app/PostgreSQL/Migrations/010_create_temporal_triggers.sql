-- Wide World Importers PostgreSQL Migration
-- Script 010: Create Temporal Table Triggers
-- Migrated from SQL Server to PostgreSQL
-- 
-- SQL Server uses SYSTEM_VERSIONING with PERIOD FOR SYSTEM_TIME
-- PostgreSQL implements temporal tables using triggers that:
-- 1. Automatically set valid_from on INSERT
-- 2. Archive old rows to history table on UPDATE
-- 3. Archive rows to history table on DELETE

-- Generic function to handle temporal table versioning
CREATE OR REPLACE FUNCTION temporal_table_trigger()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
    v_archive_table TEXT;
    v_now TIMESTAMP(6);
BEGIN
    v_now := CURRENT_TIMESTAMP;
    v_archive_table := TG_TABLE_SCHEMA || '.' || TG_TABLE_NAME || '_archive';

    IF TG_OP = 'INSERT' THEN
        -- Set valid_from to current timestamp if not already set
        IF NEW.valid_from IS NULL OR NEW.valid_from = '0001-01-01'::TIMESTAMP THEN
            NEW.valid_from := v_now;
        END IF;
        -- Set valid_to to end of time
        NEW.valid_to := '9999-12-31 23:59:59.999999'::TIMESTAMP;
        RETURN NEW;

    ELSIF TG_OP = 'UPDATE' THEN
        -- Archive the old row with valid_to set to now
        EXECUTE format(
            'INSERT INTO %I.%I SELECT ($1).*',
            TG_TABLE_SCHEMA,
            TG_TABLE_NAME || '_archive'
        ) USING OLD;
        
        -- Update the valid_to of the archived row
        EXECUTE format(
            'UPDATE %I.%I SET valid_to = $1 WHERE valid_from = $2 AND valid_to = $3',
            TG_TABLE_SCHEMA,
            TG_TABLE_NAME || '_archive'
        ) USING v_now, OLD.valid_from, OLD.valid_to;

        -- Set new valid_from to current timestamp
        NEW.valid_from := v_now;
        NEW.valid_to := '9999-12-31 23:59:59.999999'::TIMESTAMP;
        RETURN NEW;

    ELSIF TG_OP = 'DELETE' THEN
        -- Archive the deleted row
        EXECUTE format(
            'INSERT INTO %I.%I SELECT ($1).*',
            TG_TABLE_SCHEMA,
            TG_TABLE_NAME || '_archive'
        ) USING OLD;
        
        -- Update the valid_to of the archived row
        EXECUTE format(
            'UPDATE %I.%I SET valid_to = $1 WHERE valid_from = $2 AND valid_to = $3',
            TG_TABLE_SCHEMA,
            TG_TABLE_NAME || '_archive'
        ) USING v_now, OLD.valid_from, OLD.valid_to;
        
        RETURN OLD;
    END IF;

    RETURN NULL;
END;
$$;

COMMENT ON FUNCTION temporal_table_trigger() IS 'Generic trigger function for temporal table versioning';

-- Create triggers for Application schema temporal tables

-- Countries temporal trigger
DROP TRIGGER IF EXISTS tr_countries_temporal ON application.countries;
CREATE TRIGGER tr_countries_temporal
    BEFORE INSERT OR UPDATE OR DELETE ON application.countries
    FOR EACH ROW EXECUTE FUNCTION temporal_table_trigger();

-- State Provinces temporal trigger
DROP TRIGGER IF EXISTS tr_state_provinces_temporal ON application.state_provinces;
CREATE TRIGGER tr_state_provinces_temporal
    BEFORE INSERT OR UPDATE OR DELETE ON application.state_provinces
    FOR EACH ROW EXECUTE FUNCTION temporal_table_trigger();

-- Cities temporal trigger
DROP TRIGGER IF EXISTS tr_cities_temporal ON application.cities;
CREATE TRIGGER tr_cities_temporal
    BEFORE INSERT OR UPDATE OR DELETE ON application.cities
    FOR EACH ROW EXECUTE FUNCTION temporal_table_trigger();

-- People temporal trigger
DROP TRIGGER IF EXISTS tr_people_temporal ON application.people;
CREATE TRIGGER tr_people_temporal
    BEFORE INSERT OR UPDATE OR DELETE ON application.people
    FOR EACH ROW EXECUTE FUNCTION temporal_table_trigger();

-- Delivery Methods temporal trigger
DROP TRIGGER IF EXISTS tr_delivery_methods_temporal ON application.delivery_methods;
CREATE TRIGGER tr_delivery_methods_temporal
    BEFORE INSERT OR UPDATE OR DELETE ON application.delivery_methods
    FOR EACH ROW EXECUTE FUNCTION temporal_table_trigger();

-- Payment Methods temporal trigger
DROP TRIGGER IF EXISTS tr_payment_methods_temporal ON application.payment_methods;
CREATE TRIGGER tr_payment_methods_temporal
    BEFORE INSERT OR UPDATE OR DELETE ON application.payment_methods
    FOR EACH ROW EXECUTE FUNCTION temporal_table_trigger();

-- Transaction Types temporal trigger
DROP TRIGGER IF EXISTS tr_transaction_types_temporal ON application.transaction_types;
CREATE TRIGGER tr_transaction_types_temporal
    BEFORE INSERT OR UPDATE OR DELETE ON application.transaction_types
    FOR EACH ROW EXECUTE FUNCTION temporal_table_trigger();

-- Create triggers for Sales schema temporal tables

-- Buying Groups temporal trigger
DROP TRIGGER IF EXISTS tr_buying_groups_temporal ON sales.buying_groups;
CREATE TRIGGER tr_buying_groups_temporal
    BEFORE INSERT OR UPDATE OR DELETE ON sales.buying_groups
    FOR EACH ROW EXECUTE FUNCTION temporal_table_trigger();

-- Customer Categories temporal trigger
DROP TRIGGER IF EXISTS tr_customer_categories_temporal ON sales.customer_categories;
CREATE TRIGGER tr_customer_categories_temporal
    BEFORE INSERT OR UPDATE OR DELETE ON sales.customer_categories
    FOR EACH ROW EXECUTE FUNCTION temporal_table_trigger();

-- Customers temporal trigger
DROP TRIGGER IF EXISTS tr_customers_temporal ON sales.customers;
CREATE TRIGGER tr_customers_temporal
    BEFORE INSERT OR UPDATE OR DELETE ON sales.customers
    FOR EACH ROW EXECUTE FUNCTION temporal_table_trigger();

-- Create triggers for Purchasing schema temporal tables

-- Supplier Categories temporal trigger
DROP TRIGGER IF EXISTS tr_supplier_categories_temporal ON purchasing.supplier_categories;
CREATE TRIGGER tr_supplier_categories_temporal
    BEFORE INSERT OR UPDATE OR DELETE ON purchasing.supplier_categories
    FOR EACH ROW EXECUTE FUNCTION temporal_table_trigger();

-- Suppliers temporal trigger
DROP TRIGGER IF EXISTS tr_suppliers_temporal ON purchasing.suppliers;
CREATE TRIGGER tr_suppliers_temporal
    BEFORE INSERT OR UPDATE OR DELETE ON purchasing.suppliers
    FOR EACH ROW EXECUTE FUNCTION temporal_table_trigger();

-- Create triggers for Warehouse schema temporal tables

-- Colors temporal trigger
DROP TRIGGER IF EXISTS tr_colors_temporal ON warehouse.colors;
CREATE TRIGGER tr_colors_temporal
    BEFORE INSERT OR UPDATE OR DELETE ON warehouse.colors
    FOR EACH ROW EXECUTE FUNCTION temporal_table_trigger();

-- Package Types temporal trigger
DROP TRIGGER IF EXISTS tr_package_types_temporal ON warehouse.package_types;
CREATE TRIGGER tr_package_types_temporal
    BEFORE INSERT OR UPDATE OR DELETE ON warehouse.package_types
    FOR EACH ROW EXECUTE FUNCTION temporal_table_trigger();

-- Stock Groups temporal trigger
DROP TRIGGER IF EXISTS tr_stock_groups_temporal ON warehouse.stock_groups;
CREATE TRIGGER tr_stock_groups_temporal
    BEFORE INSERT OR UPDATE OR DELETE ON warehouse.stock_groups
    FOR EACH ROW EXECUTE FUNCTION temporal_table_trigger();

-- Stock Items temporal trigger
DROP TRIGGER IF EXISTS tr_stock_items_temporal ON warehouse.stock_items;
CREATE TRIGGER tr_stock_items_temporal
    BEFORE INSERT OR UPDATE OR DELETE ON warehouse.stock_items
    FOR EACH ROW EXECUTE FUNCTION temporal_table_trigger();

-- Cold Room Temperatures temporal trigger
DROP TRIGGER IF EXISTS tr_cold_room_temperatures_temporal ON warehouse.cold_room_temperatures;
CREATE TRIGGER tr_cold_room_temperatures_temporal
    BEFORE INSERT OR UPDATE OR DELETE ON warehouse.cold_room_temperatures
    FOR EACH ROW EXECUTE FUNCTION temporal_table_trigger();

-- Helper functions for temporal queries (equivalent to SQL Server FOR SYSTEM_TIME)

-- Function to query data AS OF a specific point in time
CREATE OR REPLACE FUNCTION temporal_as_of(
    p_schema_name TEXT,
    p_table_name TEXT,
    p_as_of_time TIMESTAMP
)
RETURNS SETOF RECORD
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY EXECUTE format(
        'SELECT * FROM %I.%I WHERE valid_from <= $1 AND valid_to > $1
         UNION ALL
         SELECT * FROM %I.%I WHERE valid_from <= $1 AND valid_to > $1',
        p_schema_name, p_table_name,
        p_schema_name, p_table_name || '_archive'
    ) USING p_as_of_time;
END;
$$;

-- Function to query data FROM start_time TO end_time
CREATE OR REPLACE FUNCTION temporal_from_to(
    p_schema_name TEXT,
    p_table_name TEXT,
    p_start_time TIMESTAMP,
    p_end_time TIMESTAMP
)
RETURNS SETOF RECORD
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY EXECUTE format(
        'SELECT * FROM %I.%I WHERE valid_from < $2 AND valid_to > $1
         UNION ALL
         SELECT * FROM %I.%I WHERE valid_from < $2 AND valid_to > $1',
        p_schema_name, p_table_name,
        p_schema_name, p_table_name || '_archive'
    ) USING p_start_time, p_end_time;
END;
$$;

-- Function to query data BETWEEN start_time AND end_time (inclusive)
CREATE OR REPLACE FUNCTION temporal_between(
    p_schema_name TEXT,
    p_table_name TEXT,
    p_start_time TIMESTAMP,
    p_end_time TIMESTAMP
)
RETURNS SETOF RECORD
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY EXECUTE format(
        'SELECT * FROM %I.%I WHERE valid_from <= $2 AND valid_to >= $1
         UNION ALL
         SELECT * FROM %I.%I WHERE valid_from <= $2 AND valid_to >= $1',
        p_schema_name, p_table_name,
        p_schema_name, p_table_name || '_archive'
    ) USING p_start_time, p_end_time;
END;
$$;

-- Function to query CONTAINED IN a time range
CREATE OR REPLACE FUNCTION temporal_contained_in(
    p_schema_name TEXT,
    p_table_name TEXT,
    p_start_time TIMESTAMP,
    p_end_time TIMESTAMP
)
RETURNS SETOF RECORD
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY EXECUTE format(
        'SELECT * FROM %I.%I WHERE valid_from >= $1 AND valid_to <= $2
         UNION ALL
         SELECT * FROM %I.%I WHERE valid_from >= $1 AND valid_to <= $2',
        p_schema_name, p_table_name,
        p_schema_name, p_table_name || '_archive'
    ) USING p_start_time, p_end_time;
END;
$$;

-- Function to query ALL history (current + archive)
CREATE OR REPLACE FUNCTION temporal_all(
    p_schema_name TEXT,
    p_table_name TEXT
)
RETURNS SETOF RECORD
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY EXECUTE format(
        'SELECT * FROM %I.%I
         UNION ALL
         SELECT * FROM %I.%I',
        p_schema_name, p_table_name,
        p_schema_name, p_table_name || '_archive'
    );
END;
$$;

COMMENT ON FUNCTION temporal_as_of IS 'Query temporal table data AS OF a specific point in time';
COMMENT ON FUNCTION temporal_from_to IS 'Query temporal table data FROM start_time TO end_time';
COMMENT ON FUNCTION temporal_between IS 'Query temporal table data BETWEEN start_time AND end_time (inclusive)';
COMMENT ON FUNCTION temporal_contained_in IS 'Query temporal table data CONTAINED IN a time range';
COMMENT ON FUNCTION temporal_all IS 'Query all temporal table data including history';

-- Example usage:
-- SELECT * FROM temporal_as_of('sales', 'customers', '2024-01-01 12:00:00'::TIMESTAMP) 
--     AS t(customer_id INT, customer_name VARCHAR, ...);
