-- Wide World Importers PostgreSQL Migration
-- Phase 6: Data Migration and Validation
-- File: 001-validate-row-counts.sql
-- Description: Validate row counts between SQL Server source and PostgreSQL target
--
-- This script creates a validation report comparing row counts.
-- Run the SQL Server queries first to get source counts, then run this
-- against PostgreSQL to compare.
--
-- Usage: psql -d wideworldimporters -f 001-validate-row-counts.sql

\echo '============================================='
\echo 'Wide World Importers Data Migration Validation'
\echo 'Row Count Verification Report'
\echo '============================================='
\echo ''

-- Create a temporary table to store expected counts from SQL Server
-- These values should be populated from the SQL Server extraction
CREATE TEMP TABLE expected_counts (
    schema_name varchar(50),
    table_name varchar(100),
    expected_count bigint,
    is_archive boolean DEFAULT false
);

-- =============================================
-- PostgreSQL Row Counts - OLTP Database
-- =============================================

\echo 'OLTP Database Row Counts'
\echo '============================================='

-- Application Schema
SELECT 'application' AS schema, 'people' AS table_name, COUNT(*) AS row_count 
FROM application.people
UNION ALL
SELECT 'application', 'people_archive', COUNT(*) FROM application.people_archive
UNION ALL
SELECT 'application', 'countries', COUNT(*) FROM application.countries
UNION ALL
SELECT 'application', 'countries_archive', COUNT(*) FROM application.countries_archive
UNION ALL
SELECT 'application', 'stateprovinces', COUNT(*) FROM application.stateprovinces
UNION ALL
SELECT 'application', 'stateprovinces_archive', COUNT(*) FROM application.stateprovinces_archive
UNION ALL
SELECT 'application', 'cities', COUNT(*) FROM application.cities
UNION ALL
SELECT 'application', 'cities_archive', COUNT(*) FROM application.cities_archive
UNION ALL
SELECT 'application', 'deliverymethods', COUNT(*) FROM application.deliverymethods
UNION ALL
SELECT 'application', 'deliverymethods_archive', COUNT(*) FROM application.deliverymethods_archive
UNION ALL
SELECT 'application', 'paymentmethods', COUNT(*) FROM application.paymentmethods
UNION ALL
SELECT 'application', 'paymentmethods_archive', COUNT(*) FROM application.paymentmethods_archive
UNION ALL
SELECT 'application', 'transactiontypes', COUNT(*) FROM application.transactiontypes
UNION ALL
SELECT 'application', 'transactiontypes_archive', COUNT(*) FROM application.transactiontypes_archive
UNION ALL
SELECT 'application', 'systemparameters', COUNT(*) FROM application.systemparameters

-- Warehouse Schema
UNION ALL
SELECT 'warehouse', 'colors', COUNT(*) FROM warehouse.colors
UNION ALL
SELECT 'warehouse', 'colors_archive', COUNT(*) FROM warehouse.colors_archive
UNION ALL
SELECT 'warehouse', 'packagetypes', COUNT(*) FROM warehouse.packagetypes
UNION ALL
SELECT 'warehouse', 'packagetypes_archive', COUNT(*) FROM warehouse.packagetypes_archive
UNION ALL
SELECT 'warehouse', 'stockgroups', COUNT(*) FROM warehouse.stockgroups
UNION ALL
SELECT 'warehouse', 'stockgroups_archive', COUNT(*) FROM warehouse.stockgroups_archive
UNION ALL
SELECT 'warehouse', 'stockitems', COUNT(*) FROM warehouse.stockitems
UNION ALL
SELECT 'warehouse', 'stockitems_archive', COUNT(*) FROM warehouse.stockitems_archive
UNION ALL
SELECT 'warehouse', 'stockitemholdings', COUNT(*) FROM warehouse.stockitemholdings
UNION ALL
SELECT 'warehouse', 'stockitemstockgroups', COUNT(*) FROM warehouse.stockitemstockgroups
UNION ALL
SELECT 'warehouse', 'stockitemtransactions', COUNT(*) FROM warehouse.stockitemtransactions
UNION ALL
SELECT 'warehouse', 'coldroomtemperatures', COUNT(*) FROM warehouse.coldroomtemperatures
UNION ALL
SELECT 'warehouse', 'coldroomtemperatures_archive', COUNT(*) FROM warehouse.coldroomtemperatures_archive
UNION ALL
SELECT 'warehouse', 'vehicletemperatures', COUNT(*) FROM warehouse.vehicletemperatures

-- Sales Schema
UNION ALL
SELECT 'sales', 'buyinggroups', COUNT(*) FROM sales.buyinggroups
UNION ALL
SELECT 'sales', 'buyinggroups_archive', COUNT(*) FROM sales.buyinggroups_archive
UNION ALL
SELECT 'sales', 'customercategories', COUNT(*) FROM sales.customercategories
UNION ALL
SELECT 'sales', 'customercategories_archive', COUNT(*) FROM sales.customercategories_archive
UNION ALL
SELECT 'sales', 'customers', COUNT(*) FROM sales.customers
UNION ALL
SELECT 'sales', 'customers_archive', COUNT(*) FROM sales.customers_archive
UNION ALL
SELECT 'sales', 'orders', COUNT(*) FROM sales.orders
UNION ALL
SELECT 'sales', 'orderlines', COUNT(*) FROM sales.orderlines
UNION ALL
SELECT 'sales', 'invoices', COUNT(*) FROM sales.invoices
UNION ALL
SELECT 'sales', 'invoicelines', COUNT(*) FROM sales.invoicelines
UNION ALL
SELECT 'sales', 'specialdeals', COUNT(*) FROM sales.specialdeals
UNION ALL
SELECT 'sales', 'customertransactions', COUNT(*) FROM sales.customertransactions

-- Purchasing Schema
UNION ALL
SELECT 'purchasing', 'suppliercategories', COUNT(*) FROM purchasing.suppliercategories
UNION ALL
SELECT 'purchasing', 'suppliercategories_archive', COUNT(*) FROM purchasing.suppliercategories_archive
UNION ALL
SELECT 'purchasing', 'suppliers', COUNT(*) FROM purchasing.suppliers
UNION ALL
SELECT 'purchasing', 'suppliers_archive', COUNT(*) FROM purchasing.suppliers_archive
UNION ALL
SELECT 'purchasing', 'purchaseorders', COUNT(*) FROM purchasing.purchaseorders
UNION ALL
SELECT 'purchasing', 'purchaseorderlines', COUNT(*) FROM purchasing.purchaseorderlines
UNION ALL
SELECT 'purchasing', 'suppliertransactions', COUNT(*) FROM purchasing.suppliertransactions

ORDER BY schema, table_name;

-- =============================================
-- Summary Statistics
-- =============================================

\echo ''
\echo 'Summary Statistics'
\echo '============================================='

SELECT 
    'Total Tables' AS metric,
    COUNT(DISTINCT table_schema || '.' || table_name)::text AS value
FROM information_schema.tables 
WHERE table_schema IN ('application', 'warehouse', 'sales', 'purchasing')
AND table_type = 'BASE TABLE'

UNION ALL

SELECT 
    'Total Rows (All Tables)',
    SUM(row_count)::text
FROM (
    SELECT COUNT(*) AS row_count FROM application.people
    UNION ALL SELECT COUNT(*) FROM application.countries
    UNION ALL SELECT COUNT(*) FROM application.stateprovinces
    UNION ALL SELECT COUNT(*) FROM application.cities
    UNION ALL SELECT COUNT(*) FROM application.deliverymethods
    UNION ALL SELECT COUNT(*) FROM application.paymentmethods
    UNION ALL SELECT COUNT(*) FROM application.transactiontypes
    UNION ALL SELECT COUNT(*) FROM application.systemparameters
    UNION ALL SELECT COUNT(*) FROM warehouse.colors
    UNION ALL SELECT COUNT(*) FROM warehouse.packagetypes
    UNION ALL SELECT COUNT(*) FROM warehouse.stockgroups
    UNION ALL SELECT COUNT(*) FROM warehouse.stockitems
    UNION ALL SELECT COUNT(*) FROM warehouse.stockitemholdings
    UNION ALL SELECT COUNT(*) FROM warehouse.stockitemstockgroups
    UNION ALL SELECT COUNT(*) FROM warehouse.stockitemtransactions
    UNION ALL SELECT COUNT(*) FROM warehouse.coldroomtemperatures
    UNION ALL SELECT COUNT(*) FROM warehouse.vehicletemperatures
    UNION ALL SELECT COUNT(*) FROM sales.buyinggroups
    UNION ALL SELECT COUNT(*) FROM sales.customercategories
    UNION ALL SELECT COUNT(*) FROM sales.customers
    UNION ALL SELECT COUNT(*) FROM sales.orders
    UNION ALL SELECT COUNT(*) FROM sales.orderlines
    UNION ALL SELECT COUNT(*) FROM sales.invoices
    UNION ALL SELECT COUNT(*) FROM sales.invoicelines
    UNION ALL SELECT COUNT(*) FROM sales.specialdeals
    UNION ALL SELECT COUNT(*) FROM sales.customertransactions
    UNION ALL SELECT COUNT(*) FROM purchasing.suppliercategories
    UNION ALL SELECT COUNT(*) FROM purchasing.suppliers
    UNION ALL SELECT COUNT(*) FROM purchasing.purchaseorders
    UNION ALL SELECT COUNT(*) FROM purchasing.purchaseorderlines
    UNION ALL SELECT COUNT(*) FROM purchasing.suppliertransactions
) counts;

\echo ''
\echo 'Row Count Validation Complete!'
