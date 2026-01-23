-- Wide World Importers PostgreSQL Migration
-- Script 006: Create Warehouse Schema Tables
-- Migrated from SQL Server to PostgreSQL

-- Colors table
CREATE TABLE IF NOT EXISTS warehouse.colors (
    color_id INTEGER NOT NULL DEFAULT nextval('warehouse.color_id_seq'),
    color_name VARCHAR(20) NOT NULL,
    last_edited_by INTEGER NOT NULL,
    valid_from TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    valid_to TIMESTAMP(6) NOT NULL DEFAULT '9999-12-31 23:59:59.999999',
    CONSTRAINT pk_warehouse_colors PRIMARY KEY (color_id),
    CONSTRAINT uq_warehouse_colors_color_name UNIQUE (color_name),
    CONSTRAINT fk_warehouse_colors_last_edited_by FOREIGN KEY (last_edited_by) 
        REFERENCES application.people (person_id)
);

-- Colors archive table
CREATE TABLE IF NOT EXISTS warehouse.colors_archive (
    color_id INTEGER NOT NULL,
    color_name VARCHAR(20) NOT NULL,
    last_edited_by INTEGER NOT NULL,
    valid_from TIMESTAMP(6) NOT NULL,
    valid_to TIMESTAMP(6) NOT NULL
);

-- Package Types table
CREATE TABLE IF NOT EXISTS warehouse.package_types (
    package_type_id INTEGER NOT NULL DEFAULT nextval('warehouse.package_type_id_seq'),
    package_type_name VARCHAR(50) NOT NULL,
    last_edited_by INTEGER NOT NULL,
    valid_from TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    valid_to TIMESTAMP(6) NOT NULL DEFAULT '9999-12-31 23:59:59.999999',
    CONSTRAINT pk_warehouse_package_types PRIMARY KEY (package_type_id),
    CONSTRAINT uq_warehouse_package_types_package_type_name UNIQUE (package_type_name),
    CONSTRAINT fk_warehouse_package_types_last_edited_by FOREIGN KEY (last_edited_by) 
        REFERENCES application.people (person_id)
);

-- Package Types archive table
CREATE TABLE IF NOT EXISTS warehouse.package_types_archive (
    package_type_id INTEGER NOT NULL,
    package_type_name VARCHAR(50) NOT NULL,
    last_edited_by INTEGER NOT NULL,
    valid_from TIMESTAMP(6) NOT NULL,
    valid_to TIMESTAMP(6) NOT NULL
);

-- Stock Groups table
CREATE TABLE IF NOT EXISTS warehouse.stock_groups (
    stock_group_id INTEGER NOT NULL DEFAULT nextval('warehouse.stock_group_id_seq'),
    stock_group_name VARCHAR(50) NOT NULL,
    last_edited_by INTEGER NOT NULL,
    valid_from TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    valid_to TIMESTAMP(6) NOT NULL DEFAULT '9999-12-31 23:59:59.999999',
    CONSTRAINT pk_warehouse_stock_groups PRIMARY KEY (stock_group_id),
    CONSTRAINT uq_warehouse_stock_groups_stock_group_name UNIQUE (stock_group_name),
    CONSTRAINT fk_warehouse_stock_groups_last_edited_by FOREIGN KEY (last_edited_by) 
        REFERENCES application.people (person_id)
);

-- Stock Groups archive table
CREATE TABLE IF NOT EXISTS warehouse.stock_groups_archive (
    stock_group_id INTEGER NOT NULL,
    stock_group_name VARCHAR(50) NOT NULL,
    last_edited_by INTEGER NOT NULL,
    valid_from TIMESTAMP(6) NOT NULL,
    valid_to TIMESTAMP(6) NOT NULL
);

-- Stock Items table
CREATE TABLE IF NOT EXISTS warehouse.stock_items (
    stock_item_id INTEGER NOT NULL DEFAULT nextval('warehouse.stock_item_id_seq'),
    stock_item_name VARCHAR(100) NOT NULL,
    supplier_id INTEGER NOT NULL,
    color_id INTEGER,
    unit_package_id INTEGER NOT NULL,
    outer_package_id INTEGER NOT NULL,
    brand VARCHAR(50),
    size VARCHAR(20),
    lead_time_days INTEGER NOT NULL,
    quantity_per_outer INTEGER NOT NULL,
    is_chiller_stock BOOLEAN NOT NULL,
    barcode VARCHAR(50),
    tax_rate NUMERIC(18, 3) NOT NULL,
    unit_price NUMERIC(18, 2) NOT NULL,
    recommended_retail_price NUMERIC(18, 2),
    typical_weight_per_unit NUMERIC(18, 3) NOT NULL,
    marketing_comments TEXT,
    internal_comments TEXT,
    photo BYTEA,
    custom_fields JSONB,
    -- Computed columns using GENERATED ALWAYS AS STORED
    search_details VARCHAR(201) GENERATED ALWAYS AS (stock_item_name || ' ' || COALESCE(marketing_comments, '')) STORED,
    last_edited_by INTEGER NOT NULL,
    valid_from TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    valid_to TIMESTAMP(6) NOT NULL DEFAULT '9999-12-31 23:59:59.999999',
    CONSTRAINT pk_warehouse_stock_items PRIMARY KEY (stock_item_id),
    CONSTRAINT uq_warehouse_stock_items_stock_item_name UNIQUE (stock_item_name),
    CONSTRAINT fk_warehouse_stock_items_supplier_id FOREIGN KEY (supplier_id) 
        REFERENCES purchasing.suppliers (supplier_id),
    CONSTRAINT fk_warehouse_stock_items_color_id FOREIGN KEY (color_id) 
        REFERENCES warehouse.colors (color_id),
    CONSTRAINT fk_warehouse_stock_items_unit_package_id FOREIGN KEY (unit_package_id) 
        REFERENCES warehouse.package_types (package_type_id),
    CONSTRAINT fk_warehouse_stock_items_outer_package_id FOREIGN KEY (outer_package_id) 
        REFERENCES warehouse.package_types (package_type_id),
    CONSTRAINT fk_warehouse_stock_items_last_edited_by FOREIGN KEY (last_edited_by) 
        REFERENCES application.people (person_id)
);

-- Stock Items archive table
CREATE TABLE IF NOT EXISTS warehouse.stock_items_archive (
    stock_item_id INTEGER NOT NULL,
    stock_item_name VARCHAR(100) NOT NULL,
    supplier_id INTEGER NOT NULL,
    color_id INTEGER,
    unit_package_id INTEGER NOT NULL,
    outer_package_id INTEGER NOT NULL,
    brand VARCHAR(50),
    size VARCHAR(20),
    lead_time_days INTEGER NOT NULL,
    quantity_per_outer INTEGER NOT NULL,
    is_chiller_stock BOOLEAN NOT NULL,
    barcode VARCHAR(50),
    tax_rate NUMERIC(18, 3) NOT NULL,
    unit_price NUMERIC(18, 2) NOT NULL,
    recommended_retail_price NUMERIC(18, 2),
    typical_weight_per_unit NUMERIC(18, 3) NOT NULL,
    marketing_comments TEXT,
    internal_comments TEXT,
    photo BYTEA,
    custom_fields JSONB,
    search_details VARCHAR(201),
    last_edited_by INTEGER NOT NULL,
    valid_from TIMESTAMP(6) NOT NULL,
    valid_to TIMESTAMP(6) NOT NULL
);

-- Stock Item Holdings table (current stock levels)
CREATE TABLE IF NOT EXISTS warehouse.stock_item_holdings (
    stock_item_id INTEGER NOT NULL,
    quantity_on_hand INTEGER NOT NULL,
    bin_location VARCHAR(20) NOT NULL,
    last_stocktake_quantity INTEGER NOT NULL,
    last_cost_price NUMERIC(18, 2) NOT NULL,
    reorder_level INTEGER NOT NULL,
    target_stock_level INTEGER NOT NULL,
    last_edited_by INTEGER NOT NULL,
    last_edited_when TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT pk_warehouse_stock_item_holdings PRIMARY KEY (stock_item_id),
    CONSTRAINT fk_warehouse_stock_item_holdings_stock_item_id FOREIGN KEY (stock_item_id) 
        REFERENCES warehouse.stock_items (stock_item_id),
    CONSTRAINT fk_warehouse_stock_item_holdings_last_edited_by FOREIGN KEY (last_edited_by) 
        REFERENCES application.people (person_id)
);

-- Stock Item Stock Groups (many-to-many relationship)
CREATE TABLE IF NOT EXISTS warehouse.stock_item_stock_groups (
    stock_item_stock_group_id INTEGER NOT NULL DEFAULT nextval('warehouse.stock_item_stock_group_id_seq'),
    stock_item_id INTEGER NOT NULL,
    stock_group_id INTEGER NOT NULL,
    last_edited_by INTEGER NOT NULL,
    last_edited_when TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT pk_warehouse_stock_item_stock_groups PRIMARY KEY (stock_item_stock_group_id),
    CONSTRAINT uq_warehouse_stock_item_stock_groups UNIQUE (stock_item_id, stock_group_id),
    CONSTRAINT fk_warehouse_stock_item_stock_groups_stock_item_id FOREIGN KEY (stock_item_id) 
        REFERENCES warehouse.stock_items (stock_item_id),
    CONSTRAINT fk_warehouse_stock_item_stock_groups_stock_group_id FOREIGN KEY (stock_group_id) 
        REFERENCES warehouse.stock_groups (stock_group_id),
    CONSTRAINT fk_warehouse_stock_item_stock_groups_last_edited_by FOREIGN KEY (last_edited_by) 
        REFERENCES application.people (person_id)
);

-- Stock Item Transactions table
CREATE TABLE IF NOT EXISTS warehouse.stock_item_transactions (
    stock_item_transaction_id BIGSERIAL NOT NULL,
    stock_item_id INTEGER NOT NULL,
    transaction_type_id INTEGER NOT NULL,
    customer_id INTEGER,
    invoice_id INTEGER,
    supplier_id INTEGER,
    purchase_order_id INTEGER,
    transaction_occurred_when TIMESTAMP(6) NOT NULL,
    quantity NUMERIC(18, 3) NOT NULL,
    last_edited_by INTEGER NOT NULL,
    last_edited_when TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT pk_warehouse_stock_item_transactions PRIMARY KEY (stock_item_transaction_id),
    CONSTRAINT fk_warehouse_stock_item_transactions_stock_item_id FOREIGN KEY (stock_item_id) 
        REFERENCES warehouse.stock_items (stock_item_id),
    CONSTRAINT fk_warehouse_stock_item_transactions_transaction_type_id FOREIGN KEY (transaction_type_id) 
        REFERENCES application.transaction_types (transaction_type_id),
    CONSTRAINT fk_warehouse_stock_item_transactions_customer_id FOREIGN KEY (customer_id) 
        REFERENCES sales.customers (customer_id),
    CONSTRAINT fk_warehouse_stock_item_transactions_invoice_id FOREIGN KEY (invoice_id) 
        REFERENCES sales.invoices (invoice_id),
    CONSTRAINT fk_warehouse_stock_item_transactions_supplier_id FOREIGN KEY (supplier_id) 
        REFERENCES purchasing.suppliers (supplier_id),
    CONSTRAINT fk_warehouse_stock_item_transactions_purchase_order_id FOREIGN KEY (purchase_order_id) 
        REFERENCES purchasing.purchase_orders (purchase_order_id),
    CONSTRAINT fk_warehouse_stock_item_transactions_last_edited_by FOREIGN KEY (last_edited_by) 
        REFERENCES application.people (person_id)
);

-- Cold Room Temperatures table (sensor data with temporal support)
CREATE TABLE IF NOT EXISTS warehouse.cold_room_temperatures (
    cold_room_temperature_id BIGSERIAL NOT NULL,
    cold_room_sensor_number INTEGER NOT NULL,
    recorded_when TIMESTAMP(6) NOT NULL,
    temperature NUMERIC(10, 2) NOT NULL,
    valid_from TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    valid_to TIMESTAMP(6) NOT NULL DEFAULT '9999-12-31 23:59:59.999999',
    CONSTRAINT pk_warehouse_cold_room_temperatures PRIMARY KEY (cold_room_temperature_id)
);

-- Cold Room Temperatures archive table
CREATE TABLE IF NOT EXISTS warehouse.cold_room_temperatures_archive (
    cold_room_temperature_id BIGINT NOT NULL,
    cold_room_sensor_number INTEGER NOT NULL,
    recorded_when TIMESTAMP(6) NOT NULL,
    temperature NUMERIC(10, 2) NOT NULL,
    valid_from TIMESTAMP(6) NOT NULL,
    valid_to TIMESTAMP(6) NOT NULL
);

-- Vehicle Temperatures table (sensor data)
CREATE TABLE IF NOT EXISTS warehouse.vehicle_temperatures (
    vehicle_temperature_id BIGSERIAL NOT NULL,
    vehicle_registration VARCHAR(20) NOT NULL,
    chiller_sensor_number INTEGER NOT NULL,
    recorded_when TIMESTAMP(6) NOT NULL,
    temperature NUMERIC(10, 2) NOT NULL,
    full_sensor_data TEXT,
    is_compressed BOOLEAN NOT NULL DEFAULT FALSE,
    compressed_sensor_data BYTEA,
    CONSTRAINT pk_warehouse_vehicle_temperatures PRIMARY KEY (vehicle_temperature_id)
);

-- Add foreign key references for order_lines and invoice_lines to stock_items and package_types
ALTER TABLE sales.order_lines 
    ADD CONSTRAINT fk_sales_order_lines_stock_item_id FOREIGN KEY (stock_item_id) 
        REFERENCES warehouse.stock_items (stock_item_id);

ALTER TABLE sales.order_lines 
    ADD CONSTRAINT fk_sales_order_lines_package_type_id FOREIGN KEY (package_type_id) 
        REFERENCES warehouse.package_types (package_type_id);

ALTER TABLE sales.invoice_lines 
    ADD CONSTRAINT fk_sales_invoice_lines_stock_item_id FOREIGN KEY (stock_item_id) 
        REFERENCES warehouse.stock_items (stock_item_id);

ALTER TABLE sales.invoice_lines 
    ADD CONSTRAINT fk_sales_invoice_lines_package_type_id FOREIGN KEY (package_type_id) 
        REFERENCES warehouse.package_types (package_type_id);

-- Add foreign key for special_deals to stock_items and stock_groups
ALTER TABLE sales.special_deals 
    ADD CONSTRAINT fk_sales_special_deals_stock_item_id FOREIGN KEY (stock_item_id) 
        REFERENCES warehouse.stock_items (stock_item_id);

ALTER TABLE sales.special_deals 
    ADD CONSTRAINT fk_sales_special_deals_stock_group_id FOREIGN KEY (stock_group_id) 
        REFERENCES warehouse.stock_groups (stock_group_id);

-- Add foreign key for purchase_order_lines to stock_items and package_types
ALTER TABLE purchasing.purchase_order_lines 
    ADD CONSTRAINT fk_purchasing_purchase_order_lines_stock_item_id FOREIGN KEY (stock_item_id) 
        REFERENCES warehouse.stock_items (stock_item_id);

ALTER TABLE purchasing.purchase_order_lines 
    ADD CONSTRAINT fk_purchasing_purchase_order_lines_package_type_id FOREIGN KEY (package_type_id) 
        REFERENCES warehouse.package_types (package_type_id);

-- Add comments for documentation
COMMENT ON TABLE warehouse.colors IS 'Stock item colors (optional)';
COMMENT ON TABLE warehouse.package_types IS 'Ways that stock items can be packaged (e.g., box, carton, pallet, kg, etc.)';
COMMENT ON TABLE warehouse.stock_groups IS 'Groups for categorizing stock items (e.g., novelties, toys, edible novelties, etc.)';
COMMENT ON TABLE warehouse.stock_items IS 'Main entity table for stock items';
COMMENT ON TABLE warehouse.stock_item_holdings IS 'Non-temporal table holding current stock item holdings';
COMMENT ON TABLE warehouse.stock_item_stock_groups IS 'Which stock items are in which stock groups';
COMMENT ON TABLE warehouse.stock_item_transactions IS 'Transactions covering all movements of stock items';
COMMENT ON TABLE warehouse.cold_room_temperatures IS 'Regularly recorded temperatures of cold room sensors';
COMMENT ON TABLE warehouse.vehicle_temperatures IS 'Regularly recorded temperatures of vehicle chillers';
