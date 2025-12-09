-- PostgreSQL equivalent of [WebApi].InsertCustomerCategoriesFromJson
-- Converted from T-SQL to PL/pgSQL

CREATE OR REPLACE FUNCTION webapi.insert_customer_categories_from_json(
    p_customer_categories JSONB,
    p_user_id INTEGER
)
RETURNS TABLE (customer_category_id INTEGER)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    RETURN QUERY
    INSERT INTO sales.customer_categories(customer_category_name, last_edited_by)
    SELECT 
        (item->>'CustomerCategoryName')::VARCHAR(50),
        p_user_id
    FROM jsonb_array_elements(p_customer_categories) AS item
    RETURNING sales.customer_categories.customer_category_id;
END;
$$;

COMMENT ON FUNCTION webapi.insert_customer_categories_from_json IS 'Inserts customer categories from JSON array and returns inserted IDs';
