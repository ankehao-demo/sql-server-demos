-- Wide World Importers PostgreSQL Migration
-- Phase 3: OLTP Code Migration
-- Script 001: Website Functions
-- Migrated from SQL Server T-SQL to PostgreSQL PL/pgSQL

-- =============================================
-- Website.CalculateCustomerPrice Function
-- Calculates the price for a customer based on special deals
-- =============================================
CREATE OR REPLACE FUNCTION website.calculate_customer_price(
    p_customer_id INTEGER,
    p_stock_item_id INTEGER,
    p_pricing_date DATE
)
RETURNS NUMERIC(18, 2) AS $$
DECLARE
    v_calculated_price NUMERIC(18, 2);
    v_unit_price NUMERIC(18, 2);
    v_lowest_unit_price NUMERIC(18, 2);
    v_highest_discount_amount NUMERIC(18, 2);
    v_highest_discount_percentage NUMERIC(18, 3);
    v_buying_group_id INTEGER;
    v_customer_category_id INTEGER;
BEGIN
    -- Get the base unit price for the stock item
    SELECT unit_price INTO v_unit_price
    FROM warehouse.stock_items
    WHERE stock_item_id = p_stock_item_id;
    
    IF v_unit_price IS NULL THEN
        RETURN NULL;
    END IF;
    
    -- Get customer's buying group and category
    SELECT buying_group_id, customer_category_id
    INTO v_buying_group_id, v_customer_category_id
    FROM sales.customers
    WHERE customer_id = p_customer_id;
    
    -- Find the lowest unit price from special deals
    SELECT MIN(sd.unit_price) INTO v_lowest_unit_price
    FROM sales.special_deals sd
    WHERE sd.start_date <= p_pricing_date
      AND sd.end_date >= p_pricing_date
      AND sd.unit_price IS NOT NULL
      AND (sd.stock_item_id IS NULL OR sd.stock_item_id = p_stock_item_id)
      AND (sd.customer_id IS NULL OR sd.customer_id = p_customer_id)
      AND (sd.buying_group_id IS NULL OR sd.buying_group_id = v_buying_group_id)
      AND (sd.customer_category_id IS NULL OR sd.customer_category_id = v_customer_category_id);
    
    -- Find the highest discount amount from special deals
    SELECT MAX(sd.discount_amount) INTO v_highest_discount_amount
    FROM sales.special_deals sd
    WHERE sd.start_date <= p_pricing_date
      AND sd.end_date >= p_pricing_date
      AND sd.discount_amount IS NOT NULL
      AND (sd.stock_item_id IS NULL OR sd.stock_item_id = p_stock_item_id)
      AND (sd.customer_id IS NULL OR sd.customer_id = p_customer_id)
      AND (sd.buying_group_id IS NULL OR sd.buying_group_id = v_buying_group_id)
      AND (sd.customer_category_id IS NULL OR sd.customer_category_id = v_customer_category_id);
    
    -- Find the highest discount percentage from special deals
    SELECT MAX(sd.discount_percentage) INTO v_highest_discount_percentage
    FROM sales.special_deals sd
    WHERE sd.start_date <= p_pricing_date
      AND sd.end_date >= p_pricing_date
      AND sd.discount_percentage IS NOT NULL
      AND (sd.stock_item_id IS NULL OR sd.stock_item_id = p_stock_item_id)
      AND (sd.customer_id IS NULL OR sd.customer_id = p_customer_id)
      AND (sd.buying_group_id IS NULL OR sd.buying_group_id = v_buying_group_id)
      AND (sd.customer_category_id IS NULL OR sd.customer_category_id = v_customer_category_id);
    
    -- Calculate the best price
    v_calculated_price := v_unit_price;
    
    IF v_lowest_unit_price IS NOT NULL AND v_lowest_unit_price < v_calculated_price THEN
        v_calculated_price := v_lowest_unit_price;
    END IF;
    
    IF v_highest_discount_amount IS NOT NULL AND (v_unit_price - v_highest_discount_amount) < v_calculated_price THEN
        v_calculated_price := v_unit_price - v_highest_discount_amount;
    END IF;
    
    IF v_highest_discount_percentage IS NOT NULL AND (v_unit_price * (1 - v_highest_discount_percentage / 100)) < v_calculated_price THEN
        v_calculated_price := v_unit_price * (1 - v_highest_discount_percentage / 100);
    END IF;
    
    -- Ensure price is not negative
    IF v_calculated_price < 0 THEN
        v_calculated_price := 0;
    END IF;
    
    RETURN ROUND(v_calculated_price, 2);
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION website.calculate_customer_price(INTEGER, INTEGER, DATE) IS 
'Calculates the best price for a customer based on applicable special deals';

-- =============================================
-- Application.DetermineCustomerAccess Function
-- Determines if a user has access to a customer based on sales territory
-- =============================================
CREATE OR REPLACE FUNCTION application.determine_customer_access(
    p_city_id INTEGER
)
RETURNS TABLE (access_result INTEGER) AS $$
DECLARE
    v_sales_territory VARCHAR(50);
    v_current_user VARCHAR(256);
BEGIN
    -- Get the sales territory for the city
    SELECT sp.sales_territory INTO v_sales_territory
    FROM application.cities c
    INNER JOIN application.state_provinces sp ON c.state_province_id = sp.state_province_id
    WHERE c.city_id = p_city_id;
    
    -- Get current user
    v_current_user := current_user;
    
    -- Check if user has access to this territory
    -- This is a simplified version - in production, you would check against role membership
    IF v_sales_territory IS NULL THEN
        RETURN QUERY SELECT 0;
    ELSIF EXISTS (
        SELECT 1 FROM pg_roles 
        WHERE rolname = v_current_user 
        AND (
            pg_has_role(v_current_user, 'db_owner', 'member') OR
            pg_has_role(v_current_user, v_sales_territory || ' Sales', 'member')
        )
    ) THEN
        RETURN QUERY SELECT 1;
    ELSE
        RETURN QUERY SELECT 0;
    END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

COMMENT ON FUNCTION application.determine_customer_access(INTEGER) IS 
'Determines if the current user has access to customers in a specific city based on sales territory';

-- =============================================
-- DataLoadSimulation.GetAreaCode Function
-- Returns the area code for a state province
-- =============================================
CREATE OR REPLACE FUNCTION dataload_simulation.get_area_code(
    p_state_province_id INTEGER
)
RETURNS VARCHAR(3) AS $$
DECLARE
    v_state_province_code VARCHAR(5);
    v_area_code VARCHAR(3);
BEGIN
    -- Get the state province code
    SELECT state_province_code INTO v_state_province_code
    FROM application.state_provinces
    WHERE state_province_id = p_state_province_id;
    
    -- Map state codes to area codes (simplified mapping)
    v_area_code := CASE v_state_province_code
        WHEN 'AL' THEN '205'
        WHEN 'AK' THEN '907'
        WHEN 'AZ' THEN '480'
        WHEN 'AR' THEN '501'
        WHEN 'CA' THEN '213'
        WHEN 'CO' THEN '303'
        WHEN 'CT' THEN '203'
        WHEN 'DE' THEN '302'
        WHEN 'FL' THEN '305'
        WHEN 'GA' THEN '404'
        WHEN 'HI' THEN '808'
        WHEN 'ID' THEN '208'
        WHEN 'IL' THEN '312'
        WHEN 'IN' THEN '317'
        WHEN 'IA' THEN '515'
        WHEN 'KS' THEN '316'
        WHEN 'KY' THEN '502'
        WHEN 'LA' THEN '504'
        WHEN 'ME' THEN '207'
        WHEN 'MD' THEN '301'
        WHEN 'MA' THEN '617'
        WHEN 'MI' THEN '313'
        WHEN 'MN' THEN '612'
        WHEN 'MS' THEN '601'
        WHEN 'MO' THEN '314'
        WHEN 'MT' THEN '406'
        WHEN 'NE' THEN '402'
        WHEN 'NV' THEN '702'
        WHEN 'NH' THEN '603'
        WHEN 'NJ' THEN '201'
        WHEN 'NM' THEN '505'
        WHEN 'NY' THEN '212'
        WHEN 'NC' THEN '704'
        WHEN 'ND' THEN '701'
        WHEN 'OH' THEN '216'
        WHEN 'OK' THEN '405'
        WHEN 'OR' THEN '503'
        WHEN 'PA' THEN '215'
        WHEN 'RI' THEN '401'
        WHEN 'SC' THEN '803'
        WHEN 'SD' THEN '605'
        WHEN 'TN' THEN '615'
        WHEN 'TX' THEN '214'
        WHEN 'UT' THEN '801'
        WHEN 'VT' THEN '802'
        WHEN 'VA' THEN '703'
        WHEN 'WA' THEN '206'
        WHEN 'WV' THEN '304'
        WHEN 'WI' THEN '414'
        WHEN 'WY' THEN '307'
        WHEN 'DC' THEN '202'
        ELSE '555'
    END;
    
    RETURN v_area_code;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION dataload_simulation.get_area_code(INTEGER) IS 
'Returns the area code for a given state province';
