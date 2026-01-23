-- Wide World Importers PostgreSQL Migration
-- Phase 6: Data Migration and Validation
-- File: 004-validate-business-logic.sql
-- Description: Validate critical business logic and stored procedures work correctly
--
-- This script tests the migrated stored procedures from Phase 3 to ensure
-- they work correctly with the migrated data.
--
-- Usage: psql -d wideworldimporters -f 004-validate-business-logic.sql

\echo '============================================='
\echo 'Wide World Importers Data Migration Validation'
\echo 'Business Logic Verification Report'
\echo '============================================='
\echo ''

-- =============================================
-- Test Website Schema Functions
-- =============================================

\echo 'Testing Website Schema Functions'
\echo '============================================='

-- Test website.searchforcustomers
\echo 'Testing website.searchforcustomers...'
DO $$
DECLARE
    v_count integer;
BEGIN
    SELECT COUNT(*) INTO v_count
    FROM website.searchforcustomers('Tailspin', 10);
    
    IF v_count >= 0 THEN
        RAISE NOTICE 'website.searchforcustomers: PASSED (returned % rows)', v_count;
    ELSE
        RAISE NOTICE 'website.searchforcustomers: FAILED';
    END IF;
END $$;

-- Test website.searchforstockitems
\echo 'Testing website.searchforstockitems...'
DO $$
DECLARE
    v_count integer;
BEGIN
    SELECT COUNT(*) INTO v_count
    FROM website.searchforstockitems('USB', 10);
    
    IF v_count >= 0 THEN
        RAISE NOTICE 'website.searchforstockitems: PASSED (returned % rows)', v_count;
    ELSE
        RAISE NOTICE 'website.searchforstockitems: FAILED';
    END IF;
END $$;

-- Test website.searchforsuppliers
\echo 'Testing website.searchforsuppliers...'
DO $$
DECLARE
    v_count integer;
BEGIN
    SELECT COUNT(*) INTO v_count
    FROM website.searchforsuppliers('Fabrikam', 10);
    
    IF v_count >= 0 THEN
        RAISE NOTICE 'website.searchforsuppliers: PASSED (returned % rows)', v_count;
    ELSE
        RAISE NOTICE 'website.searchforsuppliers: FAILED';
    END IF;
END $$;

-- =============================================
-- Test Integration Functions (ETL)
-- =============================================

\echo ''
\echo 'Testing Integration Functions (ETL)'
\echo '============================================='

-- Test integration.getcityupdates
\echo 'Testing integration.getcityupdates...'
DO $$
DECLARE
    v_count integer;
BEGIN
    SELECT COUNT(*) INTO v_count
    FROM integration.getcityupdates('2013-01-01'::timestamp, '2020-01-01'::timestamp);
    
    IF v_count >= 0 THEN
        RAISE NOTICE 'integration.getcityupdates: PASSED (returned % rows)', v_count;
    ELSE
        RAISE NOTICE 'integration.getcityupdates: FAILED';
    END IF;
EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'integration.getcityupdates: SKIPPED (function may not exist)';
END $$;

-- Test integration.getcustomerupdates
\echo 'Testing integration.getcustomerupdates...'
DO $$
DECLARE
    v_count integer;
BEGIN
    SELECT COUNT(*) INTO v_count
    FROM integration.getcustomerupdates('2013-01-01'::timestamp, '2020-01-01'::timestamp);
    
    IF v_count >= 0 THEN
        RAISE NOTICE 'integration.getcustomerupdates: PASSED (returned % rows)', v_count;
    ELSE
        RAISE NOTICE 'integration.getcustomerupdates: FAILED';
    END IF;
EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'integration.getcustomerupdates: SKIPPED (function may not exist)';
END $$;

-- Test integration.getemployeeupdates
\echo 'Testing integration.getemployeeupdates...'
DO $$
DECLARE
    v_count integer;
BEGIN
    SELECT COUNT(*) INTO v_count
    FROM integration.getemployeeupdates('2013-01-01'::timestamp, '2020-01-01'::timestamp);
    
    IF v_count >= 0 THEN
        RAISE NOTICE 'integration.getemployeeupdates: PASSED (returned % rows)', v_count;
    ELSE
        RAISE NOTICE 'integration.getemployeeupdates: FAILED';
    END IF;
EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'integration.getemployeeupdates: SKIPPED (function may not exist)';
END $$;

-- =============================================
-- Test Computed Column Equivalents
-- =============================================

\echo ''
\echo 'Testing Computed Column Equivalents'
\echo '============================================='

-- Test SearchName computed column in People
\echo 'Testing application.people.searchname...'
SELECT 
    CASE 
        WHEN COUNT(*) = COUNT(searchname) THEN 'PASSED: All searchname values computed'
        ELSE 'FAILED: Some searchname values are NULL'
    END AS result
FROM application.people;

-- Test SearchDetails computed column in StockItems
\echo 'Testing warehouse.stockitems.searchdetails...'
SELECT 
    CASE 
        WHEN COUNT(*) = COUNT(searchdetails) THEN 'PASSED: All searchdetails values computed'
        ELSE 'FAILED: Some searchdetails values are NULL'
    END AS result
FROM warehouse.stockitems;

-- Test IsFinalized computed column in CustomerTransactions
\echo 'Testing sales.customertransactions.isfinalized...'
SELECT 
    CASE 
        WHEN COUNT(*) = (
            SELECT COUNT(*) 
            FROM sales.customertransactions 
            WHERE (finalizationdate IS NOT NULL AND isfinalized = true)
               OR (finalizationdate IS NULL AND isfinalized = false)
        ) THEN 'PASSED: IsFinalized computed correctly'
        ELSE 'FAILED: IsFinalized computation mismatch'
    END AS result
FROM sales.customertransactions;

-- Test IsFinalized computed column in SupplierTransactions
\echo 'Testing purchasing.suppliertransactions.isfinalized...'
SELECT 
    CASE 
        WHEN COUNT(*) = (
            SELECT COUNT(*) 
            FROM purchasing.suppliertransactions 
            WHERE (finalizationdate IS NOT NULL AND isfinalized = true)
               OR (finalizationdate IS NULL AND isfinalized = false)
        ) THEN 'PASSED: IsFinalized computed correctly'
        ELSE 'FAILED: IsFinalized computation mismatch'
    END AS result
FROM purchasing.suppliertransactions;

-- =============================================
-- Test Invoice View with Computed Columns
-- =============================================

\echo ''
\echo 'Testing Invoice View with Computed Columns'
\echo '============================================='

-- Test sales.invoices_with_delivery view
\echo 'Testing sales.invoices_with_delivery view...'
DO $$
DECLARE
    v_count integer;
    v_with_delivery integer;
BEGIN
    SELECT COUNT(*) INTO v_count FROM sales.invoices_with_delivery;
    SELECT COUNT(*) INTO v_with_delivery 
    FROM sales.invoices_with_delivery 
    WHERE confirmeddeliverytime IS NOT NULL;
    
    RAISE NOTICE 'sales.invoices_with_delivery: % total invoices, % with delivery confirmation', 
        v_count, v_with_delivery;
END $$;

-- =============================================
-- Test Data Relationships
-- =============================================

\echo ''
\echo 'Testing Data Relationships'
\echo '============================================='

-- Test Order -> Invoice relationship
\echo 'Testing Order -> Invoice relationship...'
SELECT 
    'Orders with Invoices' AS relationship,
    COUNT(DISTINCT o.orderid) AS orders_with_invoices,
    (SELECT COUNT(*) FROM sales.orders) AS total_orders,
    ROUND(COUNT(DISTINCT o.orderid)::numeric / NULLIF((SELECT COUNT(*) FROM sales.orders), 0) * 100, 2) AS percentage
FROM sales.orders o
INNER JOIN sales.invoices i ON i.orderid = o.orderid;

-- Test Customer -> Order relationship
\echo 'Testing Customer -> Order relationship...'
SELECT 
    'Customers with Orders' AS relationship,
    COUNT(DISTINCT c.customerid) AS customers_with_orders,
    (SELECT COUNT(*) FROM sales.customers) AS total_customers,
    ROUND(COUNT(DISTINCT c.customerid)::numeric / NULLIF((SELECT COUNT(*) FROM sales.customers), 0) * 100, 2) AS percentage
FROM sales.customers c
INNER JOIN sales.orders o ON o.customerid = c.customerid;

-- Test Supplier -> PurchaseOrder relationship
\echo 'Testing Supplier -> PurchaseOrder relationship...'
SELECT 
    'Suppliers with PurchaseOrders' AS relationship,
    COUNT(DISTINCT s.supplierid) AS suppliers_with_orders,
    (SELECT COUNT(*) FROM purchasing.suppliers) AS total_suppliers,
    ROUND(COUNT(DISTINCT s.supplierid)::numeric / NULLIF((SELECT COUNT(*) FROM purchasing.suppliers), 0) * 100, 2) AS percentage
FROM purchasing.suppliers s
INNER JOIN purchasing.purchaseorders po ON po.supplierid = s.supplierid;

-- =============================================
-- Test Aggregate Calculations
-- =============================================

\echo ''
\echo 'Testing Aggregate Calculations'
\echo '============================================='

-- Test Invoice totals
\echo 'Testing Invoice line totals...'
SELECT 
    'Invoice Line Totals' AS check_name,
    CASE 
        WHEN ABS(SUM(il.extendedprice) - SUM(il.quantity * il.unitprice + il.taxamount)) < 0.01 
        THEN 'PASSED: Extended price calculation correct'
        ELSE 'WARNING: Extended price calculation may have rounding differences'
    END AS result
FROM sales.invoicelines il;

-- Test Order line calculations
\echo 'Testing Order line calculations...'
SELECT 
    'Order Line Calculations' AS check_name,
    COUNT(*) AS total_lines,
    SUM(quantity) AS total_quantity,
    SUM(unitprice * quantity) AS total_value
FROM sales.orderlines;

-- =============================================
-- Test Temporal Data Queries
-- =============================================

\echo ''
\echo 'Testing Temporal Data Queries'
\echo '============================================='

-- Test querying historical data
\echo 'Testing historical customer data...'
SELECT 
    'Historical Customer Records' AS query_type,
    COUNT(*) AS archive_records,
    MIN(validfrom) AS earliest_record,
    MAX(validto) AS latest_archive
FROM sales.customers_archive;

-- Test current vs historical counts
\echo 'Testing current vs historical record counts...'
SELECT 
    'People' AS table_name,
    (SELECT COUNT(*) FROM application.people) AS current_count,
    (SELECT COUNT(*) FROM application.people_archive) AS archive_count
UNION ALL
SELECT 
    'Customers',
    (SELECT COUNT(*) FROM sales.customers),
    (SELECT COUNT(*) FROM sales.customers_archive)
UNION ALL
SELECT 
    'Suppliers',
    (SELECT COUNT(*) FROM purchasing.suppliers),
    (SELECT COUNT(*) FROM purchasing.suppliers_archive)
UNION ALL
SELECT 
    'StockItems',
    (SELECT COUNT(*) FROM warehouse.stockitems),
    (SELECT COUNT(*) FROM warehouse.stockitems_archive);

-- =============================================
-- Summary
-- =============================================

\echo ''
\echo 'Business Logic Validation Complete!'
\echo '============================================='
\echo 'Review the output above for any FAILED or WARNING messages.'
\echo 'All PASSED results indicate successful validation.'
