-- Wide World Importers PostgreSQL Migration
-- Phase 2: OLTP Schema Migration
-- Purchasing.SupplierCategories table (temporal table)

-- Main table
CREATE TABLE purchasing.supplier_categories (
    supplier_category_id INTEGER NOT NULL DEFAULT nextval('sequences.supplier_category_id'),
    supplier_category_name VARCHAR(50) NOT NULL,
    last_edited_by INTEGER NOT NULL,
    valid_from TIMESTAMP NOT NULL DEFAULT clock_timestamp(),
    valid_to TIMESTAMP NOT NULL DEFAULT '9999-12-31 23:59:59.999999'::timestamp,
    
    CONSTRAINT pk_purchasing_supplier_categories PRIMARY KEY (supplier_category_id),
    CONSTRAINT uq_purchasing_supplier_categories_supplier_category_name UNIQUE (supplier_category_name),
    CONSTRAINT fk_purchasing_supplier_categories_last_edited_by 
        FOREIGN KEY (last_edited_by) REFERENCES application.people(person_id)
);

-- History/Archive table for temporal data
CREATE TABLE purchasing.supplier_categories_archive (
    supplier_category_id INTEGER NOT NULL,
    supplier_category_name VARCHAR(50) NOT NULL,
    last_edited_by INTEGER NOT NULL,
    valid_from TIMESTAMP NOT NULL,
    valid_to TIMESTAMP NOT NULL,
    
    CONSTRAINT pk_purchasing_supplier_categories_archive PRIMARY KEY (supplier_category_id, valid_from)
);
