-- Wide World Importers PostgreSQL Migration
-- DataLoadSimulation Schema Tables
-- This script creates all tables in the DataLoadSimulation schema

-- SeasonVariation Table (for data load simulation)
CREATE TABLE IF NOT EXISTS dataloadSimulation.seasonvariation (
    seasonvariationid serial PRIMARY KEY,
    year integer NOT NULL,
    season smallint NOT NULL,
    yearlyvariation double precision NOT NULL,
    seasonalvariation double precision NOT NULL,
    CONSTRAINT uq_seasonvariation_year_season UNIQUE (year, season)
);
COMMENT ON TABLE dataloadSimulation.seasonvariation IS 'Stores seasonal variation factors for data simulation';

-- FicticiousNamePool Table (for generating random names)
CREATE TABLE IF NOT EXISTS dataloadSimulation.ficticiousnamepool (
    ficticiousnamepoolid serial PRIMARY KEY,
    firstname varchar(50) NOT NULL,
    lastname varchar(50) NOT NULL,
    fullname varchar(101) GENERATED ALWAYS AS (firstname || ' ' || lastname) STORED
);
COMMENT ON TABLE dataloadSimulation.ficticiousnamepool IS 'Pool of fictitious names for data generation';

-- AreaCode Table (for generating random phone numbers)
CREATE TABLE IF NOT EXISTS dataloadSimulation.areacode (
    areacodeid serial PRIMARY KEY,
    stateprovinceid integer NOT NULL,
    areacode varchar(10) NOT NULL,
    CONSTRAINT fk_areacode_stateprovinceid FOREIGN KEY (stateprovinceid) REFERENCES application.stateprovinces(stateprovinceid)
);
COMMENT ON TABLE dataloadSimulation.areacode IS 'Area codes for phone number generation';
CREATE INDEX IF NOT EXISTS ix_areacode_stateprovinceid ON dataloadSimulation.areacode(stateprovinceid);

-- SampleVersion Table (for tracking sample data version)
CREATE TABLE IF NOT EXISTS dataloadSimulation.sampleversion (
    sampleversionid serial PRIMARY KEY,
    majorversion integer NOT NULL,
    minorversion integer NOT NULL,
    buildversion integer NOT NULL,
    revisionversion integer NOT NULL,
    versiondate date NOT NULL DEFAULT CURRENT_DATE
);
COMMENT ON TABLE dataloadSimulation.sampleversion IS 'Tracks the version of sample data';
