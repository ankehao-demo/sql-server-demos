-- PostgreSQL equivalent of [WebApi].DeleteSupplierCategory
-- Converted from T-SQL to PL/pgSQL

CREATE OR REPLACE PROCEDURE webapi.delete_supplier_category(
    p_supplier_category_id INTEGER
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    DELETE FROM purchasing.supplier_categories
    WHERE supplier_category_id = p_supplier_category_id;
END;
$$;

COMMENT ON PROCEDURE webapi.delete_supplier_category IS 'Deletes a supplier category by ID';
