-- PostgreSQL equivalent of [WebApi].SearchForStockItems
-- Converted from T-SQL to PL/pgSQL

CREATE OR REPLACE FUNCTION webapi.search_for_stock_items(
    p_name VARCHAR(100) DEFAULT NULL,
    p_tag VARCHAR(100) DEFAULT NULL,
    p_min_price DECIMAL(18,2) DEFAULT NULL,
    p_max_price DECIMAL(18,2) DEFAULT NULL,
    p_stock_group_id INTEGER DEFAULT NULL,
    p_maximum_rows_to_return INTEGER DEFAULT 100
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_result JSONB;
    v_items JSONB;
    v_tags JSONB;
BEGIN
    -- Get matching stock items
    SELECT COALESCE(jsonb_agg(item_row), '[]'::JSONB)
    INTO v_items
    FROM (
        SELECT jsonb_build_object(
            'StockItemID', si.stock_item_id,
            'StockItemName', si.stock_item_name,
            'Brand', si.brand,
            'ColorName', si.color_name,
            'UnitPrice', si.unit_price,
            'TaxRate', si.tax_rate,
            'Size', si.size,
            'MarketingComments', si.marketing_comments
        ) AS item_row
        FROM webapi.stock_items si
        WHERE (p_name IS NULL OR si.stock_item_name ILIKE '%' || p_name || '%')
        AND (p_min_price IS NULL OR si.unit_price > p_min_price)
        AND (p_max_price IS NULL OR si.unit_price < p_max_price)
        AND (p_tag IS NULL OR EXISTS (
            SELECT 1 FROM jsonb_array_elements_text(si.custom_fields->'Tags') AS tag
            WHERE tag = p_tag
        ))
        AND (p_stock_group_id IS NULL OR EXISTS (
            SELECT 1 FROM warehouse.stock_item_stock_groups sisg
            WHERE sisg.stock_item_id = si.stock_item_id
            AND sisg.stock_group_id = p_stock_group_id
        ))
        LIMIT p_maximum_rows_to_return
    ) sub;
    
    -- Get tag counts
    SELECT COALESCE(jsonb_agg(tag_row), '[]'::JSONB)
    INTO v_tags
    FROM (
        SELECT jsonb_build_object(
            'Tag', tag,
            'Items', COUNT(*)
        ) AS tag_row
        FROM webapi.stock_items si
        CROSS JOIN LATERAL jsonb_array_elements_text(si.custom_fields->'Tags') AS tag
        WHERE (p_name IS NULL OR si.stock_item_name ILIKE '%' || p_name || '%')
        AND (p_min_price IS NULL OR si.unit_price > p_min_price)
        AND (p_max_price IS NULL OR si.unit_price < p_max_price)
        GROUP BY tag
    ) sub;
    
    -- Build result
    v_result := jsonb_build_object(
        'value', v_items,
        'tags', v_tags
    );
    
    RETURN v_result;
END;
$$;

COMMENT ON FUNCTION webapi.search_for_stock_items IS 'Searches for stock items with optional filters and returns results as JSON';
