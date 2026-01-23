-- Wide World Importers PostgreSQL Migration
-- Script 004: Create Sales Schema Tables
-- Migrated from SQL Server to PostgreSQL

-- Buying Groups table
CREATE TABLE IF NOT EXISTS sales.buying_groups (
    buying_group_id INTEGER NOT NULL DEFAULT nextval('sales.buying_group_id_seq'),
    buying_group_name VARCHAR(50) NOT NULL,
    last_edited_by INTEGER NOT NULL,
    valid_from TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    valid_to TIMESTAMP(6) NOT NULL DEFAULT '9999-12-31 23:59:59.999999',
    CONSTRAINT pk_sales_buying_groups PRIMARY KEY (buying_group_id),
    CONSTRAINT uq_sales_buying_groups_buying_group_name UNIQUE (buying_group_name),
    CONSTRAINT fk_sales_buying_groups_last_edited_by FOREIGN KEY (last_edited_by) 
        REFERENCES application.people (person_id)
);

-- Buying Groups archive table
CREATE TABLE IF NOT EXISTS sales.buying_groups_archive (
    buying_group_id INTEGER NOT NULL,
    buying_group_name VARCHAR(50) NOT NULL,
    last_edited_by INTEGER NOT NULL,
    valid_from TIMESTAMP(6) NOT NULL,
    valid_to TIMESTAMP(6) NOT NULL
);

-- Customer Categories table
CREATE TABLE IF NOT EXISTS sales.customer_categories (
    customer_category_id INTEGER NOT NULL DEFAULT nextval('sales.customer_category_id_seq'),
    customer_category_name VARCHAR(50) NOT NULL,
    last_edited_by INTEGER NOT NULL,
    valid_from TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    valid_to TIMESTAMP(6) NOT NULL DEFAULT '9999-12-31 23:59:59.999999',
    CONSTRAINT pk_sales_customer_categories PRIMARY KEY (customer_category_id),
    CONSTRAINT uq_sales_customer_categories_customer_category_name UNIQUE (customer_category_name),
    CONSTRAINT fk_sales_customer_categories_last_edited_by FOREIGN KEY (last_edited_by) 
        REFERENCES application.people (person_id)
);

-- Customer Categories archive table
CREATE TABLE IF NOT EXISTS sales.customer_categories_archive (
    customer_category_id INTEGER NOT NULL,
    customer_category_name VARCHAR(50) NOT NULL,
    last_edited_by INTEGER NOT NULL,
    valid_from TIMESTAMP(6) NOT NULL,
    valid_to TIMESTAMP(6) NOT NULL
);

-- Customers table
CREATE TABLE IF NOT EXISTS sales.customers (
    customer_id INTEGER NOT NULL DEFAULT nextval('sales.customer_id_seq'),
    customer_name VARCHAR(100) NOT NULL,
    bill_to_customer_id INTEGER NOT NULL,
    customer_category_id INTEGER NOT NULL,
    buying_group_id INTEGER,
    primary_contact_person_id INTEGER NOT NULL,
    alternate_contact_person_id INTEGER,
    delivery_method_id INTEGER NOT NULL,
    delivery_city_id INTEGER NOT NULL,
    postal_city_id INTEGER NOT NULL,
    credit_limit NUMERIC(18, 2),
    account_opened_date DATE NOT NULL,
    standard_discount_percentage NUMERIC(18, 3) NOT NULL,
    is_statement_sent BOOLEAN NOT NULL,
    is_on_credit_hold BOOLEAN NOT NULL,
    payment_days INTEGER NOT NULL,
    phone_number VARCHAR(20) NOT NULL,
    fax_number VARCHAR(20) NOT NULL,
    delivery_run VARCHAR(5),
    run_position VARCHAR(5),
    website_url VARCHAR(256) NOT NULL,
    delivery_address_line_1 VARCHAR(60) NOT NULL,
    delivery_address_line_2 VARCHAR(60),
    delivery_postal_code VARCHAR(10) NOT NULL,
    delivery_location GEOGRAPHY(POINT, 4326),
    postal_address_line_1 VARCHAR(60) NOT NULL,
    postal_address_line_2 VARCHAR(60),
    postal_postal_code VARCHAR(10) NOT NULL,
    last_edited_by INTEGER NOT NULL,
    valid_from TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    valid_to TIMESTAMP(6) NOT NULL DEFAULT '9999-12-31 23:59:59.999999',
    CONSTRAINT pk_sales_customers PRIMARY KEY (customer_id),
    CONSTRAINT uq_sales_customers_customer_name UNIQUE (customer_name),
    CONSTRAINT fk_sales_customers_bill_to_customer_id FOREIGN KEY (bill_to_customer_id) 
        REFERENCES sales.customers (customer_id),
    CONSTRAINT fk_sales_customers_customer_category_id FOREIGN KEY (customer_category_id) 
        REFERENCES sales.customer_categories (customer_category_id),
    CONSTRAINT fk_sales_customers_buying_group_id FOREIGN KEY (buying_group_id) 
        REFERENCES sales.buying_groups (buying_group_id),
    CONSTRAINT fk_sales_customers_primary_contact_person_id FOREIGN KEY (primary_contact_person_id) 
        REFERENCES application.people (person_id),
    CONSTRAINT fk_sales_customers_alternate_contact_person_id FOREIGN KEY (alternate_contact_person_id) 
        REFERENCES application.people (person_id),
    CONSTRAINT fk_sales_customers_delivery_method_id FOREIGN KEY (delivery_method_id) 
        REFERENCES application.delivery_methods (delivery_method_id),
    CONSTRAINT fk_sales_customers_delivery_city_id FOREIGN KEY (delivery_city_id) 
        REFERENCES application.cities (city_id),
    CONSTRAINT fk_sales_customers_postal_city_id FOREIGN KEY (postal_city_id) 
        REFERENCES application.cities (city_id),
    CONSTRAINT fk_sales_customers_last_edited_by FOREIGN KEY (last_edited_by) 
        REFERENCES application.people (person_id)
);

-- Customers archive table
CREATE TABLE IF NOT EXISTS sales.customers_archive (
    customer_id INTEGER NOT NULL,
    customer_name VARCHAR(100) NOT NULL,
    bill_to_customer_id INTEGER NOT NULL,
    customer_category_id INTEGER NOT NULL,
    buying_group_id INTEGER,
    primary_contact_person_id INTEGER NOT NULL,
    alternate_contact_person_id INTEGER,
    delivery_method_id INTEGER NOT NULL,
    delivery_city_id INTEGER NOT NULL,
    postal_city_id INTEGER NOT NULL,
    credit_limit NUMERIC(18, 2),
    account_opened_date DATE NOT NULL,
    standard_discount_percentage NUMERIC(18, 3) NOT NULL,
    is_statement_sent BOOLEAN NOT NULL,
    is_on_credit_hold BOOLEAN NOT NULL,
    payment_days INTEGER NOT NULL,
    phone_number VARCHAR(20) NOT NULL,
    fax_number VARCHAR(20) NOT NULL,
    delivery_run VARCHAR(5),
    run_position VARCHAR(5),
    website_url VARCHAR(256) NOT NULL,
    delivery_address_line_1 VARCHAR(60) NOT NULL,
    delivery_address_line_2 VARCHAR(60),
    delivery_postal_code VARCHAR(10) NOT NULL,
    delivery_location GEOGRAPHY(POINT, 4326),
    postal_address_line_1 VARCHAR(60) NOT NULL,
    postal_address_line_2 VARCHAR(60),
    postal_postal_code VARCHAR(10) NOT NULL,
    last_edited_by INTEGER NOT NULL,
    valid_from TIMESTAMP(6) NOT NULL,
    valid_to TIMESTAMP(6) NOT NULL
);

-- Orders table
CREATE TABLE IF NOT EXISTS sales.orders (
    order_id INTEGER NOT NULL DEFAULT nextval('sales.order_id_seq'),
    customer_id INTEGER NOT NULL,
    salesperson_person_id INTEGER NOT NULL,
    picked_by_person_id INTEGER,
    contact_person_id INTEGER NOT NULL,
    backorder_order_id INTEGER,
    order_date DATE NOT NULL,
    expected_delivery_date DATE NOT NULL,
    customer_purchase_order_number VARCHAR(20),
    is_undersupply_backordered BOOLEAN NOT NULL,
    comments TEXT,
    delivery_instructions TEXT,
    internal_comments TEXT,
    picking_completed_when TIMESTAMP(6),
    last_edited_by INTEGER NOT NULL,
    last_edited_when TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT pk_sales_orders PRIMARY KEY (order_id),
    CONSTRAINT fk_sales_orders_customer_id FOREIGN KEY (customer_id) 
        REFERENCES sales.customers (customer_id),
    CONSTRAINT fk_sales_orders_salesperson_person_id FOREIGN KEY (salesperson_person_id) 
        REFERENCES application.people (person_id),
    CONSTRAINT fk_sales_orders_picked_by_person_id FOREIGN KEY (picked_by_person_id) 
        REFERENCES application.people (person_id),
    CONSTRAINT fk_sales_orders_contact_person_id FOREIGN KEY (contact_person_id) 
        REFERENCES application.people (person_id),
    CONSTRAINT fk_sales_orders_backorder_order_id FOREIGN KEY (backorder_order_id) 
        REFERENCES sales.orders (order_id),
    CONSTRAINT fk_sales_orders_last_edited_by FOREIGN KEY (last_edited_by) 
        REFERENCES application.people (person_id)
);

-- Order Lines table
CREATE TABLE IF NOT EXISTS sales.order_lines (
    order_line_id INTEGER NOT NULL DEFAULT nextval('sales.order_line_id_seq'),
    order_id INTEGER NOT NULL,
    stock_item_id INTEGER NOT NULL,
    description VARCHAR(100) NOT NULL,
    package_type_id INTEGER NOT NULL,
    quantity INTEGER NOT NULL,
    unit_price NUMERIC(18, 2),
    tax_rate NUMERIC(18, 3) NOT NULL,
    picked_quantity INTEGER NOT NULL,
    picking_completed_when TIMESTAMP(6),
    last_edited_by INTEGER NOT NULL,
    last_edited_when TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT pk_sales_order_lines PRIMARY KEY (order_line_id),
    CONSTRAINT fk_sales_order_lines_order_id FOREIGN KEY (order_id) 
        REFERENCES sales.orders (order_id),
    CONSTRAINT fk_sales_order_lines_last_edited_by FOREIGN KEY (last_edited_by) 
        REFERENCES application.people (person_id)
);

-- Invoices table
CREATE TABLE IF NOT EXISTS sales.invoices (
    invoice_id INTEGER NOT NULL DEFAULT nextval('sales.invoice_id_seq'),
    customer_id INTEGER NOT NULL,
    bill_to_customer_id INTEGER NOT NULL,
    order_id INTEGER,
    delivery_method_id INTEGER NOT NULL,
    contact_person_id INTEGER NOT NULL,
    accounts_person_id INTEGER NOT NULL,
    salesperson_person_id INTEGER NOT NULL,
    packed_by_person_id INTEGER NOT NULL,
    invoice_date DATE NOT NULL,
    customer_purchase_order_number VARCHAR(20),
    is_credit_note BOOLEAN NOT NULL,
    credit_note_reason TEXT,
    comments TEXT,
    delivery_instructions TEXT,
    internal_comments TEXT,
    total_dry_items INTEGER NOT NULL,
    total_chiller_items INTEGER NOT NULL,
    delivery_run VARCHAR(5),
    run_position VARCHAR(5),
    returned_delivery_data TEXT,
    confirmed_delivery_time TIMESTAMP(6),
    confirmed_received_by VARCHAR(4000),
    last_edited_by INTEGER NOT NULL,
    last_edited_when TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT pk_sales_invoices PRIMARY KEY (invoice_id),
    CONSTRAINT fk_sales_invoices_customer_id FOREIGN KEY (customer_id) 
        REFERENCES sales.customers (customer_id),
    CONSTRAINT fk_sales_invoices_bill_to_customer_id FOREIGN KEY (bill_to_customer_id) 
        REFERENCES sales.customers (customer_id),
    CONSTRAINT fk_sales_invoices_order_id FOREIGN KEY (order_id) 
        REFERENCES sales.orders (order_id),
    CONSTRAINT fk_sales_invoices_delivery_method_id FOREIGN KEY (delivery_method_id) 
        REFERENCES application.delivery_methods (delivery_method_id),
    CONSTRAINT fk_sales_invoices_contact_person_id FOREIGN KEY (contact_person_id) 
        REFERENCES application.people (person_id),
    CONSTRAINT fk_sales_invoices_accounts_person_id FOREIGN KEY (accounts_person_id) 
        REFERENCES application.people (person_id),
    CONSTRAINT fk_sales_invoices_salesperson_person_id FOREIGN KEY (salesperson_person_id) 
        REFERENCES application.people (person_id),
    CONSTRAINT fk_sales_invoices_packed_by_person_id FOREIGN KEY (packed_by_person_id) 
        REFERENCES application.people (person_id),
    CONSTRAINT fk_sales_invoices_last_edited_by FOREIGN KEY (last_edited_by) 
        REFERENCES application.people (person_id)
);

-- Invoice Lines table
CREATE TABLE IF NOT EXISTS sales.invoice_lines (
    invoice_line_id INTEGER NOT NULL DEFAULT nextval('sales.invoice_line_id_seq'),
    invoice_id INTEGER NOT NULL,
    stock_item_id INTEGER NOT NULL,
    description VARCHAR(100) NOT NULL,
    package_type_id INTEGER NOT NULL,
    quantity INTEGER NOT NULL,
    unit_price NUMERIC(18, 2),
    tax_rate NUMERIC(18, 3) NOT NULL,
    tax_amount NUMERIC(18, 2) NOT NULL,
    line_profit NUMERIC(18, 2) NOT NULL,
    extended_price NUMERIC(18, 2) NOT NULL,
    last_edited_by INTEGER NOT NULL,
    last_edited_when TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT pk_sales_invoice_lines PRIMARY KEY (invoice_line_id),
    CONSTRAINT fk_sales_invoice_lines_invoice_id FOREIGN KEY (invoice_id) 
        REFERENCES sales.invoices (invoice_id),
    CONSTRAINT fk_sales_invoice_lines_last_edited_by FOREIGN KEY (last_edited_by) 
        REFERENCES application.people (person_id)
);

-- Customer Transactions table
CREATE TABLE IF NOT EXISTS sales.customer_transactions (
    customer_transaction_id INTEGER NOT NULL DEFAULT nextval('sales.transaction_id_seq'),
    customer_id INTEGER NOT NULL,
    transaction_type_id INTEGER NOT NULL,
    invoice_id INTEGER,
    payment_method_id INTEGER,
    transaction_date DATE NOT NULL,
    amount_excluding_tax NUMERIC(18, 2) NOT NULL,
    tax_amount NUMERIC(18, 2) NOT NULL,
    transaction_amount NUMERIC(18, 2) NOT NULL,
    outstanding_balance NUMERIC(18, 2) NOT NULL,
    finalization_date DATE,
    is_finalized BOOLEAN GENERATED ALWAYS AS (finalization_date IS NOT NULL) STORED,
    last_edited_by INTEGER NOT NULL,
    last_edited_when TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT pk_sales_customer_transactions PRIMARY KEY (customer_transaction_id),
    CONSTRAINT fk_sales_customer_transactions_customer_id FOREIGN KEY (customer_id) 
        REFERENCES sales.customers (customer_id),
    CONSTRAINT fk_sales_customer_transactions_transaction_type_id FOREIGN KEY (transaction_type_id) 
        REFERENCES application.transaction_types (transaction_type_id),
    CONSTRAINT fk_sales_customer_transactions_invoice_id FOREIGN KEY (invoice_id) 
        REFERENCES sales.invoices (invoice_id),
    CONSTRAINT fk_sales_customer_transactions_payment_method_id FOREIGN KEY (payment_method_id) 
        REFERENCES application.payment_methods (payment_method_id),
    CONSTRAINT fk_sales_customer_transactions_last_edited_by FOREIGN KEY (last_edited_by) 
        REFERENCES application.people (person_id)
);

-- Special Deals table
CREATE TABLE IF NOT EXISTS sales.special_deals (
    special_deal_id INTEGER NOT NULL DEFAULT nextval('sales.special_deal_id_seq'),
    stock_item_id INTEGER,
    customer_id INTEGER,
    buying_group_id INTEGER,
    customer_category_id INTEGER,
    stock_group_id INTEGER,
    deal_description VARCHAR(30) NOT NULL,
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    discount_amount NUMERIC(18, 2),
    discount_percentage NUMERIC(18, 3),
    unit_price NUMERIC(18, 2),
    last_edited_by INTEGER NOT NULL,
    last_edited_when TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT pk_sales_special_deals PRIMARY KEY (special_deal_id),
    CONSTRAINT fk_sales_special_deals_customer_id FOREIGN KEY (customer_id) 
        REFERENCES sales.customers (customer_id),
    CONSTRAINT fk_sales_special_deals_buying_group_id FOREIGN KEY (buying_group_id) 
        REFERENCES sales.buying_groups (buying_group_id),
    CONSTRAINT fk_sales_special_deals_customer_category_id FOREIGN KEY (customer_category_id) 
        REFERENCES sales.customer_categories (customer_category_id),
    CONSTRAINT fk_sales_special_deals_last_edited_by FOREIGN KEY (last_edited_by) 
        REFERENCES application.people (person_id),
    CONSTRAINT ck_sales_special_deals_unit_price_discount 
        CHECK ((discount_amount IS NOT NULL AND discount_percentage IS NULL AND unit_price IS NULL)
            OR (discount_amount IS NULL AND discount_percentage IS NOT NULL AND unit_price IS NULL)
            OR (discount_amount IS NULL AND discount_percentage IS NULL AND unit_price IS NOT NULL))
);

-- Add comments for documentation
COMMENT ON TABLE sales.buying_groups IS 'Customer buying groups (e.g., Tailspin Toys)';
COMMENT ON TABLE sales.customer_categories IS 'Categories for customers (e.g., Novelty Shop, Supermarket)';
COMMENT ON TABLE sales.customers IS 'Main entity tables for customers (organizations or individuals)';
COMMENT ON TABLE sales.orders IS 'Detail of customer orders';
COMMENT ON TABLE sales.order_lines IS 'Detail of customer order lines';
COMMENT ON TABLE sales.invoices IS 'Details of customer invoices';
COMMENT ON TABLE sales.invoice_lines IS 'Detail of customer invoice lines';
COMMENT ON TABLE sales.customer_transactions IS 'All financial transactions that are customer-related';
COMMENT ON TABLE sales.special_deals IS 'Special pricing deals (can apply to customers, buying groups, customer categories, or stock items)';
