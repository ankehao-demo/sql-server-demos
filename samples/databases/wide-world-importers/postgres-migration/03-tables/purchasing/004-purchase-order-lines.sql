-- Wide World Importers PostgreSQL Migration
-- Phase 2: OLTP Schema Migration
-- Purchasing.PurchaseOrderLines table (non-temporal)
-- Note: References Warehouse.StockItems and Warehouse.PackageTypes - FK constraints added later

CREATE TABLE purchasing.purchase_order_lines (
    purchase_order_line_id INTEGER NOT NULL DEFAULT nextval('sequences.purchase_order_line_id'),
    purchase_order_id INTEGER NOT NULL,
    stock_item_id INTEGER NOT NULL,
    ordered_outers INTEGER NOT NULL,
    description VARCHAR(100) NOT NULL,
    received_outers INTEGER NOT NULL,
    package_type_id INTEGER NOT NULL,
    expected_unit_price_per_outer NUMERIC(18, 2) NULL,
    last_receipt_date DATE NULL,
    is_order_line_finalized BOOLEAN NOT NULL,
    last_edited_by INTEGER NOT NULL,
    last_edited_when TIMESTAMP NOT NULL DEFAULT clock_timestamp(),
    
    CONSTRAINT pk_purchasing_purchase_order_lines PRIMARY KEY (purchase_order_line_id),
    CONSTRAINT fk_purchasing_purchase_order_lines_purchase_order 
        FOREIGN KEY (purchase_order_id) REFERENCES purchasing.purchase_orders(purchase_order_id),
    CONSTRAINT fk_purchasing_purchase_order_lines_last_edited_by 
        FOREIGN KEY (last_edited_by) REFERENCES application.people(person_id)
);

-- Indexes for foreign keys and performance
CREATE INDEX ix_purchasing_purchase_order_lines_purchase_order_id 
    ON purchasing.purchase_order_lines(purchase_order_id);
CREATE INDEX ix_purchasing_purchase_order_lines_stock_item_id 
    ON purchasing.purchase_order_lines(stock_item_id);
CREATE INDEX ix_purchasing_purchase_order_lines_package_type_id 
    ON purchasing.purchase_order_lines(package_type_id);
CREATE INDEX ix_purchasing_purchase_order_lines_perf 
    ON purchasing.purchase_order_lines(is_order_line_finalized, stock_item_id) 
    INCLUDE (ordered_outers, received_outers);
