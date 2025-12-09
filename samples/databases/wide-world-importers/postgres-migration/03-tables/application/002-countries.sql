-- Wide World Importers PostgreSQL Migration
-- Phase 2: OLTP Schema Migration
-- Application.Countries table (temporal table)

-- Main table
CREATE TABLE application.countries (
    country_id INTEGER NOT NULL DEFAULT nextval('sequences.country_id'),
    country_name VARCHAR(60) NOT NULL,
    formal_name VARCHAR(60) NOT NULL,
    iso_alpha3_code VARCHAR(3) NULL,
    iso_numeric_code INTEGER NULL,
    country_type VARCHAR(20) NULL,
    latest_recorded_population BIGINT NULL,
    continent VARCHAR(30) NOT NULL,
    region VARCHAR(30) NOT NULL,
    subregion VARCHAR(30) NOT NULL,
    border GEOGRAPHY(Geometry, 4326) NULL,
    last_edited_by INTEGER NOT NULL,
    valid_from TIMESTAMP NOT NULL DEFAULT clock_timestamp(),
    valid_to TIMESTAMP NOT NULL DEFAULT '9999-12-31 23:59:59.999999'::timestamp,
    
    CONSTRAINT pk_application_countries PRIMARY KEY (country_id),
    CONSTRAINT uq_application_countries_country_name UNIQUE (country_name),
    CONSTRAINT uq_application_countries_formal_name UNIQUE (formal_name),
    CONSTRAINT fk_application_countries_last_edited_by 
        FOREIGN KEY (last_edited_by) REFERENCES application.people(person_id)
);

-- History/Archive table for temporal data
CREATE TABLE application.countries_archive (
    country_id INTEGER NOT NULL,
    country_name VARCHAR(60) NOT NULL,
    formal_name VARCHAR(60) NOT NULL,
    iso_alpha3_code VARCHAR(3) NULL,
    iso_numeric_code INTEGER NULL,
    country_type VARCHAR(20) NULL,
    latest_recorded_population BIGINT NULL,
    continent VARCHAR(30) NOT NULL,
    region VARCHAR(30) NOT NULL,
    subregion VARCHAR(30) NOT NULL,
    border GEOGRAPHY(Geometry, 4326) NULL,
    last_edited_by INTEGER NOT NULL,
    valid_from TIMESTAMP NOT NULL,
    valid_to TIMESTAMP NOT NULL,
    
    CONSTRAINT pk_application_countries_archive PRIMARY KEY (country_id, valid_from)
);
