-- PostgreSQL equivalent of [WebApi].InsertTransactionTypesFromJson
-- Converted from T-SQL to PL/pgSQL

CREATE OR REPLACE FUNCTION webapi.insert_transaction_types_from_json(
    p_transaction_types JSONB,
    p_user_id INTEGER
)
RETURNS TABLE (transaction_type_id INTEGER)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    RETURN QUERY
    INSERT INTO application.transaction_types(transaction_type_name, last_edited_by)
    SELECT 
        (item->>'TransactionTypeName')::VARCHAR(50),
        p_user_id
    FROM jsonb_array_elements(p_transaction_types) AS item
    RETURNING application.transaction_types.transaction_type_id;
END;
$$;

COMMENT ON FUNCTION webapi.insert_transaction_types_from_json IS 'Inserts transaction types from JSON array and returns inserted IDs';
