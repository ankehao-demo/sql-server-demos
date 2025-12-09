-- Wide World Importers Data Warehouse - PostgreSQL Schema Migration
-- Phase 4: OLAP Schema Migration
-- Dimension: City
-- Note: Uses PostGIS extension for geography type

CREATE TABLE dimension.city (
    city_key                     INTEGER NOT NULL DEFAULT nextval('sequences.city_key'),
    wwi_city_id                  INTEGER NOT NULL,
    city                         VARCHAR(50) NOT NULL,
    state_province               VARCHAR(50) NOT NULL,
    country                      VARCHAR(60) NOT NULL,
    continent                    VARCHAR(30) NOT NULL,
    sales_territory              VARCHAR(50) NOT NULL,
    region                       VARCHAR(30) NOT NULL,
    subregion                    VARCHAR(30) NOT NULL,
    location                     GEOGRAPHY(Point, 4326),
    latest_recorded_population   BIGINT NOT NULL,
    valid_from                   TIMESTAMP NOT NULL,
    valid_to                     TIMESTAMP NOT NULL,
    lineage_key                  INTEGER NOT NULL,

    CONSTRAINT pk_dimension_city PRIMARY KEY (city_key)
);

-- Create index for WWI City ID lookups (SCD Type 2 pattern)
CREATE INDEX ix_dimension_city_wwi_city_id 
    ON dimension.city (wwi_city_id, valid_from, valid_to);

-- Add table and column comments
COMMENT ON TABLE dimension.city IS 'City dimension';
COMMENT ON COLUMN dimension.city.city_key IS 'DW key for the city dimension';
COMMENT ON COLUMN dimension.city.wwi_city_id IS 'Numeric ID used for reference to a city within the WWI database';
COMMENT ON COLUMN dimension.city.city IS 'Formal name of the city';
COMMENT ON COLUMN dimension.city.state_province IS 'State or province for this city';
COMMENT ON COLUMN dimension.city.country IS 'Country name';
COMMENT ON COLUMN dimension.city.continent IS 'Continent that this city is on';
COMMENT ON COLUMN dimension.city.sales_territory IS 'Sales territory for this StateProvince';
COMMENT ON COLUMN dimension.city.region IS 'Name of the region';
COMMENT ON COLUMN dimension.city.subregion IS 'Name of the subregion';
COMMENT ON COLUMN dimension.city.location IS 'Geographic location of the city';
COMMENT ON COLUMN dimension.city.latest_recorded_population IS 'Latest available population for the City';
COMMENT ON COLUMN dimension.city.valid_from IS 'Valid from this date and time';
COMMENT ON COLUMN dimension.city.valid_to IS 'Valid until this date and time';
COMMENT ON COLUMN dimension.city.lineage_key IS 'Lineage Key for the data load for this row';
COMMENT ON INDEX dimension.ix_dimension_city_wwi_city_id IS 'Allows quickly locating by WWI ID';
