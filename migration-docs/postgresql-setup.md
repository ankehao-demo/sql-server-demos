# PostgreSQL Environment Setup - Wide World Importers Migration

This document provides setup instructions for the PostgreSQL environment to host the migrated Wide World Importers database.

## 1. PostgreSQL Version Recommendation

### Recommended Version: PostgreSQL 15+

PostgreSQL 15 is recommended for this migration due to:

| Feature | Benefit for WWI Migration |
|---------|---------------------------|
| **MERGE statement** | Simplifies upsert operations in ETL procedures |
| **JSON improvements** | Better JSON path expressions for CustomFields columns |
| **Logical replication improvements** | Easier data migration from SQL Server |
| **Performance improvements** | Better query planning for complex joins |
| **Security enhancements** | Improved role management for RLS |

### Minimum Version: PostgreSQL 13

PostgreSQL 13 is the minimum acceptable version due to:
- Native JSON path expressions (`jsonb_path_query`)
- Improved partitioning performance
- Better parallel query execution
- `gen_random_uuid()` function without extension

### Version Compatibility Matrix

| PostgreSQL Version | Compatibility | Notes |
|-------------------|---------------|-------|
| 17 | Excellent | Latest features, best performance |
| 16 | Excellent | Recommended for production |
| 15 | Excellent | Stable, well-tested |
| 14 | Good | Missing some JSON improvements |
| 13 | Acceptable | Minimum for this migration |
| 12 and below | Not Recommended | Missing critical features |

## 2. Required Extensions

### Core Extensions

```sql
-- PostGIS for geography/spatial data
CREATE EXTENSION IF NOT EXISTS postgis;
CREATE EXTENSION IF NOT EXISTS postgis_topology;

-- Cryptographic functions for password hashing
CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- Fuzzy string matching (replaces SQL Server full-text in some cases)
CREATE EXTENSION IF NOT EXISTS pg_trgm;

-- UUID generation
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Scheduling for ETL jobs (replaces SQL Server Agent)
CREATE EXTENSION IF NOT EXISTS pg_cron;
```

### Extension Details

#### PostGIS (Required)

**Purpose:** Replaces SQL Server's `geography` data type for spatial data.

**Installation:**
```bash
# Ubuntu/Debian
sudo apt-get install postgresql-15-postgis-3

# RHEL/CentOS
sudo yum install postgis33_15

# macOS (Homebrew)
brew install postgis
```

**Usage:**
```sql
-- Create geography column
ALTER TABLE application.cities 
ADD COLUMN location geography(Point, 4326);

-- Spatial query
SELECT city_name, ST_Distance(location, ST_MakePoint(-122.4194, 37.7749)::geography) as distance
FROM application.cities
ORDER BY distance;
```

#### pgcrypto (Required)

**Purpose:** Replaces SQL Server's `HASHBYTES()` function for password hashing.

**Usage:**
```sql
-- Hash password (equivalent to HASHBYTES('SHA2_256', @password))
SELECT digest('password123', 'sha256');

-- Generate random bytes
SELECT gen_random_bytes(32);
```

#### pg_trgm (Required)

**Purpose:** Provides trigram-based fuzzy string matching, complementing full-text search.

**Usage:**
```sql
-- Create trigram index
CREATE INDEX idx_people_name_trgm ON application.people 
USING GIN (full_name gin_trgm_ops);

-- Fuzzy search
SELECT * FROM application.people 
WHERE full_name % 'John Smith'
ORDER BY similarity(full_name, 'John Smith') DESC;
```

#### pg_cron (Required for ETL)

**Purpose:** Replaces SQL Server Agent for scheduling ETL jobs.

**Installation:**
```bash
# Add to postgresql.conf
shared_preload_libraries = 'pg_cron'
cron.database_name = 'wideworldimporters'
```

**Usage:**
```sql
-- Schedule daily ETL at 2 AM
SELECT cron.schedule('daily-etl', '0 2 * * *', 
    'CALL integration.run_daily_etl()');

-- View scheduled jobs
SELECT * FROM cron.job;
```

### Optional Extensions

```sql
-- Partitioning management (optional, for automated partition creation)
CREATE EXTENSION IF NOT EXISTS pg_partman;

-- Foreign data wrapper for SQL Server (useful during migration)
CREATE EXTENSION IF NOT EXISTS tds_fdw;

-- Additional statistics for query optimization
CREATE EXTENSION IF NOT EXISTS pg_stat_statements;

-- Columnar storage (if using Citus)
-- CREATE EXTENSION IF NOT EXISTS citus;
```

## 3. Database Configuration

### Memory Configuration

```ini
# postgresql.conf

# Shared memory (25% of total RAM, max 8GB for most workloads)
shared_buffers = 4GB

# Work memory for sorts and hashes (per operation)
work_mem = 256MB

# Maintenance operations memory
maintenance_work_mem = 1GB

# Effective cache size (75% of total RAM)
effective_cache_size = 12GB
```

### Connection Settings

```ini
# Maximum connections (adjust based on application needs)
max_connections = 200

# Connection timeout
statement_timeout = 300000  # 5 minutes

# Idle transaction timeout
idle_in_transaction_session_timeout = 60000  # 1 minute
```

### Write-Ahead Log (WAL) Settings

```ini
# WAL level for logical replication (useful during migration)
wal_level = logical

# WAL size
max_wal_size = 4GB
min_wal_size = 1GB

# Checkpoint settings
checkpoint_completion_target = 0.9
checkpoint_timeout = 10min
```

### Query Planner Settings

```ini
# Enable parallel query execution
max_parallel_workers_per_gather = 4
max_parallel_workers = 8
max_parallel_maintenance_workers = 4

# Random page cost (lower for SSD storage)
random_page_cost = 1.1

# Enable JIT compilation for complex queries
jit = on
```

### Logging Configuration

```ini
# Log destination
logging_collector = on
log_directory = 'pg_log'
log_filename = 'postgresql-%Y-%m-%d_%H%M%S.log'

# What to log
log_statement = 'ddl'
log_duration = on
log_min_duration_statement = 1000  # Log queries > 1 second

# Log format
log_line_prefix = '%t [%p]: [%l-1] user=%u,db=%d,app=%a,client=%h '
```

## 4. Schema Setup

### Create Schemas

```sql
-- Create schemas matching SQL Server structure
CREATE SCHEMA IF NOT EXISTS application;
CREATE SCHEMA IF NOT EXISTS sales;
CREATE SCHEMA IF NOT EXISTS purchasing;
CREATE SCHEMA IF NOT EXISTS warehouse;
CREATE SCHEMA IF NOT EXISTS sequences;
CREATE SCHEMA IF NOT EXISTS integration;
CREATE SCHEMA IF NOT EXISTS website;
CREATE SCHEMA IF NOT EXISTS data_load_simulation;

-- OLAP schemas
CREATE SCHEMA IF NOT EXISTS dimension;
CREATE SCHEMA IF NOT EXISTS fact;
```

### Create Roles

```sql
-- Application roles
CREATE ROLE wwi_application;
CREATE ROLE wwi_sales;
CREATE ROLE wwi_purchasing;
CREATE ROLE wwi_warehouse;
CREATE ROLE wwi_website;
CREATE ROLE wwi_integration;
CREATE ROLE wwi_reports;
CREATE ROLE wwi_powerbi;

-- Sales territory roles (for RLS)
CREATE ROLE "External Sales";
CREATE ROLE "Far West Sales";
CREATE ROLE "Great Lakes Sales";
CREATE ROLE "Mideast Sales";
CREATE ROLE "New England Sales";
CREATE ROLE "Plains Sales";
CREATE ROLE "Rocky Mountain Sales";
CREATE ROLE "Southeast Sales";
CREATE ROLE "Southwest Sales";

-- Grant schema access
GRANT USAGE ON SCHEMA application TO wwi_application;
GRANT USAGE ON SCHEMA sales TO wwi_sales;
GRANT USAGE ON SCHEMA purchasing TO wwi_purchasing;
GRANT USAGE ON SCHEMA warehouse TO wwi_warehouse;
GRANT USAGE ON SCHEMA website TO wwi_website;
GRANT USAGE ON SCHEMA integration TO wwi_integration;
```

### Create Application Users

```sql
-- Web application user
CREATE USER webapi WITH PASSWORD 'secure_password_here';
GRANT wwi_website TO webapi;
GRANT wwi_sales TO webapi;

-- ETL user
CREATE USER etl_user WITH PASSWORD 'secure_password_here';
GRANT wwi_integration TO etl_user;

-- Reporting user
CREATE USER report_user WITH PASSWORD 'secure_password_here';
GRANT wwi_reports TO report_user;
GRANT wwi_powerbi TO report_user;
```

## 5. Session Context Configuration

### Application Settings for RLS

SQL Server uses `SESSION_CONTEXT()` for passing application context. PostgreSQL uses `current_setting()` with custom GUCs.

```sql
-- Add to postgresql.conf
-- custom_variable_classes = 'app'  # Not needed in PostgreSQL 9.2+

-- Set session context in application
SET app.sales_territory = 'Great Lakes';
SET app.user_id = '123';

-- Read session context
SELECT current_setting('app.sales_territory', true);
```

### Connection String Configuration

```
# Standard connection string
postgresql://webapi:password@localhost:5432/wideworldimporters?application_name=WWI_WebApp

# With SSL
postgresql://webapi:password@localhost:5432/wideworldimporters?sslmode=require

# Connection pooling (PgBouncer)
postgresql://webapi:password@localhost:6432/wideworldimporters?application_name=WWI_WebApp
```

## 6. Performance Optimization

### Index Strategy

```sql
-- B-tree indexes for primary keys and foreign keys (default)
CREATE INDEX idx_orders_customer_id ON sales.orders(customer_id);

-- BRIN indexes for date columns in large tables
CREATE INDEX idx_orders_order_date_brin ON sales.orders 
USING BRIN(order_date) WITH (pages_per_range = 128);

-- GIN indexes for full-text search
CREATE INDEX idx_people_search ON application.people 
USING GIN(to_tsvector('english', full_name || ' ' || COALESCE(custom_fields::text, '')));

-- GIN indexes for JSON columns
CREATE INDEX idx_people_custom_fields ON application.people 
USING GIN(custom_fields jsonb_path_ops);

-- Partial indexes for common queries
CREATE INDEX idx_orders_pending ON sales.orders(order_id) 
WHERE is_undersupply_backordered = true;
```

### Table Statistics

```sql
-- Increase statistics target for frequently queried columns
ALTER TABLE sales.orders ALTER COLUMN customer_id SET STATISTICS 1000;
ALTER TABLE sales.orders ALTER COLUMN order_date SET STATISTICS 1000;

-- Analyze tables after bulk load
ANALYZE sales.orders;
ANALYZE sales.order_lines;
```

### Connection Pooling

**PgBouncer Configuration (pgbouncer.ini):**

```ini
[databases]
wideworldimporters = host=localhost port=5432 dbname=wideworldimporters

[pgbouncer]
listen_addr = *
listen_port = 6432
auth_type = md5
auth_file = /etc/pgbouncer/userlist.txt
pool_mode = transaction
max_client_conn = 1000
default_pool_size = 50
min_pool_size = 10
reserve_pool_size = 10
```

## 7. Backup and Recovery

### Backup Configuration

```bash
# Full backup with pg_dump
pg_dump -Fc -f /backup/wwi_$(date +%Y%m%d).dump wideworldimporters

# Continuous archiving (WAL archiving)
# postgresql.conf
archive_mode = on
archive_command = 'cp %p /archive/%f'
```

### Point-in-Time Recovery

```bash
# Restore to specific point in time
pg_restore -d wideworldimporters /backup/wwi_20250101.dump

# Recovery configuration (recovery.conf or postgresql.conf in PG12+)
restore_command = 'cp /archive/%f %p'
recovery_target_time = '2025-01-15 14:30:00'
```

## 8. Monitoring Setup

### pg_stat_statements

```sql
-- Enable query statistics
CREATE EXTENSION IF NOT EXISTS pg_stat_statements;

-- View slow queries
SELECT query, calls, total_exec_time, mean_exec_time
FROM pg_stat_statements
ORDER BY total_exec_time DESC
LIMIT 20;
```

### System Catalog Queries

```sql
-- Table sizes
SELECT schemaname, tablename, 
       pg_size_pretty(pg_total_relation_size(schemaname || '.' || tablename)) as size
FROM pg_tables
WHERE schemaname IN ('sales', 'warehouse', 'purchasing', 'application')
ORDER BY pg_total_relation_size(schemaname || '.' || tablename) DESC;

-- Index usage
SELECT schemaname, tablename, indexname, idx_scan, idx_tup_read
FROM pg_stat_user_indexes
ORDER BY idx_scan DESC;

-- Lock monitoring
SELECT pid, usename, query, state, wait_event_type, wait_event
FROM pg_stat_activity
WHERE state != 'idle';
```

## 9. Docker Deployment (Development)

### docker-compose.yml

```yaml
version: '3.8'

services:
  postgres:
    image: postgis/postgis:15-3.3
    container_name: wwi-postgres
    environment:
      POSTGRES_DB: wideworldimporters
      POSTGRES_USER: postgres
      POSTGRES_PASSWORD: ${POSTGRES_PASSWORD}
    ports:
      - "5432:5432"
    volumes:
      - postgres_data:/var/lib/postgresql/data
      - ./init-scripts:/docker-entrypoint-initdb.d
    command: >
      postgres
      -c shared_buffers=1GB
      -c work_mem=64MB
      -c maintenance_work_mem=256MB
      -c effective_cache_size=3GB
      -c shared_preload_libraries=pg_cron,pg_stat_statements

  pgadmin:
    image: dpage/pgadmin4
    container_name: wwi-pgadmin
    environment:
      PGADMIN_DEFAULT_EMAIL: admin@example.com
      PGADMIN_DEFAULT_PASSWORD: ${PGADMIN_PASSWORD}
    ports:
      - "5050:80"
    depends_on:
      - postgres

volumes:
  postgres_data:
```

### Initialization Script

```sql
-- init-scripts/01-extensions.sql
CREATE EXTENSION IF NOT EXISTS postgis;
CREATE EXTENSION IF NOT EXISTS pgcrypto;
CREATE EXTENSION IF NOT EXISTS pg_trgm;
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS pg_cron;
CREATE EXTENSION IF NOT EXISTS pg_stat_statements;
```

## 10. Cloud Deployment Options

### AWS RDS PostgreSQL

```hcl
# Terraform example
resource "aws_db_instance" "wwi" {
  identifier           = "wwi-postgres"
  engine               = "postgres"
  engine_version       = "15.4"
  instance_class       = "db.r6g.xlarge"
  allocated_storage    = 100
  storage_type         = "gp3"
  
  db_name              = "wideworldimporters"
  username             = "postgres"
  password             = var.db_password
  
  parameter_group_name = aws_db_parameter_group.wwi.name
  
  backup_retention_period = 7
  multi_az               = true
  
  performance_insights_enabled = true
}
```

### Azure Database for PostgreSQL

```bash
# Azure CLI
az postgres flexible-server create \
  --name wwi-postgres \
  --resource-group wwi-rg \
  --location eastus \
  --admin-user postgres \
  --admin-password $DB_PASSWORD \
  --sku-name Standard_D4s_v3 \
  --storage-size 128 \
  --version 15 \
  --high-availability ZoneRedundant
```

### Google Cloud SQL

```bash
# gcloud CLI
gcloud sql instances create wwi-postgres \
  --database-version=POSTGRES_15 \
  --tier=db-custom-4-16384 \
  --region=us-central1 \
  --availability-type=REGIONAL \
  --storage-size=100GB \
  --storage-type=SSD
```

## Checklist

- [ ] PostgreSQL 15+ installed
- [ ] PostGIS extension installed and enabled
- [ ] pgcrypto extension enabled
- [ ] pg_trgm extension enabled
- [ ] pg_cron extension enabled (for ETL scheduling)
- [ ] Memory settings configured based on available RAM
- [ ] WAL settings configured for logical replication
- [ ] Schemas created
- [ ] Roles and users created
- [ ] Connection pooling configured (PgBouncer)
- [ ] Backup strategy implemented
- [ ] Monitoring enabled (pg_stat_statements)
