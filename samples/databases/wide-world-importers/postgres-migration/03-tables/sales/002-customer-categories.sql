-- Wide World Importers PostgreSQL Migration
-- Phase 2: OLTP Schema Migration
-- Sales.CustomerCategories table (temporal table)

-- Main table
CREATE TABLE sales.customer_categories (
    customer_category_id INTEGER NOT NULL DEFAULT nextval('sequences.customer_category_id'),
    customer_category_name VARCHAR(50) NOT NULL,
    last_edited_by INTEGER NOT NULL,
    valid_from TIMESTAMP NOT NULL DEFAULT clock_timestamp(),
    valid_to TIMESTAMP NOT NULL DEFAULT '9999-12-31 23:59:59.999999'::timestamp,
    
    CONSTRAINT pk_sales_customer_categories PRIMARY KEY (customer_category_id),
    CONSTRAINT uq_sales_customer_categories_customer_category_name UNIQUE (customer_category_name),
    CONSTRAINT fk_sales_customer_categories_last_edited_by 
        FOREIGN KEY (last_edited_by) REFERENCES application.people(person_id)
);

-- History/Archive table for temporal data
CREATE TABLE sales.customer_categories_archive (
    customer_category_id INTEGER NOT NULL,
    customer_category_name VARCHAR(50) NOT NULL,
    last_edited_by INTEGER NOT NULL,
    valid_from TIMESTAMP NOT NULL,
    valid_to TIMESTAMP NOT NULL,
    
    CONSTRAINT pk_sales_customer_categories_archive PRIMARY KEY (customer_category_id, valid_from)
);
