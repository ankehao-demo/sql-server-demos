-- Wide World Importers PostgreSQL Migration
-- Phase 2: OLTP Schema Migration
-- Script 005: Purchasing Schema Tables
-- Migrated from SQL Server to PostgreSQL

-- =============================================
-- Purchasing.SupplierCategories Table
-- =============================================
CREATE TABLE purchasing.supplier_categories (
    supplier_category_id integer NOT NULL DEFAULT nextval('sequences.supplier_category_id'),
    supplier_category_name varchar(50) NOT NULL,
    last_edited_by integer NOT NULL,
    valid_from timestamp NOT NULL DEFAULT clock_timestamp(),
    valid_to timestamp NOT NULL DEFAULT '9999-12-31 23:59:59.9999999'::timestamp,
    CONSTRAINT pk_purchasing_supplier_categories PRIMARY KEY (supplier_category_id),
    CONSTRAINT uq_purchasing_supplier_categories_supplier_category_name UNIQUE (supplier_category_name)
);

-- History table for temporal data
CREATE TABLE purchasing.supplier_categories_archive (
    supplier_category_id integer NOT NULL,
    supplier_category_name varchar(50) NOT NULL,
    last_edited_by integer NOT NULL,
    valid_from timestamp NOT NULL,
    valid_to timestamp NOT NULL
);

-- Comments
COMMENT ON TABLE purchasing.supplier_categories IS 'Categories for suppliers (such as novelty goods, clothing, packaging, etc.)';
COMMENT ON COLUMN purchasing.supplier_categories.supplier_category_id IS 'Numeric ID used for reference to a supplier category within the database';
COMMENT ON COLUMN purchasing.supplier_categories.supplier_category_name IS 'Full name of the category that suppliers can be assigned to';

-- =============================================
-- Purchasing.Suppliers Table
-- =============================================
CREATE TABLE purchasing.suppliers (
    supplier_id integer NOT NULL DEFAULT nextval('sequences.supplier_id'),
    supplier_name varchar(100) NOT NULL,
    supplier_category_id integer NOT NULL,
    primary_contact_person_id integer NOT NULL,
    alternate_contact_person_id integer NULL,
    delivery_method_id integer NULL,
    delivery_city_id integer NOT NULL,
    postal_city_id integer NOT NULL,
    supplier_reference varchar(20) NULL,
    bank_account_name varchar(50) NULL,
    bank_account_branch varchar(50) NULL,
    bank_account_code varchar(20) NULL,
    bank_account_number varchar(20) NULL,
    bank_international_code varchar(20) NULL,
    payment_days integer NOT NULL,
    internal_comments text NULL,
    phone_number varchar(20) NOT NULL,
    fax_number varchar(20) NOT NULL,
    website_url varchar(256) NOT NULL,
    delivery_address_line_1 varchar(60) NOT NULL,
    delivery_address_line_2 varchar(60) NULL,
    delivery_postal_code varchar(10) NOT NULL,
    delivery_location geometry NULL,
    postal_address_line_1 varchar(60) NOT NULL,
    postal_address_line_2 varchar(60) NULL,
    postal_postal_code varchar(10) NOT NULL,
    last_edited_by integer NOT NULL,
    valid_from timestamp NOT NULL DEFAULT clock_timestamp(),
    valid_to timestamp NOT NULL DEFAULT '9999-12-31 23:59:59.9999999'::timestamp,
    CONSTRAINT pk_purchasing_suppliers PRIMARY KEY (supplier_id),
    CONSTRAINT uq_purchasing_suppliers_supplier_name UNIQUE (supplier_name)
);

-- History table for temporal data
CREATE TABLE purchasing.suppliers_archive (
    supplier_id integer NOT NULL,
    supplier_name varchar(100) NOT NULL,
    supplier_category_id integer NOT NULL,
    primary_contact_person_id integer NOT NULL,
    alternate_contact_person_id integer NULL,
    delivery_method_id integer NULL,
    delivery_city_id integer NOT NULL,
    postal_city_id integer NOT NULL,
    supplier_reference varchar(20) NULL,
    bank_account_name varchar(50) NULL,
    bank_account_branch varchar(50) NULL,
    bank_account_code varchar(20) NULL,
    bank_account_number varchar(20) NULL,
    bank_international_code varchar(20) NULL,
    payment_days integer NOT NULL,
    internal_comments text NULL,
    phone_number varchar(20) NOT NULL,
    fax_number varchar(20) NOT NULL,
    website_url varchar(256) NOT NULL,
    delivery_address_line_1 varchar(60) NOT NULL,
    delivery_address_line_2 varchar(60) NULL,
    delivery_postal_code varchar(10) NOT NULL,
    delivery_location geometry NULL,
    postal_address_line_1 varchar(60) NOT NULL,
    postal_address_line_2 varchar(60) NULL,
    postal_postal_code varchar(10) NOT NULL,
    last_edited_by integer NOT NULL,
    valid_from timestamp NOT NULL,
    valid_to timestamp NOT NULL
);

-- Indexes
CREATE INDEX fk_purchasing_suppliers_supplier_category_id ON purchasing.suppliers(supplier_category_id);
CREATE INDEX fk_purchasing_suppliers_primary_contact_person_id ON purchasing.suppliers(primary_contact_person_id);
CREATE INDEX fk_purchasing_suppliers_alternate_contact_person_id ON purchasing.suppliers(alternate_contact_person_id);
CREATE INDEX fk_purchasing_suppliers_delivery_method_id ON purchasing.suppliers(delivery_method_id);
CREATE INDEX fk_purchasing_suppliers_delivery_city_id ON purchasing.suppliers(delivery_city_id);
CREATE INDEX fk_purchasing_suppliers_postal_city_id ON purchasing.suppliers(postal_city_id);

-- Comments
COMMENT ON TABLE purchasing.suppliers IS 'Main entity table for suppliers (organizations)';
COMMENT ON COLUMN purchasing.suppliers.supplier_id IS 'Numeric ID used for reference to a supplier within the database';
COMMENT ON COLUMN purchasing.suppliers.supplier_name IS 'Supplier''s full name (usually a trading name)';
COMMENT ON COLUMN purchasing.suppliers.supplier_category_id IS 'Supplier''s category';
COMMENT ON COLUMN purchasing.suppliers.primary_contact_person_id IS 'Primary contact';
COMMENT ON COLUMN purchasing.suppliers.alternate_contact_person_id IS 'Alternate contact';
COMMENT ON COLUMN purchasing.suppliers.delivery_method_id IS 'Standard delivery method for stock items received from this supplier';
COMMENT ON COLUMN purchasing.suppliers.delivery_city_id IS 'ID of the delivery city for this address';
COMMENT ON COLUMN purchasing.suppliers.postal_city_id IS 'ID of the postal city for this address';
COMMENT ON COLUMN purchasing.suppliers.supplier_reference IS 'Supplier reference for our organization (might be our account number at the supplier)';
COMMENT ON COLUMN purchasing.suppliers.bank_account_name IS 'Supplier''s bank account name (ie name on the account)';
COMMENT ON COLUMN purchasing.suppliers.bank_account_branch IS 'Supplier''s bank branch';
COMMENT ON COLUMN purchasing.suppliers.bank_account_code IS 'Supplier''s bank account code (usually a national bank code)';
COMMENT ON COLUMN purchasing.suppliers.bank_account_number IS 'Supplier''s bank account number';
COMMENT ON COLUMN purchasing.suppliers.bank_international_code IS 'Supplier''s bank''s international code (such as a SWIFT code)';
COMMENT ON COLUMN purchasing.suppliers.payment_days IS 'Number of days for payment of an invoice (ie payment terms)';
COMMENT ON COLUMN purchasing.suppliers.internal_comments IS 'Internal comments (not exposed outside organization)';
COMMENT ON COLUMN purchasing.suppliers.phone_number IS 'Phone number';
COMMENT ON COLUMN purchasing.suppliers.fax_number IS 'Fax number';
COMMENT ON COLUMN purchasing.suppliers.website_url IS 'URL for the website for this supplier';
COMMENT ON COLUMN purchasing.suppliers.delivery_address_line_1 IS 'First delivery address line for the supplier';
COMMENT ON COLUMN purchasing.suppliers.delivery_address_line_2 IS 'Second delivery address line for the supplier';
COMMENT ON COLUMN purchasing.suppliers.delivery_postal_code IS 'Delivery postal code for the supplier';
COMMENT ON COLUMN purchasing.suppliers.delivery_location IS 'Geographic location for the supplier''s office/warehouse';

-- =============================================
-- Purchasing.PurchaseOrders Table
-- =============================================
CREATE TABLE purchasing.purchase_orders (
    purchase_order_id integer NOT NULL DEFAULT nextval('sequences.purchase_order_id'),
    supplier_id integer NOT NULL,
    order_date date NOT NULL,
    delivery_method_id integer NOT NULL,
    contact_person_id integer NOT NULL,
    expected_delivery_date date NULL,
    supplier_reference varchar(20) NULL,
    is_order_finalized boolean NOT NULL,
    comments text NULL,
    internal_comments text NULL,
    last_edited_by integer NOT NULL,
    last_edited_when timestamp NOT NULL DEFAULT clock_timestamp(),
    CONSTRAINT pk_purchasing_purchase_orders PRIMARY KEY (purchase_order_id)
);

-- Indexes
CREATE INDEX fk_purchasing_purchase_orders_supplier_id ON purchasing.purchase_orders(supplier_id);
CREATE INDEX fk_purchasing_purchase_orders_delivery_method_id ON purchasing.purchase_orders(delivery_method_id);
CREATE INDEX fk_purchasing_purchase_orders_contact_person_id ON purchasing.purchase_orders(contact_person_id);
CREATE INDEX ix_purchasing_purchase_orders_order_date ON purchasing.purchase_orders(order_date);

-- Comments
COMMENT ON TABLE purchasing.purchase_orders IS 'Details of supplier purchase orders';
COMMENT ON COLUMN purchasing.purchase_orders.purchase_order_id IS 'Numeric ID used for reference to a purchase order within the database';
COMMENT ON COLUMN purchasing.purchase_orders.supplier_id IS 'Supplier for this purchase order';
COMMENT ON COLUMN purchasing.purchase_orders.order_date IS 'Date that this purchase order was raised';
COMMENT ON COLUMN purchasing.purchase_orders.delivery_method_id IS 'How this purchase order should be delivered';
COMMENT ON COLUMN purchasing.purchase_orders.contact_person_id IS 'The person who is the primary contact for this purchase order';
COMMENT ON COLUMN purchasing.purchase_orders.expected_delivery_date IS 'Expected delivery date for this purchase order';
COMMENT ON COLUMN purchasing.purchase_orders.supplier_reference IS 'Reference number provided by the supplier';
COMMENT ON COLUMN purchasing.purchase_orders.is_order_finalized IS 'Is this purchase order now considered finalized?';
COMMENT ON COLUMN purchasing.purchase_orders.comments IS 'Any comments related to this purchase order (sent to supplier)';
COMMENT ON COLUMN purchasing.purchase_orders.internal_comments IS 'Any internal comments related to this purchase order (not sent to the supplier)';

-- =============================================
-- Purchasing.PurchaseOrderLines Table
-- =============================================
CREATE TABLE purchasing.purchase_order_lines (
    purchase_order_line_id integer NOT NULL DEFAULT nextval('sequences.purchase_order_line_id'),
    purchase_order_id integer NOT NULL,
    stock_item_id integer NOT NULL,
    ordered_outers integer NOT NULL,
    description varchar(100) NOT NULL,
    received_outers integer NOT NULL,
    package_type_id integer NOT NULL,
    expected_unit_price_per_outer numeric(18, 2) NULL,
    last_receipt_date date NULL,
    is_order_line_finalized boolean NOT NULL,
    last_edited_by integer NOT NULL,
    last_edited_when timestamp NOT NULL DEFAULT clock_timestamp(),
    CONSTRAINT pk_purchasing_purchase_order_lines PRIMARY KEY (purchase_order_line_id)
);

-- Indexes
CREATE INDEX fk_purchasing_purchase_order_lines_purchase_order_id ON purchasing.purchase_order_lines(purchase_order_id);
CREATE INDEX fk_purchasing_purchase_order_lines_stock_item_id ON purchasing.purchase_order_lines(stock_item_id);
CREATE INDEX fk_purchasing_purchase_order_lines_package_type_id ON purchasing.purchase_order_lines(package_type_id);
CREATE INDEX ix_purchasing_purchase_order_lines_perf_20160301_04 ON purchasing.purchase_order_lines(is_order_line_finalized, stock_item_id) INCLUDE (ordered_outers, received_outers);

-- Comments
COMMENT ON TABLE purchasing.purchase_order_lines IS 'Detail lines from supplier purchase orders';
COMMENT ON COLUMN purchasing.purchase_order_lines.purchase_order_line_id IS 'Numeric ID used for reference to a line on a purchase order within the database';
COMMENT ON COLUMN purchasing.purchase_order_lines.purchase_order_id IS 'Purchase order that this line is associated with';
COMMENT ON COLUMN purchasing.purchase_order_lines.stock_item_id IS 'Stock item for this purchase order line';
COMMENT ON COLUMN purchasing.purchase_order_lines.ordered_outers IS 'Quantity of the stock item that is ordered';
COMMENT ON COLUMN purchasing.purchase_order_lines.description IS 'Description of the item to be supplied (Usually the stock item name but can be overridden)';
COMMENT ON COLUMN purchasing.purchase_order_lines.received_outers IS 'Total quantity of the stock item that has been received so far';
COMMENT ON COLUMN purchasing.purchase_order_lines.package_type_id IS 'Type of package received';
COMMENT ON COLUMN purchasing.purchase_order_lines.expected_unit_price_per_outer IS 'The unit price that we expect to be charged';
COMMENT ON COLUMN purchasing.purchase_order_lines.last_receipt_date IS 'The last date on which this stock item was received for this purchase order';
COMMENT ON COLUMN purchasing.purchase_order_lines.is_order_line_finalized IS 'Is this purchase order line now considered finalized? (Receipts are complete)';

-- =============================================
-- Purchasing.SupplierTransactions Table
-- =============================================
CREATE TABLE purchasing.supplier_transactions (
    supplier_transaction_id integer NOT NULL DEFAULT nextval('sequences.transaction_id'),
    supplier_id integer NOT NULL,
    transaction_type_id integer NOT NULL,
    purchase_order_id integer NULL,
    payment_method_id integer NULL,
    supplier_invoice_number varchar(20) NULL,
    transaction_date date NOT NULL,
    amount_excluding_tax numeric(18, 2) NOT NULL,
    tax_amount numeric(18, 2) NOT NULL,
    transaction_amount numeric(18, 2) NOT NULL,
    outstanding_balance numeric(18, 2) NOT NULL,
    finalization_date date NULL,
    is_finalized boolean GENERATED ALWAYS AS (finalization_date IS NOT NULL) STORED,
    last_edited_by integer NOT NULL,
    last_edited_when timestamp NOT NULL DEFAULT clock_timestamp(),
    CONSTRAINT pk_purchasing_supplier_transactions PRIMARY KEY (supplier_transaction_id)
);

-- Indexes
CREATE INDEX fk_purchasing_supplier_transactions_supplier_id ON purchasing.supplier_transactions(supplier_id);
CREATE INDEX fk_purchasing_supplier_transactions_transaction_type_id ON purchasing.supplier_transactions(transaction_type_id);
CREATE INDEX fk_purchasing_supplier_transactions_purchase_order_id ON purchasing.supplier_transactions(purchase_order_id);
CREATE INDEX fk_purchasing_supplier_transactions_payment_method_id ON purchasing.supplier_transactions(payment_method_id);
CREATE INDEX ix_purchasing_supplier_transactions_is_finalized ON purchasing.supplier_transactions(is_finalized);

-- Comments
COMMENT ON TABLE purchasing.supplier_transactions IS 'All financial transactions that are supplier-related';
COMMENT ON COLUMN purchasing.supplier_transactions.supplier_transaction_id IS 'Numeric ID used to refer to a supplier transaction within the database';
COMMENT ON COLUMN purchasing.supplier_transactions.supplier_id IS 'Supplier for this transaction';
COMMENT ON COLUMN purchasing.supplier_transactions.transaction_type_id IS 'Type of transaction';
COMMENT ON COLUMN purchasing.supplier_transactions.purchase_order_id IS 'ID of an purchase order (for transactions associated with a purchase order)';
COMMENT ON COLUMN purchasing.supplier_transactions.payment_method_id IS 'ID of a payment method (for transactions involving payments)';
COMMENT ON COLUMN purchasing.supplier_transactions.supplier_invoice_number IS 'Invoice number for an invoice received from the supplier';
COMMENT ON COLUMN purchasing.supplier_transactions.transaction_date IS 'Date for the transaction';
COMMENT ON COLUMN purchasing.supplier_transactions.amount_excluding_tax IS 'Transaction amount (excluding tax)';
COMMENT ON COLUMN purchasing.supplier_transactions.tax_amount IS 'Tax amount calculated';
COMMENT ON COLUMN purchasing.supplier_transactions.transaction_amount IS 'Transaction amount (including tax)';
COMMENT ON COLUMN purchasing.supplier_transactions.outstanding_balance IS 'Amount still outstanding for this transaction';
COMMENT ON COLUMN purchasing.supplier_transactions.finalization_date IS 'Date that this transaction was finalized (if it has been)';
COMMENT ON COLUMN purchasing.supplier_transactions.is_finalized IS 'Is this transaction finalized (invoices, credits and payments have been matched)';
