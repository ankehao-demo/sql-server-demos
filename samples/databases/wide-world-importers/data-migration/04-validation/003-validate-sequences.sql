-- Wide World Importers PostgreSQL Migration
-- Phase 6: Data Migration and Validation
-- File: 003-validate-sequences.sql
-- Description: Validate that sequences are properly seeded after data migration
--
-- This script verifies:
-- 1. All sequences exist
-- 2. Sequence values are higher than max IDs in corresponding tables
-- 3. New inserts will not cause primary key conflicts
--
-- Usage: psql -d wideworldimporters -f 003-validate-sequences.sql

\echo '============================================='
\echo 'Wide World Importers Data Migration Validation'
\echo 'Sequence Verification Report'
\echo '============================================='
\echo ''

-- =============================================
-- Sequence Existence Check
-- =============================================

\echo 'Sequence Existence Check'
\echo '============================================='

SELECT 
    'sequences.' || sequencename AS sequence_name,
    CASE WHEN last_value IS NOT NULL THEN 'EXISTS' ELSE 'MISSING' END AS status
FROM pg_sequences
WHERE schemaname = 'sequences'
ORDER BY sequencename;

-- =============================================
-- Sequence Value vs Max ID Comparison
-- =============================================

\echo ''
\echo 'Sequence Value vs Max ID Comparison'
\echo '============================================='
\echo 'All differences should be >= 0 (sequence >= max_id)'

-- Application Schema
SELECT 
    'sequences.personid' AS sequence_name,
    (SELECT last_value FROM pg_sequences WHERE schemaname = 'sequences' AND sequencename = 'personid') AS sequence_value,
    COALESCE(MAX(personid), 0) AS max_id,
    (SELECT last_value FROM pg_sequences WHERE schemaname = 'sequences' AND sequencename = 'personid') - COALESCE(MAX(personid), 0) AS difference
FROM application.people

UNION ALL
SELECT 
    'sequences.countryid',
    (SELECT last_value FROM pg_sequences WHERE schemaname = 'sequences' AND sequencename = 'countryid'),
    COALESCE(MAX(countryid), 0),
    (SELECT last_value FROM pg_sequences WHERE schemaname = 'sequences' AND sequencename = 'countryid') - COALESCE(MAX(countryid), 0)
FROM application.countries

UNION ALL
SELECT 
    'sequences.stateprovinceid',
    (SELECT last_value FROM pg_sequences WHERE schemaname = 'sequences' AND sequencename = 'stateprovinceid'),
    COALESCE(MAX(stateprovinceid), 0),
    (SELECT last_value FROM pg_sequences WHERE schemaname = 'sequences' AND sequencename = 'stateprovinceid') - COALESCE(MAX(stateprovinceid), 0)
FROM application.stateprovinces

UNION ALL
SELECT 
    'sequences.cityid',
    (SELECT last_value FROM pg_sequences WHERE schemaname = 'sequences' AND sequencename = 'cityid'),
    COALESCE(MAX(cityid), 0),
    (SELECT last_value FROM pg_sequences WHERE schemaname = 'sequences' AND sequencename = 'cityid') - COALESCE(MAX(cityid), 0)
FROM application.cities

UNION ALL
SELECT 
    'sequences.deliverymethodid',
    (SELECT last_value FROM pg_sequences WHERE schemaname = 'sequences' AND sequencename = 'deliverymethodid'),
    COALESCE(MAX(deliverymethodid), 0),
    (SELECT last_value FROM pg_sequences WHERE schemaname = 'sequences' AND sequencename = 'deliverymethodid') - COALESCE(MAX(deliverymethodid), 0)
FROM application.deliverymethods

UNION ALL
SELECT 
    'sequences.paymentmethodid',
    (SELECT last_value FROM pg_sequences WHERE schemaname = 'sequences' AND sequencename = 'paymentmethodid'),
    COALESCE(MAX(paymentmethodid), 0),
    (SELECT last_value FROM pg_sequences WHERE schemaname = 'sequences' AND sequencename = 'paymentmethodid') - COALESCE(MAX(paymentmethodid), 0)
FROM application.paymentmethods

UNION ALL
SELECT 
    'sequences.transactiontypeid',
    (SELECT last_value FROM pg_sequences WHERE schemaname = 'sequences' AND sequencename = 'transactiontypeid'),
    COALESCE(MAX(transactiontypeid), 0),
    (SELECT last_value FROM pg_sequences WHERE schemaname = 'sequences' AND sequencename = 'transactiontypeid') - COALESCE(MAX(transactiontypeid), 0)
FROM application.transactiontypes

-- Warehouse Schema
UNION ALL
SELECT 
    'sequences.colorid',
    (SELECT last_value FROM pg_sequences WHERE schemaname = 'sequences' AND sequencename = 'colorid'),
    COALESCE(MAX(colorid), 0),
    (SELECT last_value FROM pg_sequences WHERE schemaname = 'sequences' AND sequencename = 'colorid') - COALESCE(MAX(colorid), 0)
FROM warehouse.colors

UNION ALL
SELECT 
    'sequences.packagetypeid',
    (SELECT last_value FROM pg_sequences WHERE schemaname = 'sequences' AND sequencename = 'packagetypeid'),
    COALESCE(MAX(packagetypeid), 0),
    (SELECT last_value FROM pg_sequences WHERE schemaname = 'sequences' AND sequencename = 'packagetypeid') - COALESCE(MAX(packagetypeid), 0)
FROM warehouse.packagetypes

UNION ALL
SELECT 
    'sequences.stockgroupid',
    (SELECT last_value FROM pg_sequences WHERE schemaname = 'sequences' AND sequencename = 'stockgroupid'),
    COALESCE(MAX(stockgroupid), 0),
    (SELECT last_value FROM pg_sequences WHERE schemaname = 'sequences' AND sequencename = 'stockgroupid') - COALESCE(MAX(stockgroupid), 0)
FROM warehouse.stockgroups

UNION ALL
SELECT 
    'sequences.stockitemid',
    (SELECT last_value FROM pg_sequences WHERE schemaname = 'sequences' AND sequencename = 'stockitemid'),
    COALESCE(MAX(stockitemid), 0),
    (SELECT last_value FROM pg_sequences WHERE schemaname = 'sequences' AND sequencename = 'stockitemid') - COALESCE(MAX(stockitemid), 0)
FROM warehouse.stockitems

UNION ALL
SELECT 
    'sequences.stockitemstockgroupid',
    (SELECT last_value FROM pg_sequences WHERE schemaname = 'sequences' AND sequencename = 'stockitemstockgroupid'),
    COALESCE(MAX(stockitemstockgroupid), 0),
    (SELECT last_value FROM pg_sequences WHERE schemaname = 'sequences' AND sequencename = 'stockitemstockgroupid') - COALESCE(MAX(stockitemstockgroupid), 0)
FROM warehouse.stockitemstockgroups

-- Sales Schema
UNION ALL
SELECT 
    'sequences.buyinggroupid',
    (SELECT last_value FROM pg_sequences WHERE schemaname = 'sequences' AND sequencename = 'buyinggroupid'),
    COALESCE(MAX(buyinggroupid), 0),
    (SELECT last_value FROM pg_sequences WHERE schemaname = 'sequences' AND sequencename = 'buyinggroupid') - COALESCE(MAX(buyinggroupid), 0)
FROM sales.buyinggroups

UNION ALL
SELECT 
    'sequences.customercategoryid',
    (SELECT last_value FROM pg_sequences WHERE schemaname = 'sequences' AND sequencename = 'customercategoryid'),
    COALESCE(MAX(customercategoryid), 0),
    (SELECT last_value FROM pg_sequences WHERE schemaname = 'sequences' AND sequencename = 'customercategoryid') - COALESCE(MAX(customercategoryid), 0)
FROM sales.customercategories

UNION ALL
SELECT 
    'sequences.customerid',
    (SELECT last_value FROM pg_sequences WHERE schemaname = 'sequences' AND sequencename = 'customerid'),
    COALESCE(MAX(customerid), 0),
    (SELECT last_value FROM pg_sequences WHERE schemaname = 'sequences' AND sequencename = 'customerid') - COALESCE(MAX(customerid), 0)
FROM sales.customers

UNION ALL
SELECT 
    'sequences.orderid',
    (SELECT last_value FROM pg_sequences WHERE schemaname = 'sequences' AND sequencename = 'orderid'),
    COALESCE(MAX(orderid), 0),
    (SELECT last_value FROM pg_sequences WHERE schemaname = 'sequences' AND sequencename = 'orderid') - COALESCE(MAX(orderid), 0)
FROM sales.orders

UNION ALL
SELECT 
    'sequences.orderlineid',
    (SELECT last_value FROM pg_sequences WHERE schemaname = 'sequences' AND sequencename = 'orderlineid'),
    COALESCE(MAX(orderlineid), 0),
    (SELECT last_value FROM pg_sequences WHERE schemaname = 'sequences' AND sequencename = 'orderlineid') - COALESCE(MAX(orderlineid), 0)
FROM sales.orderlines

UNION ALL
SELECT 
    'sequences.invoiceid',
    (SELECT last_value FROM pg_sequences WHERE schemaname = 'sequences' AND sequencename = 'invoiceid'),
    COALESCE(MAX(invoiceid), 0),
    (SELECT last_value FROM pg_sequences WHERE schemaname = 'sequences' AND sequencename = 'invoiceid') - COALESCE(MAX(invoiceid), 0)
FROM sales.invoices

UNION ALL
SELECT 
    'sequences.invoicelineid',
    (SELECT last_value FROM pg_sequences WHERE schemaname = 'sequences' AND sequencename = 'invoicelineid'),
    COALESCE(MAX(invoicelineid), 0),
    (SELECT last_value FROM pg_sequences WHERE schemaname = 'sequences' AND sequencename = 'invoicelineid') - COALESCE(MAX(invoicelineid), 0)
FROM sales.invoicelines

UNION ALL
SELECT 
    'sequences.specialdealid',
    (SELECT last_value FROM pg_sequences WHERE schemaname = 'sequences' AND sequencename = 'specialdealid'),
    COALESCE(MAX(specialdealid), 0),
    (SELECT last_value FROM pg_sequences WHERE schemaname = 'sequences' AND sequencename = 'specialdealid') - COALESCE(MAX(specialdealid), 0)
FROM sales.specialdeals

-- Purchasing Schema
UNION ALL
SELECT 
    'sequences.suppliercategoryid',
    (SELECT last_value FROM pg_sequences WHERE schemaname = 'sequences' AND sequencename = 'suppliercategoryid'),
    COALESCE(MAX(suppliercategoryid), 0),
    (SELECT last_value FROM pg_sequences WHERE schemaname = 'sequences' AND sequencename = 'suppliercategoryid') - COALESCE(MAX(suppliercategoryid), 0)
FROM purchasing.suppliercategories

UNION ALL
SELECT 
    'sequences.supplierid',
    (SELECT last_value FROM pg_sequences WHERE schemaname = 'sequences' AND sequencename = 'supplierid'),
    COALESCE(MAX(supplierid), 0),
    (SELECT last_value FROM pg_sequences WHERE schemaname = 'sequences' AND sequencename = 'supplierid') - COALESCE(MAX(supplierid), 0)
FROM purchasing.suppliers

UNION ALL
SELECT 
    'sequences.purchaseorderid',
    (SELECT last_value FROM pg_sequences WHERE schemaname = 'sequences' AND sequencename = 'purchaseorderid'),
    COALESCE(MAX(purchaseorderid), 0),
    (SELECT last_value FROM pg_sequences WHERE schemaname = 'sequences' AND sequencename = 'purchaseorderid') - COALESCE(MAX(purchaseorderid), 0)
FROM purchasing.purchaseorders

UNION ALL
SELECT 
    'sequences.purchaseorderlineid',
    (SELECT last_value FROM pg_sequences WHERE schemaname = 'sequences' AND sequencename = 'purchaseorderlineid'),
    COALESCE(MAX(purchaseorderlineid), 0),
    (SELECT last_value FROM pg_sequences WHERE schemaname = 'sequences' AND sequencename = 'purchaseorderlineid') - COALESCE(MAX(purchaseorderlineid), 0)
FROM purchasing.purchaseorderlines

-- Shared Transaction Sequence
UNION ALL
SELECT 
    'sequences.transactionid (customer)',
    (SELECT last_value FROM pg_sequences WHERE schemaname = 'sequences' AND sequencename = 'transactionid'),
    COALESCE(MAX(customertransactionid), 0),
    (SELECT last_value FROM pg_sequences WHERE schemaname = 'sequences' AND sequencename = 'transactionid') - COALESCE(MAX(customertransactionid), 0)
FROM sales.customertransactions

UNION ALL
SELECT 
    'sequences.transactionid (supplier)',
    (SELECT last_value FROM pg_sequences WHERE schemaname = 'sequences' AND sequencename = 'transactionid'),
    COALESCE(MAX(suppliertransactionid), 0),
    (SELECT last_value FROM pg_sequences WHERE schemaname = 'sequences' AND sequencename = 'transactionid') - COALESCE(MAX(suppliertransactionid), 0)
FROM purchasing.suppliertransactions

UNION ALL
SELECT 
    'sequences.transactionid (stockitem)',
    (SELECT last_value FROM pg_sequences WHERE schemaname = 'sequences' AND sequencename = 'transactionid'),
    COALESCE(MAX(stockitemtransactionid), 0),
    (SELECT last_value FROM pg_sequences WHERE schemaname = 'sequences' AND sequencename = 'transactionid') - COALESCE(MAX(stockitemtransactionid), 0)
FROM warehouse.stockitemtransactions

ORDER BY sequence_name;

-- =============================================
-- Identify Sequences That Need Updating
-- =============================================

\echo ''
\echo 'Sequences Requiring Update (difference < 1)'
\echo '============================================='

WITH sequence_checks AS (
    SELECT 
        'sequences.personid' AS sequence_name,
        (SELECT last_value FROM pg_sequences WHERE schemaname = 'sequences' AND sequencename = 'personid') AS seq_val,
        COALESCE((SELECT MAX(personid) FROM application.people), 0) AS max_id
    UNION ALL
    SELECT 'sequences.countryid',
        (SELECT last_value FROM pg_sequences WHERE schemaname = 'sequences' AND sequencename = 'countryid'),
        COALESCE((SELECT MAX(countryid) FROM application.countries), 0)
    UNION ALL
    SELECT 'sequences.customerid',
        (SELECT last_value FROM pg_sequences WHERE schemaname = 'sequences' AND sequencename = 'customerid'),
        COALESCE((SELECT MAX(customerid) FROM sales.customers), 0)
    UNION ALL
    SELECT 'sequences.orderid',
        (SELECT last_value FROM pg_sequences WHERE schemaname = 'sequences' AND sequencename = 'orderid'),
        COALESCE((SELECT MAX(orderid) FROM sales.orders), 0)
    UNION ALL
    SELECT 'sequences.invoiceid',
        (SELECT last_value FROM pg_sequences WHERE schemaname = 'sequences' AND sequencename = 'invoiceid'),
        COALESCE((SELECT MAX(invoiceid) FROM sales.invoices), 0)
    UNION ALL
    SELECT 'sequences.stockitemid',
        (SELECT last_value FROM pg_sequences WHERE schemaname = 'sequences' AND sequencename = 'stockitemid'),
        COALESCE((SELECT MAX(stockitemid) FROM warehouse.stockitems), 0)
    UNION ALL
    SELECT 'sequences.supplierid',
        (SELECT last_value FROM pg_sequences WHERE schemaname = 'sequences' AND sequencename = 'supplierid'),
        COALESCE((SELECT MAX(supplierid) FROM purchasing.suppliers), 0)
)
SELECT 
    sequence_name,
    seq_val AS current_sequence_value,
    max_id AS max_table_id,
    'SELECT setval(''' || sequence_name || ''', ' || (max_id + 1)::text || ', false);' AS fix_command
FROM sequence_checks
WHERE seq_val <= max_id
ORDER BY sequence_name;

\echo ''
\echo 'Sequence Validation Complete!'
\echo '============================================='
\echo 'If any sequences appear in the "Requiring Update" section,'
\echo 'run the provided fix commands or execute 003-update-sequences.sql'
