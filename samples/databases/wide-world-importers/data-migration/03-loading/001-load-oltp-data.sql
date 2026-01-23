-- Wide World Importers PostgreSQL Migration
-- Phase 6: Data Migration and Validation
-- File: 001-load-oltp-data.sql
-- Description: PostgreSQL COPY commands to load transformed OLTP data
--
-- Prerequisites:
-- 1. PostgreSQL schema must be created (run postgres-migration/install.sql first)
-- 2. Data must be extracted and transformed
-- 3. Constraints should be disabled during load for performance
--
-- Usage: Run this script against the PostgreSQL database
-- psql -d wideworldimporters -f 001-load-oltp-data.sql

-- =============================================
-- Pre-Load Setup
-- =============================================

-- Disable triggers during bulk load
SET session_replication_role = 'replica';

-- Set work_mem for better COPY performance
SET work_mem = '256MB';

-- =============================================
-- Helper function to load data with geography conversion
-- =============================================

-- Create a temporary staging table function for geography data
CREATE OR REPLACE FUNCTION migration.load_with_geography(
    p_table_name text,
    p_file_path text,
    p_geography_column text,
    p_geography_position int
) RETURNS void AS $$
BEGIN
    -- This function would be called from the shell script
    -- to handle geography conversion during load
    RAISE NOTICE 'Loading % from %', p_table_name, p_file_path;
END;
$$ LANGUAGE plpgsql;

-- =============================================
-- Application Schema - Current Tables
-- =============================================

-- Application.People
\echo 'Loading Application.People...'
COPY application.people (
    personid, fullname, preferredname, ispermittedtologon, logonname,
    isexternallogonprovider, hashedpassword, issystemuser, isemployee,
    issalesperson, userpreferences, phonenumber, faxnumber, emailaddress,
    photo, customfields, lasteditedby, validfrom, validto
) FROM :'data_dir'/oltp/current/application_people.csv
WITH (FORMAT csv, DELIMITER '|', NULL '', QUOTE '"');

-- Application.Countries (without geography for now)
\echo 'Loading Application.Countries...'
CREATE TEMP TABLE countries_staging (
    countryid integer,
    countryname varchar(60),
    formalname varchar(60),
    isoalpha3code varchar(3),
    isonumericcode integer,
    countrytype varchar(20),
    latestrecordedpopulation bigint,
    continent varchar(30),
    region varchar(30),
    subregion varchar(30),
    border_wkt text,
    lasteditedby integer,
    validfrom timestamp,
    validto timestamp
);

COPY countries_staging FROM :'data_dir'/oltp/current/application_countries.csv
WITH (FORMAT csv, DELIMITER '|', NULL '', QUOTE '"');

INSERT INTO application.countries (
    countryid, countryname, formalname, isoalpha3code, isonumericcode,
    countrytype, latestrecordedpopulation, continent, region, subregion,
    border, lasteditedby, validfrom, validto
)
SELECT 
    countryid, countryname, formalname, isoalpha3code, isonumericcode,
    countrytype, latestrecordedpopulation, continent, region, subregion,
    CASE WHEN border_wkt IS NOT NULL AND border_wkt != '' 
         THEN ST_GeogFromText(border_wkt) 
         ELSE NULL END,
    lasteditedby, validfrom, validto
FROM countries_staging;

DROP TABLE countries_staging;

-- Application.StateProvinces
\echo 'Loading Application.StateProvinces...'
CREATE TEMP TABLE stateprovinces_staging (
    stateprovinceid integer,
    stateprovincecode varchar(5),
    stateprovincename varchar(50),
    countryid integer,
    salesterritory varchar(50),
    border_wkt text,
    latestrecordedpopulation bigint,
    lasteditedby integer,
    validfrom timestamp,
    validto timestamp
);

COPY stateprovinces_staging FROM :'data_dir'/oltp/current/application_stateprovinces.csv
WITH (FORMAT csv, DELIMITER '|', NULL '', QUOTE '"');

INSERT INTO application.stateprovinces (
    stateprovinceid, stateprovincecode, stateprovincename, countryid,
    salesterritory, border, latestrecordedpopulation, lasteditedby,
    validfrom, validto
)
SELECT 
    stateprovinceid, stateprovincecode, stateprovincename, countryid,
    salesterritory,
    CASE WHEN border_wkt IS NOT NULL AND border_wkt != '' 
         THEN ST_GeogFromText(border_wkt) 
         ELSE NULL END,
    latestrecordedpopulation, lasteditedby, validfrom, validto
FROM stateprovinces_staging;

DROP TABLE stateprovinces_staging;

-- Application.Cities
\echo 'Loading Application.Cities...'
CREATE TEMP TABLE cities_staging (
    cityid integer,
    cityname varchar(50),
    stateprovinceid integer,
    location_wkt text,
    latestrecordedpopulation bigint,
    lasteditedby integer,
    validfrom timestamp,
    validto timestamp
);

COPY cities_staging FROM :'data_dir'/oltp/current/application_cities.csv
WITH (FORMAT csv, DELIMITER '|', NULL '', QUOTE '"');

INSERT INTO application.cities (
    cityid, cityname, stateprovinceid, location, latestrecordedpopulation,
    lasteditedby, validfrom, validto
)
SELECT 
    cityid, cityname, stateprovinceid,
    CASE WHEN location_wkt IS NOT NULL AND location_wkt != '' 
         THEN ST_GeogFromText(location_wkt) 
         ELSE NULL END,
    latestrecordedpopulation, lasteditedby, validfrom, validto
FROM cities_staging;

DROP TABLE cities_staging;

-- Application.DeliveryMethods
\echo 'Loading Application.DeliveryMethods...'
COPY application.deliverymethods (
    deliverymethodid, deliverymethodname, lasteditedby, validfrom, validto
) FROM :'data_dir'/oltp/current/application_deliverymethods.csv
WITH (FORMAT csv, DELIMITER '|', NULL '', QUOTE '"');

-- Application.PaymentMethods
\echo 'Loading Application.PaymentMethods...'
COPY application.paymentmethods (
    paymentmethodid, paymentmethodname, lasteditedby, validfrom, validto
) FROM :'data_dir'/oltp/current/application_paymentmethods.csv
WITH (FORMAT csv, DELIMITER '|', NULL '', QUOTE '"');

-- Application.TransactionTypes
\echo 'Loading Application.TransactionTypes...'
COPY application.transactiontypes (
    transactiontypeid, transactiontypename, lasteditedby, validfrom, validto
) FROM :'data_dir'/oltp/current/application_transactiontypes.csv
WITH (FORMAT csv, DELIMITER '|', NULL '', QUOTE '"');

-- Application.SystemParameters
\echo 'Loading Application.SystemParameters...'
CREATE TEMP TABLE systemparameters_staging (
    systemparameterid integer,
    deliveryaddressline1 varchar(60),
    deliveryaddressline2 varchar(60),
    deliverycityid integer,
    deliverypostalcode varchar(10),
    deliverylocation_wkt text,
    postaladdressline1 varchar(60),
    postaladdressline2 varchar(60),
    postalcityid integer,
    postalpostalcode varchar(10),
    applicationsettings text,
    lasteditedby integer,
    lasteditedwhen timestamp
);

COPY systemparameters_staging FROM :'data_dir'/oltp/current/application_systemparameters.csv
WITH (FORMAT csv, DELIMITER '|', NULL '', QUOTE '"');

INSERT INTO application.systemparameters (
    systemparameterid, deliveryaddressline1, deliveryaddressline2,
    deliverycityid, deliverypostalcode, deliverylocation,
    postaladdressline1, postaladdressline2, postalcityid, postalpostalcode,
    applicationsettings, lasteditedby, lasteditedwhen
)
SELECT 
    systemparameterid, deliveryaddressline1, deliveryaddressline2,
    deliverycityid, deliverypostalcode,
    CASE WHEN deliverylocation_wkt IS NOT NULL AND deliverylocation_wkt != '' 
         THEN ST_GeogFromText(deliverylocation_wkt) 
         ELSE NULL END,
    postaladdressline1, postaladdressline2, postalcityid, postalpostalcode,
    applicationsettings, lasteditedby, lasteditedwhen
FROM systemparameters_staging;

DROP TABLE systemparameters_staging;

-- =============================================
-- Warehouse Schema - Current Tables
-- =============================================

-- Warehouse.Colors
\echo 'Loading Warehouse.Colors...'
COPY warehouse.colors (
    colorid, colorname, lasteditedby, validfrom, validto
) FROM :'data_dir'/oltp/current/warehouse_colors.csv
WITH (FORMAT csv, DELIMITER '|', NULL '', QUOTE '"');

-- Warehouse.PackageTypes
\echo 'Loading Warehouse.PackageTypes...'
COPY warehouse.packagetypes (
    packagetypeid, packagetypename, lasteditedby, validfrom, validto
) FROM :'data_dir'/oltp/current/warehouse_packagetypes.csv
WITH (FORMAT csv, DELIMITER '|', NULL '', QUOTE '"');

-- Warehouse.StockGroups
\echo 'Loading Warehouse.StockGroups...'
COPY warehouse.stockgroups (
    stockgroupid, stockgroupname, lasteditedby, validfrom, validto
) FROM :'data_dir'/oltp/current/warehouse_stockgroups.csv
WITH (FORMAT csv, DELIMITER '|', NULL '', QUOTE '"');

-- Warehouse.StockItems (without computed columns)
\echo 'Loading Warehouse.StockItems...'
CREATE TEMP TABLE stockitems_staging (
    stockitemid integer,
    stockitemname varchar(100),
    supplierid integer,
    colorid integer,
    unitpackageid integer,
    outerpackageid integer,
    brand varchar(50),
    size varchar(20),
    leadtimedays integer,
    quantityperouter integer,
    ischillerstock boolean,
    barcode varchar(50),
    taxrate numeric(18,3),
    unitprice numeric(18,2),
    recommendedretailprice numeric(18,2),
    typicalweightperunit numeric(18,3),
    marketingcomments text,
    internalcomments text,
    photo bytea,
    customfields text,
    lasteditedby integer,
    validfrom timestamp,
    validto timestamp
);

COPY stockitems_staging FROM :'data_dir'/oltp/current/warehouse_stockitems.csv
WITH (FORMAT csv, DELIMITER '|', NULL '', QUOTE '"');

INSERT INTO warehouse.stockitems (
    stockitemid, stockitemname, supplierid, colorid, unitpackageid,
    outerpackageid, brand, size, leadtimedays, quantityperouter,
    ischillerstock, barcode, taxrate, unitprice, recommendedretailprice,
    typicalweightperunit, marketingcomments, internalcomments, photo,
    customfields, lasteditedby, validfrom, validto
)
SELECT * FROM stockitems_staging;

DROP TABLE stockitems_staging;

-- Warehouse.StockItemHoldings
\echo 'Loading Warehouse.StockItemHoldings...'
COPY warehouse.stockitemholdings (
    stockitemid, quantityonhand, binlocation, laststocktakequantity,
    lastcostprice, reorderlevel, targetstocklevel, lasteditedby, lasteditedwhen
) FROM :'data_dir'/oltp/current/warehouse_stockitemholdings.csv
WITH (FORMAT csv, DELIMITER '|', NULL '', QUOTE '"');

-- Warehouse.StockItemStockGroups
\echo 'Loading Warehouse.StockItemStockGroups...'
COPY warehouse.stockitemstockgroups (
    stockitemstockgroupid, stockitemid, stockgroupid, lasteditedby, lasteditedwhen
) FROM :'data_dir'/oltp/current/warehouse_stockitemstockgroups.csv
WITH (FORMAT csv, DELIMITER '|', NULL '', QUOTE '"');

-- Warehouse.StockItemTransactions
\echo 'Loading Warehouse.StockItemTransactions...'
COPY warehouse.stockitemtransactions (
    stockitemtransactionid, stockitemid, transactiontypeid, customerid,
    invoiceid, supplierid, purchaseorderid, transactionoccurredwhen,
    quantity, lasteditedby, lasteditedwhen
) FROM :'data_dir'/oltp/current/warehouse_stockitemtransactions.csv
WITH (FORMAT csv, DELIMITER '|', NULL '', QUOTE '"');

-- Warehouse.ColdRoomTemperatures
\echo 'Loading Warehouse.ColdRoomTemperatures...'
COPY warehouse.coldroomtemperatures (
    coldroomtemperatureid, coldroomsensornumber, recordedwhen, temperature,
    validfrom, validto
) FROM :'data_dir'/oltp/current/warehouse_coldroomtemperatures.csv
WITH (FORMAT csv, DELIMITER '|', NULL '', QUOTE '"');

-- Warehouse.VehicleTemperatures
\echo 'Loading Warehouse.VehicleTemperatures...'
COPY warehouse.vehicletemperatures (
    vehicletemperatureid, vehicleregistration, chillersensornumber,
    recordedwhen, temperature, fullsensordata, iscompressed, compressedsensordata
) FROM :'data_dir'/oltp/current/warehouse_vehicletemperatures.csv
WITH (FORMAT csv, DELIMITER '|', NULL '', QUOTE '"');

-- =============================================
-- Sales Schema - Current Tables
-- =============================================

-- Sales.BuyingGroups
\echo 'Loading Sales.BuyingGroups...'
COPY sales.buyinggroups (
    buyinggroupid, buyinggroupname, lasteditedby, validfrom, validto
) FROM :'data_dir'/oltp/current/sales_buyinggroups.csv
WITH (FORMAT csv, DELIMITER '|', NULL '', QUOTE '"');

-- Sales.CustomerCategories
\echo 'Loading Sales.CustomerCategories...'
COPY sales.customercategories (
    customercategoryid, customercategoryname, lasteditedby, validfrom, validto
) FROM :'data_dir'/oltp/current/sales_customercategories.csv
WITH (FORMAT csv, DELIMITER '|', NULL '', QUOTE '"');

-- Sales.Customers
\echo 'Loading Sales.Customers...'
CREATE TEMP TABLE customers_staging (
    customerid integer,
    customername varchar(100),
    billtocustomerid integer,
    customercategoryid integer,
    buyinggroupid integer,
    primarycontactpersonid integer,
    alternatecontactpersonid integer,
    deliverymethodid integer,
    deliverycityid integer,
    postalcityid integer,
    creditlimit numeric(18,2),
    accountopeneddate date,
    standarddiscountpercentage numeric(18,3),
    isstatementsent boolean,
    isoncredithold boolean,
    paymentdays integer,
    phonenumber varchar(20),
    faxnumber varchar(20),
    deliveryrun varchar(5),
    runposition varchar(5),
    websiteurl varchar(256),
    deliveryaddressline1 varchar(60),
    deliveryaddressline2 varchar(60),
    deliverypostalcode varchar(10),
    deliverylocation_wkt text,
    postaladdressline1 varchar(60),
    postaladdressline2 varchar(60),
    postalpostalcode varchar(10),
    lasteditedby integer,
    validfrom timestamp,
    validto timestamp
);

COPY customers_staging FROM :'data_dir'/oltp/current/sales_customers.csv
WITH (FORMAT csv, DELIMITER '|', NULL '', QUOTE '"');

INSERT INTO sales.customers (
    customerid, customername, billtocustomerid, customercategoryid,
    buyinggroupid, primarycontactpersonid, alternatecontactpersonid,
    deliverymethodid, deliverycityid, postalcityid, creditlimit,
    accountopeneddate, standarddiscountpercentage, isstatementsent,
    isoncredithold, paymentdays, phonenumber, faxnumber, deliveryrun,
    runposition, websiteurl, deliveryaddressline1, deliveryaddressline2,
    deliverypostalcode, deliverylocation, postaladdressline1,
    postaladdressline2, postalpostalcode, lasteditedby, validfrom, validto
)
SELECT 
    customerid, customername, billtocustomerid, customercategoryid,
    buyinggroupid, primarycontactpersonid, alternatecontactpersonid,
    deliverymethodid, deliverycityid, postalcityid, creditlimit,
    accountopeneddate, standarddiscountpercentage, isstatementsent,
    isoncredithold, paymentdays, phonenumber, faxnumber, deliveryrun,
    runposition, websiteurl, deliveryaddressline1, deliveryaddressline2,
    deliverypostalcode,
    CASE WHEN deliverylocation_wkt IS NOT NULL AND deliverylocation_wkt != '' 
         THEN ST_GeogFromText(deliverylocation_wkt) 
         ELSE NULL END,
    postaladdressline1, postaladdressline2, postalpostalcode,
    lasteditedby, validfrom, validto
FROM customers_staging;

DROP TABLE customers_staging;

-- Sales.Orders
\echo 'Loading Sales.Orders...'
COPY sales.orders (
    orderid, customerid, salespersonpersonid, pickedbypersonid,
    contactpersonid, backorderorderid, orderdate, expecteddeliverydate,
    customerpurchaseordernumber, isundersupplybackordered, comments,
    deliveryinstructions, internalcomments, pickingcompletedwhen,
    lasteditedby, lasteditedwhen
) FROM :'data_dir'/oltp/current/sales_orders.csv
WITH (FORMAT csv, DELIMITER '|', NULL '', QUOTE '"');

-- Sales.OrderLines
\echo 'Loading Sales.OrderLines...'
COPY sales.orderlines (
    orderlineid, orderid, stockitemid, description, packagetypeid,
    quantity, unitprice, taxrate, pickedquantity, pickingcompletedwhen,
    lasteditedby, lasteditedwhen
) FROM :'data_dir'/oltp/current/sales_orderlines.csv
WITH (FORMAT csv, DELIMITER '|', NULL '', QUOTE '"');

-- Sales.Invoices
\echo 'Loading Sales.Invoices...'
COPY sales.invoices (
    invoiceid, customerid, billtocustomerid, orderid, deliverymethodid,
    contactpersonid, accountspersonid, salespersonpersonid, packedbypersonid,
    invoicedate, customerpurchaseordernumber, iscreditnote, creditnotereason,
    comments, deliveryinstructions, internalcomments, totaldryitems,
    totalchilleritems, deliveryrun, runposition, returneddeliverydata,
    lasteditedby, lasteditedwhen
) FROM :'data_dir'/oltp/current/sales_invoices.csv
WITH (FORMAT csv, DELIMITER '|', NULL '', QUOTE '"');

-- Sales.InvoiceLines
\echo 'Loading Sales.InvoiceLines...'
COPY sales.invoicelines (
    invoicelineid, invoiceid, stockitemid, description, packagetypeid,
    quantity, unitprice, taxrate, taxamount, lineprofit, extendedprice,
    lasteditedby, lasteditedwhen
) FROM :'data_dir'/oltp/current/sales_invoicelines.csv
WITH (FORMAT csv, DELIMITER '|', NULL '', QUOTE '"');

-- Sales.SpecialDeals
\echo 'Loading Sales.SpecialDeals...'
COPY sales.specialdeals (
    specialdealid, stockitemid, customerid, buyinggroupid, customercategoryid,
    stockgroupid, dealdescription, startdate, enddate, discountamount,
    discountpercentage, unitprice, lasteditedby, lasteditedwhen
) FROM :'data_dir'/oltp/current/sales_specialdeals.csv
WITH (FORMAT csv, DELIMITER '|', NULL '', QUOTE '"');

-- Sales.CustomerTransactions (without computed column)
\echo 'Loading Sales.CustomerTransactions...'
COPY sales.customertransactions (
    customertransactionid, customerid, transactiontypeid, invoiceid,
    paymentmethodid, transactiondate, amountexcludingtax, taxamount,
    transactionamount, outstandingbalance, finalizationdate,
    lasteditedby, lasteditedwhen
) FROM :'data_dir'/oltp/current/sales_customertransactions.csv
WITH (FORMAT csv, DELIMITER '|', NULL '', QUOTE '"');

-- =============================================
-- Purchasing Schema - Current Tables
-- =============================================

-- Purchasing.SupplierCategories
\echo 'Loading Purchasing.SupplierCategories...'
COPY purchasing.suppliercategories (
    suppliercategoryid, suppliercategoryname, lasteditedby, validfrom, validto
) FROM :'data_dir'/oltp/current/purchasing_suppliercategories.csv
WITH (FORMAT csv, DELIMITER '|', NULL '', QUOTE '"');

-- Purchasing.Suppliers
\echo 'Loading Purchasing.Suppliers...'
CREATE TEMP TABLE suppliers_staging (
    supplierid integer,
    suppliername varchar(100),
    suppliercategoryid integer,
    primarycontactpersonid integer,
    alternatecontactpersonid integer,
    deliverymethodid integer,
    deliverycityid integer,
    postalcityid integer,
    supplierreference varchar(20),
    bankaccountname varchar(50),
    bankaccountbranch varchar(50),
    bankaccountcode varchar(20),
    bankaccountnumber varchar(20),
    bankinternationalcode varchar(20),
    paymentdays integer,
    internalcomments text,
    phonenumber varchar(20),
    faxnumber varchar(20),
    websiteurl varchar(256),
    deliveryaddressline1 varchar(60),
    deliveryaddressline2 varchar(60),
    deliverypostalcode varchar(10),
    deliverylocation_wkt text,
    postaladdressline1 varchar(60),
    postaladdressline2 varchar(60),
    postalpostalcode varchar(10),
    lasteditedby integer,
    validfrom timestamp,
    validto timestamp
);

COPY suppliers_staging FROM :'data_dir'/oltp/current/purchasing_suppliers.csv
WITH (FORMAT csv, DELIMITER '|', NULL '', QUOTE '"');

INSERT INTO purchasing.suppliers (
    supplierid, suppliername, suppliercategoryid, primarycontactpersonid,
    alternatecontactpersonid, deliverymethodid, deliverycityid, postalcityid,
    supplierreference, bankaccountname, bankaccountbranch, bankaccountcode,
    bankaccountnumber, bankinternationalcode, paymentdays, internalcomments,
    phonenumber, faxnumber, websiteurl, deliveryaddressline1,
    deliveryaddressline2, deliverypostalcode, deliverylocation,
    postaladdressline1, postaladdressline2, postalpostalcode,
    lasteditedby, validfrom, validto
)
SELECT 
    supplierid, suppliername, suppliercategoryid, primarycontactpersonid,
    alternatecontactpersonid, deliverymethodid, deliverycityid, postalcityid,
    supplierreference, bankaccountname, bankaccountbranch, bankaccountcode,
    bankaccountnumber, bankinternationalcode, paymentdays, internalcomments,
    phonenumber, faxnumber, websiteurl, deliveryaddressline1,
    deliveryaddressline2, deliverypostalcode,
    CASE WHEN deliverylocation_wkt IS NOT NULL AND deliverylocation_wkt != '' 
         THEN ST_GeogFromText(deliverylocation_wkt) 
         ELSE NULL END,
    postaladdressline1, postaladdressline2, postalpostalcode,
    lasteditedby, validfrom, validto
FROM suppliers_staging;

DROP TABLE suppliers_staging;

-- Purchasing.PurchaseOrders
\echo 'Loading Purchasing.PurchaseOrders...'
COPY purchasing.purchaseorders (
    purchaseorderid, supplierid, orderdate, deliverymethodid, contactpersonid,
    expecteddeliverydate, supplierreference, isorderfinalized, comments,
    internalcomments, lasteditedby, lasteditedwhen
) FROM :'data_dir'/oltp/current/purchasing_purchaseorders.csv
WITH (FORMAT csv, DELIMITER '|', NULL '', QUOTE '"');

-- Purchasing.PurchaseOrderLines
\echo 'Loading Purchasing.PurchaseOrderLines...'
COPY purchasing.purchaseorderlines (
    purchaseorderlineid, purchaseorderid, stockitemid, orderedouters,
    description, receivedouters, packagetypeid, expectedunitpriceperouter,
    lastreceiptdate, isorderlinefinalized, lasteditedby, lasteditedwhen
) FROM :'data_dir'/oltp/current/purchasing_purchaseorderlines.csv
WITH (FORMAT csv, DELIMITER '|', NULL '', QUOTE '"');

-- Purchasing.SupplierTransactions (without computed column)
\echo 'Loading Purchasing.SupplierTransactions...'
COPY purchasing.suppliertransactions (
    suppliertransactionid, supplierid, transactiontypeid, purchaseorderid,
    paymentmethodid, supplierinvoicenumber, transactiondate, amountexcludingtax,
    taxamount, transactionamount, outstandingbalance, finalizationdate,
    lasteditedby, lasteditedwhen
) FROM :'data_dir'/oltp/current/purchasing_suppliertransactions.csv
WITH (FORMAT csv, DELIMITER '|', NULL '', QUOTE '"');

-- =============================================
-- Archive Tables (Historical Data)
-- =============================================

\echo 'Loading Archive Tables...'

-- Application Archive Tables
COPY application.people_archive FROM :'data_dir'/oltp/archive/application_people_archive.csv
WITH (FORMAT csv, DELIMITER '|', NULL '', QUOTE '"');

COPY application.countries_archive (
    countryid, countryname, formalname, isoalpha3code, isonumericcode,
    countrytype, latestrecordedpopulation, continent, region, subregion,
    lasteditedby, validfrom, validto
) FROM :'data_dir'/oltp/archive/application_countries_archive.csv
WITH (FORMAT csv, DELIMITER '|', NULL '', QUOTE '"');

COPY application.stateprovinces_archive (
    stateprovinceid, stateprovincecode, stateprovincename, countryid,
    salesterritory, latestrecordedpopulation, lasteditedby, validfrom, validto
) FROM :'data_dir'/oltp/archive/application_stateprovinces_archive.csv
WITH (FORMAT csv, DELIMITER '|', NULL '', QUOTE '"');

COPY application.cities_archive (
    cityid, cityname, stateprovinceid, latestrecordedpopulation,
    lasteditedby, validfrom, validto
) FROM :'data_dir'/oltp/archive/application_cities_archive.csv
WITH (FORMAT csv, DELIMITER '|', NULL '', QUOTE '"');

COPY application.deliverymethods_archive FROM :'data_dir'/oltp/archive/application_deliverymethods_archive.csv
WITH (FORMAT csv, DELIMITER '|', NULL '', QUOTE '"');

COPY application.paymentmethods_archive FROM :'data_dir'/oltp/archive/application_paymentmethods_archive.csv
WITH (FORMAT csv, DELIMITER '|', NULL '', QUOTE '"');

COPY application.transactiontypes_archive FROM :'data_dir'/oltp/archive/application_transactiontypes_archive.csv
WITH (FORMAT csv, DELIMITER '|', NULL '', QUOTE '"');

-- Warehouse Archive Tables
COPY warehouse.colors_archive FROM :'data_dir'/oltp/archive/warehouse_colors_archive.csv
WITH (FORMAT csv, DELIMITER '|', NULL '', QUOTE '"');

COPY warehouse.packagetypes_archive FROM :'data_dir'/oltp/archive/warehouse_packagetypes_archive.csv
WITH (FORMAT csv, DELIMITER '|', NULL '', QUOTE '"');

COPY warehouse.stockgroups_archive FROM :'data_dir'/oltp/archive/warehouse_stockgroups_archive.csv
WITH (FORMAT csv, DELIMITER '|', NULL '', QUOTE '"');

COPY warehouse.stockitems_archive FROM :'data_dir'/oltp/archive/warehouse_stockitems_archive.csv
WITH (FORMAT csv, DELIMITER '|', NULL '', QUOTE '"');

COPY warehouse.coldroomtemperatures_archive FROM :'data_dir'/oltp/archive/warehouse_coldroomtemperatures_archive.csv
WITH (FORMAT csv, DELIMITER '|', NULL '', QUOTE '"');

-- Sales Archive Tables
COPY sales.buyinggroups_archive FROM :'data_dir'/oltp/archive/sales_buyinggroups_archive.csv
WITH (FORMAT csv, DELIMITER '|', NULL '', QUOTE '"');

COPY sales.customercategories_archive FROM :'data_dir'/oltp/archive/sales_customercategories_archive.csv
WITH (FORMAT csv, DELIMITER '|', NULL '', QUOTE '"');

COPY sales.customers_archive (
    customerid, customername, billtocustomerid, customercategoryid,
    buyinggroupid, primarycontactpersonid, alternatecontactpersonid,
    deliverymethodid, deliverycityid, postalcityid, creditlimit,
    accountopeneddate, standarddiscountpercentage, isstatementsent,
    isoncredithold, paymentdays, phonenumber, faxnumber, deliveryrun,
    runposition, websiteurl, deliveryaddressline1, deliveryaddressline2,
    deliverypostalcode, postaladdressline1, postaladdressline2,
    postalpostalcode, lasteditedby, validfrom, validto
) FROM :'data_dir'/oltp/archive/sales_customers_archive.csv
WITH (FORMAT csv, DELIMITER '|', NULL '', QUOTE '"');

-- Purchasing Archive Tables
COPY purchasing.suppliercategories_archive FROM :'data_dir'/oltp/archive/purchasing_suppliercategories_archive.csv
WITH (FORMAT csv, DELIMITER '|', NULL '', QUOTE '"');

COPY purchasing.suppliers_archive (
    supplierid, suppliername, suppliercategoryid, primarycontactpersonid,
    alternatecontactpersonid, deliverymethodid, deliverycityid, postalcityid,
    supplierreference, bankaccountname, bankaccountbranch, bankaccountcode,
    bankaccountnumber, bankinternationalcode, paymentdays, internalcomments,
    phonenumber, faxnumber, websiteurl, deliveryaddressline1,
    deliveryaddressline2, deliverypostalcode, postaladdressline1,
    postaladdressline2, postalpostalcode, lasteditedby, validfrom, validto
) FROM :'data_dir'/oltp/archive/purchasing_suppliers_archive.csv
WITH (FORMAT csv, DELIMITER '|', NULL '', QUOTE '"');

-- =============================================
-- Post-Load Setup
-- =============================================

-- Re-enable triggers
SET session_replication_role = 'origin';

-- Reset work_mem
RESET work_mem;

\echo 'OLTP Data Load Complete!'
