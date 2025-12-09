-- Wide World Importers PostgreSQL Migration
-- Phase 4: OLAP Schema Migration (WideWorldImportersDW)
-- Script 002: Dimension Tables
-- Migrated from SQL Server to PostgreSQL

-- =============================================
-- Dimension.City
-- City dimension with SCD Type 2 support
-- =============================================
CREATE TABLE dimension.city (
    city_key INTEGER NOT NULL DEFAULT nextval('dimension.city_key_seq'),
    wwi_city_id INTEGER NOT NULL,
    city VARCHAR(50) NOT NULL,
    state_province VARCHAR(50) NOT NULL,
    country VARCHAR(60) NOT NULL,
    continent VARCHAR(30) NOT NULL,
    sales_territory VARCHAR(50) NOT NULL,
    region VARCHAR(30) NOT NULL,
    subregion VARCHAR(30) NOT NULL,
    location geometry NULL,
    latest_recorded_population BIGINT NOT NULL,
    valid_from TIMESTAMP NOT NULL,
    valid_to TIMESTAMP NOT NULL,
    lineage_key INTEGER NOT NULL,
    CONSTRAINT pk_dimension_city PRIMARY KEY (city_key)
);

CREATE INDEX ix_dimension_city_wwi_city_id ON dimension.city(wwi_city_id);
CREATE INDEX ix_dimension_city_valid_from ON dimension.city(valid_from);
CREATE INDEX ix_dimension_city_valid_to ON dimension.city(valid_to);

COMMENT ON TABLE dimension.city IS 'City dimension table with SCD Type 2 support';
COMMENT ON COLUMN dimension.city.city_key IS 'Surrogate key for the city dimension';
COMMENT ON COLUMN dimension.city.wwi_city_id IS 'Business key from source system';
COMMENT ON COLUMN dimension.city.location IS 'Geographic location (PostGIS geometry)';
COMMENT ON COLUMN dimension.city.valid_from IS 'Start of validity period for SCD Type 2';
COMMENT ON COLUMN dimension.city.valid_to IS 'End of validity period for SCD Type 2';
COMMENT ON COLUMN dimension.city.lineage_key IS 'ETL lineage tracking key';

-- =============================================
-- Dimension.Customer
-- Customer dimension with SCD Type 2 support
-- =============================================
CREATE TABLE dimension.customer (
    customer_key INTEGER NOT NULL DEFAULT nextval('dimension.customer_key_seq'),
    wwi_customer_id INTEGER NOT NULL,
    customer VARCHAR(100) NOT NULL,
    bill_to_customer VARCHAR(100) NOT NULL,
    category VARCHAR(50) NOT NULL,
    buying_group VARCHAR(50) NOT NULL,
    primary_contact VARCHAR(50) NOT NULL,
    postal_code VARCHAR(10) NOT NULL,
    valid_from TIMESTAMP NOT NULL,
    valid_to TIMESTAMP NOT NULL,
    lineage_key INTEGER NOT NULL,
    CONSTRAINT pk_dimension_customer PRIMARY KEY (customer_key)
);

CREATE INDEX ix_dimension_customer_wwi_customer_id ON dimension.customer(wwi_customer_id);
CREATE INDEX ix_dimension_customer_valid_from ON dimension.customer(valid_from);
CREATE INDEX ix_dimension_customer_valid_to ON dimension.customer(valid_to);

COMMENT ON TABLE dimension.customer IS 'Customer dimension table with SCD Type 2 support';
COMMENT ON COLUMN dimension.customer.customer_key IS 'Surrogate key for the customer dimension';
COMMENT ON COLUMN dimension.customer.wwi_customer_id IS 'Business key from source system';

-- =============================================
-- Dimension.Date
-- Date dimension (calendar table)
-- =============================================
CREATE TABLE dimension.date (
    date_key DATE NOT NULL,
    day_number INTEGER NOT NULL,
    day_name VARCHAR(10) NOT NULL,
    day_of_week INTEGER NOT NULL,
    day_of_week_name VARCHAR(10) NOT NULL,
    day_of_year INTEGER NOT NULL,
    week_of_year INTEGER NOT NULL,
    month_number INTEGER NOT NULL,
    month_name VARCHAR(10) NOT NULL,
    calendar_month_label VARCHAR(20) NOT NULL,
    calendar_year INTEGER NOT NULL,
    calendar_year_label VARCHAR(10) NOT NULL,
    fiscal_month_number INTEGER NOT NULL,
    fiscal_month_label VARCHAR(20) NOT NULL,
    fiscal_year INTEGER NOT NULL,
    fiscal_year_label VARCHAR(10) NOT NULL,
    iso_week_number INTEGER NOT NULL,
    CONSTRAINT pk_dimension_date PRIMARY KEY (date_key)
);

CREATE INDEX ix_dimension_date_calendar_year ON dimension.date(calendar_year);
CREATE INDEX ix_dimension_date_fiscal_year ON dimension.date(fiscal_year);
CREATE INDEX ix_dimension_date_month_number ON dimension.date(month_number);

COMMENT ON TABLE dimension.date IS 'Date dimension table (calendar)';
COMMENT ON COLUMN dimension.date.date_key IS 'Primary key - the date itself';
COMMENT ON COLUMN dimension.date.fiscal_year IS 'Fiscal year (July-June)';

-- =============================================
-- Dimension.Employee
-- Employee dimension with SCD Type 2 support
-- =============================================
CREATE TABLE dimension.employee (
    employee_key INTEGER NOT NULL DEFAULT nextval('dimension.employee_key_seq'),
    wwi_employee_id INTEGER NOT NULL,
    employee VARCHAR(50) NOT NULL,
    preferred_name VARCHAR(50) NOT NULL,
    is_salesperson BOOLEAN NOT NULL,
    photo BYTEA NULL,
    valid_from TIMESTAMP NOT NULL,
    valid_to TIMESTAMP NOT NULL,
    lineage_key INTEGER NOT NULL,
    CONSTRAINT pk_dimension_employee PRIMARY KEY (employee_key)
);

CREATE INDEX ix_dimension_employee_wwi_employee_id ON dimension.employee(wwi_employee_id);
CREATE INDEX ix_dimension_employee_valid_from ON dimension.employee(valid_from);
CREATE INDEX ix_dimension_employee_valid_to ON dimension.employee(valid_to);

COMMENT ON TABLE dimension.employee IS 'Employee dimension table with SCD Type 2 support';
COMMENT ON COLUMN dimension.employee.employee_key IS 'Surrogate key for the employee dimension';
COMMENT ON COLUMN dimension.employee.wwi_employee_id IS 'Business key from source system';
COMMENT ON COLUMN dimension.employee.photo IS 'Employee photo (binary data)';

-- =============================================
-- Dimension.Payment_Method
-- Payment Method dimension with SCD Type 2 support
-- =============================================
CREATE TABLE dimension.payment_method (
    payment_method_key INTEGER NOT NULL DEFAULT nextval('dimension.payment_method_key_seq'),
    wwi_payment_method_id INTEGER NOT NULL,
    payment_method VARCHAR(50) NOT NULL,
    valid_from TIMESTAMP NOT NULL,
    valid_to TIMESTAMP NOT NULL,
    lineage_key INTEGER NOT NULL,
    CONSTRAINT pk_dimension_payment_method PRIMARY KEY (payment_method_key)
);

CREATE INDEX ix_dimension_payment_method_wwi_payment_method_id ON dimension.payment_method(wwi_payment_method_id);
CREATE INDEX ix_dimension_payment_method_valid_from ON dimension.payment_method(valid_from);
CREATE INDEX ix_dimension_payment_method_valid_to ON dimension.payment_method(valid_to);

COMMENT ON TABLE dimension.payment_method IS 'Payment Method dimension table with SCD Type 2 support';
COMMENT ON COLUMN dimension.payment_method.payment_method_key IS 'Surrogate key for the payment method dimension';
COMMENT ON COLUMN dimension.payment_method.wwi_payment_method_id IS 'Business key from source system';

-- =============================================
-- Dimension.Stock_Item
-- Stock Item dimension with SCD Type 2 support
-- =============================================
CREATE TABLE dimension.stock_item (
    stock_item_key INTEGER NOT NULL DEFAULT nextval('dimension.stock_item_key_seq'),
    wwi_stock_item_id INTEGER NOT NULL,
    stock_item VARCHAR(100) NOT NULL,
    color VARCHAR(20) NOT NULL,
    selling_package VARCHAR(50) NOT NULL,
    buying_package VARCHAR(50) NOT NULL,
    brand VARCHAR(50) NOT NULL,
    size VARCHAR(20) NOT NULL,
    lead_time_days INTEGER NOT NULL,
    quantity_per_outer INTEGER NOT NULL,
    is_chiller_stock BOOLEAN NOT NULL,
    barcode VARCHAR(50) NULL,
    tax_rate NUMERIC(18, 3) NOT NULL,
    unit_price NUMERIC(18, 2) NOT NULL,
    recommended_retail_price NUMERIC(18, 2) NULL,
    typical_weight_per_unit NUMERIC(18, 3) NOT NULL,
    photo BYTEA NULL,
    valid_from TIMESTAMP NOT NULL,
    valid_to TIMESTAMP NOT NULL,
    lineage_key INTEGER NOT NULL,
    CONSTRAINT pk_dimension_stock_item PRIMARY KEY (stock_item_key)
);

CREATE INDEX ix_dimension_stock_item_wwi_stock_item_id ON dimension.stock_item(wwi_stock_item_id);
CREATE INDEX ix_dimension_stock_item_valid_from ON dimension.stock_item(valid_from);
CREATE INDEX ix_dimension_stock_item_valid_to ON dimension.stock_item(valid_to);

COMMENT ON TABLE dimension.stock_item IS 'Stock Item dimension table with SCD Type 2 support';
COMMENT ON COLUMN dimension.stock_item.stock_item_key IS 'Surrogate key for the stock item dimension';
COMMENT ON COLUMN dimension.stock_item.wwi_stock_item_id IS 'Business key from source system';
COMMENT ON COLUMN dimension.stock_item.photo IS 'Product photo (binary data)';

-- =============================================
-- Dimension.Supplier
-- Supplier dimension with SCD Type 2 support
-- =============================================
CREATE TABLE dimension.supplier (
    supplier_key INTEGER NOT NULL DEFAULT nextval('dimension.supplier_key_seq'),
    wwi_supplier_id INTEGER NOT NULL,
    supplier VARCHAR(100) NOT NULL,
    category VARCHAR(50) NOT NULL,
    primary_contact VARCHAR(50) NOT NULL,
    supplier_reference VARCHAR(20) NULL,
    payment_days INTEGER NOT NULL,
    postal_code VARCHAR(10) NOT NULL,
    valid_from TIMESTAMP NOT NULL,
    valid_to TIMESTAMP NOT NULL,
    lineage_key INTEGER NOT NULL,
    CONSTRAINT pk_dimension_supplier PRIMARY KEY (supplier_key)
);

CREATE INDEX ix_dimension_supplier_wwi_supplier_id ON dimension.supplier(wwi_supplier_id);
CREATE INDEX ix_dimension_supplier_valid_from ON dimension.supplier(valid_from);
CREATE INDEX ix_dimension_supplier_valid_to ON dimension.supplier(valid_to);

COMMENT ON TABLE dimension.supplier IS 'Supplier dimension table with SCD Type 2 support';
COMMENT ON COLUMN dimension.supplier.supplier_key IS 'Surrogate key for the supplier dimension';
COMMENT ON COLUMN dimension.supplier.wwi_supplier_id IS 'Business key from source system';

-- =============================================
-- Dimension.Transaction_Type
-- Transaction Type dimension with SCD Type 2 support
-- =============================================
CREATE TABLE dimension.transaction_type (
    transaction_type_key INTEGER NOT NULL DEFAULT nextval('dimension.transaction_type_key_seq'),
    wwi_transaction_type_id INTEGER NOT NULL,
    transaction_type VARCHAR(50) NOT NULL,
    valid_from TIMESTAMP NOT NULL,
    valid_to TIMESTAMP NOT NULL,
    lineage_key INTEGER NOT NULL,
    CONSTRAINT pk_dimension_transaction_type PRIMARY KEY (transaction_type_key)
);

CREATE INDEX ix_dimension_transaction_type_wwi_transaction_type_id ON dimension.transaction_type(wwi_transaction_type_id);
CREATE INDEX ix_dimension_transaction_type_valid_from ON dimension.transaction_type(valid_from);
CREATE INDEX ix_dimension_transaction_type_valid_to ON dimension.transaction_type(valid_to);

COMMENT ON TABLE dimension.transaction_type IS 'Transaction Type dimension table with SCD Type 2 support';
COMMENT ON COLUMN dimension.transaction_type.transaction_type_key IS 'Surrogate key for the transaction type dimension';
COMMENT ON COLUMN dimension.transaction_type.wwi_transaction_type_id IS 'Business key from source system';

-- =============================================
-- Populate Date Dimension
-- Generate dates from 2013-01-01 to 2025-12-31
-- =============================================
INSERT INTO dimension.date (
    date_key, day_number, day_name, day_of_week, day_of_week_name, day_of_year,
    week_of_year, month_number, month_name, calendar_month_label, calendar_year,
    calendar_year_label, fiscal_month_number, fiscal_month_label, fiscal_year,
    fiscal_year_label, iso_week_number
)
SELECT 
    d::DATE AS date_key,
    EXTRACT(DAY FROM d)::INTEGER AS day_number,
    TO_CHAR(d, 'Day') AS day_name,
    EXTRACT(DOW FROM d)::INTEGER AS day_of_week,
    TO_CHAR(d, 'Day') AS day_of_week_name,
    EXTRACT(DOY FROM d)::INTEGER AS day_of_year,
    EXTRACT(WEEK FROM d)::INTEGER AS week_of_year,
    EXTRACT(MONTH FROM d)::INTEGER AS month_number,
    TO_CHAR(d, 'Month') AS month_name,
    TO_CHAR(d, 'Mon YYYY') AS calendar_month_label,
    EXTRACT(YEAR FROM d)::INTEGER AS calendar_year,
    'CY' || EXTRACT(YEAR FROM d)::TEXT AS calendar_year_label,
    CASE 
        WHEN EXTRACT(MONTH FROM d) >= 7 THEN EXTRACT(MONTH FROM d)::INTEGER - 6
        ELSE EXTRACT(MONTH FROM d)::INTEGER + 6
    END AS fiscal_month_number,
    'FM' || CASE 
        WHEN EXTRACT(MONTH FROM d) >= 7 THEN EXTRACT(MONTH FROM d)::INTEGER - 6
        ELSE EXTRACT(MONTH FROM d)::INTEGER + 6
    END AS fiscal_month_label,
    CASE 
        WHEN EXTRACT(MONTH FROM d) >= 7 THEN EXTRACT(YEAR FROM d)::INTEGER + 1
        ELSE EXTRACT(YEAR FROM d)::INTEGER
    END AS fiscal_year,
    'FY' || CASE 
        WHEN EXTRACT(MONTH FROM d) >= 7 THEN EXTRACT(YEAR FROM d)::INTEGER + 1
        ELSE EXTRACT(YEAR FROM d)::INTEGER
    END AS fiscal_year_label,
    EXTRACT(WEEK FROM d)::INTEGER AS iso_week_number
FROM generate_series('2013-01-01'::DATE, '2025-12-31'::DATE, '1 day'::INTERVAL) AS d
ON CONFLICT (date_key) DO NOTHING;
