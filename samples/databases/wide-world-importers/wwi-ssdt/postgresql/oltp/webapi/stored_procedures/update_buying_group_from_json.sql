-- PostgreSQL equivalent of [WebApi].UpdateBuyingGroupFromJson
-- Converted from T-SQL to PL/pgSQL

CREATE OR REPLACE PROCEDURE webapi.update_buying_group_from_json(
    p_buying_group JSONB,
    p_buying_group_id INTEGER,
    p_user_id INTEGER
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    UPDATE sales.buying_groups SET
        buying_group_name = (p_buying_group->>'BuyingGroupName')::VARCHAR(50),
        last_edited_by = p_user_id
    WHERE buying_group_id = p_buying_group_id;
END;
$$;

COMMENT ON PROCEDURE webapi.update_buying_group_from_json IS 'Updates a buying group from JSON';
