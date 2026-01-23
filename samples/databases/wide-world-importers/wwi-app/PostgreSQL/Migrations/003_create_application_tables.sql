-- Wide World Importers PostgreSQL Migration
-- Script 003: Create Application Schema Tables
-- Migrated from SQL Server to PostgreSQL

-- Data Type Mapping Reference:
-- SQL Server NVARCHAR(n) -> PostgreSQL VARCHAR(n) or TEXT
-- SQL Server NVARCHAR(MAX) -> PostgreSQL TEXT
-- SQL Server DATETIME2(7) -> PostgreSQL TIMESTAMP(6)
-- SQL Server DATE -> PostgreSQL DATE
-- SQL Server BIT -> PostgreSQL BOOLEAN
-- SQL Server INT -> PostgreSQL INTEGER
-- SQL Server BIGINT -> PostgreSQL BIGINT
-- SQL Server DECIMAL(p,s) -> PostgreSQL NUMERIC(p,s)
-- SQL Server VARBINARY(MAX) -> PostgreSQL BYTEA
-- SQL Server geography -> PostgreSQL GEOGRAPHY (PostGIS)

-- Countries table (with temporal/history support)
CREATE TABLE IF NOT EXISTS application.countries (
    country_id INTEGER NOT NULL DEFAULT nextval('application.country_id_seq'),
    country_name VARCHAR(60) NOT NULL,
    formal_name VARCHAR(60) NOT NULL,
    iso_alpha3_code VARCHAR(3),
    iso_numeric_code INTEGER,
    country_type VARCHAR(20),
    latest_recorded_population BIGINT,
    continent VARCHAR(30) NOT NULL,
    region VARCHAR(30) NOT NULL,
    subregion VARCHAR(30) NOT NULL,
    border GEOGRAPHY(MULTIPOLYGON, 4326),
    last_edited_by INTEGER NOT NULL,
    valid_from TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    valid_to TIMESTAMP(6) NOT NULL DEFAULT '9999-12-31 23:59:59.999999',
    CONSTRAINT pk_application_countries PRIMARY KEY (country_id),
    CONSTRAINT uq_application_countries_country_name UNIQUE (country_name),
    CONSTRAINT uq_application_countries_formal_name UNIQUE (formal_name)
);

-- Countries archive table for temporal data
CREATE TABLE IF NOT EXISTS application.countries_archive (
    country_id INTEGER NOT NULL,
    country_name VARCHAR(60) NOT NULL,
    formal_name VARCHAR(60) NOT NULL,
    iso_alpha3_code VARCHAR(3),
    iso_numeric_code INTEGER,
    country_type VARCHAR(20),
    latest_recorded_population BIGINT,
    continent VARCHAR(30) NOT NULL,
    region VARCHAR(30) NOT NULL,
    subregion VARCHAR(30) NOT NULL,
    border GEOGRAPHY(MULTIPOLYGON, 4326),
    last_edited_by INTEGER NOT NULL,
    valid_from TIMESTAMP(6) NOT NULL,
    valid_to TIMESTAMP(6) NOT NULL
);

-- State Provinces table
CREATE TABLE IF NOT EXISTS application.state_provinces (
    state_province_id INTEGER NOT NULL DEFAULT nextval('application.state_province_id_seq'),
    state_province_code VARCHAR(5) NOT NULL,
    state_province_name VARCHAR(50) NOT NULL,
    country_id INTEGER NOT NULL,
    sales_territory VARCHAR(50) NOT NULL,
    border GEOGRAPHY(MULTIPOLYGON, 4326),
    latest_recorded_population BIGINT,
    last_edited_by INTEGER NOT NULL,
    valid_from TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    valid_to TIMESTAMP(6) NOT NULL DEFAULT '9999-12-31 23:59:59.999999',
    CONSTRAINT pk_application_state_provinces PRIMARY KEY (state_province_id),
    CONSTRAINT uq_application_state_provinces_state_province_name UNIQUE (state_province_name),
    CONSTRAINT fk_application_state_provinces_country_id FOREIGN KEY (country_id) 
        REFERENCES application.countries (country_id)
);

-- State Provinces archive table
CREATE TABLE IF NOT EXISTS application.state_provinces_archive (
    state_province_id INTEGER NOT NULL,
    state_province_code VARCHAR(5) NOT NULL,
    state_province_name VARCHAR(50) NOT NULL,
    country_id INTEGER NOT NULL,
    sales_territory VARCHAR(50) NOT NULL,
    border GEOGRAPHY(MULTIPOLYGON, 4326),
    latest_recorded_population BIGINT,
    last_edited_by INTEGER NOT NULL,
    valid_from TIMESTAMP(6) NOT NULL,
    valid_to TIMESTAMP(6) NOT NULL
);

-- Cities table
CREATE TABLE IF NOT EXISTS application.cities (
    city_id INTEGER NOT NULL DEFAULT nextval('application.city_id_seq'),
    city_name VARCHAR(50) NOT NULL,
    state_province_id INTEGER NOT NULL,
    location GEOGRAPHY(POINT, 4326),
    latest_recorded_population BIGINT,
    last_edited_by INTEGER NOT NULL,
    valid_from TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    valid_to TIMESTAMP(6) NOT NULL DEFAULT '9999-12-31 23:59:59.999999',
    CONSTRAINT pk_application_cities PRIMARY KEY (city_id),
    CONSTRAINT fk_application_cities_state_province_id FOREIGN KEY (state_province_id) 
        REFERENCES application.state_provinces (state_province_id)
);

-- Cities archive table
CREATE TABLE IF NOT EXISTS application.cities_archive (
    city_id INTEGER NOT NULL,
    city_name VARCHAR(50) NOT NULL,
    state_province_id INTEGER NOT NULL,
    location GEOGRAPHY(POINT, 4326),
    latest_recorded_population BIGINT,
    last_edited_by INTEGER NOT NULL,
    valid_from TIMESTAMP(6) NOT NULL,
    valid_to TIMESTAMP(6) NOT NULL
);

-- People table
CREATE TABLE IF NOT EXISTS application.people (
    person_id INTEGER NOT NULL DEFAULT nextval('application.person_id_seq'),
    full_name VARCHAR(50) NOT NULL,
    preferred_name VARCHAR(50) NOT NULL,
    search_name VARCHAR(101) GENERATED ALWAYS AS (preferred_name || ' ' || full_name) STORED,
    is_permitted_to_logon BOOLEAN NOT NULL,
    logon_name VARCHAR(256),
    is_external_logon_provider BOOLEAN NOT NULL,
    hashed_password BYTEA,
    is_system_user BOOLEAN NOT NULL,
    is_employee BOOLEAN NOT NULL,
    is_salesperson BOOLEAN NOT NULL,
    user_preferences TEXT,
    phone_number VARCHAR(20),
    fax_number VARCHAR(20),
    email_address VARCHAR(256),
    photo BYTEA,
    custom_fields JSONB,
    last_edited_by INTEGER NOT NULL,
    valid_from TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    valid_to TIMESTAMP(6) NOT NULL DEFAULT '9999-12-31 23:59:59.999999',
    CONSTRAINT pk_application_people PRIMARY KEY (person_id)
);

-- People archive table
CREATE TABLE IF NOT EXISTS application.people_archive (
    person_id INTEGER NOT NULL,
    full_name VARCHAR(50) NOT NULL,
    preferred_name VARCHAR(50) NOT NULL,
    search_name VARCHAR(101),
    is_permitted_to_logon BOOLEAN NOT NULL,
    logon_name VARCHAR(256),
    is_external_logon_provider BOOLEAN NOT NULL,
    hashed_password BYTEA,
    is_system_user BOOLEAN NOT NULL,
    is_employee BOOLEAN NOT NULL,
    is_salesperson BOOLEAN NOT NULL,
    user_preferences TEXT,
    phone_number VARCHAR(20),
    fax_number VARCHAR(20),
    email_address VARCHAR(256),
    photo BYTEA,
    custom_fields JSONB,
    last_edited_by INTEGER NOT NULL,
    valid_from TIMESTAMP(6) NOT NULL,
    valid_to TIMESTAMP(6) NOT NULL
);

-- Delivery Methods table
CREATE TABLE IF NOT EXISTS application.delivery_methods (
    delivery_method_id INTEGER NOT NULL DEFAULT nextval('application.delivery_method_id_seq'),
    delivery_method_name VARCHAR(50) NOT NULL,
    last_edited_by INTEGER NOT NULL,
    valid_from TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    valid_to TIMESTAMP(6) NOT NULL DEFAULT '9999-12-31 23:59:59.999999',
    CONSTRAINT pk_application_delivery_methods PRIMARY KEY (delivery_method_id),
    CONSTRAINT uq_application_delivery_methods_delivery_method_name UNIQUE (delivery_method_name),
    CONSTRAINT fk_application_delivery_methods_last_edited_by FOREIGN KEY (last_edited_by) 
        REFERENCES application.people (person_id)
);

-- Delivery Methods archive table
CREATE TABLE IF NOT EXISTS application.delivery_methods_archive (
    delivery_method_id INTEGER NOT NULL,
    delivery_method_name VARCHAR(50) NOT NULL,
    last_edited_by INTEGER NOT NULL,
    valid_from TIMESTAMP(6) NOT NULL,
    valid_to TIMESTAMP(6) NOT NULL
);

-- Payment Methods table
CREATE TABLE IF NOT EXISTS application.payment_methods (
    payment_method_id INTEGER NOT NULL DEFAULT nextval('application.payment_method_id_seq'),
    payment_method_name VARCHAR(50) NOT NULL,
    last_edited_by INTEGER NOT NULL,
    valid_from TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    valid_to TIMESTAMP(6) NOT NULL DEFAULT '9999-12-31 23:59:59.999999',
    CONSTRAINT pk_application_payment_methods PRIMARY KEY (payment_method_id),
    CONSTRAINT uq_application_payment_methods_payment_method_name UNIQUE (payment_method_name),
    CONSTRAINT fk_application_payment_methods_last_edited_by FOREIGN KEY (last_edited_by) 
        REFERENCES application.people (person_id)
);

-- Payment Methods archive table
CREATE TABLE IF NOT EXISTS application.payment_methods_archive (
    payment_method_id INTEGER NOT NULL,
    payment_method_name VARCHAR(50) NOT NULL,
    last_edited_by INTEGER NOT NULL,
    valid_from TIMESTAMP(6) NOT NULL,
    valid_to TIMESTAMP(6) NOT NULL
);

-- Transaction Types table
CREATE TABLE IF NOT EXISTS application.transaction_types (
    transaction_type_id INTEGER NOT NULL DEFAULT nextval('application.transaction_type_id_seq'),
    transaction_type_name VARCHAR(50) NOT NULL,
    last_edited_by INTEGER NOT NULL,
    valid_from TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    valid_to TIMESTAMP(6) NOT NULL DEFAULT '9999-12-31 23:59:59.999999',
    CONSTRAINT pk_application_transaction_types PRIMARY KEY (transaction_type_id),
    CONSTRAINT uq_application_transaction_types_transaction_type_name UNIQUE (transaction_type_name),
    CONSTRAINT fk_application_transaction_types_last_edited_by FOREIGN KEY (last_edited_by) 
        REFERENCES application.people (person_id)
);

-- Transaction Types archive table
CREATE TABLE IF NOT EXISTS application.transaction_types_archive (
    transaction_type_id INTEGER NOT NULL,
    transaction_type_name VARCHAR(50) NOT NULL,
    last_edited_by INTEGER NOT NULL,
    valid_from TIMESTAMP(6) NOT NULL,
    valid_to TIMESTAMP(6) NOT NULL
);

-- System Parameters table
CREATE TABLE IF NOT EXISTS application.system_parameters (
    system_parameter_id INTEGER NOT NULL DEFAULT nextval('application.system_parameter_id_seq'),
    delivery_address_line_1 VARCHAR(60) NOT NULL,
    delivery_address_line_2 VARCHAR(60),
    delivery_city_id INTEGER NOT NULL,
    delivery_postal_code VARCHAR(10) NOT NULL,
    delivery_location GEOGRAPHY(POINT, 4326) NOT NULL,
    postal_address_line_1 VARCHAR(60) NOT NULL,
    postal_address_line_2 VARCHAR(60),
    postal_city_id INTEGER NOT NULL,
    postal_postal_code VARCHAR(10) NOT NULL,
    application_settings TEXT NOT NULL,
    last_edited_by INTEGER NOT NULL,
    last_edited_when TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT pk_application_system_parameters PRIMARY KEY (system_parameter_id),
    CONSTRAINT fk_application_system_parameters_delivery_city_id FOREIGN KEY (delivery_city_id) 
        REFERENCES application.cities (city_id),
    CONSTRAINT fk_application_system_parameters_postal_city_id FOREIGN KEY (postal_city_id) 
        REFERENCES application.cities (city_id),
    CONSTRAINT fk_application_system_parameters_last_edited_by FOREIGN KEY (last_edited_by) 
        REFERENCES application.people (person_id)
);

-- Application Logs table (non-temporal)
CREATE TABLE IF NOT EXISTS application.logs (
    log_id BIGSERIAL NOT NULL,
    logged_when TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    logged_by VARCHAR(256) NOT NULL,
    event_type VARCHAR(50) NOT NULL,
    event_description TEXT NOT NULL,
    CONSTRAINT pk_application_logs PRIMARY KEY (log_id)
);

-- Add self-referential foreign key for people.last_edited_by
ALTER TABLE application.people 
    ADD CONSTRAINT fk_application_people_last_edited_by 
    FOREIGN KEY (last_edited_by) REFERENCES application.people (person_id);

-- Add foreign keys for countries and state_provinces
ALTER TABLE application.countries 
    ADD CONSTRAINT fk_application_countries_last_edited_by 
    FOREIGN KEY (last_edited_by) REFERENCES application.people (person_id);

ALTER TABLE application.state_provinces 
    ADD CONSTRAINT fk_application_state_provinces_last_edited_by 
    FOREIGN KEY (last_edited_by) REFERENCES application.people (person_id);

ALTER TABLE application.cities 
    ADD CONSTRAINT fk_application_cities_last_edited_by 
    FOREIGN KEY (last_edited_by) REFERENCES application.people (person_id);

-- Add comments for documentation
COMMENT ON TABLE application.countries IS 'Countries that contain addresses (including geographic boundaries)';
COMMENT ON TABLE application.state_provinces IS 'States or provinces that contain cities (including geographic boundaries)';
COMMENT ON TABLE application.cities IS 'Cities that are part of any address (including geographic location)';
COMMENT ON TABLE application.people IS 'People known to the application (staff, customer contacts, supplier contacts)';
COMMENT ON TABLE application.delivery_methods IS 'Ways that stock items can be delivered (e.g., courier, post, etc.)';
COMMENT ON TABLE application.payment_methods IS 'Ways that payments can be made (e.g., cash, check, EFT, etc.)';
COMMENT ON TABLE application.transaction_types IS 'Types of customer, supplier, or stock transactions (e.g., invoice, credit note, etc.)';
COMMENT ON TABLE application.system_parameters IS 'System-wide parameters and settings';
COMMENT ON TABLE application.logs IS 'Application event logs';
