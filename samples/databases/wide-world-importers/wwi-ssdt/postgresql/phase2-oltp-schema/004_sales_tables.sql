-- Wide World Importers PostgreSQL Migration
-- Phase 2: OLTP Schema Migration
-- Script 004: Sales Schema Tables
-- Migrated from SQL Server to PostgreSQL

-- =============================================
-- Sales.BuyingGroups Table
-- =============================================
CREATE TABLE sales.buying_groups (
    buying_group_id integer NOT NULL DEFAULT nextval('sequences.buying_group_id'),
    buying_group_name varchar(50) NOT NULL,
    last_edited_by integer NOT NULL,
    valid_from timestamp NOT NULL DEFAULT clock_timestamp(),
    valid_to timestamp NOT NULL DEFAULT '9999-12-31 23:59:59.9999999'::timestamp,
    CONSTRAINT pk_sales_buying_groups PRIMARY KEY (buying_group_id),
    CONSTRAINT uq_sales_buying_groups_buying_group_name UNIQUE (buying_group_name)
);

-- History table for temporal data
CREATE TABLE sales.buying_groups_archive (
    buying_group_id integer NOT NULL,
    buying_group_name varchar(50) NOT NULL,
    last_edited_by integer NOT NULL,
    valid_from timestamp NOT NULL,
    valid_to timestamp NOT NULL
);

-- Comments
COMMENT ON TABLE sales.buying_groups IS 'Customer organizations can be part of groups that exert greater buying power';
COMMENT ON COLUMN sales.buying_groups.buying_group_id IS 'Numeric ID used for reference to a buying group within the database';
COMMENT ON COLUMN sales.buying_groups.buying_group_name IS 'Full name of a buying group that customers can be members of';

-- =============================================
-- Sales.CustomerCategories Table
-- =============================================
CREATE TABLE sales.customer_categories (
    customer_category_id integer NOT NULL DEFAULT nextval('sequences.customer_category_id'),
    customer_category_name varchar(50) NOT NULL,
    last_edited_by integer NOT NULL,
    valid_from timestamp NOT NULL DEFAULT clock_timestamp(),
    valid_to timestamp NOT NULL DEFAULT '9999-12-31 23:59:59.9999999'::timestamp,
    CONSTRAINT pk_sales_customer_categories PRIMARY KEY (customer_category_id),
    CONSTRAINT uq_sales_customer_categories_customer_category_name UNIQUE (customer_category_name)
);

-- History table for temporal data
CREATE TABLE sales.customer_categories_archive (
    customer_category_id integer NOT NULL,
    customer_category_name varchar(50) NOT NULL,
    last_edited_by integer NOT NULL,
    valid_from timestamp NOT NULL,
    valid_to timestamp NOT NULL
);

-- Comments
COMMENT ON TABLE sales.customer_categories IS 'Categories for customers (such as novelty store, supermarket, etc.)';
COMMENT ON COLUMN sales.customer_categories.customer_category_id IS 'Numeric ID used for reference to a customer category within the database';
COMMENT ON COLUMN sales.customer_categories.customer_category_name IS 'Full name of the category that customers can be assigned to';

-- =============================================
-- Sales.Customers Table
-- =============================================
CREATE TABLE sales.customers (
    customer_id integer NOT NULL DEFAULT nextval('sequences.customer_id'),
    customer_name varchar(100) NOT NULL,
    bill_to_customer_id integer NOT NULL,
    customer_category_id integer NOT NULL,
    buying_group_id integer NULL,
    primary_contact_person_id integer NOT NULL,
    alternate_contact_person_id integer NULL,
    delivery_method_id integer NOT NULL,
    delivery_city_id integer NOT NULL,
    postal_city_id integer NOT NULL,
    credit_limit numeric(18, 2) NULL,
    account_opened_date date NOT NULL,
    standard_discount_percentage numeric(18, 3) NOT NULL,
    is_statement_sent boolean NOT NULL,
    is_on_credit_hold boolean NOT NULL,
    payment_days integer NOT NULL,
    phone_number varchar(20) NOT NULL,
    fax_number varchar(20) NOT NULL,
    delivery_run varchar(5) NULL,
    run_position varchar(5) NULL,
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
    CONSTRAINT pk_sales_customers PRIMARY KEY (customer_id),
    CONSTRAINT uq_sales_customers_customer_name UNIQUE (customer_name)
);

-- History table for temporal data
CREATE TABLE sales.customers_archive (
    customer_id integer NOT NULL,
    customer_name varchar(100) NOT NULL,
    bill_to_customer_id integer NOT NULL,
    customer_category_id integer NOT NULL,
    buying_group_id integer NULL,
    primary_contact_person_id integer NOT NULL,
    alternate_contact_person_id integer NULL,
    delivery_method_id integer NOT NULL,
    delivery_city_id integer NOT NULL,
    postal_city_id integer NOT NULL,
    credit_limit numeric(18, 2) NULL,
    account_opened_date date NOT NULL,
    standard_discount_percentage numeric(18, 3) NOT NULL,
    is_statement_sent boolean NOT NULL,
    is_on_credit_hold boolean NOT NULL,
    payment_days integer NOT NULL,
    phone_number varchar(20) NOT NULL,
    fax_number varchar(20) NOT NULL,
    delivery_run varchar(5) NULL,
    run_position varchar(5) NULL,
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
CREATE INDEX fk_sales_customers_customer_category_id ON sales.customers(customer_category_id);
CREATE INDEX fk_sales_customers_buying_group_id ON sales.customers(buying_group_id);
CREATE INDEX fk_sales_customers_primary_contact_person_id ON sales.customers(primary_contact_person_id);
CREATE INDEX fk_sales_customers_alternate_contact_person_id ON sales.customers(alternate_contact_person_id);
CREATE INDEX fk_sales_customers_delivery_method_id ON sales.customers(delivery_method_id);
CREATE INDEX fk_sales_customers_delivery_city_id ON sales.customers(delivery_city_id);
CREATE INDEX fk_sales_customers_postal_city_id ON sales.customers(postal_city_id);
CREATE INDEX ix_sales_customers_perf_20160301_06 ON sales.customers(is_on_credit_hold, customer_id, bill_to_customer_id) INCLUDE (primary_contact_person_id);

-- Comments
COMMENT ON TABLE sales.customers IS 'Main entity tables for customers (organizations or individuals)';
COMMENT ON COLUMN sales.customers.customer_id IS 'Numeric ID used for reference to a customer within the database';
COMMENT ON COLUMN sales.customers.customer_name IS 'Customer''s full name (usually a trading name)';
COMMENT ON COLUMN sales.customers.bill_to_customer_id IS 'Customer that this is billed to (usually the same customer but can be another parent company)';
COMMENT ON COLUMN sales.customers.customer_category_id IS 'Customer''s category';
COMMENT ON COLUMN sales.customers.buying_group_id IS 'Customer''s buying group (optional)';
COMMENT ON COLUMN sales.customers.primary_contact_person_id IS 'Primary contact';
COMMENT ON COLUMN sales.customers.alternate_contact_person_id IS 'Alternate contact';
COMMENT ON COLUMN sales.customers.delivery_method_id IS 'Standard delivery method for stock items sent to this customer';
COMMENT ON COLUMN sales.customers.delivery_city_id IS 'ID of the delivery city for this address';
COMMENT ON COLUMN sales.customers.postal_city_id IS 'ID of the postal city for this address';
COMMENT ON COLUMN sales.customers.credit_limit IS 'Credit limit for this customer (NULL if unlimited)';
COMMENT ON COLUMN sales.customers.account_opened_date IS 'Date this customer account was opened';
COMMENT ON COLUMN sales.customers.standard_discount_percentage IS 'Standard discount offered to this customer';
COMMENT ON COLUMN sales.customers.is_statement_sent IS 'Is a statement sent to this customer? (Or do they just pay on each invoice?)';
COMMENT ON COLUMN sales.customers.is_on_credit_hold IS 'Is this customer on credit hold? (Prevents further deliveries to this customer)';
COMMENT ON COLUMN sales.customers.payment_days IS 'Number of days for payment of an invoice (ie payment terms)';
COMMENT ON COLUMN sales.customers.phone_number IS 'Phone number';
COMMENT ON COLUMN sales.customers.fax_number IS 'Fax number';
COMMENT ON COLUMN sales.customers.delivery_run IS 'Normal delivery run for this customer';
COMMENT ON COLUMN sales.customers.run_position IS 'Normal position in the delivery run for this customer';
COMMENT ON COLUMN sales.customers.website_url IS 'URL for the website for this customer';
COMMENT ON COLUMN sales.customers.delivery_address_line_1 IS 'First delivery address line for the customer';
COMMENT ON COLUMN sales.customers.delivery_address_line_2 IS 'Second delivery address line for the customer';
COMMENT ON COLUMN sales.customers.delivery_postal_code IS 'Delivery postal code for the customer';
COMMENT ON COLUMN sales.customers.delivery_location IS 'Geographic location for the customer''s office/warehouse';

-- =============================================
-- Sales.Orders Table
-- =============================================
CREATE TABLE sales.orders (
    order_id integer NOT NULL DEFAULT nextval('sequences.order_id'),
    customer_id integer NOT NULL,
    salesperson_person_id integer NOT NULL,
    picked_by_person_id integer NULL,
    contact_person_id integer NOT NULL,
    backorder_order_id integer NULL,
    order_date date NOT NULL,
    expected_delivery_date date NOT NULL,
    customer_purchase_order_number varchar(20) NULL,
    is_undersupply_backordered boolean NOT NULL,
    comments text NULL,
    delivery_instructions text NULL,
    internal_comments text NULL,
    picking_completed_when timestamp NULL,
    last_edited_by integer NOT NULL,
    last_edited_when timestamp NOT NULL DEFAULT clock_timestamp(),
    CONSTRAINT pk_sales_orders PRIMARY KEY (order_id)
);

-- Indexes
CREATE INDEX fk_sales_orders_customer_id ON sales.orders(customer_id);
CREATE INDEX fk_sales_orders_salesperson_person_id ON sales.orders(salesperson_person_id);
CREATE INDEX fk_sales_orders_picked_by_person_id ON sales.orders(picked_by_person_id);
CREATE INDEX fk_sales_orders_contact_person_id ON sales.orders(contact_person_id);
CREATE INDEX fk_sales_orders_backorder_order_id ON sales.orders(backorder_order_id);
CREATE INDEX ix_sales_orders_order_date ON sales.orders(order_date);

-- Comments
COMMENT ON TABLE sales.orders IS 'Detail of customer orders';
COMMENT ON COLUMN sales.orders.order_id IS 'Numeric ID used for reference to an order within the database';
COMMENT ON COLUMN sales.orders.customer_id IS 'Customer for this order';
COMMENT ON COLUMN sales.orders.salesperson_person_id IS 'Salesperson for this order';
COMMENT ON COLUMN sales.orders.picked_by_person_id IS 'Person who picked this shipment';
COMMENT ON COLUMN sales.orders.contact_person_id IS 'Customer contact for this order';
COMMENT ON COLUMN sales.orders.backorder_order_id IS 'If this order is a backorder, ID of the original order';
COMMENT ON COLUMN sales.orders.order_date IS 'Date that this order was raised';
COMMENT ON COLUMN sales.orders.expected_delivery_date IS 'Expected delivery date';
COMMENT ON COLUMN sales.orders.customer_purchase_order_number IS 'Purchase Order Number received from customer';
COMMENT ON COLUMN sales.orders.is_undersupply_backordered IS 'If items cannot be supplied are they backordered?';
COMMENT ON COLUMN sales.orders.comments IS 'Any comments related to this order (sent to customer)';
COMMENT ON COLUMN sales.orders.delivery_instructions IS 'Any comments related to order delivery (sent to customer)';
COMMENT ON COLUMN sales.orders.internal_comments IS 'Any internal comments related to this order (not sent to the customer)';
COMMENT ON COLUMN sales.orders.picking_completed_when IS 'When was picking of the entire order completed?';

-- =============================================
-- Sales.OrderLines Table
-- =============================================
CREATE TABLE sales.order_lines (
    order_line_id integer NOT NULL DEFAULT nextval('sequences.order_line_id'),
    order_id integer NOT NULL,
    stock_item_id integer NOT NULL,
    description varchar(100) NOT NULL,
    package_type_id integer NOT NULL,
    quantity integer NOT NULL,
    unit_price numeric(18, 2) NULL,
    tax_rate numeric(18, 3) NOT NULL,
    picked_quantity integer NOT NULL,
    picking_completed_when timestamp NULL,
    last_edited_by integer NOT NULL,
    last_edited_when timestamp NOT NULL DEFAULT clock_timestamp(),
    CONSTRAINT pk_sales_order_lines PRIMARY KEY (order_line_id)
);

-- Indexes
CREATE INDEX fk_sales_order_lines_order_id ON sales.order_lines(order_id);
CREATE INDEX fk_sales_order_lines_stock_item_id ON sales.order_lines(stock_item_id);
CREATE INDEX fk_sales_order_lines_package_type_id ON sales.order_lines(package_type_id);
CREATE INDEX ix_sales_order_lines_perf_20160301_01 ON sales.order_lines(picking_completed_when, order_id, order_line_id) INCLUDE (quantity, stock_item_id);
CREATE INDEX ix_sales_order_lines_perf_20160301_02 ON sales.order_lines(stock_item_id, picking_completed_when) INCLUDE (order_id, picked_quantity);

-- Comments
COMMENT ON TABLE sales.order_lines IS 'Detail lines from customer orders';
COMMENT ON COLUMN sales.order_lines.order_line_id IS 'Numeric ID used for reference to a line on an order within the database';
COMMENT ON COLUMN sales.order_lines.order_id IS 'Order that this line is associated with';
COMMENT ON COLUMN sales.order_lines.stock_item_id IS 'Stock item for this order line (FK not enforced if order is a backorder line)';
COMMENT ON COLUMN sales.order_lines.description IS 'Description of the item supplied (Usually the stock item name but can be overridden)';
COMMENT ON COLUMN sales.order_lines.package_type_id IS 'Type of package to be supplied';
COMMENT ON COLUMN sales.order_lines.quantity IS 'Quantity to be supplied';
COMMENT ON COLUMN sales.order_lines.unit_price IS 'Unit price to be charged';
COMMENT ON COLUMN sales.order_lines.tax_rate IS 'Tax rate to be applied';
COMMENT ON COLUMN sales.order_lines.picked_quantity IS 'Quantity picked from stock';
COMMENT ON COLUMN sales.order_lines.picking_completed_when IS 'When was picking of this line completed?';

-- =============================================
-- Sales.Invoices Table
-- =============================================
CREATE TABLE sales.invoices (
    invoice_id integer NOT NULL DEFAULT nextval('sequences.invoice_id'),
    customer_id integer NOT NULL,
    bill_to_customer_id integer NOT NULL,
    order_id integer NULL,
    delivery_method_id integer NOT NULL,
    contact_person_id integer NOT NULL,
    accounts_person_id integer NOT NULL,
    salesperson_person_id integer NOT NULL,
    packed_by_person_id integer NOT NULL,
    invoice_date date NOT NULL,
    customer_purchase_order_number varchar(20) NULL,
    is_credit_note boolean NOT NULL,
    credit_note_reason text NULL,
    comments text NULL,
    delivery_instructions text NULL,
    internal_comments text NULL,
    total_dry_items integer NOT NULL,
    total_chiller_items integer NOT NULL,
    delivery_run varchar(5) NULL,
    run_position varchar(5) NULL,
    returned_delivery_data text NULL,
    confirmed_delivery_time timestamp NULL,
    confirmed_received_by varchar(4000) NULL,
    last_edited_by integer NOT NULL,
    last_edited_when timestamp NOT NULL DEFAULT clock_timestamp(),
    CONSTRAINT pk_sales_invoices PRIMARY KEY (invoice_id)
);

-- Indexes
CREATE INDEX fk_sales_invoices_customer_id ON sales.invoices(customer_id);
CREATE INDEX fk_sales_invoices_bill_to_customer_id ON sales.invoices(bill_to_customer_id);
CREATE INDEX fk_sales_invoices_order_id ON sales.invoices(order_id);
CREATE INDEX fk_sales_invoices_delivery_method_id ON sales.invoices(delivery_method_id);
CREATE INDEX fk_sales_invoices_contact_person_id ON sales.invoices(contact_person_id);
CREATE INDEX fk_sales_invoices_accounts_person_id ON sales.invoices(accounts_person_id);
CREATE INDEX fk_sales_invoices_salesperson_person_id ON sales.invoices(salesperson_person_id);
CREATE INDEX fk_sales_invoices_packed_by_person_id ON sales.invoices(packed_by_person_id);
CREATE INDEX ix_sales_invoices_confirmed_delivery_time ON sales.invoices(confirmed_delivery_time) INCLUDE (confirmed_received_by);

-- Comments
COMMENT ON TABLE sales.invoices IS 'Details of customer invoices';
COMMENT ON COLUMN sales.invoices.invoice_id IS 'Numeric ID used for reference to an invoice within the database';
COMMENT ON COLUMN sales.invoices.customer_id IS 'Customer for this invoice';
COMMENT ON COLUMN sales.invoices.bill_to_customer_id IS 'Bill to customer for this invoice (invoices might be billed to a head office)';
COMMENT ON COLUMN sales.invoices.order_id IS 'Sales order (if any) for this invoice';
COMMENT ON COLUMN sales.invoices.delivery_method_id IS 'How these items were delivered';
COMMENT ON COLUMN sales.invoices.contact_person_id IS 'Customer contact for this invoice';
COMMENT ON COLUMN sales.invoices.accounts_person_id IS 'Customer accounts contact for this invoice';
COMMENT ON COLUMN sales.invoices.salesperson_person_id IS 'Salesperson for this invoice';
COMMENT ON COLUMN sales.invoices.packed_by_person_id IS 'Person who packed this shipment (or checked the packing)';
COMMENT ON COLUMN sales.invoices.invoice_date IS 'Date that this invoice was raised';
COMMENT ON COLUMN sales.invoices.customer_purchase_order_number IS 'Purchase Order Number received from customer';
COMMENT ON COLUMN sales.invoices.is_credit_note IS 'Is this a credit note (rather than an invoice)';
COMMENT ON COLUMN sales.invoices.credit_note_reason IS 'Reason that this credit note needed to be generated (if applicable)';
COMMENT ON COLUMN sales.invoices.comments IS 'Any comments related to this invoice (sent to customer)';
COMMENT ON COLUMN sales.invoices.delivery_instructions IS 'Any comments related to delivery (sent to customer)';
COMMENT ON COLUMN sales.invoices.internal_comments IS 'Any internal comments related to this invoice (not sent to the customer)';
COMMENT ON COLUMN sales.invoices.total_dry_items IS 'Total number of dry items';
COMMENT ON COLUMN sales.invoices.total_chiller_items IS 'Total number of chiller items';
COMMENT ON COLUMN sales.invoices.delivery_run IS 'Delivery run for this shipment';
COMMENT ON COLUMN sales.invoices.run_position IS 'Position in the delivery run for this shipment';
COMMENT ON COLUMN sales.invoices.returned_delivery_data IS 'JSON-structured data returned from delivery devices for deliveries made directly by the company';
COMMENT ON COLUMN sales.invoices.confirmed_delivery_time IS 'Confirmed delivery date and time promoted from JSON delivery data';
COMMENT ON COLUMN sales.invoices.confirmed_received_by IS 'Confirmed receiver promoted from JSON delivery data';

-- =============================================
-- Sales.InvoiceLines Table
-- =============================================
CREATE TABLE sales.invoice_lines (
    invoice_line_id integer NOT NULL DEFAULT nextval('sequences.invoice_line_id'),
    invoice_id integer NOT NULL,
    stock_item_id integer NOT NULL,
    description varchar(100) NOT NULL,
    package_type_id integer NOT NULL,
    quantity integer NOT NULL,
    unit_price numeric(18, 2) NULL,
    tax_rate numeric(18, 3) NOT NULL,
    tax_amount numeric(18, 2) NOT NULL,
    line_profit numeric(18, 2) NOT NULL,
    extended_price numeric(18, 2) NOT NULL,
    last_edited_by integer NOT NULL,
    last_edited_when timestamp NOT NULL DEFAULT clock_timestamp(),
    CONSTRAINT pk_sales_invoice_lines PRIMARY KEY (invoice_line_id)
);

-- Indexes
CREATE INDEX fk_sales_invoice_lines_invoice_id ON sales.invoice_lines(invoice_id);
CREATE INDEX fk_sales_invoice_lines_stock_item_id ON sales.invoice_lines(stock_item_id);
CREATE INDEX fk_sales_invoice_lines_package_type_id ON sales.invoice_lines(package_type_id);

-- Comments
COMMENT ON TABLE sales.invoice_lines IS 'Detail lines from customer invoices';
COMMENT ON COLUMN sales.invoice_lines.invoice_line_id IS 'Numeric ID used for reference to a line on an invoice within the database';
COMMENT ON COLUMN sales.invoice_lines.invoice_id IS 'Invoice that this line is associated with';
COMMENT ON COLUMN sales.invoice_lines.stock_item_id IS 'Stock item for this invoice line';
COMMENT ON COLUMN sales.invoice_lines.description IS 'Description of the item supplied (Usually the stock item name but can be overridden)';
COMMENT ON COLUMN sales.invoice_lines.package_type_id IS 'Type of package supplied';
COMMENT ON COLUMN sales.invoice_lines.quantity IS 'Quantity supplied';
COMMENT ON COLUMN sales.invoice_lines.unit_price IS 'Unit price charged';
COMMENT ON COLUMN sales.invoice_lines.tax_rate IS 'Tax rate applied';
COMMENT ON COLUMN sales.invoice_lines.tax_amount IS 'Tax amount calculated';
COMMENT ON COLUMN sales.invoice_lines.line_profit IS 'Profit made on this line item at current cost price';
COMMENT ON COLUMN sales.invoice_lines.extended_price IS 'Extended line price charged';

-- =============================================
-- Sales.CustomerTransactions Table
-- =============================================
CREATE TABLE sales.customer_transactions (
    customer_transaction_id integer NOT NULL DEFAULT nextval('sequences.transaction_id'),
    customer_id integer NOT NULL,
    transaction_type_id integer NOT NULL,
    invoice_id integer NULL,
    payment_method_id integer NULL,
    transaction_date date NOT NULL,
    amount_excluding_tax numeric(18, 2) NOT NULL,
    tax_amount numeric(18, 2) NOT NULL,
    transaction_amount numeric(18, 2) NOT NULL,
    outstanding_balance numeric(18, 2) NOT NULL,
    finalization_date date NULL,
    is_finalized boolean GENERATED ALWAYS AS (finalization_date IS NOT NULL) STORED,
    last_edited_by integer NOT NULL,
    last_edited_when timestamp NOT NULL DEFAULT clock_timestamp(),
    CONSTRAINT pk_sales_customer_transactions PRIMARY KEY (customer_transaction_id)
);

-- Indexes
CREATE INDEX fk_sales_customer_transactions_customer_id ON sales.customer_transactions(customer_id);
CREATE INDEX fk_sales_customer_transactions_transaction_type_id ON sales.customer_transactions(transaction_type_id);
CREATE INDEX fk_sales_customer_transactions_invoice_id ON sales.customer_transactions(invoice_id);
CREATE INDEX fk_sales_customer_transactions_payment_method_id ON sales.customer_transactions(payment_method_id);
CREATE INDEX ix_sales_customer_transactions_is_finalized ON sales.customer_transactions(is_finalized);

-- Comments
COMMENT ON TABLE sales.customer_transactions IS 'All financial transactions that are customer-related';
COMMENT ON COLUMN sales.customer_transactions.customer_transaction_id IS 'Numeric ID used to refer to a customer transaction within the database';
COMMENT ON COLUMN sales.customer_transactions.customer_id IS 'Customer for this transaction';
COMMENT ON COLUMN sales.customer_transactions.transaction_type_id IS 'Type of transaction';
COMMENT ON COLUMN sales.customer_transactions.invoice_id IS 'ID of an invoice (for transactions associated with an invoice)';
COMMENT ON COLUMN sales.customer_transactions.payment_method_id IS 'ID of a payment method (for transactions involving payments)';
COMMENT ON COLUMN sales.customer_transactions.transaction_date IS 'Date for the transaction';
COMMENT ON COLUMN sales.customer_transactions.amount_excluding_tax IS 'Transaction amount (excluding tax)';
COMMENT ON COLUMN sales.customer_transactions.tax_amount IS 'Tax amount calculated';
COMMENT ON COLUMN sales.customer_transactions.transaction_amount IS 'Transaction amount (including tax)';
COMMENT ON COLUMN sales.customer_transactions.outstanding_balance IS 'Amount still outstanding for this transaction';
COMMENT ON COLUMN sales.customer_transactions.finalization_date IS 'Date that this transaction was finalized (if it has been)';
COMMENT ON COLUMN sales.customer_transactions.is_finalized IS 'Is this transaction finalized (invoices, credits and payments have been matched)';

-- =============================================
-- Sales.SpecialDeals Table
-- =============================================
CREATE TABLE sales.special_deals (
    special_deal_id integer NOT NULL DEFAULT nextval('sequences.special_deal_id'),
    stock_item_id integer NULL,
    customer_id integer NULL,
    buying_group_id integer NULL,
    customer_category_id integer NULL,
    stock_group_id integer NULL,
    deal_description varchar(30) NOT NULL,
    start_date date NOT NULL,
    end_date date NOT NULL,
    discount_amount numeric(18, 2) NULL,
    discount_percentage numeric(18, 3) NULL,
    unit_price numeric(18, 2) NULL,
    last_edited_by integer NOT NULL,
    last_edited_when timestamp NOT NULL DEFAULT clock_timestamp(),
    CONSTRAINT pk_sales_special_deals PRIMARY KEY (special_deal_id)
);

-- Indexes
CREATE INDEX fk_sales_special_deals_stock_item_id ON sales.special_deals(stock_item_id);
CREATE INDEX fk_sales_special_deals_customer_id ON sales.special_deals(customer_id);
CREATE INDEX fk_sales_special_deals_buying_group_id ON sales.special_deals(buying_group_id);
CREATE INDEX fk_sales_special_deals_customer_category_id ON sales.special_deals(customer_category_id);
CREATE INDEX fk_sales_special_deals_stock_group_id ON sales.special_deals(stock_group_id);

-- Comments
COMMENT ON TABLE sales.special_deals IS 'Special pricing (can include fixed prices, discount $ Desktop or discount %)';
COMMENT ON COLUMN sales.special_deals.special_deal_id IS 'ID (sequence based) for a special deal';
COMMENT ON COLUMN sales.special_deals.stock_item_id IS 'Stock item that the deal applies to (if NULL, then all items)';
COMMENT ON COLUMN sales.special_deals.customer_id IS 'ID of the customer that the special pricing applies to (if NULL then all customers)';
COMMENT ON COLUMN sales.special_deals.buying_group_id IS 'ID of the buying group that the special pricing applies to (optional)';
COMMENT ON COLUMN sales.special_deals.customer_category_id IS 'ID of the customer category that the special pricing applies to (optional)';
COMMENT ON COLUMN sales.special_deals.stock_group_id IS 'ID of the stock group that the special pricing applies to (optional)';
COMMENT ON COLUMN sales.special_deals.deal_description IS 'Description of the special deal';
COMMENT ON COLUMN sales.special_deals.start_date IS 'Date that the special pricing starts from';
COMMENT ON COLUMN sales.special_deals.end_date IS 'Date that the special pricing ends on';
COMMENT ON COLUMN sales.special_deals.discount_amount IS 'Discount per unit to be applied to the normal unit price (optional)';
COMMENT ON COLUMN sales.special_deals.discount_percentage IS 'Discount percentage per unit to be applied to the normal unit price (optional)';
COMMENT ON COLUMN sales.special_deals.unit_price IS 'Special price per unit to be applied instead of the normal unit price (optional)';
