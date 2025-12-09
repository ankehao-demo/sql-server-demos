-- PostgreSQL equivalent of [Website].CalculateCustomerPrice
-- Converted from T-SQL to PL/pgSQL
-- This function calculates the price for a customer based on their buying group and special deals

CREATE OR REPLACE FUNCTION website.calculate_customer_price(
    p_customer_id INTEGER,
    p_stock_item_id INTEGER,
    p_pricing_date TIMESTAMP DEFAULT NOW()
)
RETURNS DECIMAL(18,2)
LANGUAGE plpgsql
STABLE
AS $$
DECLARE
    v_calculated_price DECIMAL(18,2);
    v_unit_price DECIMAL(18,2);
    v_lowest_unit_price DECIMAL(18,2);
    v_highest_discount_percentage DECIMAL(18,3);
    v_buying_group_id INTEGER;
    v_customer_category_id INTEGER;
BEGIN
    -- Get the standard unit price for the stock item
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
    
    -- Initialize with the standard price
    v_calculated_price := v_unit_price;
    v_lowest_unit_price := v_unit_price;
    v_highest_discount_percentage := 0;
    
    -- Check for special deals that apply to this customer
    -- Look for deals by stock item, buying group, or customer category
    SELECT 
        COALESCE(MIN(sd.unit_price), v_unit_price),
        COALESCE(MAX(sd.discount_percentage), 0)
    INTO v_lowest_unit_price, v_highest_discount_percentage
    FROM sales.special_deals sd
    WHERE (sd.stock_item_id = p_stock_item_id OR sd.stock_item_id IS NULL)
    AND (sd.customer_id = p_customer_id OR sd.customer_id IS NULL)
    AND (sd.buying_group_id = v_buying_group_id OR sd.buying_group_id IS NULL)
    AND (sd.customer_category_id = v_customer_category_id OR sd.customer_category_id IS NULL)
    AND p_pricing_date::DATE BETWEEN sd.start_date AND sd.end_date;
    
    -- Calculate the best price
    -- Either use the special deal unit price or apply the discount percentage
    IF v_lowest_unit_price < v_unit_price THEN
        v_calculated_price := v_lowest_unit_price;
    END IF;
    
    IF v_highest_discount_percentage > 0 THEN
        v_calculated_price := LEAST(
            v_calculated_price, 
            ROUND(v_unit_price * (1 - v_highest_discount_percentage / 100), 2)
        );
    END IF;
    
    RETURN v_calculated_price;
END;
$$;

COMMENT ON FUNCTION website.calculate_customer_price IS 'Calculates the price for a customer based on special deals and buying group discounts';
