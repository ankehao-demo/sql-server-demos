-- Wide World Importers PostgreSQL Migration
-- Phase 2: OLTP Schema Migration
-- Application.PaymentMethods table (temporal table)

-- Main table
CREATE TABLE application.payment_methods (
    payment_method_id INTEGER NOT NULL DEFAULT nextval('sequences.payment_method_id'),
    payment_method_name VARCHAR(50) NOT NULL,
    last_edited_by INTEGER NOT NULL,
    valid_from TIMESTAMP NOT NULL DEFAULT clock_timestamp(),
    valid_to TIMESTAMP NOT NULL DEFAULT '9999-12-31 23:59:59.999999'::timestamp,
    
    CONSTRAINT pk_application_payment_methods PRIMARY KEY (payment_method_id),
    CONSTRAINT uq_application_payment_methods_payment_method_name UNIQUE (payment_method_name),
    CONSTRAINT fk_application_payment_methods_last_edited_by 
        FOREIGN KEY (last_edited_by) REFERENCES application.people(person_id)
);

-- History/Archive table for temporal data
CREATE TABLE application.payment_methods_archive (
    payment_method_id INTEGER NOT NULL,
    payment_method_name VARCHAR(50) NOT NULL,
    last_edited_by INTEGER NOT NULL,
    valid_from TIMESTAMP NOT NULL,
    valid_to TIMESTAMP NOT NULL,
    
    CONSTRAINT pk_application_payment_methods_archive PRIMARY KEY (payment_method_id, valid_from)
);
