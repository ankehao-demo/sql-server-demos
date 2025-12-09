-- Wide World Importers PostgreSQL Migration
-- Phase 2: OLTP Schema Migration
-- Extensions required for the database

-- Enable PostGIS for geography data type support
CREATE EXTENSION IF NOT EXISTS postgis;

-- Enable UUID support (for potential UNIQUEIDENTIFIER columns)
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Enable pg_trgm for text search optimization
CREATE EXTENSION IF NOT EXISTS pg_trgm;
