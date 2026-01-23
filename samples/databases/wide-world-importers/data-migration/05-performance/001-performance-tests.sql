-- Wide World Importers PostgreSQL Migration
-- Phase 6: Data Migration and Validation
-- File: 001-performance-tests.sql
-- Description: Performance testing queries and benchmarks
--
-- This script tests query performance on the migrated data to ensure
-- acceptable response times for common operations.
--
-- Usage: psql -d wideworldimporters -f 001-performance-tests.sql

\echo '============================================='
\echo 'Wide World Importers Data Migration'
\echo 'Performance Testing Report'
\echo '============================================='
\echo ''

-- Enable timing
\timing on

-- =============================================
-- Index Usage Analysis
-- =============================================

\echo 'Index Usage Analysis'
\echo '============================================='

-- Check index usage statistics
SELECT 
    schemaname,
    tablename,
    indexname,
    idx_scan AS index_scans,
    idx_tup_read AS tuples_read,
    idx_tup_fetch AS tuples_fetched
FROM pg_stat_user_indexes
WHERE schemaname IN ('application', 'warehouse', 'sales', 'purchasing')
ORDER BY idx_scan DESC
LIMIT 20;

-- =============================================
-- Table Statistics
-- =============================================

\echo ''
\echo 'Table Statistics'
\echo '============================================='

SELECT 
    schemaname,
    relname AS table_name,
    n_live_tup AS live_rows,
    n_dead_tup AS dead_rows,
    last_vacuum,
    last_autovacuum,
    last_analyze,
    last_autoanalyze
FROM pg_stat_user_tables
WHERE schemaname IN ('application', 'warehouse', 'sales', 'purchasing')
ORDER BY n_live_tup DESC
LIMIT 20;

-- =============================================
-- Performance Test: Simple Lookups
-- =============================================

\echo ''
\echo 'Performance Test: Simple Lookups'
\echo '============================================='

-- Test 1: Primary key lookup
\echo 'Test 1: Primary key lookup (Customer by ID)'
EXPLAIN (ANALYZE, BUFFERS, FORMAT TEXT)
SELECT * FROM sales.customers WHERE customerid = 1;

-- Test 2: Unique constraint lookup
\echo ''
\echo 'Test 2: Unique constraint lookup (Customer by Name)'
EXPLAIN (ANALYZE, BUFFERS, FORMAT TEXT)
SELECT * FROM sales.customers WHERE customername = 'Tailspin Toys (Head Office)';

-- Test 3: Foreign key lookup
\echo ''
\echo 'Test 3: Foreign key lookup (Orders by Customer)'
EXPLAIN (ANALYZE, BUFFERS, FORMAT TEXT)
SELECT * FROM sales.orders WHERE customerid = 1 LIMIT 100;

-- =============================================
-- Performance Test: Join Operations
-- =============================================

\echo ''
\echo 'Performance Test: Join Operations'
\echo '============================================='

-- Test 4: Two-table join
\echo 'Test 4: Two-table join (Orders with Customers)'
EXPLAIN (ANALYZE, BUFFERS, FORMAT TEXT)
SELECT 
    o.orderid,
    o.orderdate,
    c.customername
FROM sales.orders o
INNER JOIN sales.customers c ON c.customerid = o.customerid
WHERE o.orderdate >= '2016-01-01'
LIMIT 100;

-- Test 5: Multi-table join
\echo ''
\echo 'Test 5: Multi-table join (Invoice details)'
EXPLAIN (ANALYZE, BUFFERS, FORMAT TEXT)
SELECT 
    i.invoiceid,
    i.invoicedate,
    c.customername,
    il.description,
    il.quantity,
    il.unitprice,
    il.extendedprice
FROM sales.invoices i
INNER JOIN sales.customers c ON c.customerid = i.customerid
INNER JOIN sales.invoicelines il ON il.invoiceid = i.invoiceid
WHERE i.invoicedate >= '2016-01-01'
LIMIT 100;

-- Test 6: Complex join with aggregation
\echo ''
\echo 'Test 6: Complex join with aggregation (Customer sales summary)'
EXPLAIN (ANALYZE, BUFFERS, FORMAT TEXT)
SELECT 
    c.customerid,
    c.customername,
    COUNT(DISTINCT i.invoiceid) AS invoice_count,
    SUM(il.extendedprice) AS total_sales
FROM sales.customers c
INNER JOIN sales.invoices i ON i.customerid = c.customerid
INNER JOIN sales.invoicelines il ON il.invoiceid = i.invoiceid
WHERE i.invoicedate >= '2016-01-01'
GROUP BY c.customerid, c.customername
ORDER BY total_sales DESC
LIMIT 20;

-- =============================================
-- Performance Test: Aggregations
-- =============================================

\echo ''
\echo 'Performance Test: Aggregations'
\echo '============================================='

-- Test 7: Simple count
\echo 'Test 7: Simple count (Total orders)'
EXPLAIN (ANALYZE, BUFFERS, FORMAT TEXT)
SELECT COUNT(*) FROM sales.orders;

-- Test 8: Grouped aggregation
\echo ''
\echo 'Test 8: Grouped aggregation (Orders by date)'
EXPLAIN (ANALYZE, BUFFERS, FORMAT TEXT)
SELECT 
    DATE_TRUNC('month', orderdate) AS order_month,
    COUNT(*) AS order_count
FROM sales.orders
GROUP BY DATE_TRUNC('month', orderdate)
ORDER BY order_month;

-- Test 9: Complex aggregation
\echo ''
\echo 'Test 9: Complex aggregation (Sales by category)'
EXPLAIN (ANALYZE, BUFFERS, FORMAT TEXT)
SELECT 
    cc.customercategoryname,
    COUNT(DISTINCT c.customerid) AS customer_count,
    COUNT(DISTINCT i.invoiceid) AS invoice_count,
    SUM(il.extendedprice) AS total_sales,
    AVG(il.extendedprice) AS avg_line_value
FROM sales.customercategories cc
INNER JOIN sales.customers c ON c.customercategoryid = cc.customercategoryid
INNER JOIN sales.invoices i ON i.customerid = c.customerid
INNER JOIN sales.invoicelines il ON il.invoiceid = i.invoiceid
GROUP BY cc.customercategoryid, cc.customercategoryname
ORDER BY total_sales DESC;

-- =============================================
-- Performance Test: Text Search
-- =============================================

\echo ''
\echo 'Performance Test: Text Search'
\echo '============================================='

-- Test 10: LIKE search
\echo 'Test 10: LIKE search (Customer name pattern)'
EXPLAIN (ANALYZE, BUFFERS, FORMAT TEXT)
SELECT customerid, customername
FROM sales.customers
WHERE customername LIKE 'Tailspin%'
LIMIT 20;

-- Test 11: Full-text style search on computed column
\echo ''
\echo 'Test 11: Search on computed column (Stock item search)'
EXPLAIN (ANALYZE, BUFFERS, FORMAT TEXT)
SELECT stockitemid, stockitemname, searchdetails
FROM warehouse.stockitems
WHERE searchdetails ILIKE '%USB%'
LIMIT 20;

-- =============================================
-- Performance Test: Temporal Queries
-- =============================================

\echo ''
\echo 'Performance Test: Temporal Queries'
\echo '============================================='

-- Test 12: Current records only
\echo 'Test 12: Current records (Active customers)'
EXPLAIN (ANALYZE, BUFFERS, FORMAT TEXT)
SELECT customerid, customername, validfrom, validto
FROM sales.customers
WHERE validto = '9999-12-31 23:59:59.999999'
LIMIT 100;

-- Test 13: Point-in-time query
\echo ''
\echo 'Test 13: Point-in-time query (Customers as of specific date)'
EXPLAIN (ANALYZE, BUFFERS, FORMAT TEXT)
SELECT customerid, customername, validfrom, validto
FROM sales.customers
WHERE validfrom <= '2015-06-01' AND validto > '2015-06-01'
LIMIT 100;

-- Test 14: Historical data query
\echo ''
\echo 'Test 14: Historical data query (Customer history)'
EXPLAIN (ANALYZE, BUFFERS, FORMAT TEXT)
SELECT customerid, customername, validfrom, validto
FROM (
    SELECT customerid, customername, validfrom, validto FROM sales.customers
    UNION ALL
    SELECT customerid, customername, validfrom, validto FROM sales.customers_archive
) all_customers
WHERE customerid = 1
ORDER BY validfrom;

-- =============================================
-- Performance Test: Large Result Sets
-- =============================================

\echo ''
\echo 'Performance Test: Large Result Sets'
\echo '============================================='

-- Test 15: Large scan with filter
\echo 'Test 15: Large scan with filter (Invoice lines by date range)'
EXPLAIN (ANALYZE, BUFFERS, FORMAT TEXT)
SELECT COUNT(*), SUM(extendedprice)
FROM sales.invoicelines il
INNER JOIN sales.invoices i ON i.invoiceid = il.invoiceid
WHERE i.invoicedate BETWEEN '2015-01-01' AND '2015-12-31';

-- Test 16: Stock transaction analysis
\echo ''
\echo 'Test 16: Stock transaction analysis'
EXPLAIN (ANALYZE, BUFFERS, FORMAT TEXT)
SELECT 
    si.stockitemname,
    SUM(CASE WHEN st.quantity > 0 THEN st.quantity ELSE 0 END) AS total_in,
    SUM(CASE WHEN st.quantity < 0 THEN ABS(st.quantity) ELSE 0 END) AS total_out,
    SUM(st.quantity) AS net_change
FROM warehouse.stockitemtransactions st
INNER JOIN warehouse.stockitems si ON si.stockitemid = st.stockitemid
GROUP BY si.stockitemid, si.stockitemname
ORDER BY net_change
LIMIT 20;

-- =============================================
-- Performance Test: Subqueries
-- =============================================

\echo ''
\echo 'Performance Test: Subqueries'
\echo '============================================='

-- Test 17: Correlated subquery
\echo 'Test 17: Correlated subquery (Customers with recent orders)'
EXPLAIN (ANALYZE, BUFFERS, FORMAT TEXT)
SELECT 
    c.customerid,
    c.customername,
    (SELECT MAX(orderdate) FROM sales.orders o WHERE o.customerid = c.customerid) AS last_order_date
FROM sales.customers c
WHERE EXISTS (
    SELECT 1 FROM sales.orders o 
    WHERE o.customerid = c.customerid 
    AND o.orderdate >= '2016-01-01'
)
LIMIT 50;

-- Test 18: IN subquery
\echo ''
\echo 'Test 18: IN subquery (Stock items with recent sales)'
EXPLAIN (ANALYZE, BUFFERS, FORMAT TEXT)
SELECT stockitemid, stockitemname
FROM warehouse.stockitems
WHERE stockitemid IN (
    SELECT DISTINCT il.stockitemid
    FROM sales.invoicelines il
    INNER JOIN sales.invoices i ON i.invoiceid = il.invoiceid
    WHERE i.invoicedate >= '2016-01-01'
)
LIMIT 50;

-- =============================================
-- Performance Recommendations
-- =============================================

\echo ''
\echo 'Performance Recommendations'
\echo '============================================='

-- Check for missing indexes on foreign keys
\echo 'Foreign keys without indexes (potential performance issue):'
SELECT 
    tc.table_schema,
    tc.table_name,
    kcu.column_name,
    'CREATE INDEX idx_' || tc.table_name || '_' || kcu.column_name || 
    ' ON ' || tc.table_schema || '.' || tc.table_name || '(' || kcu.column_name || ');' AS suggested_index
FROM information_schema.table_constraints tc
JOIN information_schema.key_column_usage kcu 
    ON tc.constraint_name = kcu.constraint_name
    AND tc.table_schema = kcu.table_schema
WHERE tc.constraint_type = 'FOREIGN KEY'
AND tc.table_schema IN ('application', 'warehouse', 'sales', 'purchasing')
AND NOT EXISTS (
    SELECT 1 FROM pg_indexes pi
    WHERE pi.schemaname = tc.table_schema
    AND pi.tablename = tc.table_name
    AND pi.indexdef LIKE '%' || kcu.column_name || '%'
)
ORDER BY tc.table_schema, tc.table_name;

-- Check for tables that need VACUUM/ANALYZE
\echo ''
\echo 'Tables that may need VACUUM/ANALYZE:'
SELECT 
    schemaname,
    relname AS table_name,
    n_dead_tup AS dead_rows,
    ROUND(n_dead_tup::numeric / NULLIF(n_live_tup + n_dead_tup, 0) * 100, 2) AS dead_row_percentage,
    last_analyze,
    last_autoanalyze
FROM pg_stat_user_tables
WHERE schemaname IN ('application', 'warehouse', 'sales', 'purchasing')
AND (n_dead_tup > 1000 OR last_analyze IS NULL)
ORDER BY n_dead_tup DESC;

\timing off

\echo ''
\echo 'Performance Testing Complete!'
\echo '============================================='
\echo 'Review query plans above for any sequential scans on large tables.'
\echo 'Consider adding indexes for frequently filtered columns.'
\echo 'Run VACUUM ANALYZE on tables with high dead row counts.'
