-- Wide World Importers Data Warehouse - PostgreSQL Schema Migration
-- Phase 4: OLAP Schema Migration
-- Dimension: Employee

CREATE TABLE dimension.employee (
    employee_key        INTEGER NOT NULL DEFAULT nextval('sequences.employee_key'),
    wwi_employee_id     INTEGER NOT NULL,
    employee            VARCHAR(50) NOT NULL,
    preferred_name      VARCHAR(50) NOT NULL,
    is_salesperson      BOOLEAN NOT NULL,
    photo               BYTEA,
    valid_from          TIMESTAMP NOT NULL,
    valid_to            TIMESTAMP NOT NULL,
    lineage_key         INTEGER NOT NULL,

    CONSTRAINT pk_dimension_employee PRIMARY KEY (employee_key)
);

-- Create index for WWI Employee ID lookups (SCD Type 2 pattern)
CREATE INDEX ix_dimension_employee_wwi_employee_id 
    ON dimension.employee (wwi_employee_id, valid_from, valid_to);

-- Add table and column comments
COMMENT ON TABLE dimension.employee IS 'Employee dimension';
COMMENT ON COLUMN dimension.employee.employee_key IS 'DW key for the employee dimension';
COMMENT ON COLUMN dimension.employee.wwi_employee_id IS 'Numeric ID (PersonID) in the WWI database';
COMMENT ON COLUMN dimension.employee.employee IS 'Full name for this person';
COMMENT ON COLUMN dimension.employee.preferred_name IS 'Name that this person prefers to be called';
COMMENT ON COLUMN dimension.employee.is_salesperson IS 'Is this person a staff salesperson?';
COMMENT ON COLUMN dimension.employee.photo IS 'Photo of this person';
COMMENT ON COLUMN dimension.employee.valid_from IS 'Valid from this date and time';
COMMENT ON COLUMN dimension.employee.valid_to IS 'Valid until this date and time';
COMMENT ON COLUMN dimension.employee.lineage_key IS 'Lineage Key for the data load for this row';
COMMENT ON INDEX dimension.ix_dimension_employee_wwi_employee_id IS 'Allows quickly locating by WWI ID';
