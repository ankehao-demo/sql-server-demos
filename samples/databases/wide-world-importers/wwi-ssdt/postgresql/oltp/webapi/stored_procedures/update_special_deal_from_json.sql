-- PostgreSQL equivalent of [WebApi].UpdateSpecialDealFromJson
-- Converted from T-SQL to PL/pgSQL

CREATE OR REPLACE PROCEDURE webapi.update_special_deal_from_json(
    p_special_deal JSONB,
    p_special_deal_id INTEGER,
    p_user_id INTEGER
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    UPDATE sales.special_deals SET
        stock_item_id = (p_special_deal->>'StockItemID')::INTEGER,
        customer_id = (p_special_deal->>'CustomerID')::INTEGER,
        buying_group_id = (p_special_deal->>'BuyingGroupID')::INTEGER,
        customer_category_id = (p_special_deal->>'CustomerCategoryID')::INTEGER,
        stock_group_id = (p_special_deal->>'StockGroupID')::INTEGER,
        deal_description = COALESCE((p_special_deal->>'DealDescription')::VARCHAR(30), deal_description),
        start_date = COALESCE((p_special_deal->>'StartDate')::DATE, start_date),
        end_date = COALESCE((p_special_deal->>'EndDate')::DATE, end_date),
        discount_amount = (p_special_deal->>'DiscountAmount')::DECIMAL(18,2),
        discount_percentage = (p_special_deal->>'DiscountPercentage')::DECIMAL(18,3),
        unit_price = (p_special_deal->>'UnitPrice')::DECIMAL(18,2),
        last_edited_by = p_user_id
    WHERE special_deal_id = p_special_deal_id;
END;
$$;

COMMENT ON PROCEDURE webapi.update_special_deal_from_json IS 'Updates a special deal from JSON';
