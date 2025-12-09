-- Wide World Importers PostgreSQL Migration
-- Temporal Table Triggers
-- This script creates triggers to implement SQL Server-style temporal tables in PostgreSQL

-- Generic temporal trigger function
-- This function handles INSERT, UPDATE, and DELETE operations for temporal tables
CREATE OR REPLACE FUNCTION temporal_table_trigger()
RETURNS TRIGGER AS $$
DECLARE
    archive_table_name text;
    current_time timestamp := NOW();
BEGIN
    -- Get the archive table name from trigger arguments
    archive_table_name := TG_ARGV[0];
    
    IF TG_OP = 'INSERT' THEN
        -- Set validfrom to current time and validto to end of time
        NEW.validfrom := current_time;
        NEW.validto := '9999-12-31 23:59:59.999999'::timestamp;
        RETURN NEW;
        
    ELSIF TG_OP = 'UPDATE' THEN
        -- Archive the old record
        EXECUTE format(
            'INSERT INTO %s SELECT ($1).*',
            archive_table_name
        ) USING OLD;
        
        -- Update the validfrom for the new record
        NEW.validfrom := current_time;
        NEW.validto := '9999-12-31 23:59:59.999999'::timestamp;
        
        -- Update the validto of the archived record
        EXECUTE format(
            'UPDATE %s SET validto = $1 WHERE validfrom = $2 AND validto = ''9999-12-31 23:59:59.999999''::timestamp',
            archive_table_name
        ) USING current_time, OLD.validfrom;
        
        RETURN NEW;
        
    ELSIF TG_OP = 'DELETE' THEN
        -- Archive the deleted record with current time as validto
        OLD.validto := current_time;
        EXECUTE format(
            'INSERT INTO %s SELECT ($1).*',
            archive_table_name
        ) USING OLD;
        
        RETURN OLD;
    END IF;
    
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION temporal_table_trigger() IS 'Generic trigger function for implementing temporal table versioning';

-- Application Schema Temporal Triggers

-- Countries temporal trigger
CREATE OR REPLACE TRIGGER tr_countries_temporal
    BEFORE INSERT OR UPDATE OR DELETE ON application.countries
    FOR EACH ROW
    EXECUTE FUNCTION temporal_table_trigger('application.countries_archive');

-- StateProvinces temporal trigger
CREATE OR REPLACE TRIGGER tr_stateprovinces_temporal
    BEFORE INSERT OR UPDATE OR DELETE ON application.stateprovinces
    FOR EACH ROW
    EXECUTE FUNCTION temporal_table_trigger('application.stateprovinces_archive');

-- Cities temporal trigger
CREATE OR REPLACE TRIGGER tr_cities_temporal
    BEFORE INSERT OR UPDATE OR DELETE ON application.cities
    FOR EACH ROW
    EXECUTE FUNCTION temporal_table_trigger('application.cities_archive');

-- People temporal trigger
CREATE OR REPLACE TRIGGER tr_people_temporal
    BEFORE INSERT OR UPDATE OR DELETE ON application.people
    FOR EACH ROW
    EXECUTE FUNCTION temporal_table_trigger('application.people_archive');

-- DeliveryMethods temporal trigger
CREATE OR REPLACE TRIGGER tr_deliverymethods_temporal
    BEFORE INSERT OR UPDATE OR DELETE ON application.deliverymethods
    FOR EACH ROW
    EXECUTE FUNCTION temporal_table_trigger('application.deliverymethods_archive');

-- PaymentMethods temporal trigger
CREATE OR REPLACE TRIGGER tr_paymentmethods_temporal
    BEFORE INSERT OR UPDATE OR DELETE ON application.paymentmethods
    FOR EACH ROW
    EXECUTE FUNCTION temporal_table_trigger('application.paymentmethods_archive');

-- TransactionTypes temporal trigger
CREATE OR REPLACE TRIGGER tr_transactiontypes_temporal
    BEFORE INSERT OR UPDATE OR DELETE ON application.transactiontypes
    FOR EACH ROW
    EXECUTE FUNCTION temporal_table_trigger('application.transactiontypes_archive');

-- Sales Schema Temporal Triggers

-- BuyingGroups temporal trigger
CREATE OR REPLACE TRIGGER tr_buyinggroups_temporal
    BEFORE INSERT OR UPDATE OR DELETE ON sales.buyinggroups
    FOR EACH ROW
    EXECUTE FUNCTION temporal_table_trigger('sales.buyinggroups_archive');

-- CustomerCategories temporal trigger
CREATE OR REPLACE TRIGGER tr_customercategories_temporal
    BEFORE INSERT OR UPDATE OR DELETE ON sales.customercategories
    FOR EACH ROW
    EXECUTE FUNCTION temporal_table_trigger('sales.customercategories_archive');

-- Customers temporal trigger
CREATE OR REPLACE TRIGGER tr_customers_temporal
    BEFORE INSERT OR UPDATE OR DELETE ON sales.customers
    FOR EACH ROW
    EXECUTE FUNCTION temporal_table_trigger('sales.customers_archive');

-- Purchasing Schema Temporal Triggers

-- SupplierCategories temporal trigger
CREATE OR REPLACE TRIGGER tr_suppliercategories_temporal
    BEFORE INSERT OR UPDATE OR DELETE ON purchasing.suppliercategories
    FOR EACH ROW
    EXECUTE FUNCTION temporal_table_trigger('purchasing.suppliercategories_archive');

-- Suppliers temporal trigger
CREATE OR REPLACE TRIGGER tr_suppliers_temporal
    BEFORE INSERT OR UPDATE OR DELETE ON purchasing.suppliers
    FOR EACH ROW
    EXECUTE FUNCTION temporal_table_trigger('purchasing.suppliers_archive');

-- Warehouse Schema Temporal Triggers

-- Colors temporal trigger
CREATE OR REPLACE TRIGGER tr_colors_temporal
    BEFORE INSERT OR UPDATE OR DELETE ON warehouse.colors
    FOR EACH ROW
    EXECUTE FUNCTION temporal_table_trigger('warehouse.colors_archive');

-- PackageTypes temporal trigger
CREATE OR REPLACE TRIGGER tr_packagetypes_temporal
    BEFORE INSERT OR UPDATE OR DELETE ON warehouse.packagetypes
    FOR EACH ROW
    EXECUTE FUNCTION temporal_table_trigger('warehouse.packagetypes_archive');

-- StockGroups temporal trigger
CREATE OR REPLACE TRIGGER tr_stockgroups_temporal
    BEFORE INSERT OR UPDATE OR DELETE ON warehouse.stockgroups
    FOR EACH ROW
    EXECUTE FUNCTION temporal_table_trigger('warehouse.stockgroups_archive');

-- StockItems temporal trigger
CREATE OR REPLACE TRIGGER tr_stockitems_temporal
    BEFORE INSERT OR UPDATE OR DELETE ON warehouse.stockitems
    FOR EACH ROW
    EXECUTE FUNCTION temporal_table_trigger('warehouse.stockitems_archive');

-- ColdRoomTemperatures temporal trigger
CREATE OR REPLACE TRIGGER tr_coldroomtemperatures_temporal
    BEFORE INSERT OR UPDATE OR DELETE ON warehouse.coldroomtemperatures
    FOR EACH ROW
    EXECUTE FUNCTION temporal_table_trigger('warehouse.coldroomtemperatures_archive');

-- Helper function to query temporal data at a specific point in time
CREATE OR REPLACE FUNCTION get_temporal_data(
    table_name text,
    archive_table_name text,
    as_of_time timestamp
)
RETURNS SETOF record AS $$
BEGIN
    RETURN QUERY EXECUTE format(
        'SELECT * FROM %s WHERE validfrom <= $1 AND validto > $1
         UNION ALL
         SELECT * FROM %s WHERE validfrom <= $1 AND validto > $1',
        table_name, archive_table_name
    ) USING as_of_time;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION get_temporal_data(text, text, timestamp) IS 'Query temporal data as of a specific point in time';

-- Function to disable temporal triggers (for bulk data loading)
CREATE OR REPLACE FUNCTION disable_temporal_triggers()
RETURNS void AS $$
BEGIN
    ALTER TABLE application.countries DISABLE TRIGGER tr_countries_temporal;
    ALTER TABLE application.stateprovinces DISABLE TRIGGER tr_stateprovinces_temporal;
    ALTER TABLE application.cities DISABLE TRIGGER tr_cities_temporal;
    ALTER TABLE application.people DISABLE TRIGGER tr_people_temporal;
    ALTER TABLE application.deliverymethods DISABLE TRIGGER tr_deliverymethods_temporal;
    ALTER TABLE application.paymentmethods DISABLE TRIGGER tr_paymentmethods_temporal;
    ALTER TABLE application.transactiontypes DISABLE TRIGGER tr_transactiontypes_temporal;
    ALTER TABLE sales.buyinggroups DISABLE TRIGGER tr_buyinggroups_temporal;
    ALTER TABLE sales.customercategories DISABLE TRIGGER tr_customercategories_temporal;
    ALTER TABLE sales.customers DISABLE TRIGGER tr_customers_temporal;
    ALTER TABLE purchasing.suppliercategories DISABLE TRIGGER tr_suppliercategories_temporal;
    ALTER TABLE purchasing.suppliers DISABLE TRIGGER tr_suppliers_temporal;
    ALTER TABLE warehouse.colors DISABLE TRIGGER tr_colors_temporal;
    ALTER TABLE warehouse.packagetypes DISABLE TRIGGER tr_packagetypes_temporal;
    ALTER TABLE warehouse.stockgroups DISABLE TRIGGER tr_stockgroups_temporal;
    ALTER TABLE warehouse.stockitems DISABLE TRIGGER tr_stockitems_temporal;
    ALTER TABLE warehouse.coldroomtemperatures DISABLE TRIGGER tr_coldroomtemperatures_temporal;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION disable_temporal_triggers() IS 'Disable all temporal triggers for bulk data loading';

-- Function to enable temporal triggers (after bulk data loading)
CREATE OR REPLACE FUNCTION enable_temporal_triggers()
RETURNS void AS $$
BEGIN
    ALTER TABLE application.countries ENABLE TRIGGER tr_countries_temporal;
    ALTER TABLE application.stateprovinces ENABLE TRIGGER tr_stateprovinces_temporal;
    ALTER TABLE application.cities ENABLE TRIGGER tr_cities_temporal;
    ALTER TABLE application.people ENABLE TRIGGER tr_people_temporal;
    ALTER TABLE application.deliverymethods ENABLE TRIGGER tr_deliverymethods_temporal;
    ALTER TABLE application.paymentmethods ENABLE TRIGGER tr_paymentmethods_temporal;
    ALTER TABLE application.transactiontypes ENABLE TRIGGER tr_transactiontypes_temporal;
    ALTER TABLE sales.buyinggroups ENABLE TRIGGER tr_buyinggroups_temporal;
    ALTER TABLE sales.customercategories ENABLE TRIGGER tr_customercategories_temporal;
    ALTER TABLE sales.customers ENABLE TRIGGER tr_customers_temporal;
    ALTER TABLE purchasing.suppliercategories ENABLE TRIGGER tr_suppliercategories_temporal;
    ALTER TABLE purchasing.suppliers ENABLE TRIGGER tr_suppliers_temporal;
    ALTER TABLE warehouse.colors ENABLE TRIGGER tr_colors_temporal;
    ALTER TABLE warehouse.packagetypes ENABLE TRIGGER tr_packagetypes_temporal;
    ALTER TABLE warehouse.stockgroups ENABLE TRIGGER tr_stockgroups_temporal;
    ALTER TABLE warehouse.stockitems ENABLE TRIGGER tr_stockitems_temporal;
    ALTER TABLE warehouse.coldroomtemperatures ENABLE TRIGGER tr_coldroomtemperatures_temporal;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION enable_temporal_triggers() IS 'Enable all temporal triggers after bulk data loading';
