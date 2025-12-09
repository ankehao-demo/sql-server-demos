-- Wide World Importers PostgreSQL Migration
-- Data Migration Scripts
-- This script provides guidance and scripts for migrating data from SQL Server to PostgreSQL

-- ============================================================================
-- STEP 1: Export Data from SQL Server
-- ============================================================================

-- Option A: Using BCP (Bulk Copy Program)
-- Run these commands from SQL Server command line:

/*
-- Export each table to CSV format
bcp "SELECT * FROM WideWorldImporters.Application.Countries" queryout "countries.csv" -c -t"," -S localhost -U sa -P password
bcp "SELECT * FROM WideWorldImporters.Application.StateProvinces" queryout "stateprovinces.csv" -c -t"," -S localhost -U sa -P password
bcp "SELECT * FROM WideWorldImporters.Application.Cities" queryout "cities.csv" -c -t"," -S localhost -U sa -P password
bcp "SELECT * FROM WideWorldImporters.Application.People" queryout "people.csv" -c -t"," -S localhost -U sa -P password
-- ... repeat for all tables
*/

-- Option B: Using SQL Server Management Studio
-- Right-click database > Tasks > Export Data
-- Choose "Flat File Destination" and export to CSV

-- Option C: Using sqlcmd with -o option
/*
sqlcmd -S localhost -U sa -P password -d WideWorldImporters -Q "SELECT * FROM Application.Countries" -o countries.csv -s"," -W
*/

-- ============================================================================
-- STEP 2: Prepare PostgreSQL Database
-- ============================================================================

-- Run the schema creation scripts in order:
-- 1. 01-schemas/create_schemas.sql
-- 2. 02-sequences/create_sequences.sql
-- 3. 03-tables/01_application_tables.sql
-- 4. 03-tables/02_sales_tables.sql
-- 5. 03-tables/03_purchasing_tables.sql
-- 6. 03-tables/04_warehouse_tables.sql
-- 7. 03-tables/05_dataload_simulation_tables.sql

-- Disable temporal triggers before data load
SELECT disable_temporal_triggers();

-- ============================================================================
-- STEP 3: Load Data into PostgreSQL
-- ============================================================================

-- Option A: Using COPY command (fastest method)
-- Run from psql or pgAdmin

-- Load Application schema tables
COPY application.countries(countryid, countryname, formalname, isoalpha3code, isonumericcode, countrytype, latestrecordedpopulation, continent, region, subregion, lasteditedby, validfrom, validto)
FROM '/path/to/countries.csv' WITH (FORMAT csv, HEADER true, NULL '');

COPY application.stateprovinces(stateprovinceid, stateprovincecode, stateprovincename, countryid, salesterritory, latestrecordedpopulation, lasteditedby, validfrom, validto)
FROM '/path/to/stateprovinces.csv' WITH (FORMAT csv, HEADER true, NULL '');

COPY application.cities(cityid, cityname, stateprovinceid, latestrecordedpopulation, lasteditedby, validfrom, validto)
FROM '/path/to/cities.csv' WITH (FORMAT csv, HEADER true, NULL '');

COPY application.people(personid, fullname, preferredname, ispermittedtologon, logonname, isexternallogonprovider, hashedpassword, issystemuser, isemployee, issalesperson, userpreferences, phonenumber, faxnumber, emailaddress, photo, customfields, lasteditedby, validfrom, validto)
FROM '/path/to/people.csv' WITH (FORMAT csv, HEADER true, NULL '');

COPY application.deliverymethods(deliverymethodid, deliverymethodname, lasteditedby, validfrom, validto)
FROM '/path/to/deliverymethods.csv' WITH (FORMAT csv, HEADER true, NULL '');

COPY application.paymentmethods(paymentmethodid, paymentmethodname, lasteditedby, validfrom, validto)
FROM '/path/to/paymentmethods.csv' WITH (FORMAT csv, HEADER true, NULL '');

COPY application.transactiontypes(transactiontypeid, transactiontypename, lasteditedby, validfrom, validto)
FROM '/path/to/transactiontypes.csv' WITH (FORMAT csv, HEADER true, NULL '');

-- Load Sales schema tables
COPY sales.buyinggroups(buyinggroupid, buyinggroupname, lasteditedby, validfrom, validto)
FROM '/path/to/buyinggroups.csv' WITH (FORMAT csv, HEADER true, NULL '');

COPY sales.customercategories(customercategoryid, customercategoryname, lasteditedby, validfrom, validto)
FROM '/path/to/customercategories.csv' WITH (FORMAT csv, HEADER true, NULL '');

COPY sales.customers(customerid, customername, billtocustomerid, customercategoryid, buyinggroupid, primarycontactpersonid, alternatecontactpersonid, deliverymethodid, deliverycityid, postalcityid, creditlimit, accountopeneddate, standarddiscountpercentage, isstatementsent, isoncredithold, paymentdays, phonenumber, faxnumber, deliveryrun, runposition, websiteurl, deliveryaddressline1, deliveryaddressline2, deliverypostalcode, postaladdressline1, postaladdressline2, postalpostalcode, lasteditedby, validfrom, validto)
FROM '/path/to/customers.csv' WITH (FORMAT csv, HEADER true, NULL '');

COPY sales.orders(orderid, customerid, salespersonpersonid, pickedbypersonid, contactpersonid, backorderorderid, orderdate, expecteddeliverydate, customerpurchaseordernumber, isundersupplybackordered, comments, deliveryinstructions, internalcomments, pickingcompletedwhen, lasteditedby, lasteditedwhen)
FROM '/path/to/orders.csv' WITH (FORMAT csv, HEADER true, NULL '');

COPY sales.orderlines(orderlineid, orderid, stockitemid, description, packagetypeid, quantity, unitprice, taxrate, pickedquantity, pickingcompletedwhen, lasteditedby, lasteditedwhen)
FROM '/path/to/orderlines.csv' WITH (FORMAT csv, HEADER true, NULL '');

COPY sales.invoices(invoiceid, customerid, billtocustomerid, orderid, deliverymethodid, contactpersonid, accountspersonid, salespersonpersonid, packedbypersonid, invoicedate, customerpurchaseordernumber, iscreditnote, creditnotereason, comments, deliveryinstructions, internalcomments, totaldryitems, totalchilleritems, deliveryrun, runposition, returneddeliverydata, confirmeddeliverytime, confirmedreceivedby, lasteditedby, lasteditedwhen)
FROM '/path/to/invoices.csv' WITH (FORMAT csv, HEADER true, NULL '');

COPY sales.invoicelines(invoicelineid, invoiceid, stockitemid, description, packagetypeid, quantity, unitprice, taxrate, taxamount, lineprofit, extendedprice, lasteditedby, lasteditedwhen)
FROM '/path/to/invoicelines.csv' WITH (FORMAT csv, HEADER true, NULL '');

COPY sales.customertransactions(customertransactionid, customerid, transactiontypeid, invoiceid, paymentmethodid, transactiondate, amountexcludingtax, taxamount, transactionamount, outstandingbalance, finalizationdate, lasteditedby, lasteditedwhen)
FROM '/path/to/customertransactions.csv' WITH (FORMAT csv, HEADER true, NULL '');

-- Load Purchasing schema tables
COPY purchasing.suppliercategories(suppliercategoryid, suppliercategoryname, lasteditedby, validfrom, validto)
FROM '/path/to/suppliercategories.csv' WITH (FORMAT csv, HEADER true, NULL '');

COPY purchasing.suppliers(supplierid, suppliername, suppliercategoryid, primarycontactpersonid, alternatecontactpersonid, deliverymethodid, deliverycityid, postalcityid, supplierreference, bankaccountname, bankaccountbranch, bankaccountcode, bankaccountnumber, bankinternationalcode, paymentdays, internalcomments, phonenumber, faxnumber, websiteurl, deliveryaddressline1, deliveryaddressline2, deliverypostalcode, postaladdressline1, postaladdressline2, postalpostalcode, lasteditedby, validfrom, validto)
FROM '/path/to/suppliers.csv' WITH (FORMAT csv, HEADER true, NULL '');

COPY purchasing.purchaseorders(purchaseorderid, supplierid, orderdate, deliverymethodid, contactpersonid, expecteddeliverydate, supplierreference, isorderfinalized, comments, internalcomments, lasteditedby, lasteditedwhen)
FROM '/path/to/purchaseorders.csv' WITH (FORMAT csv, HEADER true, NULL '');

COPY purchasing.purchaseorderlines(purchaseorderlineid, purchaseorderid, stockitemid, orderedouters, description, receivedouters, packagetypeid, expectedunitpriceperouter, lastreceiptdate, isorderlinefinalized, lasteditedby, lasteditedwhen)
FROM '/path/to/purchaseorderlines.csv' WITH (FORMAT csv, HEADER true, NULL '');

COPY purchasing.suppliertransactions(suppliertransactionid, supplierid, transactiontypeid, purchaseorderid, paymentmethodid, supplierinvoicenumber, transactiondate, amountexcludingtax, taxamount, transactionamount, outstandingbalance, finalizationdate, lasteditedby, lasteditedwhen)
FROM '/path/to/suppliertransactions.csv' WITH (FORMAT csv, HEADER true, NULL '');

-- Load Warehouse schema tables
COPY warehouse.colors(colorid, colorname, lasteditedby, validfrom, validto)
FROM '/path/to/colors.csv' WITH (FORMAT csv, HEADER true, NULL '');

COPY warehouse.packagetypes(packagetypeid, packagetypename, lasteditedby, validfrom, validto)
FROM '/path/to/packagetypes.csv' WITH (FORMAT csv, HEADER true, NULL '');

COPY warehouse.stockgroups(stockgroupid, stockgroupname, lasteditedby, validfrom, validto)
FROM '/path/to/stockgroups.csv' WITH (FORMAT csv, HEADER true, NULL '');

COPY warehouse.stockitems(stockitemid, stockitemname, supplierid, colorid, unitpackageid, outerpackageid, brand, size, leadtimedays, quantityperouter, ischillerstock, barcode, taxrate, unitprice, recommendedretailprice, typicalweightperunit, marketingcomments, internalcomments, photo, customfields, lasteditedby, validfrom, validto)
FROM '/path/to/stockitems.csv' WITH (FORMAT csv, HEADER true, NULL '');

COPY warehouse.stockitemholdings(stockitemid, quantityonhand, binlocation, laststocktakequantity, lastcostprice, reorderlevel, targetstocklevel, lasteditedby, lasteditedwhen)
FROM '/path/to/stockitemholdings.csv' WITH (FORMAT csv, HEADER true, NULL '');

COPY warehouse.stockitemstockgroups(stockitemstockgroupid, stockitemid, stockgroupid, lasteditedby, lasteditedwhen)
FROM '/path/to/stockitemstockgroups.csv' WITH (FORMAT csv, HEADER true, NULL '');

COPY warehouse.stockitemtransactions(stockitemtransactionid, stockitemid, transactiontypeid, customerid, invoiceid, supplierid, purchaseorderid, transactionoccurredwhen, quantity, lasteditedby, lasteditedwhen)
FROM '/path/to/stockitemtransactions.csv' WITH (FORMAT csv, HEADER true, NULL '');

COPY warehouse.coldroomtemperatures(coldroomtemperatureid, coldroomsensornumber, recordedwhen, temperature, validfrom, validto)
FROM '/path/to/coldroomtemperatures.csv' WITH (FORMAT csv, HEADER true, NULL '');

COPY warehouse.vehicletemperatures(vehicletemperatureid, vehicleregistration, chillersensornumber, recordedwhen, temperature, fullsensordata, iscompressed, compressedsensordata)
FROM '/path/to/vehicletemperatures.csv' WITH (FORMAT csv, HEADER true, NULL '');

-- ============================================================================
-- STEP 4: Update Sequences
-- ============================================================================

-- After loading data, update sequences to start after the maximum ID values
SELECT setval('sequences.countryid', (SELECT COALESCE(MAX(countryid), 1) FROM application.countries));
SELECT setval('sequences.stateprovinceid', (SELECT COALESCE(MAX(stateprovinceid), 1) FROM application.stateprovinces));
SELECT setval('sequences.cityid', (SELECT COALESCE(MAX(cityid), 1) FROM application.cities));
SELECT setval('sequences.personid', (SELECT COALESCE(MAX(personid), 1) FROM application.people));
SELECT setval('sequences.deliverymethodid', (SELECT COALESCE(MAX(deliverymethodid), 1) FROM application.deliverymethods));
SELECT setval('sequences.paymentmethodid', (SELECT COALESCE(MAX(paymentmethodid), 1) FROM application.paymentmethods));
SELECT setval('sequences.transactiontypeid', (SELECT COALESCE(MAX(transactiontypeid), 1) FROM application.transactiontypes));
SELECT setval('sequences.buyinggroupid', (SELECT COALESCE(MAX(buyinggroupid), 1) FROM sales.buyinggroups));
SELECT setval('sequences.customercategoryid', (SELECT COALESCE(MAX(customercategoryid), 1) FROM sales.customercategories));
SELECT setval('sequences.customerid', (SELECT COALESCE(MAX(customerid), 1) FROM sales.customers));
SELECT setval('sequences.orderid', (SELECT COALESCE(MAX(orderid), 1) FROM sales.orders));
SELECT setval('sequences.orderlineid', (SELECT COALESCE(MAX(orderlineid), 1) FROM sales.orderlines));
SELECT setval('sequences.invoiceid', (SELECT COALESCE(MAX(invoiceid), 1) FROM sales.invoices));
SELECT setval('sequences.invoicelineid', (SELECT COALESCE(MAX(invoicelineid), 1) FROM sales.invoicelines));
SELECT setval('sequences.specialdealid', (SELECT COALESCE(MAX(specialdealid), 1) FROM sales.specialdeals));
SELECT setval('sequences.suppliercategoryid', (SELECT COALESCE(MAX(suppliercategoryid), 1) FROM purchasing.suppliercategories));
SELECT setval('sequences.supplierid', (SELECT COALESCE(MAX(supplierid), 1) FROM purchasing.suppliers));
SELECT setval('sequences.purchaseorderid', (SELECT COALESCE(MAX(purchaseorderid), 1) FROM purchasing.purchaseorders));
SELECT setval('sequences.purchaseorderlineid', (SELECT COALESCE(MAX(purchaseorderlineid), 1) FROM purchasing.purchaseorderlines));
SELECT setval('sequences.colorid', (SELECT COALESCE(MAX(colorid), 1) FROM warehouse.colors));
SELECT setval('sequences.packagetypeid', (SELECT COALESCE(MAX(packagetypeid), 1) FROM warehouse.packagetypes));
SELECT setval('sequences.stockgroupid', (SELECT COALESCE(MAX(stockgroupid), 1) FROM warehouse.stockgroups));
SELECT setval('sequences.stockitemid', (SELECT COALESCE(MAX(stockitemid), 1) FROM warehouse.stockitems));
SELECT setval('sequences.stockitemstockgroupid', (SELECT COALESCE(MAX(stockitemstockgroupid), 1) FROM warehouse.stockitemstockgroups));

-- Update transaction sequence (used by multiple tables)
SELECT setval('sequences.transactionid', GREATEST(
    (SELECT COALESCE(MAX(customertransactionid), 1) FROM sales.customertransactions),
    (SELECT COALESCE(MAX(suppliertransactionid), 1) FROM purchasing.suppliertransactions),
    (SELECT COALESCE(MAX(stockitemtransactionid), 1) FROM warehouse.stockitemtransactions)
));

-- ============================================================================
-- STEP 5: Re-enable Temporal Triggers
-- ============================================================================

SELECT enable_temporal_triggers();

-- ============================================================================
-- STEP 6: Verify Data Migration
-- ============================================================================

-- Check row counts
SELECT 'application.countries' AS table_name, COUNT(*) AS row_count FROM application.countries
UNION ALL SELECT 'application.stateprovinces', COUNT(*) FROM application.stateprovinces
UNION ALL SELECT 'application.cities', COUNT(*) FROM application.cities
UNION ALL SELECT 'application.people', COUNT(*) FROM application.people
UNION ALL SELECT 'application.deliverymethods', COUNT(*) FROM application.deliverymethods
UNION ALL SELECT 'application.paymentmethods', COUNT(*) FROM application.paymentmethods
UNION ALL SELECT 'application.transactiontypes', COUNT(*) FROM application.transactiontypes
UNION ALL SELECT 'sales.buyinggroups', COUNT(*) FROM sales.buyinggroups
UNION ALL SELECT 'sales.customercategories', COUNT(*) FROM sales.customercategories
UNION ALL SELECT 'sales.customers', COUNT(*) FROM sales.customers
UNION ALL SELECT 'sales.orders', COUNT(*) FROM sales.orders
UNION ALL SELECT 'sales.orderlines', COUNT(*) FROM sales.orderlines
UNION ALL SELECT 'sales.invoices', COUNT(*) FROM sales.invoices
UNION ALL SELECT 'sales.invoicelines', COUNT(*) FROM sales.invoicelines
UNION ALL SELECT 'purchasing.suppliercategories', COUNT(*) FROM purchasing.suppliercategories
UNION ALL SELECT 'purchasing.suppliers', COUNT(*) FROM purchasing.suppliers
UNION ALL SELECT 'purchasing.purchaseorders', COUNT(*) FROM purchasing.purchaseorders
UNION ALL SELECT 'purchasing.purchaseorderlines', COUNT(*) FROM purchasing.purchaseorderlines
UNION ALL SELECT 'warehouse.colors', COUNT(*) FROM warehouse.colors
UNION ALL SELECT 'warehouse.packagetypes', COUNT(*) FROM warehouse.packagetypes
UNION ALL SELECT 'warehouse.stockgroups', COUNT(*) FROM warehouse.stockgroups
UNION ALL SELECT 'warehouse.stockitems', COUNT(*) FROM warehouse.stockitems
UNION ALL SELECT 'warehouse.stockitemholdings', COUNT(*) FROM warehouse.stockitemholdings
UNION ALL SELECT 'warehouse.stockitemstockgroups', COUNT(*) FROM warehouse.stockitemstockgroups
ORDER BY table_name;

-- ============================================================================
-- STEP 7: Apply Additional Scripts
-- ============================================================================

-- Run the following scripts in order:
-- 1. 04-functions/application_functions.sql
-- 2. 04-functions/dataload_simulation_functions.sql
-- 3. 05-stored-procedures/website_procedures.sql
-- 4. 06-views/website_views.sql (if created)
-- 5. 07-triggers/temporal_tables.sql
-- 6. 08-security/row_level_security.sql
