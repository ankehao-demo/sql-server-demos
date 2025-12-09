-- PostgreSQL equivalent of [Integration].GetPaymentMethodUpdates
-- Converted from T-SQL to PL/pgSQL

CREATE OR REPLACE FUNCTION integration.get_payment_method_updates(
    p_last_cutoff TIMESTAMP,
    p_new_cutoff TIMESTAMP
)
RETURNS TABLE (
    wwi_payment_method_id INTEGER,
    payment_method VARCHAR(50),
    valid_from TIMESTAMP,
    valid_to TIMESTAMP
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_end_of_time TIMESTAMP := '9999-12-31 23:59:59.999999'::TIMESTAMP;
BEGIN
    CREATE TEMP TABLE temp_payment_method_changes (
        wwi_payment_method_id INTEGER,
        payment_method VARCHAR(50),
        valid_from TIMESTAMP,
        valid_to TIMESTAMP
    ) ON COMMIT DROP;
    
    -- Find payment method changes from archive
    INSERT INTO temp_payment_method_changes
    SELECT pm.payment_method_id, pm.payment_method_name, pm.valid_from, NULL::TIMESTAMP
    FROM application.payment_methods_archive pm
    WHERE pm.valid_from > p_last_cutoff
    AND pm.valid_from <= p_new_cutoff;
    
    -- Find payment method changes from current table
    INSERT INTO temp_payment_method_changes
    SELECT pm.payment_method_id, pm.payment_method_name, pm.valid_from, NULL::TIMESTAMP
    FROM application.payment_methods pm
    WHERE pm.valid_from > p_last_cutoff
    AND pm.valid_from <= p_new_cutoff;
    
    CREATE INDEX ON temp_payment_method_changes (wwi_payment_method_id, valid_from);
    
    UPDATE temp_payment_method_changes pmc
    SET valid_to = COALESCE(
        (SELECT MIN(pmc2.valid_from) 
         FROM temp_payment_method_changes pmc2
         WHERE pmc2.wwi_payment_method_id = pmc.wwi_payment_method_id
         AND pmc2.valid_from > pmc.valid_from),
        v_end_of_time
    );
    
    RETURN QUERY
    SELECT pmc.wwi_payment_method_id, pmc.payment_method, pmc.valid_from, pmc.valid_to
    FROM temp_payment_method_changes pmc
    ORDER BY pmc.valid_from;
END;
$$;

COMMENT ON FUNCTION integration.get_payment_method_updates IS 'Returns payment method dimension updates for ETL processing';
