-- Wide World Importers PostgreSQL Migration
-- Phase 2: OLTP Schema Migration
-- Sales.BuyingGroups table (temporal table)

-- Main table
CREATE TABLE sales.buying_groups (
    buying_group_id INTEGER NOT NULL DEFAULT nextval('sequences.buying_group_id'),
    buying_group_name VARCHAR(50) NOT NULL,
    last_edited_by INTEGER NOT NULL,
    valid_from TIMESTAMP NOT NULL DEFAULT clock_timestamp(),
    valid_to TIMESTAMP NOT NULL DEFAULT '9999-12-31 23:59:59.999999'::timestamp,
    
    CONSTRAINT pk_sales_buying_groups PRIMARY KEY (buying_group_id),
    CONSTRAINT uq_sales_buying_groups_buying_group_name UNIQUE (buying_group_name),
    CONSTRAINT fk_sales_buying_groups_last_edited_by 
        FOREIGN KEY (last_edited_by) REFERENCES application.people(person_id)
);

-- History/Archive table for temporal data
CREATE TABLE sales.buying_groups_archive (
    buying_group_id INTEGER NOT NULL,
    buying_group_name VARCHAR(50) NOT NULL,
    last_edited_by INTEGER NOT NULL,
    valid_from TIMESTAMP NOT NULL,
    valid_to TIMESTAMP NOT NULL,
    
    CONSTRAINT pk_sales_buying_groups_archive PRIMARY KEY (buying_group_id, valid_from)
);
