-- Wide World Importers Data Warehouse - PostgreSQL Schema Migration
-- Phase 4: OLAP Schema Migration
-- Integration: City Staging table
-- Note: SQL Server memory-optimized tables are converted to regular PostgreSQL tables
--       For high-performance scenarios, consider using UNLOGGED tables or TimescaleDB

CREATE TABLE integration.city_staging (
    city_staging_key            INTEGER GENERATED ALWAYS AS IDENTITY,
    wwi_city_id                 INTEGER NOT NULL,
    city                        VARCHAR(50) NOT NULL,
    state_province              VARCHAR(50) NOT NULL,
    country                     VARCHAR(60) NOT NULL,
    continent                   VARCHAR(30) NOT NULL,
    sales_territory             VARCHAR(50) NOT NULL,
    region                      VARCHAR(30) NOT NULL,
    subregion                   VARCHAR(30) NOT NULL,
    location                    GEOGRAPHY(Point, 4326),
    latest_recorded_population  BIGINT NOT NULL,
    valid_from                  TIMESTAMP NOT NULL,
    valid_to                    TIMESTAMP NOT NULL,

    CONSTRAINT pk_integration_city_staging PRIMARY KEY (city_staging_key)
);

-- Create index for WWI City ID lookups
CREATE INDEX ix_integration_city_staging_wwi_city_id 
    ON integration.city_staging (wwi_city_id);

COMMENT ON TABLE integration.city_staging IS 'City staging table';
COMMENT ON COLUMN integration.city_staging.city_staging_key IS 'Row ID within the staging table';
COMMENT ON COLUMN integration.city_staging.wwi_city_id IS 'Numeric ID used for reference to a city within the WWI database';
COMMENT ON COLUMN integration.city_staging.city IS 'Formal name of the city';
COMMENT ON COLUMN integration.city_staging.state_province IS 'State or province for this city';
COMMENT ON COLUMN integration.city_staging.country IS 'Country name';
COMMENT ON COLUMN integration.city_staging.continent IS 'Continent that this city is on';
COMMENT ON COLUMN integration.city_staging.sales_territory IS 'Sales territory for this StateProvince';
COMMENT ON COLUMN integration.city_staging.region IS 'Name of the region';
COMMENT ON COLUMN integration.city_staging.subregion IS 'Name of the subregion';
COMMENT ON COLUMN integration.city_staging.location IS 'Geographic location of the city';
COMMENT ON COLUMN integration.city_staging.latest_recorded_population IS 'Latest available population for the City';
COMMENT ON COLUMN integration.city_staging.valid_from IS 'Valid from this date and time';
COMMENT ON COLUMN integration.city_staging.valid_to IS 'Valid until this date and time';
COMMENT ON INDEX ix_integration_city_staging_wwi_city_id IS 'Allows quickly locating by WWI City Key';
