# Wide World Importers Analytics for PostgreSQL

This directory contains the PostgreSQL analytics solution that replaces SQL Server Analysis Services (SSAS) cubes from the original `wwi-ssasmd/` project.

## Overview

The original SQL Server solution uses SSAS Multidimensional cubes to provide OLAP analytics capabilities. This PostgreSQL implementation provides equivalent functionality using materialized views and analytical functions.

### Comparison with SSAS

| Feature | SSAS (Original) | PostgreSQL Analytics |
|---------|-----------------|---------------------|
| Data Model | Multidimensional Cube | Materialized Views |
| Query Language | MDX | SQL |
| Aggregations | Pre-calculated | Materialized Views |
| Dimensions | SSAS Dimensions | Dimension Tables |
| Measures | SSAS Measures | Aggregate Functions |
| Refresh | Cube Processing | REFRESH MATERIALIZED VIEW |
| Client Tools | Excel, Power BI | Any SQL Client |

## Analytics Objects

### Materialized Views

These pre-aggregated views provide fast analytical queries similar to SSAS cube aggregations:

1. **analytics.sales_summary** - Sales metrics by time, geography, customer, product, and salesperson
2. **analytics.purchase_summary** - Purchase metrics by time, supplier, and product
3. **analytics.movement_summary** - Inventory movement metrics by time, product, and transaction type
4. **analytics.transaction_summary** - Financial transaction metrics by time, customer, supplier, and payment method

### Analytical Views

These views provide additional analytical capabilities:

1. **analytics.stock_holding_current** - Current inventory status with stock level analysis
2. **analytics.sales_yoy_comparison** - Year-over-year sales comparison
3. **analytics.top_products** - Product performance ranking
4. **analytics.customer_analysis** - Customer performance analysis
5. **analytics.geographic_sales** - Geographic breakdown of sales

## Installation

```bash
psql -h localhost -U webapi -d wideworldimportersdw -f 001-analytics-views.sql
```

## Usage

### Refreshing Materialized Views

After each ETL run, refresh the materialized views to include new data:

```sql
-- Refresh all analytics views
CALL analytics.refresh_all_views();

-- Or refresh individual views
REFRESH MATERIALIZED VIEW CONCURRENTLY analytics.sales_summary;
```

### Example Queries

#### Sales by Territory and Month
```sql
SELECT 
    sales_territory,
    calendar_year,
    calendar_month_label,
    SUM(total_including_tax) AS revenue,
    SUM(total_profit) AS profit
FROM analytics.sales_summary
GROUP BY sales_territory, calendar_year, calendar_month_label
ORDER BY calendar_year, calendar_month_number;
```

#### Top 10 Products by Revenue
```sql
SELECT 
    stock_item,
    brand,
    total_revenue,
    total_profit,
    revenue_rank
FROM analytics.top_products
WHERE revenue_rank <= 10
ORDER BY revenue_rank;
```

#### Year-over-Year Growth
```sql
SELECT 
    calendar_year,
    calendar_month_number,
    current_revenue,
    previous_year_revenue,
    revenue_change_pct
FROM analytics.sales_yoy_comparison
WHERE calendar_year = EXTRACT(YEAR FROM CURRENT_DATE)
ORDER BY calendar_month_number;
```

#### Inventory Requiring Reorder
```sql
SELECT 
    stock_item,
    quantity_on_hand,
    reorder_level,
    target_stock_level,
    quantity_to_target
FROM analytics.stock_holding_current
WHERE stock_status = 'Reorder Required'
ORDER BY quantity_to_target DESC;
```

#### Customer Segmentation
```sql
SELECT 
    customer_category,
    buying_group,
    COUNT(*) AS customer_count,
    SUM(total_revenue) AS total_revenue,
    AVG(avg_monthly_revenue) AS avg_customer_monthly_revenue
FROM analytics.customer_analysis
GROUP BY customer_category, buying_group
ORDER BY total_revenue DESC;
```

## Performance Considerations

### Materialized View Refresh

- Use `REFRESH MATERIALIZED VIEW CONCURRENTLY` to allow queries during refresh
- Schedule refresh after ETL completion
- Consider partial refresh strategies for very large datasets

### Indexing

The materialized views include unique indexes to support concurrent refresh. Additional indexes can be added based on query patterns:

```sql
-- Example: Add index for territory-based queries
CREATE INDEX idx_sales_summary_territory 
ON analytics.sales_summary (sales_territory, calendar_year, calendar_month_number);
```

### Query Optimization

- Use the materialized views for aggregated queries instead of querying fact tables directly
- For ad-hoc analysis, consider creating additional materialized views
- Use EXPLAIN ANALYZE to identify slow queries

## Integration with BI Tools

### Power BI

Connect Power BI directly to PostgreSQL and use the analytics views as data sources:

1. Use "PostgreSQL database" connector
2. Select the analytics schema views
3. Build reports using the pre-aggregated data

### Tableau

Connect Tableau to PostgreSQL:

1. Use "PostgreSQL" connector
2. Select analytics views or create custom SQL
3. Build visualizations using the aggregated metrics

### Excel

Use Power Query to connect to PostgreSQL:

1. Data > Get Data > From Database > From PostgreSQL Database
2. Enter server and database details
3. Select analytics views for analysis

## Maintenance

### Monitoring View Freshness

```sql
-- Check when materialized views were last refreshed
SELECT 
    schemaname,
    matviewname,
    pg_size_pretty(pg_relation_size(schemaname || '.' || matviewname)) AS size
FROM pg_matviews
WHERE schemaname = 'analytics';
```

### Rebuilding Views

If views become corrupted or need schema changes:

```sql
-- Drop and recreate
DROP MATERIALIZED VIEW IF EXISTS analytics.sales_summary CASCADE;
-- Then re-run the creation script
```

## Files

- `001-analytics-views.sql` - All analytics objects (materialized views, views, procedures)
- `README.md` - This documentation

## Related Documentation

- [SSAS README](../../wwi-ssasmd/README.md) - Original SSAS project documentation
- [ETL README](../../wwi-etl/README.md) - ETL process documentation
- [PostgreSQL DW Migration Guide](../README.md) - OLAP migration documentation
