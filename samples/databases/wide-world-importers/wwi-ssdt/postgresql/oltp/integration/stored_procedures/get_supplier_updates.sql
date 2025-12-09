-- PostgreSQL equivalent of [Integration].GetSupplierUpdates
-- Converted from T-SQL to PL/pgSQL

CREATE OR REPLACE FUNCTION integration.get_supplier_updates(
    p_last_cutoff TIMESTAMP,
    p_new_cutoff TIMESTAMP
)
RETURNS TABLE (
    wwi_supplier_id INTEGER,
    supplier VARCHAR(100),
    category VARCHAR(50),
    primary_contact VARCHAR(50),
    supplier_reference VARCHAR(20),
    payment_days INTEGER,
    postal_code VARCHAR(10),
    valid_from TIMESTAMP,
    valid_to TIMESTAMP
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_end_of_time TIMESTAMP := '9999-12-31 23:59:59.999999'::TIMESTAMP;
BEGIN
    CREATE TEMP TABLE temp_supplier_changes (
        wwi_supplier_id INTEGER,
        supplier VARCHAR(100),
        category VARCHAR(50),
        primary_contact VARCHAR(50),
        supplier_reference VARCHAR(20),
        payment_days INTEGER,
        postal_code VARCHAR(10),
        valid_from TIMESTAMP,
        valid_to TIMESTAMP
    ) ON COMMIT DROP;
    
    -- Find supplier category changes from archive
    INSERT INTO temp_supplier_changes
    SELECT s.supplier_id, s.supplier_name, sc.supplier_category_name,
           p.full_name, s.supplier_reference, s.payment_days, s.delivery_postal_code,
           sc.valid_from, NULL::TIMESTAMP
    FROM purchasing.supplier_categories_archive sc
    JOIN purchasing.suppliers s ON s.supplier_category_id = sc.supplier_category_id
    JOIN application.people p ON s.primary_contact_person_id = p.person_id
    WHERE sc.valid_from > p_last_cutoff
    AND sc.valid_from <= p_new_cutoff;
    
    INSERT INTO temp_supplier_changes
    SELECT s.supplier_id, s.supplier_name, sc.supplier_category_name,
           p.full_name, s.supplier_reference, s.payment_days, s.delivery_postal_code,
           sc.valid_from, NULL::TIMESTAMP
    FROM purchasing.supplier_categories sc
    JOIN purchasing.suppliers s ON s.supplier_category_id = sc.supplier_category_id
    JOIN application.people p ON s.primary_contact_person_id = p.person_id
    WHERE sc.valid_from > p_last_cutoff
    AND sc.valid_from <= p_new_cutoff;
    
    -- Find supplier changes from archive
    INSERT INTO temp_supplier_changes
    SELECT s.supplier_id, s.supplier_name, sc.supplier_category_name,
           p.full_name, s.supplier_reference, s.payment_days, s.delivery_postal_code,
           s.valid_from, NULL::TIMESTAMP
    FROM purchasing.suppliers_archive s
    JOIN purchasing.supplier_categories sc ON s.supplier_category_id = sc.supplier_category_id
    JOIN application.people p ON s.primary_contact_person_id = p.person_id
    WHERE s.valid_from > p_last_cutoff
    AND s.valid_from <= p_new_cutoff;
    
    INSERT INTO temp_supplier_changes
    SELECT s.supplier_id, s.supplier_name, sc.supplier_category_name,
           p.full_name, s.supplier_reference, s.payment_days, s.delivery_postal_code,
           s.valid_from, NULL::TIMESTAMP
    FROM purchasing.suppliers s
    JOIN purchasing.supplier_categories sc ON s.supplier_category_id = sc.supplier_category_id
    JOIN application.people p ON s.primary_contact_person_id = p.person_id
    WHERE s.valid_from > p_last_cutoff
    AND s.valid_from <= p_new_cutoff;
    
    CREATE INDEX ON temp_supplier_changes (wwi_supplier_id, valid_from);
    
    UPDATE temp_supplier_changes sc
    SET valid_to = COALESCE(
        (SELECT MIN(sc2.valid_from) 
         FROM temp_supplier_changes sc2
         WHERE sc2.wwi_supplier_id = sc.wwi_supplier_id
         AND sc2.valid_from > sc.valid_from),
        v_end_of_time
    );
    
    RETURN QUERY
    SELECT sc.wwi_supplier_id, sc.supplier, sc.category, sc.primary_contact,
           sc.supplier_reference, sc.payment_days, sc.postal_code,
           sc.valid_from, sc.valid_to
    FROM temp_supplier_changes sc
    ORDER BY sc.valid_from;
END;
$$;

COMMENT ON FUNCTION integration.get_supplier_updates IS 'Returns supplier dimension updates for ETL processing';
