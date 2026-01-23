-- Wide World Importers PostgreSQL Migration
-- Script 005: Create Purchasing Schema Tables
-- Migrated from SQL Server to PostgreSQL

-- Supplier Categories table
CREATE TABLE IF NOT EXISTS purchasing.supplier_categories (
    supplier_category_id INTEGER NOT NULL DEFAULT nextval('purchasing.supplier_category_id_seq'),
    supplier_category_name VARCHAR(50) NOT NULL,
    last_edited_by INTEGER NOT NULL,
    valid_from TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    valid_to TIMESTAMP(6) NOT NULL DEFAULT '9999-12-31 23:59:59.999999',
    CONSTRAINT pk_purchasing_supplier_categories PRIMARY KEY (supplier_category_id),
    CONSTRAINT uq_purchasing_supplier_categories_supplier_category_name UNIQUE (supplier_category_name),
    CONSTRAINT fk_purchasing_supplier_categories_last_edited_by FOREIGN KEY (last_edited_by) 
        REFERENCES application.people (person_id)
);

-- Supplier Categories archive table
CREATE TABLE IF NOT EXISTS purchasing.supplier_categories_archive (
    supplier_category_id INTEGER NOT NULL,
    supplier_category_name VARCHAR(50) NOT NULL,
    last_edited_by INTEGER NOT NULL,
    valid_from TIMESTAMP(6) NOT NULL,
    valid_to TIMESTAMP(6) NOT NULL
);

-- Suppliers table
CREATE TABLE IF NOT EXISTS purchasing.suppliers (
    supplier_id INTEGER NOT NULL DEFAULT nextval('purchasing.supplier_id_seq'),
    supplier_name VARCHAR(100) NOT NULL,
    supplier_category_id INTEGER NOT NULL,
    primary_contact_person_id INTEGER NOT NULL,
    alternate_contact_person_id INTEGER,
    delivery_method_id INTEGER,
    delivery_city_id INTEGER NOT NULL,
    postal_city_id INTEGER NOT NULL,
    supplier_reference VARCHAR(20),
    bank_account_name VARCHAR(50),
    bank_account_branch VARCHAR(50),
    bank_account_code VARCHAR(20),
    bank_account_number VARCHAR(20),
    bank_international_code VARCHAR(20),
    payment_days INTEGER NOT NULL,
    internal_comments TEXT,
    phone_number VARCHAR(20) NOT NULL,
    fax_number VARCHAR(20) NOT NULL,
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
    CONSTRAINT pk_purchasing_suppliers PRIMARY KEY (supplier_id),
    CONSTRAINT uq_purchasing_suppliers_supplier_name UNIQUE (supplier_name),
    CONSTRAINT fk_purchasing_suppliers_supplier_category_id FOREIGN KEY (supplier_category_id) 
        REFERENCES purchasing.supplier_categories (supplier_category_id),
    CONSTRAINT fk_purchasing_suppliers_primary_contact_person_id FOREIGN KEY (primary_contact_person_id) 
        REFERENCES application.people (person_id),
    CONSTRAINT fk_purchasing_suppliers_alternate_contact_person_id FOREIGN KEY (alternate_contact_person_id) 
        REFERENCES application.people (person_id),
    CONSTRAINT fk_purchasing_suppliers_delivery_method_id FOREIGN KEY (delivery_method_id) 
        REFERENCES application.delivery_methods (delivery_method_id),
    CONSTRAINT fk_purchasing_suppliers_delivery_city_id FOREIGN KEY (delivery_city_id) 
        REFERENCES application.cities (city_id),
    CONSTRAINT fk_purchasing_suppliers_postal_city_id FOREIGN KEY (postal_city_id) 
        REFERENCES application.cities (city_id),
    CONSTRAINT fk_purchasing_suppliers_last_edited_by FOREIGN KEY (last_edited_by) 
        REFERENCES application.people (person_id)
);

-- Suppliers archive table
CREATE TABLE IF NOT EXISTS purchasing.suppliers_archive (
    supplier_id INTEGER NOT NULL,
    supplier_name VARCHAR(100) NOT NULL,
    supplier_category_id INTEGER NOT NULL,
    primary_contact_person_id INTEGER NOT NULL,
    alternate_contact_person_id INTEGER,
    delivery_method_id INTEGER,
    delivery_city_id INTEGER NOT NULL,
    postal_city_id INTEGER NOT NULL,
    supplier_reference VARCHAR(20),
    bank_account_name VARCHAR(50),
    bank_account_branch VARCHAR(50),
    bank_account_code VARCHAR(20),
    bank_account_number VARCHAR(20),
    bank_international_code VARCHAR(20),
    payment_days INTEGER NOT NULL,
    internal_comments TEXT,
    phone_number VARCHAR(20) NOT NULL,
    fax_number VARCHAR(20) NOT NULL,
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

-- Purchase Orders table
CREATE TABLE IF NOT EXISTS purchasing.purchase_orders (
    purchase_order_id INTEGER NOT NULL DEFAULT nextval('purchasing.purchase_order_id_seq'),
    supplier_id INTEGER NOT NULL,
    order_date DATE NOT NULL,
    delivery_method_id INTEGER NOT NULL,
    contact_person_id INTEGER NOT NULL,
    expected_delivery_date DATE,
    supplier_reference VARCHAR(20),
    is_order_finalized BOOLEAN NOT NULL,
    comments TEXT,
    internal_comments TEXT,
    last_edited_by INTEGER NOT NULL,
    last_edited_when TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT pk_purchasing_purchase_orders PRIMARY KEY (purchase_order_id),
    CONSTRAINT fk_purchasing_purchase_orders_supplier_id FOREIGN KEY (supplier_id) 
        REFERENCES purchasing.suppliers (supplier_id),
    CONSTRAINT fk_purchasing_purchase_orders_delivery_method_id FOREIGN KEY (delivery_method_id) 
        REFERENCES application.delivery_methods (delivery_method_id),
    CONSTRAINT fk_purchasing_purchase_orders_contact_person_id FOREIGN KEY (contact_person_id) 
        REFERENCES application.people (person_id),
    CONSTRAINT fk_purchasing_purchase_orders_last_edited_by FOREIGN KEY (last_edited_by) 
        REFERENCES application.people (person_id)
);

-- Purchase Order Lines table
CREATE TABLE IF NOT EXISTS purchasing.purchase_order_lines (
    purchase_order_line_id INTEGER NOT NULL DEFAULT nextval('purchasing.purchase_order_line_id_seq'),
    purchase_order_id INTEGER NOT NULL,
    stock_item_id INTEGER NOT NULL,
    ordered_outers INTEGER NOT NULL,
    description VARCHAR(100) NOT NULL,
    received_outers INTEGER NOT NULL,
    package_type_id INTEGER NOT NULL,
    expected_unit_price_per_outer NUMERIC(18, 2),
    last_receipt_date DATE,
    is_order_line_finalized BOOLEAN NOT NULL,
    last_edited_by INTEGER NOT NULL,
    last_edited_when TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT pk_purchasing_purchase_order_lines PRIMARY KEY (purchase_order_line_id),
    CONSTRAINT fk_purchasing_purchase_order_lines_purchase_order_id FOREIGN KEY (purchase_order_id) 
        REFERENCES purchasing.purchase_orders (purchase_order_id),
    CONSTRAINT fk_purchasing_purchase_order_lines_last_edited_by FOREIGN KEY (last_edited_by) 
        REFERENCES application.people (person_id)
);

-- Supplier Transactions table
CREATE TABLE IF NOT EXISTS purchasing.supplier_transactions (
    supplier_transaction_id INTEGER NOT NULL DEFAULT nextval('sales.transaction_id_seq'),
    supplier_id INTEGER NOT NULL,
    transaction_type_id INTEGER NOT NULL,
    purchase_order_id INTEGER,
    payment_method_id INTEGER,
    supplier_invoice_number VARCHAR(20),
    transaction_date DATE NOT NULL,
    amount_excluding_tax NUMERIC(18, 2) NOT NULL,
    tax_amount NUMERIC(18, 2) NOT NULL,
    transaction_amount NUMERIC(18, 2) NOT NULL,
    outstanding_balance NUMERIC(18, 2) NOT NULL,
    finalization_date DATE,
    is_finalized BOOLEAN GENERATED ALWAYS AS (finalization_date IS NOT NULL) STORED,
    last_edited_by INTEGER NOT NULL,
    last_edited_when TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT pk_purchasing_supplier_transactions PRIMARY KEY (supplier_transaction_id),
    CONSTRAINT fk_purchasing_supplier_transactions_supplier_id FOREIGN KEY (supplier_id) 
        REFERENCES purchasing.suppliers (supplier_id),
    CONSTRAINT fk_purchasing_supplier_transactions_transaction_type_id FOREIGN KEY (transaction_type_id) 
        REFERENCES application.transaction_types (transaction_type_id),
    CONSTRAINT fk_purchasing_supplier_transactions_purchase_order_id FOREIGN KEY (purchase_order_id) 
        REFERENCES purchasing.purchase_orders (purchase_order_id),
    CONSTRAINT fk_purchasing_supplier_transactions_payment_method_id FOREIGN KEY (payment_method_id) 
        REFERENCES application.payment_methods (payment_method_id),
    CONSTRAINT fk_purchasing_supplier_transactions_last_edited_by FOREIGN KEY (last_edited_by) 
        REFERENCES application.people (person_id)
);

-- Add comments for documentation
COMMENT ON TABLE purchasing.supplier_categories IS 'Categories for suppliers (e.g., novelty goods, clothing, packaging)';
COMMENT ON TABLE purchasing.suppliers IS 'Main entity table for suppliers (organizations)';
COMMENT ON TABLE purchasing.purchase_orders IS 'Detail of supplier purchase orders';
COMMENT ON TABLE purchasing.purchase_order_lines IS 'Detail of supplier purchase order lines';
COMMENT ON TABLE purchasing.supplier_transactions IS 'All financial transactions that are supplier-related';
