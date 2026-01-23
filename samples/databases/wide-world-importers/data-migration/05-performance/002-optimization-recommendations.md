# Wide World Importers PostgreSQL Migration
## Phase 6: Performance Optimization Recommendations

This document provides optimization recommendations for the migrated PostgreSQL database based on common query patterns and data characteristics.

### Table of Contents
1. [Index Optimization](#index-optimization)
2. [Query Optimization](#query-optimization)
3. [Configuration Tuning](#configuration-tuning)
4. [Maintenance Procedures](#maintenance-procedures)
5. [Monitoring Recommendations](#monitoring-recommendations)

---

## Index Optimization

### Recommended Additional Indexes

The following indexes are recommended based on common query patterns in the Wide World Importers application:

#### Sales Schema

```sql
-- Improve order lookup by date range
CREATE INDEX idx_orders_orderdate ON sales.orders (orderdate);

-- Improve invoice lookup by date range
CREATE INDEX idx_invoices_invoicedate ON sales.invoices (invoicedate);

-- Improve customer transaction lookup by date
CREATE INDEX idx_customertransactions_transactiondate 
ON sales.customertransactions (transactiondate);

-- Composite index for order filtering
CREATE INDEX idx_orders_customer_date 
ON sales.orders (customerid, orderdate DESC);

-- Composite index for invoice filtering
CREATE INDEX idx_invoices_customer_date 
ON sales.invoices (customerid, invoicedate DESC);
```

#### Warehouse Schema

```sql
-- Improve stock transaction lookup by date
CREATE INDEX idx_stockitemtransactions_transactiondate 
ON warehouse.stockitemtransactions (transactionoccurredwhen);

-- Improve stock item lookup by supplier
CREATE INDEX idx_stockitems_supplier 
ON warehouse.stockitems (supplierid);

-- Composite index for stock transactions
CREATE INDEX idx_stockitemtransactions_item_date 
ON warehouse.stockitemtransactions (stockitemid, transactionoccurredwhen DESC);
```

#### Purchasing Schema

```sql
-- Improve purchase order lookup by date
CREATE INDEX idx_purchaseorders_orderdate 
ON purchasing.purchaseorders (orderdate);

-- Improve supplier transaction lookup by date
CREATE INDEX idx_suppliertransactions_transactiondate 
ON purchasing.suppliertransactions (transactiondate);
```

#### Temporal Table Indexes

```sql
-- Improve temporal queries on archive tables
CREATE INDEX idx_customers_archive_validfrom 
ON sales.customers_archive (validfrom);

CREATE INDEX idx_customers_archive_validto 
ON sales.customers_archive (validto);

CREATE INDEX idx_people_archive_validfrom 
ON application.people_archive (validfrom);

CREATE INDEX idx_stockitems_archive_validfrom 
ON warehouse.stockitems_archive (validfrom);
```

### Partial Indexes

For tables with status flags, consider partial indexes:

```sql
-- Index only active/current records
CREATE INDEX idx_orders_active 
ON sales.orders (orderid) 
WHERE ispickedbyinternalstaff = false;

-- Index only finalized transactions
CREATE INDEX idx_purchaseorders_finalized 
ON purchasing.purchaseorders (purchaseorderid) 
WHERE isorderfinalized = true;
```

---

## Query Optimization

### Common Query Patterns and Optimizations

#### Pattern 1: Date Range Queries

**Before:**
```sql
SELECT * FROM sales.orders 
WHERE orderdate >= '2016-01-01' AND orderdate < '2017-01-01';
```

**Optimized:**
```sql
-- Use index-friendly date comparisons
SELECT * FROM sales.orders 
WHERE orderdate >= '2016-01-01'::date 
AND orderdate < '2017-01-01'::date;
```

#### Pattern 2: Customer Sales Summary

**Before:**
```sql
SELECT c.customername, SUM(il.extendedprice)
FROM sales.customers c
JOIN sales.invoices i ON i.customerid = c.customerid
JOIN sales.invoicelines il ON il.invoiceid = i.invoiceid
GROUP BY c.customerid, c.customername;
```

**Optimized:**
```sql
-- Use materialized view for frequently accessed summaries
CREATE MATERIALIZED VIEW sales.customer_sales_summary AS
SELECT 
    c.customerid,
    c.customername,
    COUNT(DISTINCT i.invoiceid) AS invoice_count,
    SUM(il.extendedprice) AS total_sales,
    MAX(i.invoicedate) AS last_invoice_date
FROM sales.customers c
JOIN sales.invoices i ON i.customerid = c.customerid
JOIN sales.invoicelines il ON il.invoiceid = i.invoiceid
GROUP BY c.customerid, c.customername;

CREATE UNIQUE INDEX ON sales.customer_sales_summary (customerid);

-- Refresh periodically
REFRESH MATERIALIZED VIEW CONCURRENTLY sales.customer_sales_summary;
```

#### Pattern 3: Temporal Queries

**Before:**
```sql
-- Query all historical records
SELECT * FROM sales.customers
UNION ALL
SELECT * FROM sales.customers_archive
WHERE customerid = 1;
```

**Optimized:**
```sql
-- Create a view for temporal queries
CREATE OR REPLACE VIEW sales.customers_history AS
SELECT *, 'current' AS record_status FROM sales.customers
UNION ALL
SELECT *, 'archive' AS record_status FROM sales.customers_archive;

-- Query with proper index usage
SELECT * FROM sales.customers_history
WHERE customerid = 1
ORDER BY validfrom;
```

---

## Configuration Tuning

### PostgreSQL Configuration Recommendations

Based on typical Wide World Importers workloads, consider these settings:

```ini
# Memory Settings (adjust based on available RAM)
shared_buffers = 256MB          # 25% of RAM for dedicated DB server
effective_cache_size = 768MB    # 75% of RAM
work_mem = 64MB                 # For complex sorts/joins
maintenance_work_mem = 128MB    # For VACUUM, CREATE INDEX

# Write Performance
wal_buffers = 16MB
checkpoint_completion_target = 0.9
max_wal_size = 1GB

# Query Planning
random_page_cost = 1.1          # For SSD storage
effective_io_concurrency = 200  # For SSD storage
default_statistics_target = 100

# Parallel Query (PostgreSQL 10+)
max_parallel_workers_per_gather = 2
max_parallel_workers = 4
parallel_tuple_cost = 0.01
parallel_setup_cost = 100

# Connection Settings
max_connections = 100
```

### Connection Pooling

For production deployments, use PgBouncer or similar connection pooler:

```ini
# pgbouncer.ini example
[databases]
wideworldimporters = host=localhost port=5432 dbname=wideworldimporters

[pgbouncer]
listen_port = 6432
listen_addr = *
auth_type = md5
auth_file = /etc/pgbouncer/userlist.txt
pool_mode = transaction
max_client_conn = 1000
default_pool_size = 20
```

---

## Maintenance Procedures

### Regular Maintenance Schedule

#### Daily Tasks

```sql
-- Analyze tables with high write activity
ANALYZE sales.orders;
ANALYZE sales.orderlines;
ANALYZE sales.invoices;
ANALYZE sales.invoicelines;
ANALYZE warehouse.stockitemtransactions;
```

#### Weekly Tasks

```sql
-- Vacuum tables to reclaim space
VACUUM ANALYZE sales.orders;
VACUUM ANALYZE sales.orderlines;
VACUUM ANALYZE sales.invoices;
VACUUM ANALYZE sales.invoicelines;
VACUUM ANALYZE warehouse.stockitemtransactions;
VACUUM ANALYZE sales.customertransactions;
VACUUM ANALYZE purchasing.suppliertransactions;

-- Reindex if needed (during low-traffic periods)
REINDEX TABLE CONCURRENTLY sales.orders;
REINDEX TABLE CONCURRENTLY sales.invoices;
```

#### Monthly Tasks

```sql
-- Full vacuum on all tables
VACUUM FULL ANALYZE;

-- Refresh materialized views
REFRESH MATERIALIZED VIEW CONCURRENTLY sales.customer_sales_summary;

-- Update table statistics with higher sampling
ANALYZE (VERBOSE) sales.orders;
ANALYZE (VERBOSE) sales.invoices;
```

### Automated Maintenance with pg_cron

```sql
-- Schedule daily analyze
SELECT cron.schedule('daily-analyze', '0 2 * * *', 
    'ANALYZE sales.orders; ANALYZE sales.invoices;');

-- Schedule weekly vacuum
SELECT cron.schedule('weekly-vacuum', '0 3 * 0 *', 
    'VACUUM ANALYZE sales.orders; VACUUM ANALYZE sales.invoices;');
```

---

## Monitoring Recommendations

### Key Metrics to Monitor

1. **Query Performance**
   - Average query execution time
   - Slow query count (> 1 second)
   - Cache hit ratio

2. **Table Health**
   - Dead tuple count
   - Table bloat percentage
   - Index bloat percentage

3. **Connection Usage**
   - Active connections
   - Idle connections
   - Connection wait time

4. **Disk Usage**
   - Database size growth
   - Table size growth
   - Index size

### Monitoring Queries

```sql
-- Check cache hit ratio (should be > 99%)
SELECT 
    sum(heap_blks_hit) / (sum(heap_blks_hit) + sum(heap_blks_read)) AS cache_hit_ratio
FROM pg_statio_user_tables;

-- Find slow queries
SELECT 
    query,
    calls,
    mean_time,
    total_time
FROM pg_stat_statements
ORDER BY mean_time DESC
LIMIT 10;

-- Check table bloat
SELECT 
    schemaname,
    tablename,
    pg_size_pretty(pg_total_relation_size(schemaname || '.' || tablename)) AS total_size,
    n_dead_tup,
    n_live_tup,
    ROUND(n_dead_tup::numeric / NULLIF(n_live_tup, 0) * 100, 2) AS dead_ratio
FROM pg_stat_user_tables
WHERE schemaname IN ('application', 'warehouse', 'sales', 'purchasing')
ORDER BY n_dead_tup DESC;

-- Check index usage
SELECT 
    schemaname,
    tablename,
    indexname,
    idx_scan,
    idx_tup_read,
    idx_tup_fetch
FROM pg_stat_user_indexes
WHERE schemaname IN ('application', 'warehouse', 'sales', 'purchasing')
AND idx_scan = 0
ORDER BY pg_relation_size(indexrelid) DESC;
```

### Recommended Monitoring Tools

1. **pg_stat_statements** - Query performance tracking
2. **pgBadger** - Log analysis and reporting
3. **Prometheus + Grafana** - Real-time metrics and alerting
4. **pg_stat_monitor** - Enhanced query monitoring (PostgreSQL 13+)

---

## Summary

The key optimization areas for the Wide World Importers PostgreSQL migration are:

1. **Indexing**: Add indexes for date-based queries and temporal table lookups
2. **Materialized Views**: Use for frequently accessed aggregations
3. **Configuration**: Tune memory and parallel query settings
4. **Maintenance**: Establish regular VACUUM and ANALYZE schedules
5. **Monitoring**: Track cache hit ratio, slow queries, and table bloat

Implement these recommendations incrementally and measure the impact on query performance before and after each change.
