-- PostgreSQL equivalent of [WebApi].UpdateSupplierCategoryFromJson
-- Converted from T-SQL to PL/pgSQL

CREATE OR REPLACE PROCEDURE webapi.update_supplier_category_from_json(
    p_supplier_category JSONB,
    p_supplier_category_id INTEGER,
    p_user_id INTEGER
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    UPDATE purchasing.supplier_categories SET
        supplier_category_name = (p_supplier_category->>'SupplierCategoryName')::VARCHAR(50),
        last_edited_by = p_user_id
    WHERE supplier_category_id = p_supplier_category_id;
END;
$$;

COMMENT ON PROCEDURE webapi.update_supplier_category_from_json IS 'Updates a supplier category from JSON';
