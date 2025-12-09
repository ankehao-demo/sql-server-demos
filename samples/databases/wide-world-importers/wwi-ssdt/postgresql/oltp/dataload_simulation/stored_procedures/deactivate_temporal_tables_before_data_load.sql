-- PostgreSQL equivalent of [DataLoadSimulation].DeactivateTemporalTablesBeforeDataLoad
-- Converted from T-SQL to PL/pgSQL
-- Note: PostgreSQL uses trigger-based temporal tables instead of SQL Server's SYSTEM_VERSIONING
-- This procedure disables the temporal triggers during bulk data load

CREATE OR REPLACE PROCEDURE dataload_simulation.deactivate_temporal_tables_before_data_load()
LANGUAGE plpgsql
AS $$
BEGIN
    -- Disable temporal triggers on all temporal tables
    -- In PostgreSQL, we disable the triggers that maintain history
    
    -- Application schema temporal tables
    ALTER TABLE application.cities DISABLE TRIGGER ALL;
    ALTER TABLE application.countries DISABLE TRIGGER ALL;
    ALTER TABLE application.delivery_methods DISABLE TRIGGER ALL;
    ALTER TABLE application.payment_methods DISABLE TRIGGER ALL;
    ALTER TABLE application.people DISABLE TRIGGER ALL;
    ALTER TABLE application.state_provinces DISABLE TRIGGER ALL;
    ALTER TABLE application.transaction_types DISABLE TRIGGER ALL;
    
    -- Purchasing schema temporal tables
    ALTER TABLE purchasing.supplier_categories DISABLE TRIGGER ALL;
    ALTER TABLE purchasing.suppliers DISABLE TRIGGER ALL;
    
    -- Sales schema temporal tables
    ALTER TABLE sales.buying_groups DISABLE TRIGGER ALL;
    ALTER TABLE sales.customer_categories DISABLE TRIGGER ALL;
    ALTER TABLE sales.customers DISABLE TRIGGER ALL;
    
    -- Warehouse schema temporal tables
    ALTER TABLE warehouse.cold_room_temperatures DISABLE TRIGGER ALL;
    ALTER TABLE warehouse.colors DISABLE TRIGGER ALL;
    ALTER TABLE warehouse.package_types DISABLE TRIGGER ALL;
    ALTER TABLE warehouse.stock_groups DISABLE TRIGGER ALL;
    ALTER TABLE warehouse.stock_items DISABLE TRIGGER ALL;
    
    RAISE NOTICE 'Temporal table triggers disabled for data load';
    
EXCEPTION WHEN OTHERS THEN
    -- Some tables might not have triggers, continue anyway
    RAISE NOTICE 'Warning: Some temporal triggers could not be disabled: %', SQLERRM;
END;
$$;

COMMENT ON PROCEDURE dataload_simulation.deactivate_temporal_tables_before_data_load IS 'Disables temporal table triggers before bulk data load';
