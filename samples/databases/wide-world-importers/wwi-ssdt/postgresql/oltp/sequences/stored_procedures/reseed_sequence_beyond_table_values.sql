-- PostgreSQL equivalent of [Sequences].ReseedSequenceBeyondTableValues
-- Converted from T-SQL to PL/pgSQL

CREATE OR REPLACE PROCEDURE sequences.reseed_sequence_beyond_table_values(
    p_sequence_name TEXT,
    p_schema_name TEXT,
    p_table_name TEXT,
    p_column_name TEXT
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_current_table_maximum_value BIGINT;
    v_current_sequence_value BIGINT;
    v_new_sequence_value BIGINT;
    v_sql TEXT;
BEGIN
    -- Get current sequence value
    SELECT last_value INTO v_current_sequence_value
    FROM pg_sequences
    WHERE schemaname = 'sequences'
    AND sequencename = LOWER(p_sequence_name);
    
    -- Get maximum value from the table
    v_sql := format('SELECT COALESCE(MAX(%I), 0) FROM %I.%I', 
                    p_column_name, p_schema_name, p_table_name);
    EXECUTE v_sql INTO v_current_table_maximum_value;
    
    -- If table max is >= sequence value, restart sequence
    IF v_current_table_maximum_value >= v_current_sequence_value THEN
        v_new_sequence_value := v_current_table_maximum_value + 1;
        v_sql := format('ALTER SEQUENCE sequences.%I RESTART WITH %s', 
                        p_sequence_name, v_new_sequence_value);
        EXECUTE v_sql;
    END IF;
END;
$$;

COMMENT ON PROCEDURE sequences.reseed_sequence_beyond_table_values IS 'Ensures that the next sequence value is above the maximum value of the supplied table column';
