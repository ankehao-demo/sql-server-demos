-- Wide World Importers PostgreSQL Migration
-- Schema Creation Script
-- This script creates all schemas required for the Wide World Importers database

-- Drop schemas if they exist (for clean reinstall)
-- Note: CASCADE will drop all objects in the schema
-- DROP SCHEMA IF EXISTS application CASCADE;
-- DROP SCHEMA IF EXISTS dataloadSimulation CASCADE;
-- DROP SCHEMA IF EXISTS integration CASCADE;
-- DROP SCHEMA IF EXISTS purchasing CASCADE;
-- DROP SCHEMA IF EXISTS sales CASCADE;
-- DROP SCHEMA IF EXISTS warehouse CASCADE;
-- DROP SCHEMA IF EXISTS website CASCADE;
-- DROP SCHEMA IF EXISTS webapi CASCADE;
-- DROP SCHEMA IF EXISTS sequences CASCADE;

-- Create schemas
CREATE SCHEMA IF NOT EXISTS application;
COMMENT ON SCHEMA application IS 'Tables common to the application. These are used for categorization and lookup lists.';

CREATE SCHEMA IF NOT EXISTS dataloadSimulation;
COMMENT ON SCHEMA dataloadSimulation IS 'Tables and procedures used for simulating data loading for demonstration purposes.';

CREATE SCHEMA IF NOT EXISTS integration;
COMMENT ON SCHEMA integration IS 'Tables and procedures required for integration with the data warehouse.';

CREATE SCHEMA IF NOT EXISTS purchasing;
COMMENT ON SCHEMA purchasing IS 'Details of suppliers and of purchasing of stock items.';

CREATE SCHEMA IF NOT EXISTS sales;
COMMENT ON SCHEMA sales IS 'Details of customers, salespeople, and of sales of stock items.';

CREATE SCHEMA IF NOT EXISTS warehouse;
COMMENT ON SCHEMA warehouse IS 'Details of stock items, their holdings, and transactions.';

CREATE SCHEMA IF NOT EXISTS website;
COMMENT ON SCHEMA website IS 'Views and stored procedures specifically for the website.';

CREATE SCHEMA IF NOT EXISTS webapi;
COMMENT ON SCHEMA webapi IS 'Views and stored procedures specifically for the web API.';

CREATE SCHEMA IF NOT EXISTS sequences;
COMMENT ON SCHEMA sequences IS 'Holds sequences used by all tables in the application.';

-- Grant usage on schemas to appropriate roles (customize as needed)
-- GRANT USAGE ON SCHEMA application TO app_user;
-- GRANT USAGE ON SCHEMA sales TO app_user;
-- etc.
