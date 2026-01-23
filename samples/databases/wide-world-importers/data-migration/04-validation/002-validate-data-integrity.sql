-- Wide World Importers PostgreSQL Migration
-- Phase 6: Data Migration and Validation
-- File: 002-validate-data-integrity.sql
-- Description: Validate data integrity and foreign key relationships
--
-- This script checks:
-- 1. Primary key uniqueness
-- 2. Foreign key relationship integrity
-- 3. Check constraint validity
-- 4. Data type consistency
-- 5. NULL constraint compliance
--
-- Usage: psql -d wideworldimporters -f 002-validate-data-integrity.sql

\echo '============================================='
\echo 'Wide World Importers Data Migration Validation'
\echo 'Data Integrity Verification Report'
\echo '============================================='
\echo ''

-- =============================================
-- Primary Key Validation
-- =============================================

\echo 'Primary Key Validation'
\echo '============================================='

-- Check for duplicate primary keys (should return 0 rows for each)
SELECT 'application.people' AS table_name, 
       COUNT(*) - COUNT(DISTINCT personid) AS duplicate_count
FROM application.people
UNION ALL
SELECT 'application.countries', COUNT(*) - COUNT(DISTINCT countryid) FROM application.countries
UNION ALL
SELECT 'application.stateprovinces', COUNT(*) - COUNT(DISTINCT stateprovinceid) FROM application.stateprovinces
UNION ALL
SELECT 'application.cities', COUNT(*) - COUNT(DISTINCT cityid) FROM application.cities
UNION ALL
SELECT 'warehouse.stockitems', COUNT(*) - COUNT(DISTINCT stockitemid) FROM warehouse.stockitems
UNION ALL
SELECT 'sales.customers', COUNT(*) - COUNT(DISTINCT customerid) FROM sales.customers
UNION ALL
SELECT 'sales.orders', COUNT(*) - COUNT(DISTINCT orderid) FROM sales.orders
UNION ALL
SELECT 'sales.invoices', COUNT(*) - COUNT(DISTINCT invoiceid) FROM sales.invoices
UNION ALL
SELECT 'purchasing.suppliers', COUNT(*) - COUNT(DISTINCT supplierid) FROM purchasing.suppliers
UNION ALL
SELECT 'purchasing.purchaseorders', COUNT(*) - COUNT(DISTINCT purchaseorderid) FROM purchasing.purchaseorders
ORDER BY table_name;

-- =============================================
-- Foreign Key Relationship Validation
-- =============================================

\echo ''
\echo 'Foreign Key Relationship Validation'
\echo '============================================='
\echo 'Checking for orphaned records (should return 0 for each)...'

-- Application Schema FK Checks
SELECT 'stateprovinces -> countries' AS relationship,
       COUNT(*) AS orphaned_records
FROM application.stateprovinces sp
WHERE NOT EXISTS (SELECT 1 FROM application.countries c WHERE c.countryid = sp.countryid)

UNION ALL
SELECT 'cities -> stateprovinces',
       COUNT(*)
FROM application.cities c
WHERE NOT EXISTS (SELECT 1 FROM application.stateprovinces sp WHERE sp.stateprovinceid = c.stateprovinceid)

UNION ALL
SELECT 'people -> people (lasteditedby)',
       COUNT(*)
FROM application.people p
WHERE NOT EXISTS (SELECT 1 FROM application.people p2 WHERE p2.personid = p.lasteditedby)

-- Warehouse Schema FK Checks
UNION ALL
SELECT 'stockitems -> suppliers',
       COUNT(*)
FROM warehouse.stockitems si
WHERE NOT EXISTS (SELECT 1 FROM purchasing.suppliers s WHERE s.supplierid = si.supplierid)

UNION ALL
SELECT 'stockitems -> colors',
       COUNT(*)
FROM warehouse.stockitems si
WHERE si.colorid IS NOT NULL 
AND NOT EXISTS (SELECT 1 FROM warehouse.colors c WHERE c.colorid = si.colorid)

UNION ALL
SELECT 'stockitems -> packagetypes (unit)',
       COUNT(*)
FROM warehouse.stockitems si
WHERE NOT EXISTS (SELECT 1 FROM warehouse.packagetypes pt WHERE pt.packagetypeid = si.unitpackageid)

UNION ALL
SELECT 'stockitems -> packagetypes (outer)',
       COUNT(*)
FROM warehouse.stockitems si
WHERE NOT EXISTS (SELECT 1 FROM warehouse.packagetypes pt WHERE pt.packagetypeid = si.outerpackageid)

UNION ALL
SELECT 'stockitemholdings -> stockitems',
       COUNT(*)
FROM warehouse.stockitemholdings sih
WHERE NOT EXISTS (SELECT 1 FROM warehouse.stockitems si WHERE si.stockitemid = sih.stockitemid)

UNION ALL
SELECT 'stockitemstockgroups -> stockitems',
       COUNT(*)
FROM warehouse.stockitemstockgroups sisg
WHERE NOT EXISTS (SELECT 1 FROM warehouse.stockitems si WHERE si.stockitemid = sisg.stockitemid)

UNION ALL
SELECT 'stockitemstockgroups -> stockgroups',
       COUNT(*)
FROM warehouse.stockitemstockgroups sisg
WHERE NOT EXISTS (SELECT 1 FROM warehouse.stockgroups sg WHERE sg.stockgroupid = sisg.stockgroupid)

-- Sales Schema FK Checks
UNION ALL
SELECT 'customers -> customercategories',
       COUNT(*)
FROM sales.customers c
WHERE NOT EXISTS (SELECT 1 FROM sales.customercategories cc WHERE cc.customercategoryid = c.customercategoryid)

UNION ALL
SELECT 'customers -> buyinggroups',
       COUNT(*)
FROM sales.customers c
WHERE c.buyinggroupid IS NOT NULL
AND NOT EXISTS (SELECT 1 FROM sales.buyinggroups bg WHERE bg.buyinggroupid = c.buyinggroupid)

UNION ALL
SELECT 'customers -> cities (delivery)',
       COUNT(*)
FROM sales.customers c
WHERE NOT EXISTS (SELECT 1 FROM application.cities ci WHERE ci.cityid = c.deliverycityid)

UNION ALL
SELECT 'customers -> cities (postal)',
       COUNT(*)
FROM sales.customers c
WHERE NOT EXISTS (SELECT 1 FROM application.cities ci WHERE ci.cityid = c.postalcityid)

UNION ALL
SELECT 'customers -> deliverymethods',
       COUNT(*)
FROM sales.customers c
WHERE NOT EXISTS (SELECT 1 FROM application.deliverymethods dm WHERE dm.deliverymethodid = c.deliverymethodid)

UNION ALL
SELECT 'orders -> customers',
       COUNT(*)
FROM sales.orders o
WHERE NOT EXISTS (SELECT 1 FROM sales.customers c WHERE c.customerid = o.customerid)

UNION ALL
SELECT 'orderlines -> orders',
       COUNT(*)
FROM sales.orderlines ol
WHERE NOT EXISTS (SELECT 1 FROM sales.orders o WHERE o.orderid = ol.orderid)

UNION ALL
SELECT 'orderlines -> stockitems',
       COUNT(*)
FROM sales.orderlines ol
WHERE NOT EXISTS (SELECT 1 FROM warehouse.stockitems si WHERE si.stockitemid = ol.stockitemid)

UNION ALL
SELECT 'invoices -> customers',
       COUNT(*)
FROM sales.invoices i
WHERE NOT EXISTS (SELECT 1 FROM sales.customers c WHERE c.customerid = i.customerid)

UNION ALL
SELECT 'invoicelines -> invoices',
       COUNT(*)
FROM sales.invoicelines il
WHERE NOT EXISTS (SELECT 1 FROM sales.invoices i WHERE i.invoiceid = il.invoiceid)

UNION ALL
SELECT 'invoicelines -> stockitems',
       COUNT(*)
FROM sales.invoicelines il
WHERE NOT EXISTS (SELECT 1 FROM warehouse.stockitems si WHERE si.stockitemid = il.stockitemid)

UNION ALL
SELECT 'customertransactions -> customers',
       COUNT(*)
FROM sales.customertransactions ct
WHERE NOT EXISTS (SELECT 1 FROM sales.customers c WHERE c.customerid = ct.customerid)

UNION ALL
SELECT 'customertransactions -> transactiontypes',
       COUNT(*)
FROM sales.customertransactions ct
WHERE NOT EXISTS (SELECT 1 FROM application.transactiontypes tt WHERE tt.transactiontypeid = ct.transactiontypeid)

-- Purchasing Schema FK Checks
UNION ALL
SELECT 'suppliers -> suppliercategories',
       COUNT(*)
FROM purchasing.suppliers s
WHERE NOT EXISTS (SELECT 1 FROM purchasing.suppliercategories sc WHERE sc.suppliercategoryid = s.suppliercategoryid)

UNION ALL
SELECT 'suppliers -> cities (delivery)',
       COUNT(*)
FROM purchasing.suppliers s
WHERE NOT EXISTS (SELECT 1 FROM application.cities c WHERE c.cityid = s.deliverycityid)

UNION ALL
SELECT 'purchaseorders -> suppliers',
       COUNT(*)
FROM purchasing.purchaseorders po
WHERE NOT EXISTS (SELECT 1 FROM purchasing.suppliers s WHERE s.supplierid = po.supplierid)

UNION ALL
SELECT 'purchaseorderlines -> purchaseorders',
       COUNT(*)
FROM purchasing.purchaseorderlines pol
WHERE NOT EXISTS (SELECT 1 FROM purchasing.purchaseorders po WHERE po.purchaseorderid = pol.purchaseorderid)

UNION ALL
SELECT 'purchaseorderlines -> stockitems',
       COUNT(*)
FROM purchasing.purchaseorderlines pol
WHERE NOT EXISTS (SELECT 1 FROM warehouse.stockitems si WHERE si.stockitemid = pol.stockitemid)

UNION ALL
SELECT 'suppliertransactions -> suppliers',
       COUNT(*)
FROM purchasing.suppliertransactions st
WHERE NOT EXISTS (SELECT 1 FROM purchasing.suppliers s WHERE s.supplierid = st.supplierid)

ORDER BY relationship;

-- =============================================
-- Check Constraint Validation
-- =============================================

\echo ''
\echo 'Check Constraint Validation'
\echo '============================================='

-- Validate SpecialDeals pricing constraint
SELECT 'specialdeals pricing constraint' AS constraint_name,
       COUNT(*) AS violations
FROM sales.specialdeals
WHERE NOT (
    (CASE WHEN discountamount IS NULL THEN 0 ELSE 1 END + 
     CASE WHEN discountpercentage IS NULL THEN 0 ELSE 1 END + 
     CASE WHEN unitprice IS NULL THEN 0 ELSE 1 END) = 1
)

UNION ALL
-- Validate SpecialDeals unit price requires stock item
SELECT 'specialdeals unitprice requires stockitem',
       COUNT(*)
FROM sales.specialdeals
WHERE unitprice IS NOT NULL AND stockitemid IS NULL

UNION ALL
-- Validate Invoice JSON is valid
SELECT 'invoices valid json',
       COUNT(*)
FROM sales.invoices
WHERE returneddeliverydata IS NOT NULL 
AND returneddeliverydata::jsonb IS NULL;

-- =============================================
-- Temporal Data Validation
-- =============================================

\echo ''
\echo 'Temporal Data Validation'
\echo '============================================='

-- Check that ValidFrom < ValidTo for all temporal tables
SELECT 'people temporal validity' AS check_name,
       COUNT(*) AS invalid_records
FROM application.people
WHERE validfrom >= validto

UNION ALL
SELECT 'countries temporal validity',
       COUNT(*)
FROM application.countries
WHERE validfrom >= validto

UNION ALL
SELECT 'stateprovinces temporal validity',
       COUNT(*)
FROM application.stateprovinces
WHERE validfrom >= validto

UNION ALL
SELECT 'cities temporal validity',
       COUNT(*)
FROM application.cities
WHERE validfrom >= validto

UNION ALL
SELECT 'customers temporal validity',
       COUNT(*)
FROM sales.customers
WHERE validfrom >= validto

UNION ALL
SELECT 'suppliers temporal validity',
       COUNT(*)
FROM purchasing.suppliers
WHERE validfrom >= validto

UNION ALL
SELECT 'stockitems temporal validity',
       COUNT(*)
FROM warehouse.stockitems
WHERE validfrom >= validto

ORDER BY check_name;

-- =============================================
-- Data Quality Checks
-- =============================================

\echo ''
\echo 'Data Quality Checks'
\echo '============================================='

-- Check for empty required fields
SELECT 'people with empty fullname' AS check_name,
       COUNT(*) AS count
FROM application.people
WHERE fullname IS NULL OR TRIM(fullname) = ''

UNION ALL
SELECT 'customers with empty customername',
       COUNT(*)
FROM sales.customers
WHERE customername IS NULL OR TRIM(customername) = ''

UNION ALL
SELECT 'stockitems with empty stockitemname',
       COUNT(*)
FROM warehouse.stockitems
WHERE stockitemname IS NULL OR TRIM(stockitemname) = ''

UNION ALL
SELECT 'suppliers with empty suppliername',
       COUNT(*)
FROM purchasing.suppliers
WHERE suppliername IS NULL OR TRIM(suppliername) = ''

UNION ALL
-- Check for negative quantities
SELECT 'orderlines with negative quantity',
       COUNT(*)
FROM sales.orderlines
WHERE quantity < 0

UNION ALL
SELECT 'invoicelines with negative quantity',
       COUNT(*)
FROM sales.invoicelines
WHERE quantity < 0

UNION ALL
-- Check for negative prices
SELECT 'stockitems with negative unitprice',
       COUNT(*)
FROM warehouse.stockitems
WHERE unitprice < 0

UNION ALL
SELECT 'orderlines with negative unitprice',
       COUNT(*)
FROM sales.orderlines
WHERE unitprice < 0

ORDER BY check_name;

-- =============================================
-- Summary
-- =============================================

\echo ''
\echo 'Data Integrity Validation Complete!'
\echo '============================================='
\echo 'All checks returning 0 indicate successful validation.'
\echo 'Non-zero values indicate potential data issues to investigate.'
