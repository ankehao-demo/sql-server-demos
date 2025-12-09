-- PostgreSQL equivalent of [WebApi].DeleteSupplier
-- Converted from T-SQL to PL/pgSQL

CREATE OR REPLACE PROCEDURE webapi.delete_supplier(
    p_supplier_id INTEGER
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    DELETE FROM purchasing.suppliers
    WHERE supplier_id = p_supplier_id;
END;
$$;

COMMENT ON PROCEDURE webapi.delete_supplier IS 'Deletes a supplier by ID';
