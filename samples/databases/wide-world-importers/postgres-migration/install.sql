-- Wide World Importers PostgreSQL Migration
-- Phase 2: OLTP Schema Migration
-- File: install.sql
-- Description: Master installation script that runs all migration files in order

-- This script should be run against a PostgreSQL database to create the
-- Wide World Importers schema structure migrated from SQL Server.

-- Prerequisites:
-- 1. PostgreSQL 15+ with PostGIS extension available
-- 2. A database created for the migration (e.g., wideworldimporters)
-- 3. Appropriate user permissions to create schemas, tables, sequences, triggers

-- Usage:
-- psql -d wideworldimporters -f install.sql
-- or
-- \i install.sql (from psql prompt)

\echo '=========================================='
\echo 'Wide World Importers PostgreSQL Migration'
\echo 'Phase 2: OLTP Schema Migration'
\echo '=========================================='

\echo ''
\echo 'Step 1: Creating schemas and enabling extensions...'
\i 01-schemas/001-create-schemas.sql

\echo ''
\echo 'Step 2: Creating sequences...'
\i 02-sequences/001-create-sequences.sql

\echo ''
\echo 'Step 3: Creating Application schema tables...'
\i 03-tables/001-application-tables.sql

\echo ''
\echo 'Step 4: Creating Warehouse schema tables...'
\i 03-tables/002-warehouse-tables.sql

\echo ''
\echo 'Step 5: Creating Sales schema tables...'
\i 03-tables/003-sales-tables.sql

\echo ''
\echo 'Step 6: Creating Purchasing schema tables...'
\i 03-tables/004-purchasing-tables.sql

\echo ''
\echo 'Step 7: Creating archive tables for temporal table support...'
\i 04-archive-tables/001-archive-tables.sql

\echo ''
\echo 'Step 8: Creating temporal table triggers...'
\i 05-triggers/001-temporal-triggers.sql

\echo ''
\echo 'Step 9: Creating foreign key constraints...'
\i 06-constraints/001-foreign-keys.sql

\echo ''
\echo 'Step 10: Creating indexes...'
\i 07-indexes/001-indexes.sql

\echo ''
\echo '=========================================='
\echo 'Migration completed successfully!'
\echo '=========================================='
\echo ''
\echo 'To validate the migration, run:'
\echo '  \i 08-tests/001-test-schema.sql'
\echo '  \i 08-tests/002-test-temporal-triggers.sql'
\echo ''
