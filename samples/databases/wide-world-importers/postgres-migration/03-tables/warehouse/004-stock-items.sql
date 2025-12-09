-- Wide World Importers PostgreSQL Migration
-- Phase 2: OLTP Schema Migration
-- Warehouse.StockItems table (temporal table)

-- Main table
CREATE TABLE warehouse.stock_items (
    stock_item_id INTEGER NOT NULL DEFAULT nextval('sequences.stock_item_id'),
    stock_item_name VARCHAR(100) NOT NULL,
    supplier_id INTEGER NOT NULL,
    color_id INTEGER NULL,
    unit_package_id INTEGER NOT NULL,
    outer_package_id INTEGER NOT NULL,
    brand VARCHAR(50) NULL,
    size VARCHAR(20) NULL,
    lead_time_days INTEGER NOT NULL,
    quantity_per_outer INTEGER NOT NULL,
    is_chiller_stock BOOLEAN NOT NULL,
    barcode VARCHAR(50) NULL,
    tax_rate NUMERIC(18, 3) NOT NULL,
    unit_price NUMERIC(18, 2) NOT NULL,
    recommended_retail_price NUMERIC(18, 2) NULL,
    typical_weight_per_unit NUMERIC(18, 3) NOT NULL,
    marketing_comments TEXT NULL,
    internal_comments TEXT NULL,
    photo BYTEA NULL,
    custom_fields JSONB NULL,
    tags JSONB GENERATED ALWAYS AS (custom_fields -> 'Tags') STORED,
    search_details TEXT GENERATED ALWAYS AS (stock_item_name || ' ' || COALESCE(marketing_comments, '')) STORED,
    last_edited_by INTEGER NOT NULL,
    valid_from TIMESTAMP NOT NULL DEFAULT clock_timestamp(),
    valid_to TIMESTAMP NOT NULL DEFAULT '9999-12-31 23:59:59.999999'::timestamp,
    
    CONSTRAINT pk_warehouse_stock_items PRIMARY KEY (stock_item_id),
    CONSTRAINT uq_warehouse_stock_items_stock_item_name UNIQUE (stock_item_name),
    CONSTRAINT fk_warehouse_stock_items_supplier 
        FOREIGN KEY (supplier_id) REFERENCES purchasing.suppliers(supplier_id),
    CONSTRAINT fk_warehouse_stock_items_color 
        FOREIGN KEY (color_id) REFERENCES warehouse.colors(color_id),
    CONSTRAINT fk_warehouse_stock_items_unit_package 
        FOREIGN KEY (unit_package_id) REFERENCES warehouse.package_types(package_type_id),
    CONSTRAINT fk_warehouse_stock_items_outer_package 
        FOREIGN KEY (outer_package_id) REFERENCES warehouse.package_types(package_type_id),
    CONSTRAINT fk_warehouse_stock_items_last_edited_by 
        FOREIGN KEY (last_edited_by) REFERENCES application.people(person_id)
);

-- History/Archive table for temporal data
CREATE TABLE warehouse.stock_items_archive (
    stock_item_id INTEGER NOT NULL,
    stock_item_name VARCHAR(100) NOT NULL,
    supplier_id INTEGER NOT NULL,
    color_id INTEGER NULL,
    unit_package_id INTEGER NOT NULL,
    outer_package_id INTEGER NOT NULL,
    brand VARCHAR(50) NULL,
    size VARCHAR(20) NULL,
    lead_time_days INTEGER NOT NULL,
    quantity_per_outer INTEGER NOT NULL,
    is_chiller_stock BOOLEAN NOT NULL,
    barcode VARCHAR(50) NULL,
    tax_rate NUMERIC(18, 3) NOT NULL,
    unit_price NUMERIC(18, 2) NOT NULL,
    recommended_retail_price NUMERIC(18, 2) NULL,
    typical_weight_per_unit NUMERIC(18, 3) NOT NULL,
    marketing_comments TEXT NULL,
    internal_comments TEXT NULL,
    photo BYTEA NULL,
    custom_fields JSONB NULL,
    tags JSONB,
    search_details TEXT,
    last_edited_by INTEGER NOT NULL,
    valid_from TIMESTAMP NOT NULL,
    valid_to TIMESTAMP NOT NULL,
    
    CONSTRAINT pk_warehouse_stock_items_archive PRIMARY KEY (stock_item_id, valid_from)
);

-- Indexes for foreign keys
CREATE INDEX ix_warehouse_stock_items_supplier_id 
    ON warehouse.stock_items(supplier_id);
CREATE INDEX ix_warehouse_stock_items_color_id 
    ON warehouse.stock_items(color_id);
CREATE INDEX ix_warehouse_stock_items_unit_package_id 
    ON warehouse.stock_items(unit_package_id);
CREATE INDEX ix_warehouse_stock_items_outer_package_id 
    ON warehouse.stock_items(outer_package_id);
