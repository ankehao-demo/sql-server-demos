-- Wide World Importers PostgreSQL Migration
-- Phase 2: OLTP Schema Migration
-- Sales.OrderLines table (non-temporal)
-- Note: References Warehouse.StockItems and Warehouse.PackageTypes - FK constraints added later

CREATE TABLE sales.order_lines (
    order_line_id INTEGER NOT NULL DEFAULT nextval('sequences.order_line_id'),
    order_id INTEGER NOT NULL,
    stock_item_id INTEGER NOT NULL,
    description VARCHAR(100) NOT NULL,
    package_type_id INTEGER NOT NULL,
    quantity INTEGER NOT NULL,
    unit_price NUMERIC(18, 2) NULL,
    tax_rate NUMERIC(18, 3) NOT NULL,
    picked_quantity INTEGER NOT NULL,
    picking_completed_when TIMESTAMP NULL,
    last_edited_by INTEGER NOT NULL,
    last_edited_when TIMESTAMP NOT NULL DEFAULT clock_timestamp(),
    
    CONSTRAINT pk_sales_order_lines PRIMARY KEY (order_line_id),
    CONSTRAINT fk_sales_order_lines_order 
        FOREIGN KEY (order_id) REFERENCES sales.orders(order_id),
    CONSTRAINT fk_sales_order_lines_last_edited_by 
        FOREIGN KEY (last_edited_by) REFERENCES application.people(person_id)
);

-- Indexes for foreign keys and performance
CREATE INDEX ix_sales_order_lines_order_id 
    ON sales.order_lines(order_id);
CREATE INDEX ix_sales_order_lines_package_type_id 
    ON sales.order_lines(package_type_id);
CREATE INDEX ix_sales_order_lines_allocated_stock_items 
    ON sales.order_lines(stock_item_id) 
    INCLUDE (picked_quantity);
CREATE INDEX ix_sales_order_lines_perf_01 
    ON sales.order_lines(picking_completed_when, order_id, order_line_id) 
    INCLUDE (quantity, stock_item_id);
CREATE INDEX ix_sales_order_lines_perf_02 
    ON sales.order_lines(stock_item_id, picking_completed_when) 
    INCLUDE (order_id, picked_quantity);
