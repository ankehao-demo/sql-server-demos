-- Wide World Importers PostgreSQL Migration
-- Phase 2: OLTP Schema Migration
-- Purchasing.Suppliers table (temporal table)

-- Main table
CREATE TABLE purchasing.suppliers (
    supplier_id INTEGER NOT NULL DEFAULT nextval('sequences.supplier_id'),
    supplier_name VARCHAR(100) NOT NULL,
    supplier_category_id INTEGER NOT NULL,
    primary_contact_person_id INTEGER NOT NULL,
    alternate_contact_person_id INTEGER NOT NULL,
    delivery_method_id INTEGER NULL,
    delivery_city_id INTEGER NOT NULL,
    postal_city_id INTEGER NOT NULL,
    supplier_reference VARCHAR(20) NULL,
    bank_account_name VARCHAR(50) NULL,
    bank_account_branch VARCHAR(50) NULL,
    bank_account_code VARCHAR(20) NULL,
    bank_account_number VARCHAR(20) NULL,
    bank_international_code VARCHAR(20) NULL,
    payment_days INTEGER NOT NULL,
    internal_comments TEXT NULL,
    phone_number VARCHAR(20) NOT NULL,
    fax_number VARCHAR(20) NOT NULL,
    website_url VARCHAR(256) NOT NULL,
    delivery_address_line1 VARCHAR(60) NOT NULL,
    delivery_address_line2 VARCHAR(60) NULL,
    delivery_postal_code VARCHAR(10) NOT NULL,
    delivery_location GEOGRAPHY(Point, 4326) NULL,
    postal_address_line1 VARCHAR(60) NOT NULL,
    postal_address_line2 VARCHAR(60) NULL,
    postal_postal_code VARCHAR(10) NOT NULL,
    last_edited_by INTEGER NOT NULL,
    valid_from TIMESTAMP NOT NULL DEFAULT clock_timestamp(),
    valid_to TIMESTAMP NOT NULL DEFAULT '9999-12-31 23:59:59.999999'::timestamp,
    
    CONSTRAINT pk_purchasing_suppliers PRIMARY KEY (supplier_id),
    CONSTRAINT uq_purchasing_suppliers_supplier_name UNIQUE (supplier_name),
    CONSTRAINT fk_purchasing_suppliers_supplier_category 
        FOREIGN KEY (supplier_category_id) REFERENCES purchasing.supplier_categories(supplier_category_id),
    CONSTRAINT fk_purchasing_suppliers_primary_contact_person 
        FOREIGN KEY (primary_contact_person_id) REFERENCES application.people(person_id),
    CONSTRAINT fk_purchasing_suppliers_alternate_contact_person 
        FOREIGN KEY (alternate_contact_person_id) REFERENCES application.people(person_id),
    CONSTRAINT fk_purchasing_suppliers_delivery_method 
        FOREIGN KEY (delivery_method_id) REFERENCES application.delivery_methods(delivery_method_id),
    CONSTRAINT fk_purchasing_suppliers_delivery_city 
        FOREIGN KEY (delivery_city_id) REFERENCES application.cities(city_id),
    CONSTRAINT fk_purchasing_suppliers_postal_city 
        FOREIGN KEY (postal_city_id) REFERENCES application.cities(city_id),
    CONSTRAINT fk_purchasing_suppliers_last_edited_by 
        FOREIGN KEY (last_edited_by) REFERENCES application.people(person_id)
);

-- History/Archive table for temporal data
CREATE TABLE purchasing.suppliers_archive (
    supplier_id INTEGER NOT NULL,
    supplier_name VARCHAR(100) NOT NULL,
    supplier_category_id INTEGER NOT NULL,
    primary_contact_person_id INTEGER NOT NULL,
    alternate_contact_person_id INTEGER NOT NULL,
    delivery_method_id INTEGER NULL,
    delivery_city_id INTEGER NOT NULL,
    postal_city_id INTEGER NOT NULL,
    supplier_reference VARCHAR(20) NULL,
    bank_account_name VARCHAR(50) NULL,
    bank_account_branch VARCHAR(50) NULL,
    bank_account_code VARCHAR(20) NULL,
    bank_account_number VARCHAR(20) NULL,
    bank_international_code VARCHAR(20) NULL,
    payment_days INTEGER NOT NULL,
    internal_comments TEXT NULL,
    phone_number VARCHAR(20) NOT NULL,
    fax_number VARCHAR(20) NOT NULL,
    website_url VARCHAR(256) NOT NULL,
    delivery_address_line1 VARCHAR(60) NOT NULL,
    delivery_address_line2 VARCHAR(60) NULL,
    delivery_postal_code VARCHAR(10) NOT NULL,
    delivery_location GEOGRAPHY(Point, 4326) NULL,
    postal_address_line1 VARCHAR(60) NOT NULL,
    postal_address_line2 VARCHAR(60) NULL,
    postal_postal_code VARCHAR(10) NOT NULL,
    last_edited_by INTEGER NOT NULL,
    valid_from TIMESTAMP NOT NULL,
    valid_to TIMESTAMP NOT NULL,
    
    CONSTRAINT pk_purchasing_suppliers_archive PRIMARY KEY (supplier_id, valid_from)
);

-- Indexes for foreign keys
CREATE INDEX ix_purchasing_suppliers_supplier_category_id 
    ON purchasing.suppliers(supplier_category_id);
CREATE INDEX ix_purchasing_suppliers_primary_contact_person_id 
    ON purchasing.suppliers(primary_contact_person_id);
CREATE INDEX ix_purchasing_suppliers_alternate_contact_person_id 
    ON purchasing.suppliers(alternate_contact_person_id);
CREATE INDEX ix_purchasing_suppliers_delivery_method_id 
    ON purchasing.suppliers(delivery_method_id);
CREATE INDEX ix_purchasing_suppliers_delivery_city_id 
    ON purchasing.suppliers(delivery_city_id);
CREATE INDEX ix_purchasing_suppliers_postal_city_id 
    ON purchasing.suppliers(postal_city_id);
