-- PostgreSQL equivalent of [WebApi].DeleteTransactionType
-- Converted from T-SQL to PL/pgSQL

CREATE OR REPLACE PROCEDURE webapi.delete_transaction_type(
    p_transaction_type_id INTEGER
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    DELETE FROM application.transaction_types
    WHERE transaction_type_id = p_transaction_type_id;
END;
$$;

COMMENT ON PROCEDURE webapi.delete_transaction_type IS 'Deletes a transaction type by ID';
