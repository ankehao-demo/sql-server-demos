-- Wide World Importers Data Warehouse - PostgreSQL Schema Migration
-- Phase 4: OLAP Schema Migration
-- Fact: Stock Holding
-- Note: This fact table is NOT partitioned (snapshot table, not time-series)

-- Create the fact table (non-partitioned)
CREATE TABLE fact.stock_holding (
    stock_holding_key           BIGINT GENERATED ALWAYS AS IDENTITY,
    stock_item_key              INTEGER NOT NULL,
    quantity_on_hand            INTEGER NOT NULL,
    bin_location                VARCHAR(20) NOT NULL,
    last_stocktake_quantity     INTEGER NOT NULL,
    last_cost_price             DECIMAL(18, 2) NOT NULL,
    reorder_level               INTEGER NOT NULL,
    target_stock_level          INTEGER NOT NULL,
    lineage_key                 INTEGER NOT NULL,

    CONSTRAINT pk_fact_stock_holding PRIMARY KEY (stock_holding_key)
);

-- Create index for stock item lookups
CREATE INDEX ix_fact_stock_holding_stock_item_key ON fact.stock_holding (stock_item_key);

-- Add foreign key constraint
ALTER TABLE fact.stock_holding ADD CONSTRAINT fk_fact_stock_holding_stock_item_key
    FOREIGN KEY (stock_item_key) REFERENCES dimension.stock_item (stock_item_key);

-- Add table and column comments
COMMENT ON TABLE fact.stock_holding IS 'Holdings of stock items';
COMMENT ON COLUMN fact.stock_holding.stock_holding_key IS 'DW key for a row in the Stock Holding fact';
COMMENT ON COLUMN fact.stock_holding.stock_item_key IS 'Stock item being held';
COMMENT ON COLUMN fact.stock_holding.quantity_on_hand IS 'Quantity on hand';
COMMENT ON COLUMN fact.stock_holding.bin_location IS 'Bin location (where is this stock in the warehouse)';
COMMENT ON COLUMN fact.stock_holding.last_stocktake_quantity IS 'Quantity present at last stocktake';
COMMENT ON COLUMN fact.stock_holding.last_cost_price IS 'Unit cost when the stock item was last purchased';
COMMENT ON COLUMN fact.stock_holding.reorder_level IS 'Quantity below which reordering should take place';
COMMENT ON COLUMN fact.stock_holding.target_stock_level IS 'Typical stock level held';
COMMENT ON COLUMN fact.stock_holding.lineage_key IS 'Lineage Key for the data load for this row';
COMMENT ON INDEX ix_fact_stock_holding_stock_item_key IS 'Auto-created to support a foreign key';
