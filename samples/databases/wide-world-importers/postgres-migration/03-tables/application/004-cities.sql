-- Wide World Importers PostgreSQL Migration
-- Phase 2: OLTP Schema Migration
-- Application.Cities table (temporal table)

-- Main table
CREATE TABLE application.cities (
    city_id INTEGER NOT NULL DEFAULT nextval('sequences.city_id'),
    city_name VARCHAR(50) NOT NULL,
    state_province_id INTEGER NOT NULL,
    location GEOGRAPHY(Point, 4326) NULL,
    latest_recorded_population BIGINT NULL,
    last_edited_by INTEGER NOT NULL,
    valid_from TIMESTAMP NOT NULL DEFAULT clock_timestamp(),
    valid_to TIMESTAMP NOT NULL DEFAULT '9999-12-31 23:59:59.999999'::timestamp,
    
    CONSTRAINT pk_application_cities PRIMARY KEY (city_id),
    CONSTRAINT fk_application_cities_state_province 
        FOREIGN KEY (state_province_id) REFERENCES application.state_provinces(state_province_id),
    CONSTRAINT fk_application_cities_last_edited_by 
        FOREIGN KEY (last_edited_by) REFERENCES application.people(person_id)
);

-- History/Archive table for temporal data
CREATE TABLE application.cities_archive (
    city_id INTEGER NOT NULL,
    city_name VARCHAR(50) NOT NULL,
    state_province_id INTEGER NOT NULL,
    location GEOGRAPHY(Point, 4326) NULL,
    latest_recorded_population BIGINT NULL,
    last_edited_by INTEGER NOT NULL,
    valid_from TIMESTAMP NOT NULL,
    valid_to TIMESTAMP NOT NULL,
    
    CONSTRAINT pk_application_cities_archive PRIMARY KEY (city_id, valid_from)
);
