-- Wide World Importers DW PostgreSQL Migration
-- Phase 4: OLAP Schema Migration
-- File: 001-dimension-tables.sql
-- Description: Create all dimension tables for the star schema

-- =============================================
-- Dimension.City - City dimension with SCD Type 2
-- =============================================
CREATE TABLE dimension.city (
    city_key integer NOT NULL DEFAULT nextval('sequences.city_key'),
    wwi_city_id integer NOT NULL,
    city varchar(50) NOT NULL,
    state_province varchar(50) NOT NULL,
    country varchar(60) NOT NULL,
    continent varchar(30) NOT NULL,
    sales_territory varchar(50) NOT NULL,
    region varchar(30) NOT NULL,
    subregion varchar(30) NOT NULL,
    location geography NULL,
    latest_recorded_population bigint NOT NULL,
    valid_from timestamp NOT NULL,
    valid_to timestamp NOT NULL,
    lineage_key integer NOT NULL,
    CONSTRAINT pk_dimension_city PRIMARY KEY (city_key)
);

CREATE INDEX ix_dimension_city_wwi_city_id 
    ON dimension.city (wwi_city_id, valid_from, valid_to);

COMMENT ON TABLE dimension.city IS 'City dimension';
COMMENT ON COLUMN dimension.city.city_key IS 'DW key for the city dimension';
COMMENT ON COLUMN dimension.city.wwi_city_id IS 'Numeric ID used for reference to a city within the WWI database';
COMMENT ON COLUMN dimension.city.city IS 'Formal name of the city';
COMMENT ON COLUMN dimension.city.state_province IS 'State or province for this city';
COMMENT ON COLUMN dimension.city.country IS 'Country name';
COMMENT ON COLUMN dimension.city.continent IS 'Continent that this city is on';
COMMENT ON COLUMN dimension.city.sales_territory IS 'Sales territory for this StateProvince';
COMMENT ON COLUMN dimension.city.region IS 'Name of the region';
COMMENT ON COLUMN dimension.city.subregion IS 'Name of the subregion';
COMMENT ON COLUMN dimension.city.location IS 'Geographic location of the city';
COMMENT ON COLUMN dimension.city.latest_recorded_population IS 'Latest available population for the City';
COMMENT ON COLUMN dimension.city.valid_from IS 'Valid from this date and time';
COMMENT ON COLUMN dimension.city.valid_to IS 'Valid until this date and time';
COMMENT ON COLUMN dimension.city.lineage_key IS 'Lineage Key for the data load for this row';

-- =============================================
-- Dimension.Customer - Customer dimension with SCD Type 2
-- =============================================
CREATE TABLE dimension.customer (
    customer_key integer NOT NULL DEFAULT nextval('sequences.customer_key'),
    wwi_customer_id integer NOT NULL,
    customer varchar(100) NOT NULL,
    bill_to_customer varchar(100) NOT NULL,
    category varchar(50) NOT NULL,
    buying_group varchar(50) NOT NULL,
    primary_contact varchar(50) NOT NULL,
    postal_code varchar(10) NOT NULL,
    valid_from timestamp NOT NULL,
    valid_to timestamp NOT NULL,
    lineage_key integer NOT NULL,
    CONSTRAINT pk_dimension_customer PRIMARY KEY (customer_key)
);

CREATE INDEX ix_dimension_customer_wwi_customer_id 
    ON dimension.customer (wwi_customer_id, valid_from, valid_to);

COMMENT ON TABLE dimension.customer IS 'Customer dimension';
COMMENT ON COLUMN dimension.customer.customer_key IS 'DW key for the customer dimension';
COMMENT ON COLUMN dimension.customer.wwi_customer_id IS 'Numeric ID used for reference to a customer within the WWI database';
COMMENT ON COLUMN dimension.customer.customer IS 'Customer full name (usually a trading name)';
COMMENT ON COLUMN dimension.customer.bill_to_customer IS 'Bill to customer full name';
COMMENT ON COLUMN dimension.customer.category IS 'Customer category';
COMMENT ON COLUMN dimension.customer.buying_group IS 'Customer buying group';
COMMENT ON COLUMN dimension.customer.primary_contact IS 'Primary contact';
COMMENT ON COLUMN dimension.customer.postal_code IS 'Delivery postal code for the customer';
COMMENT ON COLUMN dimension.customer.valid_from IS 'Valid from this date and time';
COMMENT ON COLUMN dimension.customer.valid_to IS 'Valid until this date and time';
COMMENT ON COLUMN dimension.customer.lineage_key IS 'Lineage Key for the data load for this row';

-- =============================================
-- Dimension.Date - Date dimension (calendar and fiscal)
-- Note: This is a large table with many columns for various date attributes
-- =============================================
CREATE TABLE dimension.date (
    date date NOT NULL,
    date_key integer NOT NULL,
    day_number integer NOT NULL,
    day varchar(10) NOT NULL,
    day_of_year varchar(5) NOT NULL,
    day_of_year_number integer NOT NULL,
    day_of_week varchar(20) NOT NULL,
    day_of_week_number integer NOT NULL,
    week_of_year varchar(5) NOT NULL,
    month varchar(10) NOT NULL,
    short_month varchar(3) NOT NULL,
    quarter varchar(2) NOT NULL,
    half_of_year varchar(3) NOT NULL,
    beginning_of_month date NOT NULL,
    beginning_of_quarter date NOT NULL,
    beginning_of_half_year date NOT NULL,
    beginning_of_year date NOT NULL,
    beginning_of_month_label varchar(40) NOT NULL,
    beginning_of_month_label_short varchar(40) NOT NULL,
    beginning_of_quarter_label varchar(40) NOT NULL,
    beginning_of_quarter_label_short varchar(40) NOT NULL,
    beginning_of_half_year_label varchar(40) NOT NULL,
    beginning_of_half_year_label_short varchar(40) NOT NULL,
    beginning_of_year_label varchar(40) NOT NULL,
    beginning_of_year_label_short varchar(40) NOT NULL,
    calendar_day_label varchar(20) NOT NULL,
    calendar_day_label_short varchar(20) NOT NULL,
    calendar_week_number integer NOT NULL,
    calendar_week_label varchar(20) NOT NULL,
    calendar_month_number integer NOT NULL,
    calendar_month_label varchar(20) NOT NULL,
    calendar_month_year_label varchar(20) NOT NULL,
    calendar_quarter_number integer NOT NULL,
    calendar_quarter_label varchar(20) NOT NULL,
    calendar_quarter_year_label varchar(20) NOT NULL,
    calendar_half_of_year_number integer NOT NULL,
    calendar_half_of_year_label varchar(20) NOT NULL,
    calendar_year_half_of_year_label varchar(20) NOT NULL,
    calendar_year integer NOT NULL,
    calendar_year_label varchar(10) NOT NULL,
    fiscal_month_number integer NOT NULL,
    fiscal_month_label varchar(20) NOT NULL,
    fiscal_quarter_number integer NOT NULL,
    fiscal_quarter_label varchar(20) NOT NULL,
    fiscal_half_of_year_number integer NOT NULL,
    fiscal_half_of_year_label varchar(20) NOT NULL,
    fiscal_year integer NOT NULL,
    fiscal_year_label varchar(10) NOT NULL,
    date_key_alt integer NOT NULL,
    year_week_key integer NOT NULL,
    year_month_key integer NOT NULL,
    year_quarter_key integer NOT NULL,
    year_half_of_year_key integer NOT NULL,
    year_key integer NOT NULL,
    beginning_of_month_key integer NOT NULL,
    beginning_of_quarter_key integer NOT NULL,
    beginning_of_half_year_key integer NOT NULL,
    beginning_of_year_key integer NOT NULL,
    fiscal_year_month_key integer NOT NULL,
    fiscal_year_quarter_key integer NOT NULL,
    fiscal_year_half_of_year_key integer NOT NULL,
    iso_week_number integer NOT NULL,
    CONSTRAINT pk_dimension_date PRIMARY KEY (date)
);

COMMENT ON TABLE dimension.date IS 'Date dimension';
COMMENT ON COLUMN dimension.date.date IS 'DW key for date dimension (actual date is used for key)';
COMMENT ON COLUMN dimension.date.date_key IS 'The date in integer format, can be used as the DW Key if desired';
COMMENT ON COLUMN dimension.date.day_number IS 'Day of the month in integer format';
COMMENT ON COLUMN dimension.date.day IS 'Day of the month in string format';
COMMENT ON COLUMN dimension.date.day_of_year IS 'Day number of year (1 to 365) as a string';
COMMENT ON COLUMN dimension.date.day_of_year_number IS 'Day number of year (1 to 365) as an integer';
COMMENT ON COLUMN dimension.date.day_of_week IS 'Day of the week (Monday, Tuesday, etc)';
COMMENT ON COLUMN dimension.date.day_of_week_number IS 'Numeric day of the week (1=Sunday, etc)';
COMMENT ON COLUMN dimension.date.calendar_year IS 'Calendar year';
COMMENT ON COLUMN dimension.date.fiscal_year IS 'Fiscal year';

-- =============================================
-- Dimension.Employee - Employee dimension with SCD Type 2
-- =============================================
CREATE TABLE dimension.employee (
    employee_key integer NOT NULL DEFAULT nextval('sequences.employee_key'),
    wwi_employee_id integer NOT NULL,
    employee varchar(50) NOT NULL,
    preferred_name varchar(50) NOT NULL,
    is_salesperson boolean NOT NULL,
    photo bytea NULL,
    valid_from timestamp NOT NULL,
    valid_to timestamp NOT NULL,
    lineage_key integer NOT NULL,
    CONSTRAINT pk_dimension_employee PRIMARY KEY (employee_key)
);

CREATE INDEX ix_dimension_employee_wwi_employee_id 
    ON dimension.employee (wwi_employee_id, valid_from, valid_to);

COMMENT ON TABLE dimension.employee IS 'Employee dimension';
COMMENT ON COLUMN dimension.employee.employee_key IS 'DW key for the employee dimension';
COMMENT ON COLUMN dimension.employee.wwi_employee_id IS 'Numeric ID (PersonID) in the WWI database';
COMMENT ON COLUMN dimension.employee.employee IS 'Full name for this person';
COMMENT ON COLUMN dimension.employee.preferred_name IS 'Name that this person prefers to be called';
COMMENT ON COLUMN dimension.employee.is_salesperson IS 'Is this person a staff salesperson?';
COMMENT ON COLUMN dimension.employee.photo IS 'Photo of this person';
COMMENT ON COLUMN dimension.employee.valid_from IS 'Valid from this date and time';
COMMENT ON COLUMN dimension.employee.valid_to IS 'Valid until this date and time';
COMMENT ON COLUMN dimension.employee.lineage_key IS 'Lineage Key for the data load for this row';

-- =============================================
-- Dimension.Payment_Method - Payment method dimension with SCD Type 2
-- =============================================
CREATE TABLE dimension.payment_method (
    payment_method_key integer NOT NULL DEFAULT nextval('sequences.payment_method_key'),
    wwi_payment_method_id integer NOT NULL,
    payment_method varchar(50) NOT NULL,
    valid_from timestamp NOT NULL,
    valid_to timestamp NOT NULL,
    lineage_key integer NOT NULL,
    CONSTRAINT pk_dimension_payment_method PRIMARY KEY (payment_method_key)
);

CREATE INDEX ix_dimension_payment_method_wwi_payment_method_id 
    ON dimension.payment_method (wwi_payment_method_id, valid_from, valid_to);

COMMENT ON TABLE dimension.payment_method IS 'PaymentMethod dimension';
COMMENT ON COLUMN dimension.payment_method.payment_method_key IS 'DW key for the payment method dimension';
COMMENT ON COLUMN dimension.payment_method.wwi_payment_method_id IS 'Numeric ID for the payment method in the WWI database';
COMMENT ON COLUMN dimension.payment_method.payment_method IS 'Payment method name';
COMMENT ON COLUMN dimension.payment_method.valid_from IS 'Valid from this date and time';
COMMENT ON COLUMN dimension.payment_method.valid_to IS 'Valid until this date and time';
COMMENT ON COLUMN dimension.payment_method.lineage_key IS 'Lineage Key for the data load for this row';

-- =============================================
-- Dimension.Stock_Item - Stock item dimension with SCD Type 2
-- =============================================
CREATE TABLE dimension.stock_item (
    stock_item_key integer NOT NULL DEFAULT nextval('sequences.stock_item_key'),
    wwi_stock_item_id integer NOT NULL,
    stock_item varchar(100) NOT NULL,
    color varchar(20) NOT NULL,
    selling_package varchar(50) NOT NULL,
    buying_package varchar(50) NOT NULL,
    brand varchar(50) NOT NULL,
    size varchar(20) NOT NULL,
    lead_time_days integer NOT NULL,
    quantity_per_outer integer NOT NULL,
    is_chiller_stock boolean NOT NULL,
    barcode varchar(50) NULL,
    tax_rate numeric(18,3) NOT NULL,
    unit_price numeric(18,2) NOT NULL,
    recommended_retail_price numeric(18,2) NULL,
    typical_weight_per_unit numeric(18,3) NOT NULL,
    photo bytea NULL,
    valid_from timestamp NOT NULL,
    valid_to timestamp NOT NULL,
    lineage_key integer NOT NULL,
    CONSTRAINT pk_dimension_stock_item PRIMARY KEY (stock_item_key)
);

CREATE INDEX ix_dimension_stock_item_wwi_stock_item_id 
    ON dimension.stock_item (wwi_stock_item_id, valid_from, valid_to);

COMMENT ON TABLE dimension.stock_item IS 'StockItem dimension';
COMMENT ON COLUMN dimension.stock_item.stock_item_key IS 'DW key for the stock item dimension';
COMMENT ON COLUMN dimension.stock_item.wwi_stock_item_id IS 'Numeric ID used for reference to a stock item within the WWI database';
COMMENT ON COLUMN dimension.stock_item.stock_item IS 'Full name of a stock item (but not a full description)';
COMMENT ON COLUMN dimension.stock_item.color IS 'Color (optional) for this stock item';
COMMENT ON COLUMN dimension.stock_item.selling_package IS 'Usual package for selling units of this stock item';
COMMENT ON COLUMN dimension.stock_item.buying_package IS 'Usual package for selling outers of this stock item';
COMMENT ON COLUMN dimension.stock_item.brand IS 'Brand for the stock item (if the item is branded)';
COMMENT ON COLUMN dimension.stock_item.size IS 'Size of this item (eg: 100mm)';
COMMENT ON COLUMN dimension.stock_item.lead_time_days IS 'Number of days typically taken from order to receipt';
COMMENT ON COLUMN dimension.stock_item.quantity_per_outer IS 'Quantity of the stock item in an outer package';
COMMENT ON COLUMN dimension.stock_item.is_chiller_stock IS 'Does this stock item need to be in a chiller?';
COMMENT ON COLUMN dimension.stock_item.barcode IS 'Barcode for this stock item';
COMMENT ON COLUMN dimension.stock_item.tax_rate IS 'Tax rate to be applied';
COMMENT ON COLUMN dimension.stock_item.unit_price IS 'Selling price (ex-tax) for one unit of this product';
COMMENT ON COLUMN dimension.stock_item.recommended_retail_price IS 'Recommended retail price for this stock item';
COMMENT ON COLUMN dimension.stock_item.typical_weight_per_unit IS 'Typical weight for one unit of this product (packaged)';
COMMENT ON COLUMN dimension.stock_item.photo IS 'Photo of the product';
COMMENT ON COLUMN dimension.stock_item.valid_from IS 'Valid from this date and time';
COMMENT ON COLUMN dimension.stock_item.valid_to IS 'Valid until this date and time';
COMMENT ON COLUMN dimension.stock_item.lineage_key IS 'Lineage Key for the data load for this row';

-- =============================================
-- Dimension.Supplier - Supplier dimension with SCD Type 2
-- =============================================
CREATE TABLE dimension.supplier (
    supplier_key integer NOT NULL DEFAULT nextval('sequences.supplier_key'),
    wwi_supplier_id integer NOT NULL,
    supplier varchar(100) NOT NULL,
    category varchar(50) NOT NULL,
    primary_contact varchar(50) NOT NULL,
    supplier_reference varchar(20) NULL,
    payment_days integer NOT NULL,
    postal_code varchar(10) NOT NULL,
    valid_from timestamp NOT NULL,
    valid_to timestamp NOT NULL,
    lineage_key integer NOT NULL,
    CONSTRAINT pk_dimension_supplier PRIMARY KEY (supplier_key)
);

CREATE INDEX ix_dimension_supplier_wwi_supplier_id 
    ON dimension.supplier (wwi_supplier_id, valid_from, valid_to);

COMMENT ON TABLE dimension.supplier IS 'Supplier dimension';
COMMENT ON COLUMN dimension.supplier.supplier_key IS 'DW key for the supplier dimension';
COMMENT ON COLUMN dimension.supplier.wwi_supplier_id IS 'Numeric ID used for reference to a supplier within the WWI database';
COMMENT ON COLUMN dimension.supplier.supplier IS 'Supplier full name (usually a trading name)';
COMMENT ON COLUMN dimension.supplier.category IS 'Supplier category';
COMMENT ON COLUMN dimension.supplier.primary_contact IS 'Primary contact';
COMMENT ON COLUMN dimension.supplier.supplier_reference IS 'Supplier reference for our organization';
COMMENT ON COLUMN dimension.supplier.payment_days IS 'Number of days for payment of an invoice (ie payment terms)';
COMMENT ON COLUMN dimension.supplier.postal_code IS 'Delivery postal code for the supplier';
COMMENT ON COLUMN dimension.supplier.valid_from IS 'Valid from this date and time';
COMMENT ON COLUMN dimension.supplier.valid_to IS 'Valid until this date and time';
COMMENT ON COLUMN dimension.supplier.lineage_key IS 'Lineage Key for the data load for this row';

-- =============================================
-- Dimension.Transaction_Type - Transaction type dimension with SCD Type 2
-- =============================================
CREATE TABLE dimension.transaction_type (
    transaction_type_key integer NOT NULL DEFAULT nextval('sequences.transaction_type_key'),
    wwi_transaction_type_id integer NOT NULL,
    transaction_type varchar(50) NOT NULL,
    valid_from timestamp NOT NULL,
    valid_to timestamp NOT NULL,
    lineage_key integer NOT NULL,
    CONSTRAINT pk_dimension_transaction_type PRIMARY KEY (transaction_type_key)
);

CREATE INDEX ix_dimension_transaction_type_wwi_transaction_type_id 
    ON dimension.transaction_type (wwi_transaction_type_id, valid_from, valid_to);

COMMENT ON TABLE dimension.transaction_type IS 'TransactionType dimension';
COMMENT ON COLUMN dimension.transaction_type.transaction_type_key IS 'DW key for the transaction type dimension';
COMMENT ON COLUMN dimension.transaction_type.wwi_transaction_type_id IS 'Numeric ID used for reference to a transaction type within the WWI database';
COMMENT ON COLUMN dimension.transaction_type.transaction_type IS 'Full name of the transaction type';
COMMENT ON COLUMN dimension.transaction_type.valid_from IS 'Valid from this date and time';
COMMENT ON COLUMN dimension.transaction_type.valid_to IS 'Valid until this date and time';
COMMENT ON COLUMN dimension.transaction_type.lineage_key IS 'Lineage Key for the data load for this row';
