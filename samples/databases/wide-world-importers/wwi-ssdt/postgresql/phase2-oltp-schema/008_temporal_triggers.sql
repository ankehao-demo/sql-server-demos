-- Wide World Importers PostgreSQL Migration
-- Phase 2: OLTP Schema Migration
-- Script 008: Temporal Table Triggers
-- Implements SQL Server temporal table functionality using PostgreSQL triggers

-- =============================================
-- Generic Temporal Table Trigger Function
-- This function handles versioning for temporal tables
-- =============================================
CREATE OR REPLACE FUNCTION temporal_table_trigger()
RETURNS TRIGGER AS $$
DECLARE
    archive_table_name TEXT;
    old_record RECORD;
BEGIN
    -- Get the archive table name from trigger argument
    archive_table_name := TG_ARGV[0];
    
    IF TG_OP = 'UPDATE' THEN
        -- Set the valid_to of the old record to current timestamp
        OLD.valid_to := clock_timestamp();
        
        -- Insert the old record into the archive table
        EXECUTE format(
            'INSERT INTO %s SELECT ($1).*',
            archive_table_name
        ) USING OLD;
        
        -- Set the valid_from of the new record to current timestamp
        NEW.valid_from := clock_timestamp();
        NEW.valid_to := '9999-12-31 23:59:59.9999999'::timestamp;
        
        RETURN NEW;
    ELSIF TG_OP = 'DELETE' THEN
        -- Set the valid_to of the old record to current timestamp
        OLD.valid_to := clock_timestamp();
        
        -- Insert the old record into the archive table
        EXECUTE format(
            'INSERT INTO %s SELECT ($1).*',
            archive_table_name
        ) USING OLD;
        
        RETURN OLD;
    END IF;
    
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

-- =============================================
-- Application Schema Temporal Triggers
-- =============================================

-- Application.People
CREATE TRIGGER tr_application_people_temporal
    BEFORE UPDATE OR DELETE ON application.people
    FOR EACH ROW
    EXECUTE FUNCTION temporal_table_trigger('application.people_archive');

-- Application.Countries
CREATE TRIGGER tr_application_countries_temporal
    BEFORE UPDATE OR DELETE ON application.countries
    FOR EACH ROW
    EXECUTE FUNCTION temporal_table_trigger('application.countries_archive');

-- Application.StateProvinces
CREATE TRIGGER tr_application_state_provinces_temporal
    BEFORE UPDATE OR DELETE ON application.state_provinces
    FOR EACH ROW
    EXECUTE FUNCTION temporal_table_trigger('application.state_provinces_archive');

-- Application.Cities
CREATE TRIGGER tr_application_cities_temporal
    BEFORE UPDATE OR DELETE ON application.cities
    FOR EACH ROW
    EXECUTE FUNCTION temporal_table_trigger('application.cities_archive');

-- Application.DeliveryMethods
CREATE TRIGGER tr_application_delivery_methods_temporal
    BEFORE UPDATE OR DELETE ON application.delivery_methods
    FOR EACH ROW
    EXECUTE FUNCTION temporal_table_trigger('application.delivery_methods_archive');

-- Application.PaymentMethods
CREATE TRIGGER tr_application_payment_methods_temporal
    BEFORE UPDATE OR DELETE ON application.payment_methods
    FOR EACH ROW
    EXECUTE FUNCTION temporal_table_trigger('application.payment_methods_archive');

-- Application.TransactionTypes
CREATE TRIGGER tr_application_transaction_types_temporal
    BEFORE UPDATE OR DELETE ON application.transaction_types
    FOR EACH ROW
    EXECUTE FUNCTION temporal_table_trigger('application.transaction_types_archive');

-- =============================================
-- Sales Schema Temporal Triggers
-- =============================================

-- Sales.BuyingGroups
CREATE TRIGGER tr_sales_buying_groups_temporal
    BEFORE UPDATE OR DELETE ON sales.buying_groups
    FOR EACH ROW
    EXECUTE FUNCTION temporal_table_trigger('sales.buying_groups_archive');

-- Sales.CustomerCategories
CREATE TRIGGER tr_sales_customer_categories_temporal
    BEFORE UPDATE OR DELETE ON sales.customer_categories
    FOR EACH ROW
    EXECUTE FUNCTION temporal_table_trigger('sales.customer_categories_archive');

-- Sales.Customers
CREATE TRIGGER tr_sales_customers_temporal
    BEFORE UPDATE OR DELETE ON sales.customers
    FOR EACH ROW
    EXECUTE FUNCTION temporal_table_trigger('sales.customers_archive');

-- =============================================
-- Purchasing Schema Temporal Triggers
-- =============================================

-- Purchasing.SupplierCategories
CREATE TRIGGER tr_purchasing_supplier_categories_temporal
    BEFORE UPDATE OR DELETE ON purchasing.supplier_categories
    FOR EACH ROW
    EXECUTE FUNCTION temporal_table_trigger('purchasing.supplier_categories_archive');

-- Purchasing.Suppliers
CREATE TRIGGER tr_purchasing_suppliers_temporal
    BEFORE UPDATE OR DELETE ON purchasing.suppliers
    FOR EACH ROW
    EXECUTE FUNCTION temporal_table_trigger('purchasing.suppliers_archive');

-- =============================================
-- Warehouse Schema Temporal Triggers
-- =============================================

-- Warehouse.Colors
CREATE TRIGGER tr_warehouse_colors_temporal
    BEFORE UPDATE OR DELETE ON warehouse.colors
    FOR EACH ROW
    EXECUTE FUNCTION temporal_table_trigger('warehouse.colors_archive');

-- Warehouse.PackageTypes
CREATE TRIGGER tr_warehouse_package_types_temporal
    BEFORE UPDATE OR DELETE ON warehouse.package_types
    FOR EACH ROW
    EXECUTE FUNCTION temporal_table_trigger('warehouse.package_types_archive');

-- Warehouse.StockGroups
CREATE TRIGGER tr_warehouse_stock_groups_temporal
    BEFORE UPDATE OR DELETE ON warehouse.stock_groups
    FOR EACH ROW
    EXECUTE FUNCTION temporal_table_trigger('warehouse.stock_groups_archive');

-- Warehouse.StockItems
CREATE TRIGGER tr_warehouse_stock_items_temporal
    BEFORE UPDATE OR DELETE ON warehouse.stock_items
    FOR EACH ROW
    EXECUTE FUNCTION temporal_table_trigger('warehouse.stock_items_archive');

-- Warehouse.ColdRoomTemperatures
CREATE TRIGGER tr_warehouse_cold_room_temperatures_temporal
    BEFORE UPDATE OR DELETE ON warehouse.cold_room_temperatures
    FOR EACH ROW
    EXECUTE FUNCTION temporal_table_trigger('warehouse.cold_room_temperatures_archive');

-- =============================================
-- Helper Functions for Temporal Queries
-- =============================================

-- Function to query temporal data as of a specific point in time
CREATE OR REPLACE FUNCTION temporal_as_of(
    p_table_name TEXT,
    p_as_of_time TIMESTAMP
)
RETURNS SETOF RECORD AS $$
BEGIN
    RETURN QUERY EXECUTE format(
        'SELECT * FROM %s WHERE valid_from <= $1 AND valid_to > $1
         UNION ALL
         SELECT * FROM %s_archive WHERE valid_from <= $1 AND valid_to > $1',
        p_table_name, p_table_name
    ) USING p_as_of_time;
END;
$$ LANGUAGE plpgsql;

-- Function to query temporal data between two points in time
CREATE OR REPLACE FUNCTION temporal_between(
    p_table_name TEXT,
    p_start_time TIMESTAMP,
    p_end_time TIMESTAMP
)
RETURNS SETOF RECORD AS $$
BEGIN
    RETURN QUERY EXECUTE format(
        'SELECT * FROM %s WHERE valid_from < $2 AND valid_to > $1
         UNION ALL
         SELECT * FROM %s_archive WHERE valid_from < $2 AND valid_to > $1',
        p_table_name, p_table_name
    ) USING p_start_time, p_end_time;
END;
$$ LANGUAGE plpgsql;

-- =============================================
-- Procedures to Deactivate/Reactivate Temporal Tables
-- (Used during data load operations)
-- =============================================

-- Procedure to deactivate temporal table triggers
CREATE OR REPLACE PROCEDURE dataload_simulation.deactivate_temporal_tables()
LANGUAGE plpgsql AS $$
BEGIN
    -- Application schema
    ALTER TABLE application.people DISABLE TRIGGER tr_application_people_temporal;
    ALTER TABLE application.countries DISABLE TRIGGER tr_application_countries_temporal;
    ALTER TABLE application.state_provinces DISABLE TRIGGER tr_application_state_provinces_temporal;
    ALTER TABLE application.cities DISABLE TRIGGER tr_application_cities_temporal;
    ALTER TABLE application.delivery_methods DISABLE TRIGGER tr_application_delivery_methods_temporal;
    ALTER TABLE application.payment_methods DISABLE TRIGGER tr_application_payment_methods_temporal;
    ALTER TABLE application.transaction_types DISABLE TRIGGER tr_application_transaction_types_temporal;
    
    -- Sales schema
    ALTER TABLE sales.buying_groups DISABLE TRIGGER tr_sales_buying_groups_temporal;
    ALTER TABLE sales.customer_categories DISABLE TRIGGER tr_sales_customer_categories_temporal;
    ALTER TABLE sales.customers DISABLE TRIGGER tr_sales_customers_temporal;
    
    -- Purchasing schema
    ALTER TABLE purchasing.supplier_categories DISABLE TRIGGER tr_purchasing_supplier_categories_temporal;
    ALTER TABLE purchasing.suppliers DISABLE TRIGGER tr_purchasing_suppliers_temporal;
    
    -- Warehouse schema
    ALTER TABLE warehouse.colors DISABLE TRIGGER tr_warehouse_colors_temporal;
    ALTER TABLE warehouse.package_types DISABLE TRIGGER tr_warehouse_package_types_temporal;
    ALTER TABLE warehouse.stock_groups DISABLE TRIGGER tr_warehouse_stock_groups_temporal;
    ALTER TABLE warehouse.stock_items DISABLE TRIGGER tr_warehouse_stock_items_temporal;
    ALTER TABLE warehouse.cold_room_temperatures DISABLE TRIGGER tr_warehouse_cold_room_temperatures_temporal;
    
    RAISE NOTICE 'Temporal table triggers have been deactivated for data load';
END;
$$;

-- Procedure to reactivate temporal table triggers
CREATE OR REPLACE PROCEDURE dataload_simulation.reactivate_temporal_tables()
LANGUAGE plpgsql AS $$
BEGIN
    -- Application schema
    ALTER TABLE application.people ENABLE TRIGGER tr_application_people_temporal;
    ALTER TABLE application.countries ENABLE TRIGGER tr_application_countries_temporal;
    ALTER TABLE application.state_provinces ENABLE TRIGGER tr_application_state_provinces_temporal;
    ALTER TABLE application.cities ENABLE TRIGGER tr_application_cities_temporal;
    ALTER TABLE application.delivery_methods ENABLE TRIGGER tr_application_delivery_methods_temporal;
    ALTER TABLE application.payment_methods ENABLE TRIGGER tr_application_payment_methods_temporal;
    ALTER TABLE application.transaction_types ENABLE TRIGGER tr_application_transaction_types_temporal;
    
    -- Sales schema
    ALTER TABLE sales.buying_groups ENABLE TRIGGER tr_sales_buying_groups_temporal;
    ALTER TABLE sales.customer_categories ENABLE TRIGGER tr_sales_customer_categories_temporal;
    ALTER TABLE sales.customers ENABLE TRIGGER tr_sales_customers_temporal;
    
    -- Purchasing schema
    ALTER TABLE purchasing.supplier_categories ENABLE TRIGGER tr_purchasing_supplier_categories_temporal;
    ALTER TABLE purchasing.suppliers ENABLE TRIGGER tr_purchasing_suppliers_temporal;
    
    -- Warehouse schema
    ALTER TABLE warehouse.colors ENABLE TRIGGER tr_warehouse_colors_temporal;
    ALTER TABLE warehouse.package_types ENABLE TRIGGER tr_warehouse_package_types_temporal;
    ALTER TABLE warehouse.stock_groups ENABLE TRIGGER tr_warehouse_stock_groups_temporal;
    ALTER TABLE warehouse.stock_items ENABLE TRIGGER tr_warehouse_stock_items_temporal;
    ALTER TABLE warehouse.cold_room_temperatures ENABLE TRIGGER tr_warehouse_cold_room_temperatures_temporal;
    
    RAISE NOTICE 'Temporal table triggers have been reactivated';
END;
$$;

-- Comments
COMMENT ON FUNCTION temporal_table_trigger() IS 'Generic trigger function for implementing SQL Server temporal table functionality';
COMMENT ON FUNCTION temporal_as_of(TEXT, TIMESTAMP) IS 'Query temporal data as of a specific point in time';
COMMENT ON FUNCTION temporal_between(TEXT, TIMESTAMP, TIMESTAMP) IS 'Query temporal data between two points in time';
COMMENT ON PROCEDURE dataload_simulation.deactivate_temporal_tables() IS 'Deactivate temporal table triggers for bulk data load operations';
COMMENT ON PROCEDURE dataload_simulation.reactivate_temporal_tables() IS 'Reactivate temporal table triggers after bulk data load operations';
