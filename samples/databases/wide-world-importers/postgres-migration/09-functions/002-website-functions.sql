-- Phase 3: OLTP Code Migration - Website Schema Functions
-- Converted from SQL Server T-SQL to PostgreSQL PL/pgSQL

-- =============================================
-- Function: Website.CalculateCustomerPrice
-- Description: Calculates the price for a customer based on special deals
-- =============================================
CREATE OR REPLACE FUNCTION website.calculate_customer_price(
    p_customer_id integer,
    p_stock_item_id integer,
    p_pricing_date date
)
RETURNS numeric(18,2)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_calculated_price numeric(18,2);
    v_unit_price numeric(18,2);
    v_lowest_unit_price numeric(18,2);
    v_highest_discount_amount numeric(18,2);
    v_highest_discount_percentage numeric(18,3);
    v_buying_group_id integer;
    v_customer_category_id integer;
    v_discounted_unit_price numeric(18,2);
BEGIN
    -- Get customer's buying group and category
    SELECT buyinggroupid, customercategoryid
    INTO v_buying_group_id, v_customer_category_id
    FROM sales.customers
    WHERE customerid = p_customer_id;
    
    -- Get the stock item's unit price
    SELECT unitprice
    INTO v_unit_price
    FROM warehouse.stockitems
    WHERE stockitemid = p_stock_item_id;
    
    v_calculated_price := v_unit_price;
    
    -- Find the lowest unit price from special deals
    SELECT MIN(sd.unitprice)
    INTO v_lowest_unit_price
    FROM sales.specialdeals AS sd
    WHERE ((sd.stockitemid = p_stock_item_id) OR (sd.stockitemid IS NULL))
    AND ((sd.customerid = p_customer_id) OR (sd.customerid IS NULL))
    AND ((sd.buyinggroupid = v_buying_group_id) OR (sd.buyinggroupid IS NULL))
    AND ((sd.customercategoryid = v_customer_category_id) OR (sd.customercategoryid IS NULL))
    AND ((sd.stockgroupid IS NULL) OR EXISTS (
        SELECT 1 FROM warehouse.stockitemstockgroups AS sisg
        WHERE sisg.stockitemid = p_stock_item_id
        AND sisg.stockgroupid = sd.stockgroupid
    ))
    AND sd.unitprice IS NOT NULL
    AND p_pricing_date BETWEEN sd.startdate AND sd.enddate;
    
    IF v_lowest_unit_price IS NOT NULL AND v_lowest_unit_price < v_unit_price THEN
        v_calculated_price := v_lowest_unit_price;
    END IF;
    
    -- Find the highest discount amount from special deals
    SELECT MAX(sd.discountamount)
    INTO v_highest_discount_amount
    FROM sales.specialdeals AS sd
    WHERE ((sd.stockitemid = p_stock_item_id) OR (sd.stockitemid IS NULL))
    AND ((sd.customerid = p_customer_id) OR (sd.customerid IS NULL))
    AND ((sd.buyinggroupid = v_buying_group_id) OR (sd.buyinggroupid IS NULL))
    AND ((sd.customercategoryid = v_customer_category_id) OR (sd.customercategoryid IS NULL))
    AND ((sd.stockgroupid IS NULL) OR EXISTS (
        SELECT 1 FROM warehouse.stockitemstockgroups AS sisg
        WHERE sisg.stockitemid = p_stock_item_id
        AND sisg.stockgroupid = sd.stockgroupid
    ))
    AND sd.discountamount IS NOT NULL
    AND p_pricing_date BETWEEN sd.startdate AND sd.enddate;
    
    IF v_highest_discount_amount IS NOT NULL AND (v_unit_price - v_highest_discount_amount) < v_calculated_price THEN
        v_calculated_price := v_unit_price - v_highest_discount_amount;
    END IF;
    
    -- Find the highest discount percentage from special deals
    SELECT MAX(sd.discountpercentage)
    INTO v_highest_discount_percentage
    FROM sales.specialdeals AS sd
    WHERE ((sd.stockitemid = p_stock_item_id) OR (sd.stockitemid IS NULL))
    AND ((sd.customerid = p_customer_id) OR (sd.customerid IS NULL))
    AND ((sd.buyinggroupid = v_buying_group_id) OR (sd.buyinggroupid IS NULL))
    AND ((sd.customercategoryid = v_customer_category_id) OR (sd.customercategoryid IS NULL))
    AND ((sd.stockgroupid IS NULL) OR EXISTS (
        SELECT 1 FROM warehouse.stockitemstockgroups AS sisg
        WHERE sisg.stockitemid = p_stock_item_id
        AND sisg.stockgroupid = sd.stockgroupid
    ))
    AND sd.discountpercentage IS NOT NULL
    AND p_pricing_date BETWEEN sd.startdate AND sd.enddate;
    
    IF v_highest_discount_percentage IS NOT NULL THEN
        v_discounted_unit_price := ROUND(v_unit_price * v_highest_discount_percentage / 100.0, 2);
        IF v_discounted_unit_price < v_calculated_price THEN
            v_calculated_price := v_discounted_unit_price;
        END IF;
    END IF;
    
    RETURN v_calculated_price;
END;
$$;

COMMENT ON FUNCTION website.calculate_customer_price(integer, integer, date) IS 
'Calculates the price for a customer based on special deals, discounts, and promotions';
