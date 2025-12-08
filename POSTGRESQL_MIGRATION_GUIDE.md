# PostgreSQL Migration Guide

This guide outlines the dependencies and steps needed to migrate the Wide World Importers application from SQL Server to PostgreSQL.

## Dependencies Already Installed

✅ **PostgreSQL Client Tools**
- `psql` (PostgreSQL 14.19)
- `pgcli` (enhanced PostgreSQL CLI with syntax highlighting)

✅ **Docker Images**
- `postgres:15` (latest stable PostgreSQL server)

✅ **Development Environment**
- .NET 8.0 SDK (compatible with Npgsql)
- Docker for containerized PostgreSQL

## Additional Dependencies Needed for Migration

### 1. .NET PostgreSQL Driver
```bash
# Add to Wide World Importers project
cd ~/repos/sql-server-demos/samples/databases/wide-world-importers/wwi-app
dotnet add package Npgsql.EntityFrameworkCore.PostgreSQL
dotnet add package Npgsql
```

### 2. Schema Migration Tools
```bash
# Install schema migration tools
pip install pg_dump
npm install -g db-migrate
npm install -g db-migrate-pg
```

### 3. Data Migration Tools
- **pgloader** - For bulk data migration from SQL Server to PostgreSQL
- **AWS Database Migration Service** - For complex migrations (if using AWS)
- **Custom migration scripts** - For Wide World Importers specific data

## Migration Strategy for Wide World Importers

### Phase 1: Schema Migration
1. **Convert SQL Server schema to PostgreSQL**
   - Data types mapping (e.g., `nvarchar` → `text`, `datetime2` → `timestamp`)
   - Convert stored procedures to PostgreSQL functions
   - Migrate views and indexes
   - Handle Row-Level Security (PostgreSQL has native RLS support)

### Phase 2: Application Code Changes
1. **Connection String Updates**
   ```json
   {
     "ConnectionStrings": {
       "WWI": "Host=localhost;Database=wideworldimporters;Username=webapi;Password=Sp1d3rman#"
     }
   }
   ```

2. **Replace SQL Server-specific Features**
   - JSON functions (PostgreSQL has excellent JSON support)
   - Full-text search (PostgreSQL has built-in FTS)
   - Spatial data (PostGIS extension)

3. **Update Entity Framework Configuration**
   - Replace `UseSqlServer()` with `UseNpgsql()`
   - Update data annotations for PostgreSQL-specific features

### Phase 3: Data Migration
1. **Export data from SQL Server**
2. **Transform data for PostgreSQL compatibility**
3. **Import data using pgloader or custom scripts**

## PostgreSQL Advantages for Wide World Importers

- **Better JSON Support**: Native JSON/JSONB types
- **Advanced Analytics**: Window functions, CTEs, recursive queries
- **Full-Text Search**: Built-in without additional licensing
- **Row-Level Security**: Native support (similar to SQL Server)
- **Extensions**: PostGIS for spatial data, pg_stat_statements for performance
- **Cost**: Open source, no licensing fees

## Quick Start PostgreSQL Container

```bash
# Start PostgreSQL container
docker run --name postgres-wwi \
  -e POSTGRES_DB=wideworldimporters \
  -e POSTGRES_USER=webapi \
  -e POSTGRES_PASSWORD=Sp1d3rman# \
  -p 5432:5432 \
  -d postgres:15

# Connect using pgcli
pgcli postgresql://webapi:Sp1d3rman#@localhost:5432/wideworldimporters
```

## Migration Timeline Estimate

- **Schema Migration**: 2-3 weeks
- **Application Updates**: 1-2 weeks  
- **Data Migration**: 1 week
- **Testing & Validation**: 2-3 weeks
- **Total**: 6-9 weeks for complete migration

## Next Steps

1. Set up PostgreSQL development environment
2. Create schema mapping document
3. Identify SQL Server-specific features to replace
4. Plan data migration strategy
5. Update application dependencies