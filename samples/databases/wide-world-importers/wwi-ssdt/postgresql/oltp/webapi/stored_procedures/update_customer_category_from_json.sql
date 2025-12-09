-- PostgreSQL equivalent of [WebApi].UpdateCustomerCategoryFromJson
-- Converted from T-SQL to PL/pgSQL

CREATE OR REPLACE PROCEDURE webapi.update_customer_category_from_json(
    p_customer_category JSONB,
    p_customer_category_id INTEGER,
    p_user_id INTEGER
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    UPDATE sales.customer_categories SET
        customer_category_name = (p_customer_category->>'CustomerCategoryName')::VARCHAR(50),
        last_edited_by = p_user_id
    WHERE customer_category_id = p_customer_category_id;
END;
$$;

COMMENT ON PROCEDURE webapi.update_customer_category_from_json IS 'Updates a customer category from JSON';
