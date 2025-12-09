-- Wide World Importers PostgreSQL Migration
-- Phase 2: OLTP Schema Migration
-- Warehouse.ColdRoomTemperatures table (temporal table, originally memory-optimized)
-- Note: PostgreSQL doesn't have memory-optimized tables, using regular table with optimizations

-- Main table
CREATE TABLE warehouse.cold_room_temperatures (
    cold_room_temperature_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    cold_room_sensor_number INTEGER NOT NULL,
    recorded_when TIMESTAMP NOT NULL,
    temperature NUMERIC(10, 2) NOT NULL,
    valid_from TIMESTAMP NOT NULL DEFAULT clock_timestamp(),
    valid_to TIMESTAMP NOT NULL DEFAULT '9999-12-31 23:59:59.999999'::timestamp
);

-- History/Archive table for temporal data
CREATE TABLE warehouse.cold_room_temperatures_archive (
    cold_room_temperature_id BIGINT NOT NULL,
    cold_room_sensor_number INTEGER NOT NULL,
    recorded_when TIMESTAMP NOT NULL,
    temperature NUMERIC(10, 2) NOT NULL,
    valid_from TIMESTAMP NOT NULL,
    valid_to TIMESTAMP NOT NULL,
    
    CONSTRAINT pk_warehouse_cold_room_temperatures_archive PRIMARY KEY (cold_room_temperature_id, valid_from)
);

-- Index for sensor number lookups
CREATE INDEX ix_warehouse_cold_room_temperatures_sensor_number 
    ON warehouse.cold_room_temperatures(cold_room_sensor_number);
