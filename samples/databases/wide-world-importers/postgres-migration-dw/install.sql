-- Wide World Importers DW PostgreSQL Migration
-- Phase 4: OLAP Schema Migration
-- File: install.sql
-- Description: Master installation script for the data warehouse schema
-- 
-- This script installs the complete OLAP/Data Warehouse schema for Wide World Importers
-- Run this script after the OLTP schema (postgres-migration) has been installed
--
-- Usage: psql -d wideworldimporters -f install.sql
-- Or: pgcli postgresql://user:password@localhost:5432/wideworldimporters < install.sql

\echo '============================================'
\echo 'Wide World Importers DW - PostgreSQL Migration'
\echo 'Phase 4: OLAP Schema Installation'
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

\echo '============================================'
\echo 'OLAP Schema Installation Complete!'
\echo '============================================'
\echo ''
\echo 'To validate the installation, run:'
\echo '  psql -d wideworldimporters -f 99-tests/001-validate-olap-schema.sql'
\echo ''
\echo 'Schema Summary:'
\echo '  - 3 schemas: dimension, fact, integration'
\echo '  - 8 dimension tables'
\echo '  - 6 fact tables (5 partitioned by date)'
\echo '  - 13 staging tables (UNLOGGED for ETL performance)'
\echo '  - 2 integration tables (lineage, etl_cutoff)'
\echo '  - 8 surrogate key sequences'
\echo '============================================'
