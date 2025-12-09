-- PostgreSQL equivalent of [WebApi].InsertStockItemsFromJson
-- Converted from T-SQL to PL/pgSQL

CREATE OR REPLACE FUNCTION webapi.insert_stock_items_from_json(
    p_stock_items JSONB,
    p_user_id INTEGER
)
RETURNS TABLE (stock_item_id INTEGER)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    RETURN QUERY
    INSERT INTO warehouse.stock_items(
        stock_item_name, supplier_id, color_id, unit_package_id, outer_package_id,
        brand, size, lead_time_days, quantity_per_outer, is_chiller_stock,
        barcode, tax_rate, unit_price, recommended_retail_price, typical_weight_per_unit,
        marketing_comments, internal_comments, photo, custom_fields, last_edited_by
    )
    SELECT 
        (item->>'StockItemName')::VARCHAR(100),
        (item->>'SupplierID')::INTEGER,
        (item->>'ColorID')::INTEGER,
        (item->>'UnitPackageID')::INTEGER,
        (item->>'OuterPackageID')::INTEGER,
        (item->>'Brand')::VARCHAR(50),
        (item->>'Size')::VARCHAR(20),
        (item->>'LeadTimeDays')::INTEGER,
        (item->>'QuantityPerOuter')::INTEGER,
        (item->>'IsChillerStock')::BOOLEAN,
        (item->>'Barcode')::VARCHAR(50),
        (item->>'TaxRate')::DECIMAL(18,3),
        (item->>'UnitPrice')::DECIMAL(18,2),
        (item->>'RecommendedRetailPrice')::DECIMAL(18,2),
        (item->>'TypicalWeightPerUnit')::DECIMAL(18,3),
        (item->>'MarketingComments')::TEXT,
        (item->>'InternalComments')::TEXT,
        decode((item->>'Photo')::TEXT, 'base64'),
        (item->'CustomFields')::JSONB,
        p_user_id
    FROM jsonb_array_elements(p_stock_items) AS item
    RETURNING warehouse.stock_items.stock_item_id;
END;
$$;

COMMENT ON FUNCTION webapi.insert_stock_items_from_json IS 'Inserts stock items from JSON array and returns inserted IDs';
