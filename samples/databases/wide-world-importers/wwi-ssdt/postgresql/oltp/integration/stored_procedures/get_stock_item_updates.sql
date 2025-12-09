-- PostgreSQL equivalent of [Integration].GetStockItemUpdates
-- Converted from T-SQL to PL/pgSQL

CREATE OR REPLACE FUNCTION integration.get_stock_item_updates(
    p_last_cutoff TIMESTAMP,
    p_new_cutoff TIMESTAMP
)
RETURNS TABLE (
    wwi_stock_item_id INTEGER,
    stock_item VARCHAR(100),
    color VARCHAR(20),
    unit_package VARCHAR(50),
    outer_package VARCHAR(50),
    brand VARCHAR(50),
    size VARCHAR(20),
    lead_time_days INTEGER,
    quantity_per_outer INTEGER,
    is_chiller_stock BOOLEAN,
    barcode VARCHAR(50),
    tax_rate DECIMAL(18,3),
    unit_price DECIMAL(18,2),
    recommended_retail_price DECIMAL(18,2),
    typical_weight_per_unit DECIMAL(18,3),
    photo BYTEA,
    valid_from TIMESTAMP,
    valid_to TIMESTAMP
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_end_of_time TIMESTAMP := '9999-12-31 23:59:59.999999'::TIMESTAMP;
BEGIN
    CREATE TEMP TABLE temp_stock_item_changes (
        wwi_stock_item_id INTEGER,
        stock_item VARCHAR(100),
        color VARCHAR(20),
        unit_package VARCHAR(50),
        outer_package VARCHAR(50),
        brand VARCHAR(50),
        size VARCHAR(20),
        lead_time_days INTEGER,
        quantity_per_outer INTEGER,
        is_chiller_stock BOOLEAN,
        barcode VARCHAR(50),
        tax_rate DECIMAL(18,3),
        unit_price DECIMAL(18,2),
        recommended_retail_price DECIMAL(18,2),
        typical_weight_per_unit DECIMAL(18,3),
        photo BYTEA,
        valid_from TIMESTAMP,
        valid_to TIMESTAMP
    ) ON COMMIT DROP;
    
    -- Find stock item changes from archive
    INSERT INTO temp_stock_item_changes
    SELECT si.stock_item_id, si.stock_item_name, c.color_name,
           up.package_type_name, op.package_type_name,
           si.brand, si.size, si.lead_time_days, si.quantity_per_outer,
           si.is_chiller_stock, si.barcode, si.tax_rate, si.unit_price,
           si.recommended_retail_price, si.typical_weight_per_unit,
           si.photo, si.valid_from, NULL::TIMESTAMP
    FROM warehouse.stock_items_archive si
    LEFT JOIN warehouse.colors c ON si.color_id = c.color_id
    LEFT JOIN warehouse.package_types up ON si.unit_package_id = up.package_type_id
    LEFT JOIN warehouse.package_types op ON si.outer_package_id = op.package_type_id
    WHERE si.valid_from > p_last_cutoff
    AND si.valid_from <= p_new_cutoff;
    
    -- Find stock item changes from current table
    INSERT INTO temp_stock_item_changes
    SELECT si.stock_item_id, si.stock_item_name, c.color_name,
           up.package_type_name, op.package_type_name,
           si.brand, si.size, si.lead_time_days, si.quantity_per_outer,
           si.is_chiller_stock, si.barcode, si.tax_rate, si.unit_price,
           si.recommended_retail_price, si.typical_weight_per_unit,
           si.photo, si.valid_from, NULL::TIMESTAMP
    FROM warehouse.stock_items si
    LEFT JOIN warehouse.colors c ON si.color_id = c.color_id
    LEFT JOIN warehouse.package_types up ON si.unit_package_id = up.package_type_id
    LEFT JOIN warehouse.package_types op ON si.outer_package_id = op.package_type_id
    WHERE si.valid_from > p_last_cutoff
    AND si.valid_from <= p_new_cutoff;
    
    CREATE INDEX ON temp_stock_item_changes (wwi_stock_item_id, valid_from);
    
    UPDATE temp_stock_item_changes sic
    SET valid_to = COALESCE(
        (SELECT MIN(sic2.valid_from) 
         FROM temp_stock_item_changes sic2
         WHERE sic2.wwi_stock_item_id = sic.wwi_stock_item_id
         AND sic2.valid_from > sic.valid_from),
        v_end_of_time
    );
    
    RETURN QUERY
    SELECT sic.wwi_stock_item_id, sic.stock_item, sic.color, sic.unit_package,
           sic.outer_package, sic.brand, sic.size, sic.lead_time_days,
           sic.quantity_per_outer, sic.is_chiller_stock, sic.barcode,
           sic.tax_rate, sic.unit_price, sic.recommended_retail_price,
           sic.typical_weight_per_unit, sic.photo, sic.valid_from, sic.valid_to
    FROM temp_stock_item_changes sic
    ORDER BY sic.valid_from;
END;
$$;

COMMENT ON FUNCTION integration.get_stock_item_updates IS 'Returns stock item dimension updates for ETL processing';
