-- PostgreSQL equivalent of [WebApi].UpdateTransactionTypeFromJson
-- Converted from T-SQL to PL/pgSQL

CREATE OR REPLACE PROCEDURE webapi.update_transaction_type_from_json(
    p_transaction_type JSONB,
    p_transaction_type_id INTEGER,
    p_user_id INTEGER
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    UPDATE application.transaction_types SET
        transaction_type_name = (p_transaction_type->>'TransactionTypeName')::VARCHAR(50),
        last_edited_by = p_user_id
    WHERE transaction_type_id = p_transaction_type_id;
END;
$$;

COMMENT ON PROCEDURE webapi.update_transaction_type_from_json IS 'Updates a transaction type from JSON';
