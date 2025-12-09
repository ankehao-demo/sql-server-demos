-- Wide World Importers PostgreSQL Migration
-- Phase 2: OLTP Schema Migration
-- Application.People table (temporal table)

-- Main table
CREATE TABLE application.people (
    person_id INTEGER NOT NULL DEFAULT nextval('sequences.person_id'),
    full_name VARCHAR(50) NOT NULL,
    preferred_name VARCHAR(50) NOT NULL,
    search_name VARCHAR(101) GENERATED ALWAYS AS (preferred_name || ' ' || full_name) STORED,
    is_permitted_to_logon BOOLEAN NOT NULL,
    logon_name VARCHAR(256) NULL,
    is_external_logon_provider BOOLEAN NOT NULL,
    hashed_password BYTEA NULL,
    is_system_user BOOLEAN NOT NULL,
    is_employee BOOLEAN NOT NULL,
    is_salesperson BOOLEAN NOT NULL,
    user_preferences TEXT NULL,
    phone_number VARCHAR(20) NULL,
    fax_number VARCHAR(20) NULL,
    email_address VARCHAR(256) NULL,
    photo BYTEA NULL,
    custom_fields JSONB NULL,
    other_languages JSONB GENERATED ALWAYS AS (custom_fields -> 'OtherLanguages') STORED,
    last_edited_by INTEGER NOT NULL,
    valid_from TIMESTAMP NOT NULL DEFAULT clock_timestamp(),
    valid_to TIMESTAMP NOT NULL DEFAULT '9999-12-31 23:59:59.999999'::timestamp,
    
    CONSTRAINT pk_application_people PRIMARY KEY (person_id),
    CONSTRAINT uq_application_people_full_name UNIQUE (full_name)
);

-- History/Archive table for temporal data
CREATE TABLE application.people_archive (
    person_id INTEGER NOT NULL,
    full_name VARCHAR(50) NOT NULL,
    preferred_name VARCHAR(50) NOT NULL,
    search_name VARCHAR(101),
    is_permitted_to_logon BOOLEAN NOT NULL,
    logon_name VARCHAR(256) NULL,
    is_external_logon_provider BOOLEAN NOT NULL,
    hashed_password BYTEA NULL,
    is_system_user BOOLEAN NOT NULL,
    is_employee BOOLEAN NOT NULL,
    is_salesperson BOOLEAN NOT NULL,
    user_preferences TEXT NULL,
    phone_number VARCHAR(20) NULL,
    fax_number VARCHAR(20) NULL,
    email_address VARCHAR(256) NULL,
    photo BYTEA NULL,
    custom_fields JSONB NULL,
    other_languages JSONB,
    last_edited_by INTEGER NOT NULL,
    valid_from TIMESTAMP NOT NULL,
    valid_to TIMESTAMP NOT NULL,
    
    CONSTRAINT pk_application_people_archive PRIMARY KEY (person_id, valid_from)
);

-- Add self-referential foreign key after table creation
ALTER TABLE application.people 
    ADD CONSTRAINT fk_application_people_last_edited_by 
    FOREIGN KEY (last_edited_by) REFERENCES application.people(person_id);
