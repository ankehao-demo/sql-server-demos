-- Wide World Importers PostgreSQL Migration
-- Phase 2: OLTP Schema Migration
-- Application.SystemParameters table (non-temporal)

CREATE TABLE application.system_parameters (
    system_parameter_id INTEGER NOT NULL DEFAULT nextval('sequences.system_parameter_id'),
    delivery_address_line1 VARCHAR(60) NOT NULL,
    delivery_address_line2 VARCHAR(60) NULL,
    delivery_city_id INTEGER NOT NULL,
    delivery_postal_code VARCHAR(10) NOT NULL,
    delivery_location GEOGRAPHY(Point, 4326) NOT NULL,
    postal_address_line1 VARCHAR(60) NOT NULL,
    postal_address_line2 VARCHAR(60) NULL,
    postal_city_id INTEGER NOT NULL,
    postal_postal_code VARCHAR(10) NOT NULL,
    application_settings JSONB NOT NULL,
    last_edited_by INTEGER NOT NULL,
    last_edited_when TIMESTAMP NOT NULL DEFAULT clock_timestamp(),
    
    CONSTRAINT pk_application_system_parameters PRIMARY KEY (system_parameter_id),
    CONSTRAINT fk_application_system_parameters_delivery_city 
        FOREIGN KEY (delivery_city_id) REFERENCES application.cities(city_id),
    CONSTRAINT fk_application_system_parameters_postal_city 
        FOREIGN KEY (postal_city_id) REFERENCES application.cities(city_id),
    CONSTRAINT fk_application_system_parameters_last_edited_by 
        FOREIGN KEY (last_edited_by) REFERENCES application.people(person_id)
);

-- Indexes for foreign keys
CREATE INDEX ix_application_system_parameters_delivery_city_id 
    ON application.system_parameters(delivery_city_id);
CREATE INDEX ix_application_system_parameters_postal_city_id 
    ON application.system_parameters(postal_city_id);
