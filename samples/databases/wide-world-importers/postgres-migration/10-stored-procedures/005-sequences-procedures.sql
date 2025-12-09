-- Phase 3: OLTP Code Migration - Sequences Schema Stored Procedures
-- Converted from SQL Server T-SQL to PostgreSQL PL/pgSQL

-- =============================================
-- Procedure: Sequences.ReseedSequenceBeyondTableValues
-- Description: Reseeds a sequence to be beyond the maximum value in a table
-- =============================================
CREATE OR REPLACE PROCEDURE sequences.reseed_sequence_beyond_table_values(
    p_schema_name varchar(128),
    p_table_name varchar(128),
    p_column_name varchar(128),
    p_sequence_name varchar(128)
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_max_value bigint;
    v_current_value bigint;
    v_sql text;
BEGIN
    -- Get the maximum value from the table
    v_sql := format('SELECT COALESCE(MAX(%I), 0) FROM %I.%I', p_column_name, p_schema_name, p_table_name);
    EXECUTE v_sql INTO v_max_value;
    
    -- Get the current sequence value
    v_sql := format('SELECT last_value FROM sequences.%I', p_sequence_name);
    EXECUTE v_sql INTO v_current_value;
    
    -- If the max value is greater than or equal to the current sequence value, reseed
    IF v_max_value >= v_current_value THEN
        v_sql := format('ALTER SEQUENCE sequences.%I RESTART WITH %s', p_sequence_name, v_max_value + 1);
        EXECUTE v_sql;
        RAISE NOTICE 'Sequence sequences.% reseeded to %', p_sequence_name, v_max_value + 1;
    ELSE
        RAISE NOTICE 'Sequence sequences.% is already beyond table maximum (% vs %)', 
            p_sequence_name, v_current_value, v_max_value;
    END IF;
END;
$$;

-- =============================================
-- Procedure: Sequences.ReseedAllSequences
-- Description: Reseeds all sequences to be beyond their corresponding table values
-- =============================================
CREATE OR REPLACE PROCEDURE sequences.reseed_all_sequences()
LANGUAGE plpgsql
AS $$
BEGIN
    -- Application schema sequences
    CALL sequences.reseed_sequence_beyond_table_values('application', 'cities', 'cityid', 'cityid');
    CALL sequences.reseed_sequence_beyond_table_values('application', 'countries', 'countryid', 'countryid');
    CALL sequences.reseed_sequence_beyond_table_values('application', 'deliverymethods', 'deliverymethodid', 'deliverymethodid');
    CALL sequences.reseed_sequence_beyond_table_values('application', 'paymentmethods', 'paymentmethodid', 'paymentmethodid');
    CALL sequences.reseed_sequence_beyond_table_values('application', 'people', 'personid', 'personid');
    CALL sequences.reseed_sequence_beyond_table_values('application', 'stateprovinces', 'stateprovinceid', 'stateprovinceid');
    CALL sequences.reseed_sequence_beyond_table_values('application', 'transactiontypes', 'transactiontypeid', 'transactiontypeid');
    
    -- Purchasing schema sequences
    CALL sequences.reseed_sequence_beyond_table_values('purchasing', 'purchaseorderlines', 'purchaseorderlineid', 'purchaseorderlineid');
    CALL sequences.reseed_sequence_beyond_table_values('purchasing', 'purchaseorders', 'purchaseorderid', 'purchaseorderid');
    CALL sequences.reseed_sequence_beyond_table_values('purchasing', 'suppliercategories', 'suppliercategoryid', 'suppliercategoryid');
    CALL sequences.reseed_sequence_beyond_table_values('purchasing', 'suppliers', 'supplierid', 'supplierid');
    CALL sequences.reseed_sequence_beyond_table_values('purchasing', 'suppliertransactions', 'suppliertransactionid', 'suppliertransactionid');
    
    -- Sales schema sequences
    CALL sequences.reseed_sequence_beyond_table_values('sales', 'buyinggroups', 'buyinggroupid', 'buyinggroupid');
    CALL sequences.reseed_sequence_beyond_table_values('sales', 'customercategories', 'customercategoryid', 'customercategoryid');
    CALL sequences.reseed_sequence_beyond_table_values('sales', 'customers', 'customerid', 'customerid');
    CALL sequences.reseed_sequence_beyond_table_values('sales', 'customertransactions', 'customertransactionid', 'customertransactionid');
    CALL sequences.reseed_sequence_beyond_table_values('sales', 'invoicelines', 'invoicelineid', 'invoicelineid');
    CALL sequences.reseed_sequence_beyond_table_values('sales', 'invoices', 'invoiceid', 'invoiceid');
    CALL sequences.reseed_sequence_beyond_table_values('sales', 'orderlines', 'orderlineid', 'orderlineid');
    CALL sequences.reseed_sequence_beyond_table_values('sales', 'orders', 'orderid', 'orderid');
    CALL sequences.reseed_sequence_beyond_table_values('sales', 'specialdeals', 'specialdealid', 'specialdealid');
    
    -- Warehouse schema sequences
    CALL sequences.reseed_sequence_beyond_table_values('warehouse', 'coldroomtemperatures', 'coldroomtemperatureid', 'coldroomtemperatureid');
    CALL sequences.reseed_sequence_beyond_table_values('warehouse', 'colors', 'colorid', 'colorid');
    CALL sequences.reseed_sequence_beyond_table_values('warehouse', 'packagetypes', 'packagetypeid', 'packagetypeid');
    CALL sequences.reseed_sequence_beyond_table_values('warehouse', 'stockgroups', 'stockgroupid', 'stockgroupid');
    CALL sequences.reseed_sequence_beyond_table_values('warehouse', 'stockitemholdings', 'stockitemid', 'stockitemholdingid');
    CALL sequences.reseed_sequence_beyond_table_values('warehouse', 'stockitems', 'stockitemid', 'stockitemid');
    CALL sequences.reseed_sequence_beyond_table_values('warehouse', 'stockitemstockgroups', 'stockitemstockgroupid', 'stockitemstockgroupid');
    CALL sequences.reseed_sequence_beyond_table_values('warehouse', 'stockitemtransactions', 'stockitemtransactionid', 'stockitemtransactionid');
    CALL sequences.reseed_sequence_beyond_table_values('warehouse', 'vehicletemperatures', 'vehicletemperatureid', 'vehicletemperatureid');
    
    RAISE NOTICE 'All sequences have been reseeded';
END;
$$;

COMMENT ON PROCEDURE sequences.reseed_sequence_beyond_table_values(varchar, varchar, varchar, varchar) IS 
'Reseeds a sequence to be beyond the maximum value in a table column';

COMMENT ON PROCEDURE sequences.reseed_all_sequences() IS 
'Reseeds all sequences to be beyond their corresponding table values';
