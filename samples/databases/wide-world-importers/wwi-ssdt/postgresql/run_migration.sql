-- Wide World Importers PostgreSQL Migration
-- Master Migration Script
-- Runs all migration scripts in the correct order

-- =============================================
-- PHASE 2: OLTP Schema Migration
-- =============================================

\echo '=========================================='
\echo 'Phase 2: OLTP Schema Migration'
\echo '=========================================='

\echo 'Creating schemas and extensions...'
\i phase2-oltp-schema/001_create_schemas.sql

\echo 'Creating sequences...'
\i phase2-oltp-schema/002_create_sequences.sql

\echo 'Creating Application tables...'
\i phase2-oltp-schema/003_application_tables.sql

\echo 'Creating Sales tables...'
\i phase2-oltp-schema/004_sales_tables.sql

\echo 'Creating Purchasing tables...'
\i phase2-oltp-schema/005_purchasing_tables.sql

\echo 'Creating Warehouse tables...'
\i phase2-oltp-schema/006_warehouse_tables.sql

\echo 'Creating foreign key constraints...'
\i phase2-oltp-schema/007_foreign_keys.sql

\echo 'Creating temporal table triggers...'
\i phase2-oltp-schema/008_temporal_triggers.sql

\echo 'Phase 2 complete!'

-- =============================================
-- PHASE 3: OLTP Code Migration
-- =============================================

\echo '=========================================='
\echo 'Phase 3: OLTP Code Migration'
\echo '=========================================='

\echo 'Creating website functions...'
\i phase3-oltp-code/001_website_functions.sql

\echo 'Creating website procedures...'
\i phase3-oltp-code/002_website_procedures.sql

\echo 'Creating row-level security...'
\i phase3-oltp-code/003_row_level_security.sql

\echo 'Creating data loading simulation procedures...'
\i phase3-oltp-code/004_data_loading_simulation.sql

\echo 'Phase 3 complete!'

-- =============================================
-- PHASE 4: OLAP Schema Migration
-- =============================================

\echo '=========================================='
\echo 'Phase 4: OLAP Schema Migration'
\echo '=========================================='

\echo 'Creating data warehouse schemas and sequences...'
\i phase4-olap-schema/001_create_dw_schemas.sql

\echo 'Creating dimension tables...'
\i phase4-olap-schema/002_dimension_tables.sql

\echo 'Creating fact tables...'
\i phase4-olap-schema/003_fact_tables.sql

\echo 'Creating staging tables...'
\i phase4-olap-schema/004_staging_tables.sql

\echo 'Creating integration procedures...'
\i phase4-olap-schema/005_integration_procedures.sql

\echo 'Phase 4 complete!'

\echo '=========================================='
\echo 'Migration Complete!'
\echo '=========================================='
\echo 'All phases have been executed successfully.'
\echo 'Please verify the schema structure and test the procedures.'
