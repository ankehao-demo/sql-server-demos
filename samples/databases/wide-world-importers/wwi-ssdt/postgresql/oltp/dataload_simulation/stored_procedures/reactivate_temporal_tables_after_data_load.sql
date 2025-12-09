-- PostgreSQL equivalent of [DataLoadSimulation].ReactivateTemporalTablesAfterDataLoad
-- Converted from T-SQL to PL/pgSQL
-- Note: PostgreSQL uses trigger-based temporal tables instead of SQL Server's SYSTEM_VERSIONING
-- This procedure re-enables the temporal triggers after bulk data load

CREATE OR REPLACE PROCEDURE dataload_simulation.reactivate_temporal_tables_after_data_load()
LANGUAGE plpgsql
AS $$
BEGIN
    -- Re-enable temporal triggers on all temporal tables
    
    -- Application schema temporal tables
    ALTER TABLE application.cities ENABLE TRIGGER ALL;
    ALTER TABLE application.countries ENABLE TRIGGER ALL;
    ALTER TABLE application.delivery_methods ENABLE TRIGGER ALL;
    ALTER TABLE application.payment_methods ENABLE TRIGGER ALL;
    ALTER TABLE application.people ENABLE TRIGGER ALL;
    ALTER TABLE application.state_provinces ENABLE TRIGGER ALL;
    ALTER TABLE application.transaction_types ENABLE TRIGGER ALL;
    
    -- Purchasing schema temporal tables
    ALTER TABLE purchasing.supplier_categories ENABLE TRIGGER ALL;
    ALTER TABLE purchasing.suppliers ENABLE TRIGGER ALL;
    
    -- Sales schema temporal tables
    ALTER TABLE sales.buying_groups ENABLE TRIGGER ALL;
    ALTER TABLE sales.customer_categories ENABLE TRIGGER ALL;
    ALTER TABLE sales.customers ENABLE TRIGGER ALL;
    
    -- Warehouse schema temporal tables
    ALTER TABLE warehouse.cold_room_temperatures ENABLE TRIGGER ALL;
    ALTER TABLE warehouse.colors ENABLE TRIGGER ALL;
    ALTER TABLE warehouse.package_types ENABLE TRIGGER ALL;
    ALTER TABLE warehouse.stock_groups ENABLE TRIGGER ALL;
    ALTER TABLE warehouse.stock_items ENABLE TRIGGER ALL;
    
    RAISE NOTICE 'Temporal table triggers re-enabled after data load';
    
EXCEPTION WHEN OTHERS THEN
    -- Some tables might not have triggers, continue anyway
    RAISE NOTICE 'Warning: Some temporal triggers could not be re-enabled: %', SQLERRM;
END;
$$;

COMMENT ON PROCEDURE dataload_simulation.reactivate_temporal_tables_after_data_load IS 'Re-enables temporal table triggers after bulk data load';
