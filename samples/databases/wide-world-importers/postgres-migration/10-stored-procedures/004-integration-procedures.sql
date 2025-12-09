-- Phase 3: OLTP Code Migration - Integration Schema Stored Procedures
-- Converted from SQL Server T-SQL to PostgreSQL PL/pgSQL
-- These procedures are used for ETL processes to extract data for the data warehouse

-- Create Integration schema if it doesn't exist
CREATE SCHEMA IF NOT EXISTS integration;

-- =============================================
-- Helper function to query temporal data as of a specific time
-- This replaces SQL Server's FOR SYSTEM_TIME AS OF clause
-- =============================================
CREATE OR REPLACE FUNCTION integration.get_temporal_record(
    p_table_name text,
    p_schema_name text,
    p_pk_column text,
    p_pk_value integer,
    p_as_of timestamp
)
RETURNS SETOF record
LANGUAGE plpgsql
AS $$
DECLARE
    v_sql text;
BEGIN
    -- First check the main table
    v_sql := format(
        'SELECT * FROM %I.%I WHERE %I = $1 AND validfrom <= $2 AND validto > $2',
        p_schema_name, p_table_name, p_pk_column
    );
    
    RETURN QUERY EXECUTE v_sql USING p_pk_value, p_as_of;
    
    IF NOT FOUND THEN
        -- Check the archive table
        v_sql := format(
            'SELECT * FROM %I.%I WHERE %I = $1 AND validfrom <= $2 AND validto > $2',
            p_schema_name, p_table_name || '_archive', p_pk_column
        );
        RETURN QUERY EXECUTE v_sql USING p_pk_value, p_as_of;
    END IF;
END;
$$;

-- =============================================
-- Procedure: Integration.GetCityUpdates
-- Description: Gets city updates between two cutoff times for ETL
-- =============================================
CREATE OR REPLACE PROCEDURE integration.get_city_updates(
    p_last_cutoff timestamp,
    p_new_cutoff timestamp,
    INOUT p_results refcursor DEFAULT NULL
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_end_of_time timestamp := '9999-12-31 23:59:59.999999'::timestamp;
    v_initial_load_date date := '2020-01-01'::date;
BEGIN
    -- Create temp table for city changes
    DROP TABLE IF EXISTS temp_city_changes;
    CREATE TEMP TABLE temp_city_changes (
        wwi_city_id integer,
        city varchar(50),
        state_province varchar(50),
        country varchar(50),
        continent varchar(30),
        sales_territory varchar(50),
        region varchar(30),
        subregion varchar(30),
        location geography,
        latest_recorded_population bigint,
        valid_from timestamp,
        valid_to timestamp
    );
    
    -- Get country changes
    INSERT INTO temp_city_changes
    SELECT c.cityid, c.cityname, sp.stateprovincename, co.countryname, co.continent,
           sp.salesterritory, co.region, co.subregion, c.location,
           COALESCE(c.latestrecordedpopulation, 0), co.validfrom, NULL
    FROM (
        SELECT countryid, validfrom FROM application.countries_archive
        WHERE validfrom > p_last_cutoff AND validfrom <= p_new_cutoff AND validfrom::date != v_initial_load_date
        UNION ALL
        SELECT countryid, validfrom FROM application.countries
        WHERE validfrom > p_last_cutoff AND validfrom <= p_new_cutoff AND validfrom::date != v_initial_load_date
    ) country_changes
    INNER JOIN application.countries co ON country_changes.countryid = co.countryid
    INNER JOIN application.stateprovinces sp ON sp.countryid = co.countryid
    INNER JOIN application.cities c ON c.stateprovinceid = sp.stateprovinceid;
    
    -- Get state province changes
    INSERT INTO temp_city_changes
    SELECT c.cityid, c.cityname, sp.stateprovincename, co.countryname, co.continent,
           sp.salesterritory, co.region, co.subregion, c.location,
           COALESCE(c.latestrecordedpopulation, 0), sp.validfrom, NULL
    FROM (
        SELECT stateprovinceid, validfrom FROM application.stateprovinces_archive
        WHERE validfrom > p_last_cutoff AND validfrom <= p_new_cutoff AND validfrom::date != v_initial_load_date
        UNION ALL
        SELECT stateprovinceid, validfrom FROM application.stateprovinces
        WHERE validfrom > p_last_cutoff AND validfrom <= p_new_cutoff AND validfrom::date != v_initial_load_date
    ) sp_changes
    INNER JOIN application.stateprovinces sp ON sp_changes.stateprovinceid = sp.stateprovinceid
    INNER JOIN application.countries co ON sp.countryid = co.countryid
    INNER JOIN application.cities c ON c.stateprovinceid = sp.stateprovinceid;
    
    -- Get city changes
    INSERT INTO temp_city_changes
    SELECT c.cityid, c.cityname, sp.stateprovincename, co.countryname, co.continent,
           sp.salesterritory, co.region, co.subregion, c.location,
           COALESCE(c.latestrecordedpopulation, 0), c.validfrom, NULL
    FROM (
        SELECT cityid, validfrom FROM application.cities_archive
        WHERE validfrom > p_last_cutoff AND validfrom <= p_new_cutoff
        UNION ALL
        SELECT cityid, validfrom FROM application.cities
        WHERE validfrom > p_last_cutoff AND validfrom <= p_new_cutoff
    ) city_changes
    INNER JOIN application.cities c ON city_changes.cityid = c.cityid
    INNER JOIN application.stateprovinces sp ON c.stateprovinceid = sp.stateprovinceid
    INNER JOIN application.countries co ON sp.countryid = co.countryid;
    
    -- Create index for faster lookups
    CREATE INDEX ON temp_city_changes (wwi_city_id, valid_from);
    
    -- Update valid_to values
    UPDATE temp_city_changes cc
    SET valid_to = COALESCE(
        (SELECT MIN(valid_from) FROM temp_city_changes cc2
         WHERE cc2.wwi_city_id = cc.wwi_city_id AND cc2.valid_from > cc.valid_from),
        v_end_of_time
    );
    
    -- Return results
    OPEN p_results FOR
    SELECT wwi_city_id AS "WWI City ID", city AS "City", state_province AS "State Province",
           country AS "Country", continent AS "Continent", sales_territory AS "Sales Territory",
           region AS "Region", subregion AS "Subregion", location AS "Location",
           latest_recorded_population AS "Latest Recorded Population",
           valid_from AS "Valid From", valid_to AS "Valid To"
    FROM temp_city_changes
    ORDER BY valid_from;
END;
$$;

-- =============================================
-- Procedure: Integration.GetCustomerUpdates
-- Description: Gets customer updates between two cutoff times for ETL
-- =============================================
CREATE OR REPLACE PROCEDURE integration.get_customer_updates(
    p_last_cutoff timestamp,
    p_new_cutoff timestamp,
    INOUT p_results refcursor DEFAULT NULL
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_end_of_time timestamp := '9999-12-31 23:59:59.999999'::timestamp;
BEGIN
    DROP TABLE IF EXISTS temp_customer_changes;
    CREATE TEMP TABLE temp_customer_changes (
        wwi_customer_id integer,
        customer varchar(100),
        bill_to_customer varchar(100),
        category varchar(50),
        buying_group varchar(50),
        primary_contact varchar(50),
        postal_code varchar(10),
        valid_from timestamp,
        valid_to timestamp
    );
    
    -- Get customer changes from archive and current tables
    INSERT INTO temp_customer_changes
    SELECT c.customerid, c.customername,
           btc.customername AS bill_to_customer,
           cc.customercategoryname,
           bg.buyinggroupname,
           p.fullname AS primary_contact,
           c.deliverypostalcode,
           c.validfrom, NULL
    FROM (
        SELECT customerid, validfrom FROM sales.customers_archive
        WHERE validfrom > p_last_cutoff AND validfrom <= p_new_cutoff
        UNION ALL
        SELECT customerid, validfrom FROM sales.customers
        WHERE validfrom > p_last_cutoff AND validfrom <= p_new_cutoff
    ) customer_changes
    INNER JOIN sales.customers c ON customer_changes.customerid = c.customerid
    LEFT JOIN sales.customers btc ON c.billtocustomerid = btc.customerid
    LEFT JOIN sales.customercategories cc ON c.customercategoryid = cc.customercategoryid
    LEFT JOIN sales.buyinggroups bg ON c.buyinggroupid = bg.buyinggroupid
    LEFT JOIN application.people p ON c.primarycontactpersonid = p.personid;
    
    -- Create index
    CREATE INDEX ON temp_customer_changes (wwi_customer_id, valid_from);
    
    -- Update valid_to
    UPDATE temp_customer_changes cc
    SET valid_to = COALESCE(
        (SELECT MIN(valid_from) FROM temp_customer_changes cc2
         WHERE cc2.wwi_customer_id = cc.wwi_customer_id AND cc2.valid_from > cc.valid_from),
        v_end_of_time
    );
    
    OPEN p_results FOR
    SELECT wwi_customer_id AS "WWI Customer ID", customer AS "Customer",
           bill_to_customer AS "Bill To Customer", category AS "Category",
           buying_group AS "Buying Group", primary_contact AS "Primary Contact",
           postal_code AS "Postal Code", valid_from AS "Valid From", valid_to AS "Valid To"
    FROM temp_customer_changes
    ORDER BY valid_from;
END;
$$;

-- =============================================
-- Procedure: Integration.GetEmployeeUpdates
-- Description: Gets employee updates between two cutoff times for ETL
-- =============================================
CREATE OR REPLACE PROCEDURE integration.get_employee_updates(
    p_last_cutoff timestamp,
    p_new_cutoff timestamp,
    INOUT p_results refcursor DEFAULT NULL
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_end_of_time timestamp := '9999-12-31 23:59:59.999999'::timestamp;
BEGIN
    DROP TABLE IF EXISTS temp_employee_changes;
    CREATE TEMP TABLE temp_employee_changes (
        wwi_employee_id integer,
        employee varchar(50),
        preferred_name varchar(50),
        is_salesperson boolean,
        photo bytea,
        valid_from timestamp,
        valid_to timestamp
    );
    
    INSERT INTO temp_employee_changes
    SELECT p.personid, p.fullname, p.preferredname, p.issalesperson, p.photo, p.validfrom, NULL
    FROM (
        SELECT personid, validfrom FROM application.people_archive
        WHERE validfrom > p_last_cutoff AND validfrom <= p_new_cutoff AND isemployee = true
        UNION ALL
        SELECT personid, validfrom FROM application.people
        WHERE validfrom > p_last_cutoff AND validfrom <= p_new_cutoff AND isemployee = true
    ) employee_changes
    INNER JOIN application.people p ON employee_changes.personid = p.personid
    WHERE p.isemployee = true;
    
    CREATE INDEX ON temp_employee_changes (wwi_employee_id, valid_from);
    
    UPDATE temp_employee_changes ec
    SET valid_to = COALESCE(
        (SELECT MIN(valid_from) FROM temp_employee_changes ec2
         WHERE ec2.wwi_employee_id = ec.wwi_employee_id AND ec2.valid_from > ec.valid_from),
        v_end_of_time
    );
    
    OPEN p_results FOR
    SELECT wwi_employee_id AS "WWI Employee ID", employee AS "Employee",
           preferred_name AS "Preferred Name", is_salesperson AS "Is Salesperson",
           photo AS "Photo", valid_from AS "Valid From", valid_to AS "Valid To"
    FROM temp_employee_changes
    ORDER BY valid_from;
END;
$$;

-- =============================================
-- Procedure: Integration.GetStockItemUpdates
-- Description: Gets stock item updates between two cutoff times for ETL
-- =============================================
CREATE OR REPLACE PROCEDURE integration.get_stock_item_updates(
    p_last_cutoff timestamp,
    p_new_cutoff timestamp,
    INOUT p_results refcursor DEFAULT NULL
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_end_of_time timestamp := '9999-12-31 23:59:59.999999'::timestamp;
BEGIN
    DROP TABLE IF EXISTS temp_stock_item_changes;
    CREATE TEMP TABLE temp_stock_item_changes (
        wwi_stock_item_id integer,
        stock_item varchar(100),
        color varchar(20),
        unit_package varchar(50),
        outer_package varchar(50),
        brand varchar(50),
        size varchar(20),
        lead_time_days integer,
        quantity_per_outer integer,
        is_chiller_stock boolean,
        barcode varchar(50),
        tax_rate numeric(18,3),
        unit_price numeric(18,2),
        recommended_retail_price numeric(18,2),
        typical_weight_per_unit numeric(18,3),
        photo bytea,
        valid_from timestamp,
        valid_to timestamp
    );
    
    INSERT INTO temp_stock_item_changes
    SELECT si.stockitemid, si.stockitemname, c.colorname,
           up.packagetypename AS unit_package, op.packagetypename AS outer_package,
           si.brand, si.size, si.leadtimedays, si.quantityperouter,
           si.ischillerstock, si.barcode, si.taxrate, si.unitprice,
           si.recommendedretailprice, si.typicalweightperunit, si.photo,
           si.validfrom, NULL
    FROM (
        SELECT stockitemid, validfrom FROM warehouse.stockitems_archive
        WHERE validfrom > p_last_cutoff AND validfrom <= p_new_cutoff
        UNION ALL
        SELECT stockitemid, validfrom FROM warehouse.stockitems
        WHERE validfrom > p_last_cutoff AND validfrom <= p_new_cutoff
    ) stock_changes
    INNER JOIN warehouse.stockitems si ON stock_changes.stockitemid = si.stockitemid
    LEFT JOIN warehouse.colors c ON si.colorid = c.colorid
    LEFT JOIN warehouse.packagetypes up ON si.unitpackageid = up.packagetypeid
    LEFT JOIN warehouse.packagetypes op ON si.outerpackageid = op.packagetypeid;
    
    CREATE INDEX ON temp_stock_item_changes (wwi_stock_item_id, valid_from);
    
    UPDATE temp_stock_item_changes sc
    SET valid_to = COALESCE(
        (SELECT MIN(valid_from) FROM temp_stock_item_changes sc2
         WHERE sc2.wwi_stock_item_id = sc.wwi_stock_item_id AND sc2.valid_from > sc.valid_from),
        v_end_of_time
    );
    
    OPEN p_results FOR
    SELECT wwi_stock_item_id AS "WWI Stock Item ID", stock_item AS "Stock Item",
           color AS "Color", unit_package AS "Unit Package", outer_package AS "Outer Package",
           brand AS "Brand", size AS "Size", lead_time_days AS "Lead Time Days",
           quantity_per_outer AS "Quantity Per Outer", is_chiller_stock AS "Is Chiller Stock",
           barcode AS "Barcode", tax_rate AS "Tax Rate", unit_price AS "Unit Price",
           recommended_retail_price AS "Recommended Retail Price",
           typical_weight_per_unit AS "Typical Weight Per Unit", photo AS "Photo",
           valid_from AS "Valid From", valid_to AS "Valid To"
    FROM temp_stock_item_changes
    ORDER BY valid_from;
END;
$$;

-- =============================================
-- Procedure: Integration.GetSupplierUpdates
-- Description: Gets supplier updates between two cutoff times for ETL
-- =============================================
CREATE OR REPLACE PROCEDURE integration.get_supplier_updates(
    p_last_cutoff timestamp,
    p_new_cutoff timestamp,
    INOUT p_results refcursor DEFAULT NULL
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_end_of_time timestamp := '9999-12-31 23:59:59.999999'::timestamp;
BEGIN
    DROP TABLE IF EXISTS temp_supplier_changes;
    CREATE TEMP TABLE temp_supplier_changes (
        wwi_supplier_id integer,
        supplier varchar(100),
        category varchar(50),
        primary_contact varchar(50),
        supplier_reference varchar(20),
        payment_days integer,
        postal_code varchar(10),
        valid_from timestamp,
        valid_to timestamp
    );
    
    INSERT INTO temp_supplier_changes
    SELECT s.supplierid, s.suppliername, sc.suppliercategoryname,
           p.fullname AS primary_contact, s.supplierreference,
           s.paymentdays, s.deliverypostalcode, s.validfrom, NULL
    FROM (
        SELECT supplierid, validfrom FROM purchasing.suppliers_archive
        WHERE validfrom > p_last_cutoff AND validfrom <= p_new_cutoff
        UNION ALL
        SELECT supplierid, validfrom FROM purchasing.suppliers
        WHERE validfrom > p_last_cutoff AND validfrom <= p_new_cutoff
    ) supplier_changes
    INNER JOIN purchasing.suppliers s ON supplier_changes.supplierid = s.supplierid
    LEFT JOIN purchasing.suppliercategories sc ON s.suppliercategoryid = sc.suppliercategoryid
    LEFT JOIN application.people p ON s.primarycontactpersonid = p.personid;
    
    CREATE INDEX ON temp_supplier_changes (wwi_supplier_id, valid_from);
    
    UPDATE temp_supplier_changes sc
    SET valid_to = COALESCE(
        (SELECT MIN(valid_from) FROM temp_supplier_changes sc2
         WHERE sc2.wwi_supplier_id = sc.wwi_supplier_id AND sc2.valid_from > sc.valid_from),
        v_end_of_time
    );
    
    OPEN p_results FOR
    SELECT wwi_supplier_id AS "WWI Supplier ID", supplier AS "Supplier",
           category AS "Category", primary_contact AS "Primary Contact",
           supplier_reference AS "Supplier Reference", payment_days AS "Payment Days",
           postal_code AS "Postal Code", valid_from AS "Valid From", valid_to AS "Valid To"
    FROM temp_supplier_changes
    ORDER BY valid_from;
END;
$$;

-- =============================================
-- Procedure: Integration.GetPaymentMethodUpdates
-- Description: Gets payment method updates between two cutoff times for ETL
-- =============================================
CREATE OR REPLACE PROCEDURE integration.get_payment_method_updates(
    p_last_cutoff timestamp,
    p_new_cutoff timestamp,
    INOUT p_results refcursor DEFAULT NULL
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_end_of_time timestamp := '9999-12-31 23:59:59.999999'::timestamp;
BEGIN
    OPEN p_results FOR
    SELECT pm.paymentmethodid AS "WWI Payment Method ID",
           pm.paymentmethodname AS "Payment Method",
           pm.validfrom AS "Valid From",
           COALESCE(pm.validto, v_end_of_time) AS "Valid To"
    FROM (
        SELECT paymentmethodid, paymentmethodname, validfrom, validto
        FROM application.paymentmethods_archive
        WHERE validfrom > p_last_cutoff AND validfrom <= p_new_cutoff
        UNION ALL
        SELECT paymentmethodid, paymentmethodname, validfrom, validto
        FROM application.paymentmethods
        WHERE validfrom > p_last_cutoff AND validfrom <= p_new_cutoff
    ) pm
    ORDER BY pm.validfrom;
END;
$$;

-- =============================================
-- Procedure: Integration.GetTransactionTypeUpdates
-- Description: Gets transaction type updates between two cutoff times for ETL
-- =============================================
CREATE OR REPLACE PROCEDURE integration.get_transaction_type_updates(
    p_last_cutoff timestamp,
    p_new_cutoff timestamp,
    INOUT p_results refcursor DEFAULT NULL
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_end_of_time timestamp := '9999-12-31 23:59:59.999999'::timestamp;
BEGIN
    OPEN p_results FOR
    SELECT tt.transactiontypeid AS "WWI Transaction Type ID",
           tt.transactiontypename AS "Transaction Type",
           tt.validfrom AS "Valid From",
           COALESCE(tt.validto, v_end_of_time) AS "Valid To"
    FROM (
        SELECT transactiontypeid, transactiontypename, validfrom, validto
        FROM application.transactiontypes_archive
        WHERE validfrom > p_last_cutoff AND validfrom <= p_new_cutoff
        UNION ALL
        SELECT transactiontypeid, transactiontypename, validfrom, validto
        FROM application.transactiontypes
        WHERE validfrom > p_last_cutoff AND validfrom <= p_new_cutoff
    ) tt
    ORDER BY tt.validfrom;
END;
$$;

-- =============================================
-- Procedure: Integration.GetOrderUpdates
-- Description: Gets order updates between two cutoff times for ETL
-- =============================================
CREATE OR REPLACE PROCEDURE integration.get_order_updates(
    p_last_cutoff timestamp,
    p_new_cutoff timestamp,
    INOUT p_results refcursor DEFAULT NULL
)
LANGUAGE plpgsql
AS $$
BEGIN
    OPEN p_results FOR
    SELECT o.orderid AS "WWI Order ID",
           o.customerid AS "WWI Customer ID",
           o.salespersonpersonid AS "WWI Salesperson ID",
           o.pickedbypersonid AS "WWI Picker ID",
           o.orderdate AS "Order Date",
           o.expecteddeliverydate AS "Expected Delivery Date",
           o.customerpurchaseordernumber AS "Customer Purchase Order Number",
           o.isundersupplybackordered AS "Is Undersupply Backordered",
           o.pickingcompletedwhen AS "Picking Completed When",
           o.lasteditedwhen AS "Last Edited When"
    FROM sales.orders o
    WHERE o.lasteditedwhen > p_last_cutoff AND o.lasteditedwhen <= p_new_cutoff
    ORDER BY o.lasteditedwhen;
END;
$$;

-- =============================================
-- Procedure: Integration.GetSaleUpdates
-- Description: Gets sale (invoice) updates between two cutoff times for ETL
-- =============================================
CREATE OR REPLACE PROCEDURE integration.get_sale_updates(
    p_last_cutoff timestamp,
    p_new_cutoff timestamp,
    INOUT p_results refcursor DEFAULT NULL
)
LANGUAGE plpgsql
AS $$
BEGIN
    OPEN p_results FOR
    SELECT i.invoiceid AS "WWI Invoice ID",
           i.customerid AS "WWI Customer ID",
           i.billtocustomerid AS "WWI Bill To Customer ID",
           i.salespersonpersonid AS "WWI Salesperson ID",
           i.invoicedate AS "Invoice Date",
           i.deliverymethodid AS "WWI Delivery Method ID",
           c.deliverycityid AS "WWI City ID",
           il.stockitemid AS "WWI Stock Item ID",
           il.description AS "Description",
           il.quantity AS "Quantity",
           il.unitprice AS "Unit Price",
           il.taxrate AS "Tax Rate",
           il.taxamount AS "Tax Amount",
           il.lineprofit AS "Line Profit",
           il.extendedprice AS "Extended Price",
           i.lasteditedwhen AS "Last Edited When"
    FROM sales.invoices i
    INNER JOIN sales.invoicelines il ON i.invoiceid = il.invoiceid
    INNER JOIN sales.customers c ON i.customerid = c.customerid
    WHERE i.lasteditedwhen > p_last_cutoff AND i.lasteditedwhen <= p_new_cutoff
    ORDER BY i.lasteditedwhen, il.invoicelineid;
END;
$$;

-- =============================================
-- Procedure: Integration.GetPurchaseUpdates
-- Description: Gets purchase order updates between two cutoff times for ETL
-- =============================================
CREATE OR REPLACE PROCEDURE integration.get_purchase_updates(
    p_last_cutoff timestamp,
    p_new_cutoff timestamp,
    INOUT p_results refcursor DEFAULT NULL
)
LANGUAGE plpgsql
AS $$
BEGIN
    OPEN p_results FOR
    SELECT po.purchaseorderid AS "WWI Purchase Order ID",
           po.supplierid AS "WWI Supplier ID",
           po.orderdate AS "Order Date",
           po.expecteddeliverydate AS "Expected Delivery Date",
           pol.stockitemid AS "WWI Stock Item ID",
           pol.orderedouters AS "Ordered Outers",
           pol.receivedouters AS "Received Outers",
           pol.expectedunitpriceperouter AS "Expected Unit Price Per Outer",
           pol.lasteditedwhen AS "Last Edited When"
    FROM purchasing.purchaseorders po
    INNER JOIN purchasing.purchaseorderlines pol ON po.purchaseorderid = pol.purchaseorderid
    WHERE pol.lasteditedwhen > p_last_cutoff AND pol.lasteditedwhen <= p_new_cutoff
    ORDER BY pol.lasteditedwhen, pol.purchaseorderlineid;
END;
$$;

-- =============================================
-- Procedure: Integration.GetMovementUpdates
-- Description: Gets stock movement updates between two cutoff times for ETL
-- =============================================
CREATE OR REPLACE PROCEDURE integration.get_movement_updates(
    p_last_cutoff timestamp,
    p_new_cutoff timestamp,
    INOUT p_results refcursor DEFAULT NULL
)
LANGUAGE plpgsql
AS $$
BEGIN
    OPEN p_results FOR
    SELECT sit.stockitemtransactionid AS "WWI Stock Item Transaction ID",
           sit.stockitemid AS "WWI Stock Item ID",
           sit.transactiontypeid AS "WWI Transaction Type ID",
           sit.customerid AS "WWI Customer ID",
           sit.invoiceid AS "WWI Invoice ID",
           sit.supplierid AS "WWI Supplier ID",
           sit.purchaseorderid AS "WWI Purchase Order ID",
           sit.transactionoccurredwhen AS "Transaction Occurred When",
           sit.quantity AS "Quantity",
           sit.lasteditedwhen AS "Last Edited When"
    FROM warehouse.stockitemtransactions sit
    WHERE sit.lasteditedwhen > p_last_cutoff AND sit.lasteditedwhen <= p_new_cutoff
    ORDER BY sit.lasteditedwhen, sit.stockitemtransactionid;
END;
$$;

-- =============================================
-- Procedure: Integration.GetTransactionUpdates
-- Description: Gets customer/supplier transaction updates between two cutoff times for ETL
-- =============================================
CREATE OR REPLACE PROCEDURE integration.get_transaction_updates(
    p_last_cutoff timestamp,
    p_new_cutoff timestamp,
    INOUT p_results refcursor DEFAULT NULL
)
LANGUAGE plpgsql
AS $$
BEGIN
    OPEN p_results FOR
    SELECT 'Customer' AS "Transaction Source",
           ct.customertransactionid AS "WWI Transaction ID",
           ct.customerid AS "WWI Customer ID",
           NULL::integer AS "WWI Supplier ID",
           ct.transactiontypeid AS "WWI Transaction Type ID",
           ct.paymentmethodid AS "WWI Payment Method ID",
           ct.invoiceid AS "WWI Invoice ID",
           NULL::integer AS "WWI Purchase Order ID",
           ct.transactiondate AS "Transaction Date",
           ct.amountexcludingtax AS "Amount Excluding Tax",
           ct.taxamount AS "Tax Amount",
           ct.transactionamount AS "Transaction Amount",
           ct.outstandingbalance AS "Outstanding Balance",
           ct.finalizationdate AS "Finalization Date",
           ct.lasteditedwhen AS "Last Edited When"
    FROM sales.customertransactions ct
    WHERE ct.lasteditedwhen > p_last_cutoff AND ct.lasteditedwhen <= p_new_cutoff
    UNION ALL
    SELECT 'Supplier' AS "Transaction Source",
           st.suppliertransactionid AS "WWI Transaction ID",
           NULL::integer AS "WWI Customer ID",
           st.supplierid AS "WWI Supplier ID",
           st.transactiontypeid AS "WWI Transaction Type ID",
           st.paymentmethodid AS "WWI Payment Method ID",
           NULL::integer AS "WWI Invoice ID",
           st.purchaseorderid AS "WWI Purchase Order ID",
           st.transactiondate AS "Transaction Date",
           st.amountexcludingtax AS "Amount Excluding Tax",
           st.taxamount AS "Tax Amount",
           st.transactionamount AS "Transaction Amount",
           st.outstandingbalance AS "Outstanding Balance",
           st.finalizationdate AS "Finalization Date",
           st.lasteditedwhen AS "Last Edited When"
    FROM purchasing.suppliertransactions st
    WHERE st.lasteditedwhen > p_last_cutoff AND st.lasteditedwhen <= p_new_cutoff
    ORDER BY "Last Edited When", "WWI Transaction ID";
END;
$$;

-- =============================================
-- Procedure: Integration.GetStockHoldingUpdates
-- Description: Gets stock holding updates between two cutoff times for ETL
-- =============================================
CREATE OR REPLACE PROCEDURE integration.get_stock_holding_updates(
    p_last_cutoff timestamp,
    p_new_cutoff timestamp,
    INOUT p_results refcursor DEFAULT NULL
)
LANGUAGE plpgsql
AS $$
BEGIN
    OPEN p_results FOR
    SELECT sih.stockitemid AS "WWI Stock Item ID",
           sih.quantityonhand AS "Quantity On Hand",
           sih.binlocation AS "Bin Location",
           sih.lastreceiptdate AS "Last Receipt Date",
           sih.lastcostprice AS "Last Cost Price",
           sih.reorderlevel AS "Reorder Level",
           sih.targetstocklevel AS "Target Stock Level",
           sih.lasteditedwhen AS "Last Edited When"
    FROM warehouse.stockitemholdings sih
    WHERE sih.lasteditedwhen > p_last_cutoff AND sih.lasteditedwhen <= p_new_cutoff
    ORDER BY sih.lasteditedwhen, sih.stockitemid;
END;
$$;

COMMENT ON PROCEDURE integration.get_city_updates(timestamp, timestamp, refcursor) IS 
'Gets city updates between two cutoff times for ETL to the data warehouse';

COMMENT ON PROCEDURE integration.get_customer_updates(timestamp, timestamp, refcursor) IS 
'Gets customer updates between two cutoff times for ETL to the data warehouse';

COMMENT ON PROCEDURE integration.get_employee_updates(timestamp, timestamp, refcursor) IS 
'Gets employee updates between two cutoff times for ETL to the data warehouse';

COMMENT ON PROCEDURE integration.get_stock_item_updates(timestamp, timestamp, refcursor) IS 
'Gets stock item updates between two cutoff times for ETL to the data warehouse';

COMMENT ON PROCEDURE integration.get_supplier_updates(timestamp, timestamp, refcursor) IS 
'Gets supplier updates between two cutoff times for ETL to the data warehouse';

COMMENT ON PROCEDURE integration.get_sale_updates(timestamp, timestamp, refcursor) IS 
'Gets sale (invoice) updates between two cutoff times for ETL to the data warehouse';

COMMENT ON PROCEDURE integration.get_purchase_updates(timestamp, timestamp, refcursor) IS 
'Gets purchase order updates between two cutoff times for ETL to the data warehouse';

COMMENT ON PROCEDURE integration.get_movement_updates(timestamp, timestamp, refcursor) IS 
'Gets stock movement updates between two cutoff times for ETL to the data warehouse';

COMMENT ON PROCEDURE integration.get_transaction_updates(timestamp, timestamp, refcursor) IS 
'Gets customer/supplier transaction updates between two cutoff times for ETL to the data warehouse';
