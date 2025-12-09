-- PostgreSQL equivalent of [WebApi].DeleteCustomerCategory
-- Converted from T-SQL to PL/pgSQL

CREATE OR REPLACE PROCEDURE webapi.delete_customer_category(
    p_customer_category_id INTEGER
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    DELETE FROM sales.customer_categories
    WHERE customer_category_id = p_customer_category_id;
END;
$$;

COMMENT ON PROCEDURE webapi.delete_customer_category IS 'Deletes a customer category by ID';
