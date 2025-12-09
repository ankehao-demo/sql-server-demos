-- PostgreSQL equivalent of [WebApi].UpdateStockItemFromJson
-- Converted from T-SQL to PL/pgSQL

CREATE OR REPLACE PROCEDURE webapi.update_stock_item_from_json(
    p_stock_item JSONB,
    p_stock_item_id INTEGER,
    p_user_id INTEGER
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    UPDATE warehouse.stock_items SET
        stock_item_name = COALESCE((p_stock_item->>'StockItemName')::VARCHAR(100), stock_item_name),
        supplier_id = COALESCE((p_stock_item->>'SupplierID')::INTEGER, supplier_id),
        color_id = (p_stock_item->>'ColorID')::INTEGER,
        unit_package_id = COALESCE((p_stock_item->>'UnitPackageID')::INTEGER, unit_package_id),
        outer_package_id = COALESCE((p_stock_item->>'OuterPackageID')::INTEGER, outer_package_id),
        brand = (p_stock_item->>'Brand')::VARCHAR(50),
        size = (p_stock_item->>'Size')::VARCHAR(20),
        lead_time_days = COALESCE((p_stock_item->>'LeadTimeDays')::INTEGER, lead_time_days),
        quantity_per_outer = COALESCE((p_stock_item->>'QuantityPerOuter')::INTEGER, quantity_per_outer),
        is_chiller_stock = COALESCE((p_stock_item->>'IsChillerStock')::BOOLEAN, is_chiller_stock),
        barcode = (p_stock_item->>'Barcode')::VARCHAR(50),
        tax_rate = COALESCE((p_stock_item->>'TaxRate')::DECIMAL(18,3), tax_rate),
        unit_price = COALESCE((p_stock_item->>'UnitPrice')::DECIMAL(18,2), unit_price),
        recommended_retail_price = (p_stock_item->>'RecommendedRetailPrice')::DECIMAL(18,2),
        typical_weight_per_unit = COALESCE((p_stock_item->>'TypicalWeightPerUnit')::DECIMAL(18,3), typical_weight_per_unit),
        marketing_comments = (p_stock_item->>'MarketingComments')::TEXT,
        internal_comments = (p_stock_item->>'InternalComments')::TEXT,
        photo = CASE WHEN p_stock_item->>'Photo' IS NOT NULL THEN decode((p_stock_item->>'Photo')::TEXT, 'base64') ELSE photo END,
        custom_fields = COALESCE((p_stock_item->'CustomFields')::JSONB, custom_fields),
        last_edited_by = p_user_id
    WHERE stock_item_id = p_stock_item_id;
END;
$$;

COMMENT ON PROCEDURE webapi.update_stock_item_from_json IS 'Updates a stock item from JSON';
