-- Wide World Importers PostgreSQL Migration
-- Phase 2: OLTP Schema Migration
-- Warehouse.PackageTypes table (temporal table)

-- Main table
CREATE TABLE warehouse.package_types (
    package_type_id INTEGER NOT NULL DEFAULT nextval('sequences.package_type_id'),
    package_type_name VARCHAR(50) NOT NULL,
    last_edited_by INTEGER NOT NULL,
    valid_from TIMESTAMP NOT NULL DEFAULT clock_timestamp(),
    valid_to TIMESTAMP NOT NULL DEFAULT '9999-12-31 23:59:59.999999'::timestamp,
    
    CONSTRAINT pk_warehouse_package_types PRIMARY KEY (package_type_id),
    CONSTRAINT uq_warehouse_package_types_package_type_name UNIQUE (package_type_name),
    CONSTRAINT fk_warehouse_package_types_last_edited_by 
        FOREIGN KEY (last_edited_by) REFERENCES application.people(person_id)
);

-- History/Archive table for temporal data
CREATE TABLE warehouse.package_types_archive (
    package_type_id INTEGER NOT NULL,
    package_type_name VARCHAR(50) NOT NULL,
    last_edited_by INTEGER NOT NULL,
    valid_from TIMESTAMP NOT NULL,
    valid_to TIMESTAMP NOT NULL,
    
    CONSTRAINT pk_warehouse_package_types_archive PRIMARY KEY (package_type_id, valid_from)
);
