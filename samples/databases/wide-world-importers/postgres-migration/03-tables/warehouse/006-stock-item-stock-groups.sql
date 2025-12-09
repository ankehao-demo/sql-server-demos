-- Wide World Importers PostgreSQL Migration
-- Phase 2: OLTP Schema Migration
-- Warehouse.StockItemStockGroups table (non-temporal, many-to-many relationship)

CREATE TABLE warehouse.stock_item_stock_groups (
    stock_item_stock_group_id INTEGER NOT NULL DEFAULT nextval('sequences.stock_item_stock_group_id'),
    stock_item_id INTEGER NOT NULL,
    stock_group_id INTEGER NOT NULL,
    last_edited_by INTEGER NOT NULL,
    last_edited_when TIMESTAMP NOT NULL DEFAULT clock_timestamp(),
    
    CONSTRAINT pk_warehouse_stock_item_stock_groups PRIMARY KEY (stock_item_stock_group_id),
    CONSTRAINT uq_stock_item_stock_groups_stock_group_lookup UNIQUE (stock_group_id, stock_item_id),
    CONSTRAINT uq_stock_item_stock_groups_stock_item_lookup UNIQUE (stock_item_id, stock_group_id),
    CONSTRAINT fk_warehouse_stock_item_stock_groups_stock_item 
        FOREIGN KEY (stock_item_id) REFERENCES warehouse.stock_items(stock_item_id),
    CONSTRAINT fk_warehouse_stock_item_stock_groups_stock_group 
        FOREIGN KEY (stock_group_id) REFERENCES warehouse.stock_groups(stock_group_id),
    CONSTRAINT fk_warehouse_stock_item_stock_groups_last_edited_by 
        FOREIGN KEY (last_edited_by) REFERENCES application.people(person_id)
);
