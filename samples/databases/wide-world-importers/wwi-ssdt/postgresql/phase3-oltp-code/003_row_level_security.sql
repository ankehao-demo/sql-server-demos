-- Wide World Importers PostgreSQL Migration
-- Phase 3: OLTP Code Migration
-- Script 003: Row-Level Security Implementation
-- Migrated from SQL Server RLS to PostgreSQL RLS

-- =============================================
-- Create Roles for Sales Territories
-- =============================================

-- Create roles for each sales territory
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'great_lakes_sales') THEN
        CREATE ROLE great_lakes_sales;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'plains_sales') THEN
        CREATE ROLE plains_sales;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'far_west_sales') THEN
        CREATE ROLE far_west_sales;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'new_england_sales') THEN
        CREATE ROLE new_england_sales;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'mideast_sales') THEN
        CREATE ROLE mideast_sales;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'southeast_sales') THEN
        CREATE ROLE southeast_sales;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'southwest_sales') THEN
        CREATE ROLE southwest_sales;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'rocky_mountain_sales') THEN
        CREATE ROLE rocky_mountain_sales;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'external_sales') THEN
        CREATE ROLE external_sales;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'all_territories') THEN
        CREATE ROLE all_territories;
    END IF;
END $$;

-- =============================================
-- Helper Function to Check Territory Access
-- =============================================

CREATE OR REPLACE FUNCTION application.check_territory_access(p_delivery_city_id INTEGER)
RETURNS BOOLEAN AS $$
DECLARE
    v_sales_territory VARCHAR(50);
    v_current_user VARCHAR(256);
BEGIN
    -- Get the sales territory for the city
    SELECT sp.sales_territory INTO v_sales_territory
    FROM application.cities c
    INNER JOIN application.state_provinces sp ON c.state_province_id = sp.state_province_id
    WHERE c.city_id = p_delivery_city_id;
    
    -- If no territory found, deny access
    IF v_sales_territory IS NULL THEN
        RETURN FALSE;
    END IF;
    
    -- Get current user
    v_current_user := current_user;
    
    -- Check if user has all_territories role
    IF pg_has_role(v_current_user, 'all_territories', 'member') THEN
        RETURN TRUE;
    END IF;
    
    -- Check territory-specific access
    RETURN CASE v_sales_territory
        WHEN 'Great Lakes' THEN pg_has_role(v_current_user, 'great_lakes_sales', 'member')
        WHEN 'Plains' THEN pg_has_role(v_current_user, 'plains_sales', 'member')
        WHEN 'Far West' THEN pg_has_role(v_current_user, 'far_west_sales', 'member')
        WHEN 'New England' THEN pg_has_role(v_current_user, 'new_england_sales', 'member')
        WHEN 'Mideast' THEN pg_has_role(v_current_user, 'mideast_sales', 'member')
        WHEN 'Southeast' THEN pg_has_role(v_current_user, 'southeast_sales', 'member')
        WHEN 'Southwest' THEN pg_has_role(v_current_user, 'southwest_sales', 'member')
        WHEN 'Rocky Mountain' THEN pg_has_role(v_current_user, 'rocky_mountain_sales', 'member')
        WHEN 'External' THEN pg_has_role(v_current_user, 'external_sales', 'member')
        ELSE FALSE
    END;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

COMMENT ON FUNCTION application.check_territory_access(INTEGER) IS 
'Checks if the current user has access to a specific sales territory based on delivery city';

-- =============================================
-- Row-Level Security Policies for Sales.Customers
-- =============================================

-- Enable RLS on customers table
ALTER TABLE sales.customers ENABLE ROW LEVEL SECURITY;

-- Create policy for customers based on delivery city territory
CREATE POLICY customers_territory_policy ON sales.customers
    FOR ALL
    USING (application.check_territory_access(delivery_city_id));

-- Allow superusers and db_owner to bypass RLS
ALTER TABLE sales.customers FORCE ROW LEVEL SECURITY;

-- =============================================
-- Row-Level Security Policies for Sales.Orders
-- =============================================

-- Enable RLS on orders table
ALTER TABLE sales.orders ENABLE ROW LEVEL SECURITY;

-- Create policy for orders based on customer's delivery city territory
CREATE POLICY orders_territory_policy ON sales.orders
    FOR ALL
    USING (
        EXISTS (
            SELECT 1 FROM sales.customers c
            WHERE c.customer_id = sales.orders.customer_id
            AND application.check_territory_access(c.delivery_city_id)
        )
    );

ALTER TABLE sales.orders FORCE ROW LEVEL SECURITY;

-- =============================================
-- Row-Level Security Policies for Sales.OrderLines
-- =============================================

-- Enable RLS on order_lines table
ALTER TABLE sales.order_lines ENABLE ROW LEVEL SECURITY;

-- Create policy for order_lines based on order's customer territory
CREATE POLICY order_lines_territory_policy ON sales.order_lines
    FOR ALL
    USING (
        EXISTS (
            SELECT 1 FROM sales.orders o
            INNER JOIN sales.customers c ON o.customer_id = c.customer_id
            WHERE o.order_id = sales.order_lines.order_id
            AND application.check_territory_access(c.delivery_city_id)
        )
    );

ALTER TABLE sales.order_lines FORCE ROW LEVEL SECURITY;

-- =============================================
-- Row-Level Security Policies for Sales.Invoices
-- =============================================

-- Enable RLS on invoices table
ALTER TABLE sales.invoices ENABLE ROW LEVEL SECURITY;

-- Create policy for invoices based on customer's delivery city territory
CREATE POLICY invoices_territory_policy ON sales.invoices
    FOR ALL
    USING (
        EXISTS (
            SELECT 1 FROM sales.customers c
            WHERE c.customer_id = sales.invoices.customer_id
            AND application.check_territory_access(c.delivery_city_id)
        )
    );

ALTER TABLE sales.invoices FORCE ROW LEVEL SECURITY;

-- =============================================
-- Row-Level Security Policies for Sales.InvoiceLines
-- =============================================

-- Enable RLS on invoice_lines table
ALTER TABLE sales.invoice_lines ENABLE ROW LEVEL SECURITY;

-- Create policy for invoice_lines based on invoice's customer territory
CREATE POLICY invoice_lines_territory_policy ON sales.invoice_lines
    FOR ALL
    USING (
        EXISTS (
            SELECT 1 FROM sales.invoices i
            INNER JOIN sales.customers c ON i.customer_id = c.customer_id
            WHERE i.invoice_id = sales.invoice_lines.invoice_id
            AND application.check_territory_access(c.delivery_city_id)
        )
    );

ALTER TABLE sales.invoice_lines FORCE ROW LEVEL SECURITY;

-- =============================================
-- Row-Level Security Policies for Sales.CustomerTransactions
-- =============================================

-- Enable RLS on customer_transactions table
ALTER TABLE sales.customer_transactions ENABLE ROW LEVEL SECURITY;

-- Create policy for customer_transactions based on customer's delivery city territory
CREATE POLICY customer_transactions_territory_policy ON sales.customer_transactions
    FOR ALL
    USING (
        EXISTS (
            SELECT 1 FROM sales.customers c
            WHERE c.customer_id = sales.customer_transactions.customer_id
            AND application.check_territory_access(c.delivery_city_id)
        )
    );

ALTER TABLE sales.customer_transactions FORCE ROW LEVEL SECURITY;

-- =============================================
-- Procedure to Apply Row-Level Security
-- (Equivalent to Application.Configuration_ApplyRowLevelSecurity)
-- =============================================

CREATE OR REPLACE PROCEDURE application.configuration_apply_row_level_security()
LANGUAGE plpgsql AS $$
BEGIN
    -- Enable RLS on all relevant tables
    ALTER TABLE sales.customers ENABLE ROW LEVEL SECURITY;
    ALTER TABLE sales.orders ENABLE ROW LEVEL SECURITY;
    ALTER TABLE sales.order_lines ENABLE ROW LEVEL SECURITY;
    ALTER TABLE sales.invoices ENABLE ROW LEVEL SECURITY;
    ALTER TABLE sales.invoice_lines ENABLE ROW LEVEL SECURITY;
    ALTER TABLE sales.customer_transactions ENABLE ROW LEVEL SECURITY;
    
    -- Force RLS for table owners as well
    ALTER TABLE sales.customers FORCE ROW LEVEL SECURITY;
    ALTER TABLE sales.orders FORCE ROW LEVEL SECURITY;
    ALTER TABLE sales.order_lines FORCE ROW LEVEL SECURITY;
    ALTER TABLE sales.invoices FORCE ROW LEVEL SECURITY;
    ALTER TABLE sales.invoice_lines FORCE ROW LEVEL SECURITY;
    ALTER TABLE sales.customer_transactions FORCE ROW LEVEL SECURITY;
    
    RAISE NOTICE 'Row-level security has been applied to sales tables';
END;
$$;

COMMENT ON PROCEDURE application.configuration_apply_row_level_security() IS 
'Applies row-level security to sales tables based on sales territory';

-- =============================================
-- Procedure to Remove Row-Level Security
-- (Equivalent to Application.Configuration_RemoveRowLevelSecurity)
-- =============================================

CREATE OR REPLACE PROCEDURE application.configuration_remove_row_level_security()
LANGUAGE plpgsql AS $$
BEGIN
    -- Disable RLS on all relevant tables
    ALTER TABLE sales.customers DISABLE ROW LEVEL SECURITY;
    ALTER TABLE sales.orders DISABLE ROW LEVEL SECURITY;
    ALTER TABLE sales.order_lines DISABLE ROW LEVEL SECURITY;
    ALTER TABLE sales.invoices DISABLE ROW LEVEL SECURITY;
    ALTER TABLE sales.invoice_lines DISABLE ROW LEVEL SECURITY;
    ALTER TABLE sales.customer_transactions DISABLE ROW LEVEL SECURITY;
    
    -- Remove force RLS
    ALTER TABLE sales.customers NO FORCE ROW LEVEL SECURITY;
    ALTER TABLE sales.orders NO FORCE ROW LEVEL SECURITY;
    ALTER TABLE sales.order_lines NO FORCE ROW LEVEL SECURITY;
    ALTER TABLE sales.invoices NO FORCE ROW LEVEL SECURITY;
    ALTER TABLE sales.invoice_lines NO FORCE ROW LEVEL SECURITY;
    ALTER TABLE sales.customer_transactions NO FORCE ROW LEVEL SECURITY;
    
    RAISE NOTICE 'Row-level security has been removed from sales tables';
END;
$$;

COMMENT ON PROCEDURE application.configuration_remove_row_level_security() IS 
'Removes row-level security from sales tables';

-- =============================================
-- Grant Permissions to Roles
-- =============================================

-- Grant SELECT on sales tables to all sales roles
GRANT SELECT ON sales.customers TO great_lakes_sales, plains_sales, far_west_sales, 
    new_england_sales, mideast_sales, southeast_sales, southwest_sales, 
    rocky_mountain_sales, external_sales, all_territories;

GRANT SELECT ON sales.orders TO great_lakes_sales, plains_sales, far_west_sales, 
    new_england_sales, mideast_sales, southeast_sales, southwest_sales, 
    rocky_mountain_sales, external_sales, all_territories;

GRANT SELECT ON sales.order_lines TO great_lakes_sales, plains_sales, far_west_sales, 
    new_england_sales, mideast_sales, southeast_sales, southwest_sales, 
    rocky_mountain_sales, external_sales, all_territories;

GRANT SELECT ON sales.invoices TO great_lakes_sales, plains_sales, far_west_sales, 
    new_england_sales, mideast_sales, southeast_sales, southwest_sales, 
    rocky_mountain_sales, external_sales, all_territories;

GRANT SELECT ON sales.invoice_lines TO great_lakes_sales, plains_sales, far_west_sales, 
    new_england_sales, mideast_sales, southeast_sales, southwest_sales, 
    rocky_mountain_sales, external_sales, all_territories;

GRANT SELECT ON sales.customer_transactions TO great_lakes_sales, plains_sales, far_west_sales, 
    new_england_sales, mideast_sales, southeast_sales, southwest_sales, 
    rocky_mountain_sales, external_sales, all_territories;

-- Grant INSERT, UPDATE, DELETE to all_territories role
GRANT INSERT, UPDATE, DELETE ON sales.customers TO all_territories;
GRANT INSERT, UPDATE, DELETE ON sales.orders TO all_territories;
GRANT INSERT, UPDATE, DELETE ON sales.order_lines TO all_territories;
GRANT INSERT, UPDATE, DELETE ON sales.invoices TO all_territories;
GRANT INSERT, UPDATE, DELETE ON sales.invoice_lines TO all_territories;
GRANT INSERT, UPDATE, DELETE ON sales.customer_transactions TO all_territories;

-- Grant usage on sequences
GRANT USAGE ON ALL SEQUENCES IN SCHEMA sequences TO great_lakes_sales, plains_sales, far_west_sales, 
    new_england_sales, mideast_sales, southeast_sales, southwest_sales, 
    rocky_mountain_sales, external_sales, all_territories;

-- Grant execute on functions
GRANT EXECUTE ON FUNCTION application.check_territory_access(INTEGER) TO PUBLIC;
GRANT EXECUTE ON FUNCTION website.calculate_customer_price(INTEGER, INTEGER, DATE) TO PUBLIC;
