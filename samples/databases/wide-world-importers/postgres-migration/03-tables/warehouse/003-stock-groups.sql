-- Wide World Importers PostgreSQL Migration
-- Phase 2: OLTP Schema Migration
-- Warehouse.StockGroups table (temporal table)

-- Main table
CREATE TABLE warehouse.stock_groups (
    stock_group_id INTEGER NOT NULL DEFAULT nextval('sequences.stock_group_id'),
    stock_group_name VARCHAR(50) NOT NULL,
    last_edited_by INTEGER NOT NULL,
    valid_from TIMESTAMP NOT NULL DEFAULT clock_timestamp(),
    valid_to TIMESTAMP NOT NULL DEFAULT '9999-12-31 23:59:59.999999'::timestamp,
    
    CONSTRAINT pk_warehouse_stock_groups PRIMARY KEY (stock_group_id),
    CONSTRAINT uq_warehouse_stock_groups_stock_group_name UNIQUE (stock_group_name),
    CONSTRAINT fk_warehouse_stock_groups_last_edited_by 
        FOREIGN KEY (last_edited_by) REFERENCES application.people(person_id)
);

-- History/Archive table for temporal data
CREATE TABLE warehouse.stock_groups_archive (
    stock_group_id INTEGER NOT NULL,
    stock_group_name VARCHAR(50) NOT NULL,
    last_edited_by INTEGER NOT NULL,
    valid_from TIMESTAMP NOT NULL,
    valid_to TIMESTAMP NOT NULL,
    
    CONSTRAINT pk_warehouse_stock_groups_archive PRIMARY KEY (stock_group_id, valid_from)
);
