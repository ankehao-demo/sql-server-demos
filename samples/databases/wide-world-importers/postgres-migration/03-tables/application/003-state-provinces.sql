-- Wide World Importers PostgreSQL Migration
-- Phase 2: OLTP Schema Migration
-- Application.StateProvinces table (temporal table)

-- Main table
CREATE TABLE application.state_provinces (
    state_province_id INTEGER NOT NULL DEFAULT nextval('sequences.state_province_id'),
    state_province_code VARCHAR(5) NOT NULL,
    state_province_name VARCHAR(50) NOT NULL,
    country_id INTEGER NOT NULL,
    sales_territory VARCHAR(50) NOT NULL,
    border GEOGRAPHY(Geometry, 4326) NULL,
    latest_recorded_population BIGINT NULL,
    last_edited_by INTEGER NOT NULL,
    valid_from TIMESTAMP NOT NULL DEFAULT clock_timestamp(),
    valid_to TIMESTAMP NOT NULL DEFAULT '9999-12-31 23:59:59.999999'::timestamp,
    
    CONSTRAINT pk_application_state_provinces PRIMARY KEY (state_province_id),
    CONSTRAINT uq_application_state_provinces_state_province_name UNIQUE (state_province_name),
    CONSTRAINT fk_application_state_provinces_country 
        FOREIGN KEY (country_id) REFERENCES application.countries(country_id),
    CONSTRAINT fk_application_state_provinces_last_edited_by 
        FOREIGN KEY (last_edited_by) REFERENCES application.people(person_id)
);

-- History/Archive table for temporal data
CREATE TABLE application.state_provinces_archive (
    state_province_id INTEGER NOT NULL,
    state_province_code VARCHAR(5) NOT NULL,
    state_province_name VARCHAR(50) NOT NULL,
    country_id INTEGER NOT NULL,
    sales_territory VARCHAR(50) NOT NULL,
    border GEOGRAPHY(Geometry, 4326) NULL,
    latest_recorded_population BIGINT NULL,
    last_edited_by INTEGER NOT NULL,
    valid_from TIMESTAMP NOT NULL,
    valid_to TIMESTAMP NOT NULL,
    
    CONSTRAINT pk_application_state_provinces_archive PRIMARY KEY (state_province_id, valid_from)
);
