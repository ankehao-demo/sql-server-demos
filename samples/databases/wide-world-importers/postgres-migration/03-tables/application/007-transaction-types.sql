-- Wide World Importers PostgreSQL Migration
-- Phase 2: OLTP Schema Migration
-- Application.TransactionTypes table (temporal table)

-- Main table
CREATE TABLE application.transaction_types (
    transaction_type_id INTEGER NOT NULL DEFAULT nextval('sequences.transaction_type_id'),
    transaction_type_name VARCHAR(50) NOT NULL,
    last_edited_by INTEGER NOT NULL,
    valid_from TIMESTAMP NOT NULL DEFAULT clock_timestamp(),
    valid_to TIMESTAMP NOT NULL DEFAULT '9999-12-31 23:59:59.999999'::timestamp,
    
    CONSTRAINT pk_application_transaction_types PRIMARY KEY (transaction_type_id),
    CONSTRAINT uq_application_transaction_types_transaction_type_name UNIQUE (transaction_type_name),
    CONSTRAINT fk_application_transaction_types_last_edited_by 
        FOREIGN KEY (last_edited_by) REFERENCES application.people(person_id)
);

-- History/Archive table for temporal data
CREATE TABLE application.transaction_types_archive (
    transaction_type_id INTEGER NOT NULL,
    transaction_type_name VARCHAR(50) NOT NULL,
    last_edited_by INTEGER NOT NULL,
    valid_from TIMESTAMP NOT NULL,
    valid_to TIMESTAMP NOT NULL,
    
    CONSTRAINT pk_application_transaction_types_archive PRIMARY KEY (transaction_type_id, valid_from)
);
