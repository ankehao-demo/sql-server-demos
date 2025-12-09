-- Wide World Importers PostgreSQL Migration
-- Phase 2: OLTP Schema Migration
-- Sales.Customers table (temporal table)

-- Main table
CREATE TABLE sales.customers (
    customer_id INTEGER NOT NULL DEFAULT nextval('sequences.customer_id'),
    customer_name VARCHAR(100) NOT NULL,
    bill_to_customer_id INTEGER NOT NULL,
    customer_category_id INTEGER NOT NULL,
    buying_group_id INTEGER NULL,
    primary_contact_person_id INTEGER NOT NULL,
    alternate_contact_person_id INTEGER NULL,
    delivery_method_id INTEGER NOT NULL,
    delivery_city_id INTEGER NOT NULL,
    postal_city_id INTEGER NOT NULL,
    credit_limit NUMERIC(18, 2) NULL,
    account_opened_date DATE NOT NULL,
    standard_discount_percentage NUMERIC(18, 3) NOT NULL,
    is_statement_sent BOOLEAN NOT NULL,
    is_on_credit_hold BOOLEAN NOT NULL,
    payment_days INTEGER NOT NULL,
    phone_number VARCHAR(20) NOT NULL,
    fax_number VARCHAR(20) NOT NULL,
    delivery_run VARCHAR(5) NULL,
    run_position VARCHAR(5) NULL,
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
    
    CONSTRAINT pk_sales_customers PRIMARY KEY (customer_id),
    CONSTRAINT uq_sales_customers_customer_name UNIQUE (customer_name),
    CONSTRAINT fk_sales_customers_customer_category 
        FOREIGN KEY (customer_category_id) REFERENCES sales.customer_categories(customer_category_id),
    CONSTRAINT fk_sales_customers_buying_group 
        FOREIGN KEY (buying_group_id) REFERENCES sales.buying_groups(buying_group_id),
    CONSTRAINT fk_sales_customers_primary_contact_person 
        FOREIGN KEY (primary_contact_person_id) REFERENCES application.people(person_id),
    CONSTRAINT fk_sales_customers_alternate_contact_person 
        FOREIGN KEY (alternate_contact_person_id) REFERENCES application.people(person_id),
    CONSTRAINT fk_sales_customers_delivery_method 
        FOREIGN KEY (delivery_method_id) REFERENCES application.delivery_methods(delivery_method_id),
    CONSTRAINT fk_sales_customers_delivery_city 
        FOREIGN KEY (delivery_city_id) REFERENCES application.cities(city_id),
    CONSTRAINT fk_sales_customers_postal_city 
        FOREIGN KEY (postal_city_id) REFERENCES application.cities(city_id),
    CONSTRAINT fk_sales_customers_last_edited_by 
        FOREIGN KEY (last_edited_by) REFERENCES application.people(person_id)
);

-- Self-referential foreign key for bill_to_customer_id
ALTER TABLE sales.customers 
    ADD CONSTRAINT fk_sales_customers_bill_to_customer 
    FOREIGN KEY (bill_to_customer_id) REFERENCES sales.customers(customer_id);

-- History/Archive table for temporal data
CREATE TABLE sales.customers_archive (
    customer_id INTEGER NOT NULL,
    customer_name VARCHAR(100) NOT NULL,
    bill_to_customer_id INTEGER NOT NULL,
    customer_category_id INTEGER NOT NULL,
    buying_group_id INTEGER NULL,
    primary_contact_person_id INTEGER NOT NULL,
    alternate_contact_person_id INTEGER NULL,
    delivery_method_id INTEGER NOT NULL,
    delivery_city_id INTEGER NOT NULL,
    postal_city_id INTEGER NOT NULL,
    credit_limit NUMERIC(18, 2) NULL,
    account_opened_date DATE NOT NULL,
    standard_discount_percentage NUMERIC(18, 3) NOT NULL,
    is_statement_sent BOOLEAN NOT NULL,
    is_on_credit_hold BOOLEAN NOT NULL,
    payment_days INTEGER NOT NULL,
    phone_number VARCHAR(20) NOT NULL,
    fax_number VARCHAR(20) NOT NULL,
    delivery_run VARCHAR(5) NULL,
    run_position VARCHAR(5) NULL,
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
    
    CONSTRAINT pk_sales_customers_archive PRIMARY KEY (customer_id, valid_from)
);

-- Indexes for foreign keys and performance
CREATE INDEX ix_sales_customers_customer_category_id 
    ON sales.customers(customer_category_id);
CREATE INDEX ix_sales_customers_buying_group_id 
    ON sales.customers(buying_group_id);
CREATE INDEX ix_sales_customers_primary_contact_person_id 
    ON sales.customers(primary_contact_person_id);
CREATE INDEX ix_sales_customers_alternate_contact_person_id 
    ON sales.customers(alternate_contact_person_id);
CREATE INDEX ix_sales_customers_delivery_method_id 
    ON sales.customers(delivery_method_id);
CREATE INDEX ix_sales_customers_delivery_city_id 
    ON sales.customers(delivery_city_id);
CREATE INDEX ix_sales_customers_postal_city_id 
    ON sales.customers(postal_city_id);
CREATE INDEX ix_sales_customers_perf 
    ON sales.customers(is_on_credit_hold, customer_id, bill_to_customer_id) 
    INCLUDE (primary_contact_person_id);
