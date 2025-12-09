-- Wide World Importers PostgreSQL Migration
-- Phase 2: OLTP Schema Migration
-- Cross-schema foreign key constraints
-- These constraints reference tables in other schemas and must be added after all tables are created

-- ============================================================================
-- PURCHASING SCHEMA CROSS-SCHEMA FOREIGN KEYS
-- ============================================================================

-- PurchaseOrderLines references Warehouse tables
ALTER TABLE purchasing.purchase_order_lines
    ADD CONSTRAINT fk_purchasing_purchase_order_lines_stock_item 
    FOREIGN KEY (stock_item_id) REFERENCES warehouse.stock_items(stock_item_id);

ALTER TABLE purchasing.purchase_order_lines
    ADD CONSTRAINT fk_purchasing_purchase_order_lines_package_type 
    FOREIGN KEY (package_type_id) REFERENCES warehouse.package_types(package_type_id);

-- ============================================================================
-- SALES SCHEMA CROSS-SCHEMA FOREIGN KEYS
-- ============================================================================

-- OrderLines references Warehouse tables
ALTER TABLE sales.order_lines
    ADD CONSTRAINT fk_sales_order_lines_stock_item 
    FOREIGN KEY (stock_item_id) REFERENCES warehouse.stock_items(stock_item_id);

ALTER TABLE sales.order_lines
    ADD CONSTRAINT fk_sales_order_lines_package_type 
    FOREIGN KEY (package_type_id) REFERENCES warehouse.package_types(package_type_id);

-- InvoiceLines references Warehouse tables
ALTER TABLE sales.invoice_lines
    ADD CONSTRAINT fk_sales_invoice_lines_stock_item 
    FOREIGN KEY (stock_item_id) REFERENCES warehouse.stock_items(stock_item_id);

ALTER TABLE sales.invoice_lines
    ADD CONSTRAINT fk_sales_invoice_lines_package_type 
    FOREIGN KEY (package_type_id) REFERENCES warehouse.package_types(package_type_id);

-- SpecialDeals references Warehouse tables
ALTER TABLE sales.special_deals
    ADD CONSTRAINT fk_sales_special_deals_stock_item 
    FOREIGN KEY (stock_item_id) REFERENCES warehouse.stock_items(stock_item_id);

ALTER TABLE sales.special_deals
    ADD CONSTRAINT fk_sales_special_deals_stock_group 
    FOREIGN KEY (stock_group_id) REFERENCES warehouse.stock_groups(stock_group_id);
