-- PostgreSQL equivalent of [WebApi].InsertBuyingGroupsFromJson
-- Converted from T-SQL to PL/pgSQL

CREATE OR REPLACE FUNCTION webapi.insert_buying_groups_from_json(
    p_buying_groups JSONB,
    p_user_id INTEGER
)
RETURNS TABLE (buying_group_id INTEGER)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    RETURN QUERY
    INSERT INTO sales.buying_groups(buying_group_name, last_edited_by)
    SELECT 
        (item->>'BuyingGroupName')::VARCHAR(50),
        p_user_id
    FROM jsonb_array_elements(p_buying_groups) AS item
    RETURNING sales.buying_groups.buying_group_id;
END;
$$;

COMMENT ON FUNCTION webapi.insert_buying_groups_from_json IS 'Inserts buying groups from JSON array and returns inserted IDs';
