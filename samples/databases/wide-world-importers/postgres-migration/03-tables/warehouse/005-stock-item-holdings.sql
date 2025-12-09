-- Wide World Importers PostgreSQL Migration
-- Phase 2: OLTP Schema Migration
-- Warehouse.StockItemHoldings table (non-temporal)

CREATE TABLE warehouse.stock_item_holdings (
    stock_item_id INTEGER NOT NULL,
    quantity_on_hand INTEGER NOT NULL,
    bin_location VARCHAR(20) NOT NULL,
    last_stocktake_quantity INTEGER NOT NULL,
    last_cost_price NUMERIC(18, 2) NOT NULL,
    reorder_level INTEGER NOT NULL,
    target_stock_level INTEGER NOT NULL,
    last_edited_by INTEGER NOT NULL,
    last_edited_when TIMESTAMP NOT NULL DEFAULT clock_timestamp(),
    
    CONSTRAINT pk_warehouse_stock_item_holdings PRIMARY KEY (stock_item_id),
    CONSTRAINT fk_warehouse_stock_item_holdings_stock_item 
        FOREIGN KEY (stock_item_id) REFERENCES warehouse.stock_items(stock_item_id),
    CONSTRAINT fk_warehouse_stock_item_holdings_last_edited_by 
        FOREIGN KEY (last_edited_by) REFERENCES application.people(person_id)
);
