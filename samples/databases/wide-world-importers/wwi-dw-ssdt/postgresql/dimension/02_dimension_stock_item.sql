-- Wide World Importers Data Warehouse - PostgreSQL Schema Migration
-- Phase 4: OLAP Schema Migration
-- Dimension: Stock Item

CREATE TABLE dimension.stock_item (
    stock_item_key              INTEGER NOT NULL DEFAULT nextval('sequences.stock_item_key'),
    wwi_stock_item_id           INTEGER NOT NULL,
    stock_item                  VARCHAR(100) NOT NULL,
    color                       VARCHAR(20) NOT NULL,
    selling_package             VARCHAR(50) NOT NULL,
    buying_package              VARCHAR(50) NOT NULL,
    brand                       VARCHAR(50) NOT NULL,
    size                        VARCHAR(20) NOT NULL,
    lead_time_days              INTEGER NOT NULL,
    quantity_per_outer          INTEGER NOT NULL,
    is_chiller_stock            BOOLEAN NOT NULL,
    barcode                     VARCHAR(50),
    tax_rate                    DECIMAL(18, 3) NOT NULL,
    unit_price                  DECIMAL(18, 2) NOT NULL,
    recommended_retail_price    DECIMAL(18, 2),
    typical_weight_per_unit     DECIMAL(18, 3) NOT NULL,
    photo                       BYTEA,
    valid_from                  TIMESTAMP NOT NULL,
    valid_to                    TIMESTAMP NOT NULL,
    lineage_key                 INTEGER NOT NULL,

    CONSTRAINT pk_dimension_stock_item PRIMARY KEY (stock_item_key)
);

-- Create index for WWI Stock Item ID lookups (SCD Type 2 pattern)
CREATE INDEX ix_dimension_stock_item_wwi_stock_item_id 
    ON dimension.stock_item (wwi_stock_item_id, valid_from, valid_to);

-- Add table and column comments
COMMENT ON TABLE dimension.stock_item IS 'StockItem dimension';
COMMENT ON COLUMN dimension.stock_item.stock_item_key IS 'DW key for the stock item dimension';
COMMENT ON COLUMN dimension.stock_item.wwi_stock_item_id IS 'Numeric ID used for reference to a stock item within the WWI database';
COMMENT ON COLUMN dimension.stock_item.stock_item IS 'Full name of a stock item (but not a full description)';
COMMENT ON COLUMN dimension.stock_item.color IS 'Color (optional) for this stock item';
COMMENT ON COLUMN dimension.stock_item.selling_package IS 'Usual package for selling units of this stock item';
COMMENT ON COLUMN dimension.stock_item.buying_package IS 'Usual package for selling outers of this stock item (ie cartons, boxes, etc.)';
COMMENT ON COLUMN dimension.stock_item.brand IS 'Brand for the stock item (if the item is branded)';
COMMENT ON COLUMN dimension.stock_item.size IS 'Size of this item (eg: 100mm)';
COMMENT ON COLUMN dimension.stock_item.lead_time_days IS 'Number of days typically taken from order to receipt of this stock item';
COMMENT ON COLUMN dimension.stock_item.quantity_per_outer IS 'Quantity of the stock item in an outer package';
COMMENT ON COLUMN dimension.stock_item.is_chiller_stock IS 'Does this stock item need to be in a chiller?';
COMMENT ON COLUMN dimension.stock_item.barcode IS 'Barcode for this stock item';
COMMENT ON COLUMN dimension.stock_item.tax_rate IS 'Tax rate to be applied';
COMMENT ON COLUMN dimension.stock_item.unit_price IS 'Selling price (ex-tax) for one unit of this product';
COMMENT ON COLUMN dimension.stock_item.recommended_retail_price IS 'Recommended retail price for this stock item';
COMMENT ON COLUMN dimension.stock_item.typical_weight_per_unit IS 'Typical weight for one unit of this product (packaged)';
COMMENT ON COLUMN dimension.stock_item.photo IS 'Photo of the product';
COMMENT ON COLUMN dimension.stock_item.valid_from IS 'Valid from this date and time';
COMMENT ON COLUMN dimension.stock_item.valid_to IS 'Valid until this date and time';
COMMENT ON COLUMN dimension.stock_item.lineage_key IS 'Lineage Key for the data load for this row';
COMMENT ON INDEX ix_dimension_stock_item_wwi_stock_item_id IS 'Allows quickly locating by WWI ID';
