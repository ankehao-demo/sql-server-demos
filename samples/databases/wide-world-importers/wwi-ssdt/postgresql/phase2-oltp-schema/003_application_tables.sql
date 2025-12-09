-- Wide World Importers PostgreSQL Migration
-- Phase 2: OLTP Schema Migration
-- Script 003: Application Schema Tables
-- Migrated from SQL Server to PostgreSQL

-- Data Type Mappings:
-- datetime2 -> timestamp
-- nvarchar(n) -> varchar(n)
-- decimal(p,s) -> numeric(p,s)
-- varbinary(max) -> bytea
-- bit -> boolean
-- geography -> geometry (PostGIS)

-- =============================================
-- Application.People Table
-- =============================================
CREATE TABLE application.people (
    person_id integer NOT NULL DEFAULT nextval('sequences.person_id'),
    full_name varchar(50) NOT NULL,
    preferred_name varchar(50) NOT NULL,
    search_name varchar(101) GENERATED ALWAYS AS (preferred_name || ' ' || full_name) STORED NOT NULL,
    is_permitted_to_logon boolean NOT NULL,
    logon_name varchar(256) NULL,
    is_external_logon_provider boolean NOT NULL,
    hashed_password bytea NULL,
    is_system_user boolean NOT NULL,
    is_employee boolean NOT NULL,
    is_salesperson boolean NOT NULL,
    user_preferences text NULL,
    phone_number varchar(20) NULL,
    fax_number varchar(20) NULL,
    email_address varchar(256) NULL,
    photo bytea NULL,
    custom_fields jsonb NULL,
    other_languages jsonb GENERATED ALWAYS AS (custom_fields -> 'OtherLanguages') STORED,
    last_edited_by integer NOT NULL,
    valid_from timestamp NOT NULL DEFAULT clock_timestamp(),
    valid_to timestamp NOT NULL DEFAULT '9999-12-31 23:59:59.9999999'::timestamp,
    CONSTRAINT pk_application_people PRIMARY KEY (person_id)
);

-- History table for temporal data
CREATE TABLE application.people_archive (
    person_id integer NOT NULL,
    full_name varchar(50) NOT NULL,
    preferred_name varchar(50) NOT NULL,
    search_name varchar(101) NOT NULL,
    is_permitted_to_logon boolean NOT NULL,
    logon_name varchar(256) NULL,
    is_external_logon_provider boolean NOT NULL,
    hashed_password bytea NULL,
    is_system_user boolean NOT NULL,
    is_employee boolean NOT NULL,
    is_salesperson boolean NOT NULL,
    user_preferences text NULL,
    phone_number varchar(20) NULL,
    fax_number varchar(20) NULL,
    email_address varchar(256) NULL,
    photo bytea NULL,
    custom_fields jsonb NULL,
    other_languages jsonb NULL,
    last_edited_by integer NOT NULL,
    valid_from timestamp NOT NULL,
    valid_to timestamp NOT NULL
);

-- Indexes for People table
CREATE INDEX ix_application_people_is_employee ON application.people(is_employee);
CREATE INDEX ix_application_people_is_salesperson ON application.people(is_salesperson);
CREATE INDEX ix_application_people_full_name ON application.people(full_name);
CREATE INDEX ix_application_people_perf_20160301_05 ON application.people(is_permitted_to_logon, person_id) INCLUDE (full_name, email_address);

-- Comments
COMMENT ON TABLE application.people IS 'People known to the application (staff, customer contacts, supplier contacts)';
COMMENT ON COLUMN application.people.person_id IS 'Numeric ID used for reference to a person within the database';
COMMENT ON COLUMN application.people.full_name IS 'Full name for this person';
COMMENT ON COLUMN application.people.preferred_name IS 'Name that this person prefers to be called';
COMMENT ON COLUMN application.people.search_name IS 'Name to build full text search on (computed column)';
COMMENT ON COLUMN application.people.is_permitted_to_logon IS 'Is this person permitted to log on?';
COMMENT ON COLUMN application.people.logon_name IS 'Person''s system logon name';
COMMENT ON COLUMN application.people.is_external_logon_provider IS 'Is logon token provided by an external system?';
COMMENT ON COLUMN application.people.hashed_password IS 'Hash of password for users without external logon tokens';
COMMENT ON COLUMN application.people.is_system_user IS 'Is the currently permitted to make online access?';
COMMENT ON COLUMN application.people.is_employee IS 'Is this person an employee?';
COMMENT ON COLUMN application.people.is_salesperson IS 'Is this person a staff salesperson?';
COMMENT ON COLUMN application.people.user_preferences IS 'User preferences related to the website (holds JSON data)';
COMMENT ON COLUMN application.people.phone_number IS 'Phone number';
COMMENT ON COLUMN application.people.fax_number IS 'Fax number';
COMMENT ON COLUMN application.people.email_address IS 'Email address for this person';
COMMENT ON COLUMN application.people.photo IS 'Photo of this person';
COMMENT ON COLUMN application.people.custom_fields IS 'Custom fields for employees and salespeople';
COMMENT ON COLUMN application.people.other_languages IS 'Other languages spoken (computed column from custom fields)';

-- =============================================
-- Application.Countries Table
-- =============================================
CREATE TABLE application.countries (
    country_id integer NOT NULL DEFAULT nextval('sequences.country_id'),
    country_name varchar(60) NOT NULL,
    formal_name varchar(60) NOT NULL,
    iso_alpha3_code varchar(3) NULL,
    iso_numeric_code integer NULL,
    country_type varchar(20) NULL,
    latest_recorded_population bigint NULL,
    continent varchar(30) NOT NULL,
    region varchar(30) NOT NULL,
    subregion varchar(30) NOT NULL,
    border geometry NULL,
    last_edited_by integer NOT NULL,
    valid_from timestamp NOT NULL DEFAULT clock_timestamp(),
    valid_to timestamp NOT NULL DEFAULT '9999-12-31 23:59:59.9999999'::timestamp,
    CONSTRAINT pk_application_countries PRIMARY KEY (country_id),
    CONSTRAINT uq_application_countries_country_name UNIQUE (country_name),
    CONSTRAINT uq_application_countries_formal_name UNIQUE (formal_name)
);

-- History table for temporal data
CREATE TABLE application.countries_archive (
    country_id integer NOT NULL,
    country_name varchar(60) NOT NULL,
    formal_name varchar(60) NOT NULL,
    iso_alpha3_code varchar(3) NULL,
    iso_numeric_code integer NULL,
    country_type varchar(20) NULL,
    latest_recorded_population bigint NULL,
    continent varchar(30) NOT NULL,
    region varchar(30) NOT NULL,
    subregion varchar(30) NOT NULL,
    border geometry NULL,
    last_edited_by integer NOT NULL,
    valid_from timestamp NOT NULL,
    valid_to timestamp NOT NULL
);

-- Comments
COMMENT ON TABLE application.countries IS 'Countries that contain the states or provinces (including geographic boundaries)';
COMMENT ON COLUMN application.countries.country_id IS 'Numeric ID used for reference to a country within the database';
COMMENT ON COLUMN application.countries.country_name IS 'Name of the country';
COMMENT ON COLUMN application.countries.formal_name IS 'Full formal name of the country as recognized by ISO';
COMMENT ON COLUMN application.countries.iso_alpha3_code IS '3 letter alphabetic code assigned to the country by ISO';
COMMENT ON COLUMN application.countries.iso_numeric_code IS 'Numeric code assigned to the country by ISO';
COMMENT ON COLUMN application.countries.country_type IS 'Type of country or administrative region';
COMMENT ON COLUMN application.countries.latest_recorded_population IS 'Latest available population for the country';
COMMENT ON COLUMN application.countries.continent IS 'Name of the continent';
COMMENT ON COLUMN application.countries.region IS 'Name of the region';
COMMENT ON COLUMN application.countries.subregion IS 'Name of the subregion';
COMMENT ON COLUMN application.countries.border IS 'Geographic boundary of the country';

-- =============================================
-- Application.StateProvinces Table
-- =============================================
CREATE TABLE application.state_provinces (
    state_province_id integer NOT NULL DEFAULT nextval('sequences.state_province_id'),
    state_province_code varchar(5) NOT NULL,
    state_province_name varchar(50) NOT NULL,
    country_id integer NOT NULL,
    sales_territory varchar(50) NOT NULL,
    border geometry NULL,
    latest_recorded_population bigint NULL,
    last_edited_by integer NOT NULL,
    valid_from timestamp NOT NULL DEFAULT clock_timestamp(),
    valid_to timestamp NOT NULL DEFAULT '9999-12-31 23:59:59.9999999'::timestamp,
    CONSTRAINT pk_application_state_provinces PRIMARY KEY (state_province_id),
    CONSTRAINT uq_application_state_provinces_state_province_name UNIQUE (state_province_name)
);

-- History table for temporal data
CREATE TABLE application.state_provinces_archive (
    state_province_id integer NOT NULL,
    state_province_code varchar(5) NOT NULL,
    state_province_name varchar(50) NOT NULL,
    country_id integer NOT NULL,
    sales_territory varchar(50) NOT NULL,
    border geometry NULL,
    latest_recorded_population bigint NULL,
    last_edited_by integer NOT NULL,
    valid_from timestamp NOT NULL,
    valid_to timestamp NOT NULL
);

-- Indexes
CREATE INDEX fk_application_state_provinces_country_id ON application.state_provinces(country_id);
CREATE INDEX ix_application_state_provinces_sales_territory ON application.state_provinces(sales_territory);

-- Comments
COMMENT ON TABLE application.state_provinces IS 'States or provinces that contain cities (including geographic boundaries)';
COMMENT ON COLUMN application.state_provinces.state_province_id IS 'Numeric ID used for reference to a state or province within the database';
COMMENT ON COLUMN application.state_provinces.state_province_code IS 'Common code for this state or province (such as WA - Washington for the USA)';
COMMENT ON COLUMN application.state_provinces.state_province_name IS 'Formal name of the state or province';
COMMENT ON COLUMN application.state_provinces.country_id IS 'Country for this state or province';
COMMENT ON COLUMN application.state_provinces.sales_territory IS 'Sales territory for this state or province';
COMMENT ON COLUMN application.state_provinces.border IS 'Geographic boundary of the state or province';
COMMENT ON COLUMN application.state_provinces.latest_recorded_population IS 'Latest available population for the state or province';

-- =============================================
-- Application.Cities Table
-- =============================================
CREATE TABLE application.cities (
    city_id integer NOT NULL DEFAULT nextval('sequences.city_id'),
    city_name varchar(50) NOT NULL,
    state_province_id integer NOT NULL,
    location geometry NULL,
    latest_recorded_population bigint NULL,
    last_edited_by integer NOT NULL,
    valid_from timestamp NOT NULL DEFAULT clock_timestamp(),
    valid_to timestamp NOT NULL DEFAULT '9999-12-31 23:59:59.9999999'::timestamp,
    CONSTRAINT pk_application_cities PRIMARY KEY (city_id)
);

-- History table for temporal data
CREATE TABLE application.cities_archive (
    city_id integer NOT NULL,
    city_name varchar(50) NOT NULL,
    state_province_id integer NOT NULL,
    location geometry NULL,
    latest_recorded_population bigint NULL,
    last_edited_by integer NOT NULL,
    valid_from timestamp NOT NULL,
    valid_to timestamp NOT NULL
);

-- Indexes
CREATE INDEX fk_application_cities_state_province_id ON application.cities(state_province_id);

-- Comments
COMMENT ON TABLE application.cities IS 'Cities that are part of any address (including geographic location)';
COMMENT ON COLUMN application.cities.city_id IS 'Numeric ID used for reference to a city within the database';
COMMENT ON COLUMN application.cities.city_name IS 'Formal name of the city';
COMMENT ON COLUMN application.cities.state_province_id IS 'State or province for this city';
COMMENT ON COLUMN application.cities.location IS 'Geographic location of the city';
COMMENT ON COLUMN application.cities.latest_recorded_population IS 'Latest available population for the city';

-- =============================================
-- Application.DeliveryMethods Table
-- =============================================
CREATE TABLE application.delivery_methods (
    delivery_method_id integer NOT NULL DEFAULT nextval('sequences.delivery_method_id'),
    delivery_method_name varchar(50) NOT NULL,
    last_edited_by integer NOT NULL,
    valid_from timestamp NOT NULL DEFAULT clock_timestamp(),
    valid_to timestamp NOT NULL DEFAULT '9999-12-31 23:59:59.9999999'::timestamp,
    CONSTRAINT pk_application_delivery_methods PRIMARY KEY (delivery_method_id),
    CONSTRAINT uq_application_delivery_methods_delivery_method_name UNIQUE (delivery_method_name)
);

-- History table for temporal data
CREATE TABLE application.delivery_methods_archive (
    delivery_method_id integer NOT NULL,
    delivery_method_name varchar(50) NOT NULL,
    last_edited_by integer NOT NULL,
    valid_from timestamp NOT NULL,
    valid_to timestamp NOT NULL
);

-- Comments
COMMENT ON TABLE application.delivery_methods IS 'Ways that stock items can be delivered (such as post, courier, etc.)';
COMMENT ON COLUMN application.delivery_methods.delivery_method_id IS 'Numeric ID used for reference to a delivery method within the database';
COMMENT ON COLUMN application.delivery_methods.delivery_method_name IS 'Full name of methods that can be used for delivery of customer orders';

-- =============================================
-- Application.PaymentMethods Table
-- =============================================
CREATE TABLE application.payment_methods (
    payment_method_id integer NOT NULL DEFAULT nextval('sequences.payment_method_id'),
    payment_method_name varchar(50) NOT NULL,
    last_edited_by integer NOT NULL,
    valid_from timestamp NOT NULL DEFAULT clock_timestamp(),
    valid_to timestamp NOT NULL DEFAULT '9999-12-31 23:59:59.9999999'::timestamp,
    CONSTRAINT pk_application_payment_methods PRIMARY KEY (payment_method_id),
    CONSTRAINT uq_application_payment_methods_payment_method_name UNIQUE (payment_method_name)
);

-- History table for temporal data
CREATE TABLE application.payment_methods_archive (
    payment_method_id integer NOT NULL,
    payment_method_name varchar(50) NOT NULL,
    last_edited_by integer NOT NULL,
    valid_from timestamp NOT NULL,
    valid_to timestamp NOT NULL
);

-- Comments
COMMENT ON TABLE application.payment_methods IS 'Ways that payments can be made (such as cash, check, EFT, etc.)';
COMMENT ON COLUMN application.payment_methods.payment_method_id IS 'Numeric ID used for reference to a payment method within the database';
COMMENT ON COLUMN application.payment_methods.payment_method_name IS 'Full name of the payment method';

-- =============================================
-- Application.TransactionTypes Table
-- =============================================
CREATE TABLE application.transaction_types (
    transaction_type_id integer NOT NULL DEFAULT nextval('sequences.transaction_type_id'),
    transaction_type_name varchar(50) NOT NULL,
    last_edited_by integer NOT NULL,
    valid_from timestamp NOT NULL DEFAULT clock_timestamp(),
    valid_to timestamp NOT NULL DEFAULT '9999-12-31 23:59:59.9999999'::timestamp,
    CONSTRAINT pk_application_transaction_types PRIMARY KEY (transaction_type_id),
    CONSTRAINT uq_application_transaction_types_transaction_type_name UNIQUE (transaction_type_name)
);

-- History table for temporal data
CREATE TABLE application.transaction_types_archive (
    transaction_type_id integer NOT NULL,
    transaction_type_name varchar(50) NOT NULL,
    last_edited_by integer NOT NULL,
    valid_from timestamp NOT NULL,
    valid_to timestamp NOT NULL
);

-- Comments
COMMENT ON TABLE application.transaction_types IS 'Types of customer, supplier, or stock transactions (such as invoice, credit note, etc.)';
COMMENT ON COLUMN application.transaction_types.transaction_type_id IS 'Numeric ID used for reference to a transaction type within the database';
COMMENT ON COLUMN application.transaction_types.transaction_type_name IS 'Full name of the transaction type';

-- =============================================
-- Application.SystemParameters Table
-- =============================================
CREATE TABLE application.system_parameters (
    system_parameter_id integer NOT NULL DEFAULT nextval('sequences.system_parameter_id'),
    delivery_address_line_1 varchar(60) NOT NULL,
    delivery_address_line_2 varchar(60) NULL,
    delivery_city_id integer NOT NULL,
    delivery_postal_code varchar(10) NOT NULL,
    delivery_location geometry NOT NULL,
    postal_address_line_1 varchar(60) NOT NULL,
    postal_address_line_2 varchar(60) NULL,
    postal_city_id integer NOT NULL,
    postal_postal_code varchar(10) NOT NULL,
    application_settings text NOT NULL,
    last_edited_by integer NOT NULL,
    last_edited_when timestamp NOT NULL DEFAULT clock_timestamp(),
    CONSTRAINT pk_application_system_parameters PRIMARY KEY (system_parameter_id)
);

-- Indexes
CREATE INDEX fk_application_system_parameters_delivery_city_id ON application.system_parameters(delivery_city_id);
CREATE INDEX fk_application_system_parameters_postal_city_id ON application.system_parameters(postal_city_id);

-- Comments
COMMENT ON TABLE application.system_parameters IS 'Any configurable parameters for the whole system';
COMMENT ON COLUMN application.system_parameters.system_parameter_id IS 'Numeric ID used for row holding system parameters';
COMMENT ON COLUMN application.system_parameters.delivery_address_line_1 IS 'First address line for the company';
COMMENT ON COLUMN application.system_parameters.delivery_address_line_2 IS 'Second address line for the company';
COMMENT ON COLUMN application.system_parameters.delivery_city_id IS 'ID of the city for this address';
COMMENT ON COLUMN application.system_parameters.delivery_postal_code IS 'Postal code for the company';
COMMENT ON COLUMN application.system_parameters.delivery_location IS 'Geographic location for the company office';
COMMENT ON COLUMN application.system_parameters.postal_address_line_1 IS 'First postal address line for the company';
COMMENT ON COLUMN application.system_parameters.postal_address_line_2 IS 'Second postal address line for the company';
COMMENT ON COLUMN application.system_parameters.postal_city_id IS 'ID of the city for this postal address';
COMMENT ON COLUMN application.system_parameters.postal_postal_code IS 'Postal code for the company when sending via mail';
COMMENT ON COLUMN application.system_parameters.application_settings IS 'JSON-structured application settings';

-- =============================================
-- Application.Logs Table (non-temporal)
-- =============================================
CREATE TABLE application.logs (
    log_id bigserial NOT NULL,
    logged_when timestamp NOT NULL DEFAULT clock_timestamp(),
    logged_by varchar(256) NOT NULL,
    event_type varchar(50) NOT NULL,
    event_description text NOT NULL,
    CONSTRAINT pk_application_logs PRIMARY KEY (log_id)
);

-- Indexes
CREATE INDEX ix_application_logs_logged_when ON application.logs(logged_when);

-- Comments
COMMENT ON TABLE application.logs IS 'Application event logs';
COMMENT ON COLUMN application.logs.log_id IS 'Numeric ID for the log entry';
COMMENT ON COLUMN application.logs.logged_when IS 'When the event was logged';
COMMENT ON COLUMN application.logs.logged_by IS 'Who logged the event';
COMMENT ON COLUMN application.logs.event_type IS 'Type of event';
COMMENT ON COLUMN application.logs.event_description IS 'Description of the event';
