-- Wide World Importers PostgreSQL Migration
-- Phase 2: OLTP Schema Migration
-- Warehouse.VehicleTemperatures table (non-temporal, originally memory-optimized)
-- Note: PostgreSQL doesn't have memory-optimized tables, using regular table with optimizations

CREATE TABLE warehouse.vehicle_temperatures (
    vehicle_temperature_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    vehicle_registration VARCHAR(20) NOT NULL,
    chiller_sensor_number INTEGER NOT NULL,
    recorded_when TIMESTAMP NOT NULL,
    temperature NUMERIC(10, 2) NOT NULL,
    full_sensor_data VARCHAR(1000) NULL,
    is_compressed BOOLEAN NOT NULL,
    compressed_sensor_data BYTEA NULL
);

-- Index for vehicle registration lookups
CREATE INDEX ix_warehouse_vehicle_temperatures_vehicle_registration 
    ON warehouse.vehicle_temperatures(vehicle_registration);
CREATE INDEX ix_warehouse_vehicle_temperatures_recorded_when 
    ON warehouse.vehicle_temperatures(recorded_when);
