-- PostgreSQL equivalent of [DataLoadSimulation].GetSupplierCategoryID
-- Converted from T-SQL to PL/pgSQL

CREATE OR REPLACE FUNCTION dataload_simulation.get_supplier_category_id(
    p_supplier_category_name VARCHAR(50)
)
RETURNS INTEGER
LANGUAGE plpgsql
STABLE
AS $$
DECLARE
    v_supplier_category_id INTEGER;
BEGIN
    SELECT supplier_category_id INTO v_supplier_category_id
    FROM purchasing.supplier_categories
    WHERE supplier_category_name = p_supplier_category_name
    AND valid_to = '9999-12-31 23:59:59.999999'::TIMESTAMP
    LIMIT 1;
    
    RETURN v_supplier_category_id;
END;
$$;

COMMENT ON FUNCTION dataload_simulation.get_supplier_category_id IS 'Returns the supplier category ID for a given name';
