# Wide World Importers - PostgreSQL Environment Setup

## Overview

This document describes the PostgreSQL environment setup for the Wide World Importers migration project. The environment is configured to support all features required for migrating from SQL Server.

---

## Current Environment

### PostgreSQL Server

| Property | Value |
|----------|-------|
| Version | PostgreSQL 15.15 |
| Host | localhost |
| Port | 5432 |
| Database | wideworldimporters |
| Container | postgres-wwi |
| Platform | Debian (Docker) |

### Connection Details

```bash
# Connection string
postgresql://webapi:Sp1d3rman#@localhost:5432/wideworldimporters

# psql command
PGPASSWORD='Sp1d3rman#' psql -h localhost -U webapi -d wideworldimporters

# pgcli command (recommended)
pgcli postgresql://webapi:Sp1d3rman#@localhost:5432/wideworldimporters
```

---

## Installed Extensions

The following extensions have been installed and verified:

| Extension | Version | Purpose |
|-----------|---------|---------|
| plpgsql | 1.0 | PL/pgSQL procedural language (default) |
| pg_trgm | 1.6 | Trigram matching for fuzzy text search |
| btree_gist | 1.7 | GiST index operator classes for B-tree types |
| uuid-ossp | 1.1 | UUID generation functions |
| hstore | 1.8 | Key-value pair storage |

### Extension Installation Commands

```sql
-- These extensions have been installed
CREATE EXTENSION IF NOT EXISTS pg_trgm;
CREATE EXTENSION IF NOT EXISTS btree_gist;
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS hstore;
```

---

## Required Extensions for Full Migration

The following extensions are required for the complete migration but need to be installed in a production environment:

### PostGIS (Geography Data Type)

Required for migrating SQL Server's `geography` data type.

```bash
# Install PostGIS in Docker container
docker exec -it postgres-wwi bash -c "apt-get update && apt-get install -y postgis postgresql-15-postgis-3"

# Or use PostGIS-enabled Docker image
docker run -d \
  --name postgres-wwi-postgis \
  -e POSTGRES_PASSWORD=postgres \
  -e POSTGRES_DB=wideworldimporters \
  -p 5432:5432 \
  postgis/postgis:15-3.4
```

```sql
-- Enable PostGIS
CREATE EXTENSION IF NOT EXISTS postgis;
CREATE EXTENSION IF NOT EXISTS postgis_topology;

-- Verify installation
SELECT PostGIS_Version();
```

### pg_partman (Partition Management)

Required for automatic partition management.

```sql
-- Install pg_partman
CREATE EXTENSION IF NOT EXISTS pg_partman;

-- Example: Create partitioned table with automatic management
SELECT partman.create_parent(
    p_parent_table := 'fact.sale',
    p_control := 'invoice_date_key',
    p_type := 'native',
    p_interval := '1 year'
);
```

### pg_cron (Job Scheduling)

Required for scheduling ETL jobs (replacement for SQL Server Agent).

```sql
-- Install pg_cron (requires superuser and shared_preload_libraries configuration)
CREATE EXTENSION IF NOT EXISTS pg_cron;

-- Example: Schedule daily ETL
SELECT cron.schedule('daily_etl', '0 2 * * *', 'CALL integration.run_daily_etl();');
```

### temporal_tables (Optional)

Alternative to trigger-based temporal table implementation.

```sql
-- Install temporal_tables extension
CREATE EXTENSION IF NOT EXISTS temporal_tables;

-- Example: Enable versioning on a table
SELECT enable_versioning('application.cities', 'application.cities_archive');
```

---

## Schema Setup

### Create Schemas

```sql
-- Create schemas matching SQL Server structure
CREATE SCHEMA IF NOT EXISTS application;
CREATE SCHEMA IF NOT EXISTS sales;
CREATE SCHEMA IF NOT EXISTS purchasing;
CREATE SCHEMA IF NOT EXISTS warehouse;
CREATE SCHEMA IF NOT EXISTS sequences;
CREATE SCHEMA IF NOT EXISTS website;
CREATE SCHEMA IF NOT EXISTS integration;
CREATE SCHEMA IF NOT EXISTS data_load_simulation;

-- For OLAP database
CREATE SCHEMA IF NOT EXISTS dimension;
CREATE SCHEMA IF NOT EXISTS fact;
```

### Create Roles

```sql
-- Create database roles matching SQL Server roles
CREATE ROLE db_owner;
CREATE ROLE application_users;
CREATE ROLE website_users;
CREATE ROLE webapi_users;

-- Sales territory roles
CREATE ROLE "External Sales";
CREATE ROLE "Far West Sales";
CREATE ROLE "Great Lakes Sales";
CREATE ROLE "Mideast Sales";
CREATE ROLE "New England Sales";
CREATE ROLE "Plains Sales";
CREATE ROLE "Rocky Mountain Sales";
CREATE ROLE "Southeast Sales";
CREATE ROLE "Southwest Sales";

-- Grant schema permissions
GRANT ALL ON SCHEMA application TO db_owner;
GRANT ALL ON SCHEMA sales TO db_owner;
GRANT ALL ON SCHEMA purchasing TO db_owner;
GRANT ALL ON SCHEMA warehouse TO db_owner;
GRANT USAGE ON SCHEMA application TO application_users;
GRANT USAGE ON SCHEMA sales TO application_users;
GRANT USAGE ON SCHEMA purchasing TO application_users;
GRANT USAGE ON SCHEMA warehouse TO application_users;
```

---

## Performance Configuration

### Recommended postgresql.conf Settings

```ini
# Memory Settings
shared_buffers = 256MB                  # 25% of available RAM
effective_cache_size = 768MB            # 75% of available RAM
work_mem = 64MB                         # For complex queries
maintenance_work_mem = 128MB            # For VACUUM, CREATE INDEX

# Write-Ahead Log
wal_buffers = 16MB
checkpoint_completion_target = 0.9
max_wal_size = 2GB
min_wal_size = 1GB

# Query Planner
random_page_cost = 1.1                  # For SSD storage
effective_io_concurrency = 200          # For SSD storage
default_statistics_target = 100

# Parallel Query
max_parallel_workers_per_gather = 2
max_parallel_workers = 4
max_parallel_maintenance_workers = 2

# Logging
log_min_duration_statement = 1000       # Log queries > 1 second
log_checkpoints = on
log_connections = on
log_disconnections = on
log_lock_waits = on

# Full-Text Search
default_text_search_config = 'pg_catalog.english'
```

### Apply Configuration Changes

```bash
# Edit postgresql.conf in Docker container
docker exec -it postgres-wwi bash -c "cat >> /var/lib/postgresql/data/postgresql.conf << 'EOF'
# WWI Migration Settings
shared_buffers = 256MB
effective_cache_size = 768MB
work_mem = 64MB
maintenance_work_mem = 128MB
random_page_cost = 1.1
effective_io_concurrency = 200
default_statistics_target = 100
EOF"

# Restart PostgreSQL to apply changes
docker restart postgres-wwi
```

---

## Verification Commands

### Check PostgreSQL Version

```sql
SELECT version();
```

### Check Installed Extensions

```sql
SELECT extname, extversion FROM pg_extension ORDER BY extname;
```

### Check Available Extensions

```sql
SELECT name, default_version, comment 
FROM pg_available_extensions 
WHERE name IN ('postgis', 'pg_trgm', 'btree_gist', 'uuid-ossp', 'hstore', 'pg_cron', 'pg_partman')
ORDER BY name;
```

### Check Database Size

```sql
SELECT pg_size_pretty(pg_database_size('wideworldimporters'));
```

### Check Connection Count

```sql
SELECT count(*) FROM pg_stat_activity WHERE datname = 'wideworldimporters';
```

### Check Table Count by Schema

```sql
SELECT schemaname, count(*) as table_count
FROM pg_tables
WHERE schemaname NOT IN ('pg_catalog', 'information_schema')
GROUP BY schemaname
ORDER BY schemaname;
```

---

## Docker Commands Reference

### Start PostgreSQL Container

```bash
docker start postgres-wwi
```

### Stop PostgreSQL Container

```bash
docker stop postgres-wwi
```

### View Container Logs

```bash
docker logs postgres-wwi
```

### Execute SQL in Container

```bash
docker exec -it postgres-wwi psql -U webapi -d wideworldimporters -c "SELECT 1;"
```

### Backup Database

```bash
docker exec -t postgres-wwi pg_dump -U webapi wideworldimporters > wwi_backup.sql
```

### Restore Database

```bash
docker exec -i postgres-wwi psql -U webapi wideworldimporters < wwi_backup.sql
```

---

## Production Environment Recommendations

### 1. Use PostGIS-Enabled Image

For production, use a Docker image with PostGIS pre-installed:

```bash
docker run -d \
  --name postgres-wwi-prod \
  -e POSTGRES_PASSWORD=<secure_password> \
  -e POSTGRES_DB=wideworldimporters \
  -e POSTGRES_USER=wwi_admin \
  -v postgres_data:/var/lib/postgresql/data \
  -p 5432:5432 \
  postgis/postgis:15-3.4
```

### 2. Enable SSL

```bash
# Generate SSL certificates
openssl req -new -x509 -days 365 -nodes -text -out server.crt -keyout server.key -subj "/CN=postgres-wwi"

# Configure PostgreSQL for SSL
# In postgresql.conf:
ssl = on
ssl_cert_file = '/var/lib/postgresql/data/server.crt'
ssl_key_file = '/var/lib/postgresql/data/server.key'
```

### 3. Configure Connection Pooling

Use PgBouncer for connection pooling:

```bash
docker run -d \
  --name pgbouncer \
  -e DATABASE_URL="postgres://webapi:Sp1d3rman#@postgres-wwi:5432/wideworldimporters" \
  -e POOL_MODE=transaction \
  -e MAX_CLIENT_CONN=100 \
  -e DEFAULT_POOL_SIZE=20 \
  -p 6432:6432 \
  edoburu/pgbouncer
```

### 4. Set Up Monitoring

Use pg_stat_statements for query monitoring:

```sql
-- Enable pg_stat_statements
CREATE EXTENSION IF NOT EXISTS pg_stat_statements;

-- View top queries by total time
SELECT 
    substring(query, 1, 100) as query_preview,
    calls,
    total_exec_time::numeric(10,2) as total_time_ms,
    mean_exec_time::numeric(10,2) as mean_time_ms,
    rows
FROM pg_stat_statements
ORDER BY total_exec_time DESC
LIMIT 10;
```

---

## Troubleshooting

### Connection Refused

```bash
# Check if container is running
docker ps | grep postgres-wwi

# Check container logs
docker logs postgres-wwi

# Restart container
docker restart postgres-wwi
```

### Permission Denied

```sql
-- Grant necessary permissions
GRANT ALL PRIVILEGES ON DATABASE wideworldimporters TO webapi;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO webapi;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO webapi;
```

### Extension Not Available

```bash
# Install extension packages in container
docker exec -it postgres-wwi bash -c "apt-get update && apt-get install -y postgresql-15-<extension>"

# Restart PostgreSQL
docker restart postgres-wwi
```

### Out of Memory

```sql
-- Check current memory settings
SHOW shared_buffers;
SHOW work_mem;
SHOW maintenance_work_mem;

-- Reduce work_mem for high-concurrency scenarios
SET work_mem = '32MB';
```

---

## Next Steps

1. **Install PostGIS** - Required for geography data type migration
2. **Install pg_partman** - Required for partition management
3. **Configure pg_cron** - Required for scheduled ETL jobs
4. **Set up connection pooling** - Recommended for production
5. **Configure monitoring** - Set up pg_stat_statements and alerting
6. **Create schemas and roles** - Prepare database structure for migration
7. **Begin schema migration** - Start with dimension tables, then fact tables
