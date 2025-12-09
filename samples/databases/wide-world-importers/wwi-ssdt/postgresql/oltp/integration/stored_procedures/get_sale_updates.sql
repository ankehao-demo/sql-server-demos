-- PostgreSQL equivalent of [Integration].GetSaleUpdates
-- Converted from T-SQL to PL/pgSQL

CREATE OR REPLACE FUNCTION integration.get_sale_updates(
    p_last_cutoff TIMESTAMP,
    p_new_cutoff TIMESTAMP
)
RETURNS TABLE (
    wwi_invoice_id INTEGER,
    wwi_customer_id INTEGER,
    wwi_bill_to_customer_id INTEGER,
    wwi_salesperson_id INTEGER,
    wwi_stock_item_id INTEGER,
    wwi_delivery_method_id INTEGER,
    wwi_city_id INTEGER,
    description VARCHAR(100),
    package VARCHAR(50),
    quantity INTEGER,
    unit_price DECIMAL(18,2),
    tax_rate DECIMAL(18,3),
    total_excluding_tax DECIMAL(18,2),
    tax_amount DECIMAL(18,2),
    profit DECIMAL(18,2),
    total_including_tax DECIMAL(18,2),
    total_dry_items INTEGER,
    total_chiller_items INTEGER,
    invoice_date DATE,
    last_modified_when TIMESTAMP
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    RETURN QUERY
    SELECT i.invoice_id,
           i.customer_id,
           i.bill_to_customer_id,
           i.salesperson_person_id,
           il.stock_item_id,
           i.delivery_method_id,
           c.delivery_city_id,
           il.description,
           pt.package_type_name,
           il.quantity,
           il.unit_price,
           il.tax_rate,
           il.extended_price - il.tax_amount,
           il.tax_amount,
           il.line_profit,
           il.extended_price,
           i.total_dry_items,
           i.total_chiller_items,
           i.invoice_date,
           il.last_edited_when
    FROM sales.invoices i
    JOIN sales.invoice_lines il ON i.invoice_id = il.invoice_id
    JOIN sales.customers c ON i.customer_id = c.customer_id
    LEFT JOIN warehouse.package_types pt ON il.package_type_id = pt.package_type_id
    WHERE il.last_edited_when > p_last_cutoff
    AND il.last_edited_when <= p_new_cutoff
    ORDER BY i.invoice_id, il.invoice_line_id;
END;
$$;

COMMENT ON FUNCTION integration.get_sale_updates IS 'Returns sale fact updates for ETL processing';
