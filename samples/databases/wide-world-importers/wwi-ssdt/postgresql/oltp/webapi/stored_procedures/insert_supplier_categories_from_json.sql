-- PostgreSQL equivalent of [WebApi].InsertSupplierCategoriesFromJson
-- Converted from T-SQL to PL/pgSQL

CREATE OR REPLACE FUNCTION webapi.insert_supplier_categories_from_json(
    p_supplier_categories JSONB,
    p_user_id INTEGER
)
RETURNS TABLE (supplier_category_id INTEGER)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    RETURN QUERY
    INSERT INTO purchasing.supplier_categories(supplier_category_name, last_edited_by)
    SELECT 
        (item->>'SupplierCategoryName')::VARCHAR(50),
        p_user_id
    FROM jsonb_array_elements(p_supplier_categories) AS item
    RETURNING purchasing.supplier_categories.supplier_category_id;
END;
$$;

COMMENT ON FUNCTION webapi.insert_supplier_categories_from_json IS 'Inserts supplier categories from JSON array and returns inserted IDs';
