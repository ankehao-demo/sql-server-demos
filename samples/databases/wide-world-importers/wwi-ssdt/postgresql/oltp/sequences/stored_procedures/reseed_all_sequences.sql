-- PostgreSQL equivalent of [Sequences].ReseedAllSequences
-- Converted from T-SQL to PL/pgSQL

CREATE OR REPLACE PROCEDURE sequences.reseed_all_sequences()
LANGUAGE plpgsql
AS $$
BEGIN
    -- Ensures that the next sequence values are above the maximum value of the related table columns
    
    CALL sequences.reseed_sequence_beyond_table_values('buying_group_id', 'sales', 'buying_groups', 'buying_group_id');
    CALL sequences.reseed_sequence_beyond_table_values('city_id', 'application', 'cities', 'city_id');
    CALL sequences.reseed_sequence_beyond_table_values('color_id', 'warehouse', 'colors', 'color_id');
    CALL sequences.reseed_sequence_beyond_table_values('country_id', 'application', 'countries', 'country_id');
    CALL sequences.reseed_sequence_beyond_table_values('customer_category_id', 'sales', 'customer_categories', 'customer_category_id');
    CALL sequences.reseed_sequence_beyond_table_values('customer_id', 'sales', 'customers', 'customer_id');
    CALL sequences.reseed_sequence_beyond_table_values('delivery_method_id', 'application', 'delivery_methods', 'delivery_method_id');
    CALL sequences.reseed_sequence_beyond_table_values('invoice_id', 'sales', 'invoices', 'invoice_id');
    CALL sequences.reseed_sequence_beyond_table_values('invoice_line_id', 'sales', 'invoice_lines', 'invoice_line_id');
    CALL sequences.reseed_sequence_beyond_table_values('order_id', 'sales', 'orders', 'order_id');
    CALL sequences.reseed_sequence_beyond_table_values('order_line_id', 'sales', 'order_lines', 'order_line_id');
    CALL sequences.reseed_sequence_beyond_table_values('package_type_id', 'warehouse', 'package_types', 'package_type_id');
    CALL sequences.reseed_sequence_beyond_table_values('payment_method_id', 'application', 'payment_methods', 'payment_method_id');
    CALL sequences.reseed_sequence_beyond_table_values('person_id', 'application', 'people', 'person_id');
    CALL sequences.reseed_sequence_beyond_table_values('purchase_order_id', 'purchasing', 'purchase_orders', 'purchase_order_id');
    CALL sequences.reseed_sequence_beyond_table_values('purchase_order_line_id', 'purchasing', 'purchase_order_lines', 'purchase_order_line_id');
    CALL sequences.reseed_sequence_beyond_table_values('special_deal_id', 'sales', 'special_deals', 'special_deal_id');
    CALL sequences.reseed_sequence_beyond_table_values('state_province_id', 'application', 'state_provinces', 'state_province_id');
    CALL sequences.reseed_sequence_beyond_table_values('stock_group_id', 'warehouse', 'stock_groups', 'stock_group_id');
    CALL sequences.reseed_sequence_beyond_table_values('stock_item_id', 'warehouse', 'stock_items', 'stock_item_id');
    CALL sequences.reseed_sequence_beyond_table_values('stock_item_stock_group_id', 'warehouse', 'stock_item_stock_groups', 'stock_item_stock_group_id');
    CALL sequences.reseed_sequence_beyond_table_values('supplier_category_id', 'purchasing', 'supplier_categories', 'supplier_category_id');
    CALL sequences.reseed_sequence_beyond_table_values('supplier_id', 'purchasing', 'suppliers', 'supplier_id');
    CALL sequences.reseed_sequence_beyond_table_values('system_parameter_id', 'application', 'system_parameters', 'system_parameter_id');
    CALL sequences.reseed_sequence_beyond_table_values('transaction_id', 'purchasing', 'supplier_transactions', 'supplier_transaction_id');
    CALL sequences.reseed_sequence_beyond_table_values('transaction_id', 'sales', 'customer_transactions', 'customer_transaction_id');
    CALL sequences.reseed_sequence_beyond_table_values('transaction_id', 'warehouse', 'stock_item_transactions', 'stock_item_transaction_id');
    CALL sequences.reseed_sequence_beyond_table_values('transaction_type_id', 'application', 'transaction_types', 'transaction_type_id');
END;
$$;

COMMENT ON PROCEDURE sequences.reseed_all_sequences IS 'Reseeds all sequences to be above the maximum value of their related table columns';
