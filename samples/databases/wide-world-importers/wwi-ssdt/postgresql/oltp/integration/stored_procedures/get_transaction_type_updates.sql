-- PostgreSQL equivalent of [Integration].GetTransactionTypeUpdates
-- Converted from T-SQL to PL/pgSQL

CREATE OR REPLACE FUNCTION integration.get_transaction_type_updates(
    p_last_cutoff TIMESTAMP,
    p_new_cutoff TIMESTAMP
)
RETURNS TABLE (
    wwi_transaction_type_id INTEGER,
    transaction_type VARCHAR(50),
    valid_from TIMESTAMP,
    valid_to TIMESTAMP
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_end_of_time TIMESTAMP := '9999-12-31 23:59:59.999999'::TIMESTAMP;
BEGIN
    CREATE TEMP TABLE temp_transaction_type_changes (
        wwi_transaction_type_id INTEGER,
        transaction_type VARCHAR(50),
        valid_from TIMESTAMP,
        valid_to TIMESTAMP
    ) ON COMMIT DROP;
    
    -- Find transaction type changes from archive
    INSERT INTO temp_transaction_type_changes
    SELECT tt.transaction_type_id, tt.transaction_type_name, tt.valid_from, NULL::TIMESTAMP
    FROM application.transaction_types_archive tt
    WHERE tt.valid_from > p_last_cutoff
    AND tt.valid_from <= p_new_cutoff;
    
    -- Find transaction type changes from current table
    INSERT INTO temp_transaction_type_changes
    SELECT tt.transaction_type_id, tt.transaction_type_name, tt.valid_from, NULL::TIMESTAMP
    FROM application.transaction_types tt
    WHERE tt.valid_from > p_last_cutoff
    AND tt.valid_from <= p_new_cutoff;
    
    CREATE INDEX ON temp_transaction_type_changes (wwi_transaction_type_id, valid_from);
    
    UPDATE temp_transaction_type_changes ttc
    SET valid_to = COALESCE(
        (SELECT MIN(ttc2.valid_from) 
         FROM temp_transaction_type_changes ttc2
         WHERE ttc2.wwi_transaction_type_id = ttc.wwi_transaction_type_id
         AND ttc2.valid_from > ttc.valid_from),
        v_end_of_time
    );
    
    RETURN QUERY
    SELECT ttc.wwi_transaction_type_id, ttc.transaction_type, ttc.valid_from, ttc.valid_to
    FROM temp_transaction_type_changes ttc
    ORDER BY ttc.valid_from;
END;
$$;

COMMENT ON FUNCTION integration.get_transaction_type_updates IS 'Returns transaction type dimension updates for ETL processing';
