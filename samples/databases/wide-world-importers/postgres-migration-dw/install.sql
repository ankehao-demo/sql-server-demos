-- Wide World Importers DW PostgreSQL Migration
-- Phase 4 & 5: OLAP Schema and ETL Migration
-- File: install.sql
-- Description: Master installation script for the data warehouse schema and ETL procedures
-- 
-- This script installs the complete OLAP/Data Warehouse schema for Wide World Importers
-- including ETL procedures and analytics views
-- Run this script after the OLTP schema (postgres-migration) has been installed
--
-- Usage: psql -d wideworldimportersdw -f install.sql
-- Or: pgcli postgresql://user:password@localhost:5432/wideworldimportersdw < install.sql

\echo '============================================'
\echo 'Wide World Importers DW - PostgreSQL Migration'
\echo 'Phase 4 & 5: OLAP Schema and ETL Installation'
\echo '============================================'

-- Step 1: Create schemas
\echo 'Step 1: Creating schemas...'
\i 01-schemas/001-create-schemas.sql

-- Step 2: Create sequences for surrogate keys
\echo 'Step 2: Creating sequences...'
\i 02-sequences/001-create-sequences.sql

-- Step 3: Create dimension tables
\echo 'Step 3: Creating dimension tables...'
\i 03-dimension-tables/001-dimension-tables.sql

-- Step 4: Create fact tables (with partitions)
\echo 'Step 4: Creating fact tables...'
\i 04-fact-tables/001-fact-tables.sql

-- Step 5: Create staging tables for ETL
\echo 'Step 5: Creating staging tables...'
\i 05-staging-tables/001-staging-tables.sql

-- Step 6: Create integration tables (lineage, ETL cutoff)
\echo 'Step 6: Creating integration tables...'
\i 06-integration-tables/001-integration-tables.sql

-- Step 7: Create indexes
\echo 'Step 7: Creating indexes...'
\i 07-indexes/001-indexes.sql

-- Step 8: Create foreign key constraints
\echo 'Step 8: Creating foreign key constraints...'
\i 08-constraints/001-constraints.sql

-- Step 9: Create ETL helper procedures (Phase 5)
\echo 'Step 9: Creating ETL helper procedures...'
\i 10-etl-procedures/001-helper-procedures.sql

-- Step 10: Create dimension migration procedures (Phase 5)
\echo 'Step 10: Creating dimension migration procedures...'
\i 10-etl-procedures/002-dimension-migration-procedures.sql

-- Step 11: Create fact migration procedures (Phase 5)
\echo 'Step 11: Creating fact migration procedures...'
\i 10-etl-procedures/003-fact-migration-procedures.sql

-- Step 12: Create analytics views (Phase 5)
\echo 'Step 12: Creating analytics views...'
\i 11-analytics/001-analytics-views.sql

\echo '============================================'
\echo 'OLAP Schema and ETL Installation Complete!'
\echo '============================================'
\echo ''
\echo 'To validate the installation, run:'
\echo '  psql -d wideworldimportersdw -f 99-tests/001-validate-olap-schema.sql'
\echo ''
\echo 'Schema Summary:'
\echo '  - 4 schemas: dimension, fact, integration, analytics'
\echo '  - 8 dimension tables'
\echo '  - 6 fact tables (5 partitioned by date)'
\echo '  - 13 staging tables (UNLOGGED for ETL performance)'
\echo '  - 2 integration tables (lineage, etl_cutoff)'
\echo '  - 8 surrogate key sequences'
\echo '  - 15 ETL procedures (helper, dimension, fact migration)'
\echo '  - 4 analytics materialized views'
\echo '  - 5 analytics views'
\echo ''
\echo 'To run the ETL process, use the Python ETL framework:'
\echo '  cd ../wwi-etl && python run_etl.py'
\echo '============================================'
