-- Wide World Importers DW PostgreSQL Migration
-- Phase 5: ETL and Analytics Migration
-- File: 001-analytics-views.sql
-- Description: PostgreSQL analytics solution replacing SQL Server Analysis Services (SSAS) cubes
-- This provides equivalent OLAP functionality using PostgreSQL materialized views and analytical functions

-- Create analytics schema for analytical objects
CREATE SCHEMA IF NOT EXISTS analytics;

-- =============================================
-- Sales Analytics Materialized View
-- Replaces SSAS Sales cube with pre-aggregated sales metrics
-- =============================================
CREATE MATERIALIZED VIEW analytics.sales_summary AS
SELECT 
    d.calendar_year,
    d.calendar_quarter_number,
    d.calendar_month_number,
    d.calendar_month_label,
    c.city,
    c.state_province,
    c.country,
    c.continent,
    c.sales_territory,
    cust.customer,
    cust.category AS customer_category,
    cust.buying_group,
    si.stock_item,
    si.color,
    si.brand,
    si.selling_package,
    e.employee AS salesperson,
    COUNT(*) AS transaction_count,
    SUM(s.quantity) AS total_quantity,
    SUM(s.total_excluding_tax) AS total_excluding_tax,
    SUM(s.tax_amount) AS total_tax,
    SUM(s.total_including_tax) AS total_including_tax,
    SUM(s.profit) AS total_profit,
    AVG(s.unit_price) AS avg_unit_price,
    SUM(s.total_dry_items) AS total_dry_items,
    SUM(s.total_chiller_items) AS total_chiller_items
FROM fact.sale s
JOIN dimension.date d ON s.invoice_date_key = d.date
JOIN dimension.city c ON s.city_key = c.city_key
JOIN dimension.customer cust ON s.customer_key = cust.customer_key
JOIN dimension.stock_item si ON s.stock_item_key = si.stock_item_key
JOIN dimension.employee e ON s.salesperson_key = e.employee_key
GROUP BY 
    d.calendar_year, d.calendar_quarter_number, d.calendar_month_number, d.calendar_month_label,
    c.city, c.state_province, c.country, c.continent, c.sales_territory,
    cust.customer, cust.category, cust.buying_group,
    si.stock_item, si.color, si.brand, si.selling_package,
    e.employee;

CREATE UNIQUE INDEX idx_sales_summary_pk ON analytics.sales_summary (
    calendar_year, calendar_month_number, city, customer, stock_item, salesperson
);

COMMENT ON MATERIALIZED VIEW analytics.sales_summary IS 
'Pre-aggregated sales metrics replacing SSAS Sales cube - refresh after ETL';

-- =============================================
-- Purchase Analytics Materialized View
-- Replaces SSAS Purchase cube with pre-aggregated purchase metrics
-- =============================================
CREATE MATERIALIZED VIEW analytics.purchase_summary AS
SELECT 
    d.calendar_year,
    d.calendar_quarter_number,
    d.calendar_month_number,
    d.calendar_month_label,
    sup.supplier,
    sup.category AS supplier_category,
    si.stock_item,
    si.color,
    si.brand,
    si.buying_package,
    COUNT(*) AS order_count,
    SUM(p.ordered_outers) AS total_ordered_outers,
    SUM(p.ordered_quantity) AS total_ordered_quantity,
    SUM(p.received_outers) AS total_received_outers,
    SUM(CASE WHEN p.is_order_finalized THEN 1 ELSE 0 END) AS finalized_orders,
    SUM(CASE WHEN NOT p.is_order_finalized THEN 1 ELSE 0 END) AS pending_orders
FROM fact.purchase p
JOIN dimension.date d ON p.date_key = d.date
JOIN dimension.supplier sup ON p.supplier_key = sup.supplier_key
JOIN dimension.stock_item si ON p.stock_item_key = si.stock_item_key
GROUP BY 
    d.calendar_year, d.calendar_quarter_number, d.calendar_month_number, d.calendar_month_label,
    sup.supplier, sup.category,
    si.stock_item, si.color, si.brand, si.buying_package;

CREATE UNIQUE INDEX idx_purchase_summary_pk ON analytics.purchase_summary (
    calendar_year, calendar_month_number, supplier, stock_item
);

COMMENT ON MATERIALIZED VIEW analytics.purchase_summary IS 
'Pre-aggregated purchase metrics replacing SSAS Purchase cube - refresh after ETL';

-- =============================================
-- Inventory Movement Analytics Materialized View
-- Replaces SSAS Movement cube with pre-aggregated movement metrics
-- =============================================
CREATE MATERIALIZED VIEW analytics.movement_summary AS
SELECT 
    d.calendar_year,
    d.calendar_quarter_number,
    d.calendar_month_number,
    d.calendar_month_label,
    si.stock_item,
    si.color,
    si.brand,
    tt.transaction_type,
    COALESCE(cust.customer, 'N/A') AS customer,
    COALESCE(sup.supplier, 'N/A') AS supplier,
    COUNT(*) AS movement_count,
    SUM(m.quantity) AS total_quantity,
    SUM(CASE WHEN m.quantity > 0 THEN m.quantity ELSE 0 END) AS quantity_in,
    SUM(CASE WHEN m.quantity < 0 THEN ABS(m.quantity) ELSE 0 END) AS quantity_out
FROM fact.movement m
JOIN dimension.date d ON m.date_key = d.date
JOIN dimension.stock_item si ON m.stock_item_key = si.stock_item_key
JOIN dimension.transaction_type tt ON m.transaction_type_key = tt.transaction_type_key
LEFT JOIN dimension.customer cust ON m.customer_key = cust.customer_key
LEFT JOIN dimension.supplier sup ON m.supplier_key = sup.supplier_key
GROUP BY 
    d.calendar_year, d.calendar_quarter_number, d.calendar_month_number, d.calendar_month_label,
    si.stock_item, si.color, si.brand,
    tt.transaction_type,
    cust.customer, sup.supplier;

CREATE UNIQUE INDEX idx_movement_summary_pk ON analytics.movement_summary (
    calendar_year, calendar_month_number, stock_item, transaction_type, customer, supplier
);

COMMENT ON MATERIALIZED VIEW analytics.movement_summary IS 
'Pre-aggregated inventory movement metrics replacing SSAS Movement cube - refresh after ETL';

-- =============================================
-- Transaction Analytics Materialized View
-- Replaces SSAS Transaction cube with pre-aggregated transaction metrics
-- =============================================
CREATE MATERIALIZED VIEW analytics.transaction_summary AS
SELECT 
    d.calendar_year,
    d.calendar_quarter_number,
    d.calendar_month_number,
    d.calendar_month_label,
    COALESCE(cust.customer, 'N/A') AS customer,
    COALESCE(cust.category, 'N/A') AS customer_category,
    COALESCE(sup.supplier, 'N/A') AS supplier,
    COALESCE(sup.category, 'N/A') AS supplier_category,
    tt.transaction_type,
    COALESCE(pm.payment_method, 'N/A') AS payment_method,
    COUNT(*) AS transaction_count,
    SUM(t.total_excluding_tax) AS total_excluding_tax,
    SUM(t.tax_amount) AS total_tax,
    SUM(t.total_including_tax) AS total_including_tax,
    SUM(t.outstanding_balance) AS total_outstanding,
    SUM(CASE WHEN t.is_finalized THEN 1 ELSE 0 END) AS finalized_count,
    SUM(CASE WHEN NOT t.is_finalized THEN 1 ELSE 0 END) AS pending_count
FROM fact.transaction t
JOIN dimension.date d ON t.date_key = d.date
JOIN dimension.transaction_type tt ON t.transaction_type_key = tt.transaction_type_key
LEFT JOIN dimension.customer cust ON t.customer_key = cust.customer_key
LEFT JOIN dimension.supplier sup ON t.supplier_key = sup.supplier_key
LEFT JOIN dimension.payment_method pm ON t.payment_method_key = pm.payment_method_key
GROUP BY 
    d.calendar_year, d.calendar_quarter_number, d.calendar_month_number, d.calendar_month_label,
    cust.customer, cust.category,
    sup.supplier, sup.category,
    tt.transaction_type, pm.payment_method;

CREATE UNIQUE INDEX idx_transaction_summary_pk ON analytics.transaction_summary (
    calendar_year, calendar_month_number, customer, supplier, transaction_type, payment_method
);

COMMENT ON MATERIALIZED VIEW analytics.transaction_summary IS 
'Pre-aggregated transaction metrics replacing SSAS Transaction cube - refresh after ETL';

-- =============================================
-- Stock Holding Analytics View
-- Current inventory snapshot with analytics
-- =============================================
CREATE OR REPLACE VIEW analytics.stock_holding_current AS
SELECT 
    si.stock_item,
    si.color,
    si.brand,
    si.selling_package,
    si.buying_package,
    si.is_chiller_stock,
    sh.quantity_on_hand,
    sh.bin_location,
    sh.last_stocktake_quantity,
    sh.last_cost_price,
    sh.reorder_level,
    sh.target_stock_level,
    CASE 
        WHEN sh.quantity_on_hand <= sh.reorder_level THEN 'Reorder Required'
        WHEN sh.quantity_on_hand < sh.target_stock_level THEN 'Below Target'
        ELSE 'Adequate'
    END AS stock_status,
    sh.target_stock_level - sh.quantity_on_hand AS quantity_to_target,
    sh.quantity_on_hand * sh.last_cost_price AS inventory_value
FROM fact.stock_holding sh
JOIN dimension.stock_item si ON sh.stock_item_key = si.stock_item_key
WHERE si.valid_to = '9999-12-31 23:59:59.999999'::timestamp;

COMMENT ON VIEW analytics.stock_holding_current IS 
'Current inventory status with stock level analysis';

-- =============================================
-- Sales Year-over-Year Comparison View
-- =============================================
CREATE OR REPLACE VIEW analytics.sales_yoy_comparison AS
WITH yearly_sales AS (
    SELECT 
        calendar_year,
        calendar_month_number,
        SUM(total_including_tax) AS monthly_revenue,
        SUM(total_profit) AS monthly_profit,
        SUM(total_quantity) AS monthly_quantity
    FROM analytics.sales_summary
    GROUP BY calendar_year, calendar_month_number
)
SELECT 
    curr.calendar_year,
    curr.calendar_month_number,
    curr.monthly_revenue AS current_revenue,
    prev.monthly_revenue AS previous_year_revenue,
    curr.monthly_revenue - COALESCE(prev.monthly_revenue, 0) AS revenue_change,
    CASE 
        WHEN prev.monthly_revenue > 0 
        THEN ((curr.monthly_revenue - prev.monthly_revenue) / prev.monthly_revenue * 100)
        ELSE NULL 
    END AS revenue_change_pct,
    curr.monthly_profit AS current_profit,
    prev.monthly_profit AS previous_year_profit,
    curr.monthly_quantity AS current_quantity,
    prev.monthly_quantity AS previous_year_quantity
FROM yearly_sales curr
LEFT JOIN yearly_sales prev 
    ON curr.calendar_year = prev.calendar_year + 1 
    AND curr.calendar_month_number = prev.calendar_month_number
ORDER BY curr.calendar_year, curr.calendar_month_number;

COMMENT ON VIEW analytics.sales_yoy_comparison IS 
'Year-over-year sales comparison for trend analysis';

-- =============================================
-- Top Products Analysis View
-- =============================================
CREATE OR REPLACE VIEW analytics.top_products AS
SELECT 
    stock_item,
    color,
    brand,
    SUM(total_quantity) AS total_quantity_sold,
    SUM(total_including_tax) AS total_revenue,
    SUM(total_profit) AS total_profit,
    RANK() OVER (ORDER BY SUM(total_including_tax) DESC) AS revenue_rank,
    RANK() OVER (ORDER BY SUM(total_quantity) DESC) AS quantity_rank,
    RANK() OVER (ORDER BY SUM(total_profit) DESC) AS profit_rank
FROM analytics.sales_summary
GROUP BY stock_item, color, brand;

COMMENT ON VIEW analytics.top_products IS 
'Product performance ranking by revenue, quantity, and profit';

-- =============================================
-- Customer Analysis View
-- =============================================
CREATE OR REPLACE VIEW analytics.customer_analysis AS
SELECT 
    customer,
    customer_category,
    buying_group,
    COUNT(DISTINCT calendar_year || '-' || calendar_month_number) AS active_months,
    SUM(total_quantity) AS total_quantity_purchased,
    SUM(total_including_tax) AS total_revenue,
    SUM(total_profit) AS total_profit,
    AVG(total_including_tax) AS avg_monthly_revenue,
    RANK() OVER (ORDER BY SUM(total_including_tax) DESC) AS revenue_rank
FROM analytics.sales_summary
GROUP BY customer, customer_category, buying_group;

COMMENT ON VIEW analytics.customer_analysis IS 
'Customer performance analysis with ranking';

-- =============================================
-- Geographic Sales Analysis View
-- =============================================
CREATE OR REPLACE VIEW analytics.geographic_sales AS
SELECT 
    continent,
    country,
    state_province,
    sales_territory,
    city,
    SUM(total_quantity) AS total_quantity,
    SUM(total_including_tax) AS total_revenue,
    SUM(total_profit) AS total_profit,
    COUNT(DISTINCT customer) AS unique_customers,
    AVG(total_including_tax) AS avg_transaction_value
FROM analytics.sales_summary
GROUP BY continent, country, state_province, sales_territory, city;

COMMENT ON VIEW analytics.geographic_sales IS 
'Geographic breakdown of sales performance';

-- =============================================
-- Procedure to refresh all analytics materialized views
-- =============================================
CREATE OR REPLACE PROCEDURE analytics.refresh_all_views()
LANGUAGE plpgsql
AS $$
BEGIN
    RAISE NOTICE 'Refreshing analytics.sales_summary...';
    REFRESH MATERIALIZED VIEW CONCURRENTLY analytics.sales_summary;
    
    RAISE NOTICE 'Refreshing analytics.purchase_summary...';
    REFRESH MATERIALIZED VIEW CONCURRENTLY analytics.purchase_summary;
    
    RAISE NOTICE 'Refreshing analytics.movement_summary...';
    REFRESH MATERIALIZED VIEW CONCURRENTLY analytics.movement_summary;
    
    RAISE NOTICE 'Refreshing analytics.transaction_summary...';
    REFRESH MATERIALIZED VIEW CONCURRENTLY analytics.transaction_summary;
    
    RAISE NOTICE 'All analytics views refreshed successfully.';
END;
$$;

COMMENT ON PROCEDURE analytics.refresh_all_views() IS 
'Refreshes all analytics materialized views - call after ETL completion';
