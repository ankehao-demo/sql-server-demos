-- Wide World Importers PostgreSQL Migration
-- Phase 2: OLTP Schema Migration
-- Warehouse.Colors table (temporal table)

-- Main table
CREATE TABLE warehouse.colors (
    color_id INTEGER NOT NULL DEFAULT nextval('sequences.color_id'),
    color_name VARCHAR(20) NOT NULL,
    last_edited_by INTEGER NOT NULL,
    valid_from TIMESTAMP NOT NULL DEFAULT clock_timestamp(),
    valid_to TIMESTAMP NOT NULL DEFAULT '9999-12-31 23:59:59.999999'::timestamp,
    
    CONSTRAINT pk_warehouse_colors PRIMARY KEY (color_id),
    CONSTRAINT uq_warehouse_colors_color_name UNIQUE (color_name),
    CONSTRAINT fk_warehouse_colors_last_edited_by 
        FOREIGN KEY (last_edited_by) REFERENCES application.people(person_id)
);

-- History/Archive table for temporal data
CREATE TABLE warehouse.colors_archive (
    color_id INTEGER NOT NULL,
    color_name VARCHAR(20) NOT NULL,
    last_edited_by INTEGER NOT NULL,
    valid_from TIMESTAMP NOT NULL,
    valid_to TIMESTAMP NOT NULL,
    
    CONSTRAINT pk_warehouse_colors_archive PRIMARY KEY (color_id, valid_from)
);
