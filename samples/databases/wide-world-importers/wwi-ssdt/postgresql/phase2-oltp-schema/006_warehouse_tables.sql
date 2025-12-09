-- Wide World Importers PostgreSQL Migration
-- Phase 2: OLTP Schema Migration
-- Script 006: Warehouse Schema Tables
-- Migrated from SQL Server to PostgreSQL

-- =============================================
-- Warehouse.Colors Table
-- =============================================
CREATE TABLE warehouse.colors (
    color_id integer NOT NULL DEFAULT nextval('sequences.color_id'),
    color_name varchar(20) NOT NULL,
    last_edited_by integer NOT NULL,
    valid_from timestamp NOT NULL DEFAULT clock_timestamp(),
    valid_to timestamp NOT NULL DEFAULT '9999-12-31 23:59:59.9999999'::timestamp,
    CONSTRAINT pk_warehouse_colors PRIMARY KEY (color_id),
    CONSTRAINT uq_warehouse_colors_color_name UNIQUE (color_name)
);

-- History table for temporal data
CREATE TABLE warehouse.colors_archive (
    color_id integer NOT NULL,
    color_name varchar(20) NOT NULL,
    last_edited_by integer NOT NULL,
    valid_from timestamp NOT NULL,
    valid_to timestamp NOT NULL
);

-- Comments
COMMENT ON TABLE warehouse.colors IS 'Stock items can (optionally) have colors';
COMMENT ON COLUMN warehouse.colors.color_id IS 'Numeric ID used for reference to a color within the database';
COMMENT ON COLUMN warehouse.colors.color_name IS 'Full name of a color that can be used to describe stock items';

-- =============================================
-- Warehouse.PackageTypes Table
-- =============================================
CREATE TABLE warehouse.package_types (
    package_type_id integer NOT NULL DEFAULT nextval('sequences.package_type_id'),
    package_type_name varchar(50) NOT NULL,
    last_edited_by integer NOT NULL,
    valid_from timestamp NOT NULL DEFAULT clock_timestamp(),
    valid_to timestamp NOT NULL DEFAULT '9999-12-31 23:59:59.9999999'::timestamp,
    CONSTRAINT pk_warehouse_package_types PRIMARY KEY (package_type_id),
    CONSTRAINT uq_warehouse_package_types_package_type_name UNIQUE (package_type_name)
);

-- History table for temporal data
CREATE TABLE warehouse.package_types_archive (
    package_type_id integer NOT NULL,
    package_type_name varchar(50) NOT NULL,
    last_edited_by integer NOT NULL,
    valid_from timestamp NOT NULL,
    valid_to timestamp NOT NULL
);

-- Comments
COMMENT ON TABLE warehouse.package_types IS 'Ways that stock items can be packaged (such as bag, jar, etc.)';
COMMENT ON COLUMN warehouse.package_types.package_type_id IS 'Numeric ID used for reference to a package type within the database';
COMMENT ON COLUMN warehouse.package_types.package_type_name IS 'Full name of package types that stock items can be purchased in or sold in';

-- =============================================
-- Warehouse.StockGroups Table
-- =============================================
CREATE TABLE warehouse.stock_groups (
    stock_group_id integer NOT NULL DEFAULT nextval('sequences.stock_group_id'),
    stock_group_name varchar(50) NOT NULL,
    last_edited_by integer NOT NULL,
    valid_from timestamp NOT NULL DEFAULT clock_timestamp(),
    valid_to timestamp NOT NULL DEFAULT '9999-12-31 23:59:59.9999999'::timestamp,
    CONSTRAINT pk_warehouse_stock_groups PRIMARY KEY (stock_group_id),
    CONSTRAINT uq_warehouse_stock_groups_stock_group_name UNIQUE (stock_group_name)
);

-- History table for temporal data
CREATE TABLE warehouse.stock_groups_archive (
    stock_group_id integer NOT NULL,
    stock_group_name varchar(50) NOT NULL,
    last_edited_by integer NOT NULL,
    valid_from timestamp NOT NULL,
    valid_to timestamp NOT NULL
);

-- Comments
COMMENT ON TABLE warehouse.stock_groups IS 'Groups for categorizing stock items (such as novelties, toys, edible novelties, etc.)';
COMMENT ON COLUMN warehouse.stock_groups.stock_group_id IS 'Numeric ID used for reference to a stock group within the database';
COMMENT ON COLUMN warehouse.stock_groups.stock_group_name IS 'Full name of groups used to categorize stock items';

-- =============================================
-- Warehouse.StockItems Table
-- =============================================
CREATE TABLE warehouse.stock_items (
    stock_item_id integer NOT NULL DEFAULT nextval('sequences.stock_item_id'),
    stock_item_name varchar(100) NOT NULL,
    supplier_id integer NOT NULL,
    color_id integer NULL,
    unit_package_id integer NOT NULL,
    outer_package_id integer NOT NULL,
    brand varchar(50) NULL,
    size varchar(20) NULL,
    lead_time_days integer NOT NULL,
    quantity_per_outer integer NOT NULL,
    is_chiller_stock boolean NOT NULL,
    barcode varchar(50) NULL,
    tax_rate numeric(18, 3) NOT NULL,
    unit_price numeric(18, 2) NOT NULL,
    recommended_retail_price numeric(18, 2) NULL,
    typical_weight_per_unit numeric(18, 3) NOT NULL,
    marketing_comments text NULL,
    internal_comments text NULL,
    photo bytea NULL,
    custom_fields jsonb NULL,
    tags jsonb GENERATED ALWAYS AS (custom_fields -> 'Tags') STORED,
    search_details varchar(1000) GENERATED ALWAYS AS (
        COALESCE(stock_item_name, '') || ' ' || COALESCE(marketing_comments, '')
    ) STORED,
    last_edited_by integer NOT NULL,
    valid_from timestamp NOT NULL DEFAULT clock_timestamp(),
    valid_to timestamp NOT NULL DEFAULT '9999-12-31 23:59:59.9999999'::timestamp,
    CONSTRAINT pk_warehouse_stock_items PRIMARY KEY (stock_item_id),
    CONSTRAINT uq_warehouse_stock_items_stock_item_name UNIQUE (stock_item_name)
);

-- History table for temporal data
CREATE TABLE warehouse.stock_items_archive (
    stock_item_id integer NOT NULL,
    stock_item_name varchar(100) NOT NULL,
    supplier_id integer NOT NULL,
    color_id integer NULL,
    unit_package_id integer NOT NULL,
    outer_package_id integer NOT NULL,
    brand varchar(50) NULL,
    size varchar(20) NULL,
    lead_time_days integer NOT NULL,
    quantity_per_outer integer NOT NULL,
    is_chiller_stock boolean NOT NULL,
    barcode varchar(50) NULL,
    tax_rate numeric(18, 3) NOT NULL,
    unit_price numeric(18, 2) NOT NULL,
    recommended_retail_price numeric(18, 2) NULL,
    typical_weight_per_unit numeric(18, 3) NOT NULL,
    marketing_comments text NULL,
    internal_comments text NULL,
    photo bytea NULL,
    custom_fields jsonb NULL,
    tags jsonb NULL,
    search_details varchar(1000) NULL,
    last_edited_by integer NOT NULL,
    valid_from timestamp NOT NULL,
    valid_to timestamp NOT NULL
);

-- Indexes
CREATE INDEX fk_warehouse_stock_items_supplier_id ON warehouse.stock_items(supplier_id);
CREATE INDEX fk_warehouse_stock_items_color_id ON warehouse.stock_items(color_id);
CREATE INDEX fk_warehouse_stock_items_unit_package_id ON warehouse.stock_items(unit_package_id);
CREATE INDEX fk_warehouse_stock_items_outer_package_id ON warehouse.stock_items(outer_package_id);

-- Comments
COMMENT ON TABLE warehouse.stock_items IS 'Main entity table for stock items';
COMMENT ON COLUMN warehouse.stock_items.stock_item_id IS 'Numeric ID used for reference to a stock item within the database';
COMMENT ON COLUMN warehouse.stock_items.stock_item_name IS 'Full name of a stock item (but not a full description)';
COMMENT ON COLUMN warehouse.stock_items.supplier_id IS 'Usual supplier for this stock item';
COMMENT ON COLUMN warehouse.stock_items.color_id IS 'Color (optional) for this stock item';
COMMENT ON COLUMN warehouse.stock_items.unit_package_id IS 'Usual package for selling units of this stock item';
COMMENT ON COLUMN warehouse.stock_items.outer_package_id IS 'Usual package for selling outers of this stock item (ie cartons, boxes, etc.)';
COMMENT ON COLUMN warehouse.stock_items.brand IS 'Brand for the stock item (if the item is branded)';
COMMENT ON COLUMN warehouse.stock_items.size IS 'Size of this item (eg: 100mm)';
COMMENT ON COLUMN warehouse.stock_items.lead_time_days IS 'Number of days typically taken from order to receipt of this stock item';
COMMENT ON COLUMN warehouse.stock_items.quantity_per_outer IS 'Quantity of the stock item in an outer package';
COMMENT ON COLUMN warehouse.stock_items.is_chiller_stock IS 'Does this stock item need to be in a chiller?';
COMMENT ON COLUMN warehouse.stock_items.barcode IS 'Barcode for this stock item';
COMMENT ON COLUMN warehouse.stock_items.tax_rate IS 'Tax rate to be applied';
COMMENT ON COLUMN warehouse.stock_items.unit_price IS 'Selling price (ex-tax) for one unit of this product';
COMMENT ON COLUMN warehouse.stock_items.recommended_retail_price IS 'Recommended retail price for this stock item';
COMMENT ON COLUMN warehouse.stock_items.typical_weight_per_unit IS 'Typical weight for one unit of this product (packaged)';
COMMENT ON COLUMN warehouse.stock_items.marketing_comments IS 'Marketing comments for this stock item (shared outside the organization)';
COMMENT ON COLUMN warehouse.stock_items.internal_comments IS 'Internal comments (not exposed outside organization)';
COMMENT ON COLUMN warehouse.stock_items.photo IS 'Photo of the product';
COMMENT ON COLUMN warehouse.stock_items.custom_fields IS 'Custom fields added by system users';
COMMENT ON COLUMN warehouse.stock_items.tags IS 'Advertising tags associated with this stock item (JSON array retrieved from custom fields)';
COMMENT ON COLUMN warehouse.stock_items.search_details IS 'Combination of columns used by full text search';

-- =============================================
-- Warehouse.StockItemStockGroups Table
-- =============================================
CREATE TABLE warehouse.stock_item_stock_groups (
    stock_item_stock_group_id integer NOT NULL DEFAULT nextval('sequences.stock_item_stock_group_id'),
    stock_item_id integer NOT NULL,
    stock_group_id integer NOT NULL,
    last_edited_by integer NOT NULL,
    last_edited_when timestamp NOT NULL DEFAULT clock_timestamp(),
    CONSTRAINT pk_warehouse_stock_item_stock_groups PRIMARY KEY (stock_item_stock_group_id),
    CONSTRAINT uq_warehouse_stock_item_stock_groups UNIQUE (stock_item_id, stock_group_id)
);

-- Indexes
CREATE INDEX fk_warehouse_stock_item_stock_groups_stock_item_id ON warehouse.stock_item_stock_groups(stock_item_id);
CREATE INDEX fk_warehouse_stock_item_stock_groups_stock_group_id ON warehouse.stock_item_stock_groups(stock_group_id);

-- Comments
COMMENT ON TABLE warehouse.stock_item_stock_groups IS 'Which stock items are in which stock groups';
COMMENT ON COLUMN warehouse.stock_item_stock_groups.stock_item_stock_group_id IS 'Internal reference for this linking row';
COMMENT ON COLUMN warehouse.stock_item_stock_groups.stock_item_id IS 'Stock item assigned to this stock group (FK indexed via unique constraint)';
COMMENT ON COLUMN warehouse.stock_item_stock_groups.stock_group_id IS 'StockGroup assigned to this stock item (FK indexed via unique constraint)';

-- =============================================
-- Warehouse.StockItemHoldings Table
-- =============================================
CREATE TABLE warehouse.stock_item_holdings (
    stock_item_id integer NOT NULL,
    quantity_on_hand integer NOT NULL,
    bin_location varchar(20) NOT NULL,
    last_stocktake_quantity integer NOT NULL,
    last_cost_price numeric(18, 2) NOT NULL,
    reorder_level integer NOT NULL,
    target_stock_level integer NOT NULL,
    last_edited_by integer NOT NULL,
    last_edited_when timestamp NOT NULL DEFAULT clock_timestamp(),
    CONSTRAINT pk_warehouse_stock_item_holdings PRIMARY KEY (stock_item_id)
);

-- Comments
COMMENT ON TABLE warehouse.stock_item_holdings IS 'Non-temporal attributes for stock items';
COMMENT ON COLUMN warehouse.stock_item_holdings.stock_item_id IS 'ID of the stock item that this holding relates to (this table holds non-temporal columns for stock)';
COMMENT ON COLUMN warehouse.stock_item_holdings.quantity_on_hand IS 'Quantity currently on hand (updated when orders are completed)';
COMMENT ON COLUMN warehouse.stock_item_holdings.bin_location IS 'Bin location (where is this stock item located in the warehouse)';
COMMENT ON COLUMN warehouse.stock_item_holdings.last_stocktake_quantity IS 'Quantity at last stocktake (used to determine stock movements)';
COMMENT ON COLUMN warehouse.stock_item_holdings.last_cost_price IS 'Unit cost price the last time this stock item was purchased';
COMMENT ON COLUMN warehouse.stock_item_holdings.reorder_level IS 'Quantity below which reordering should take place';
COMMENT ON COLUMN warehouse.stock_item_holdings.target_stock_level IS 'Typical quantity ordered';

-- =============================================
-- Warehouse.StockItemTransactions Table
-- =============================================
CREATE TABLE warehouse.stock_item_transactions (
    stock_item_transaction_id integer NOT NULL DEFAULT nextval('sequences.transaction_id'),
    stock_item_id integer NOT NULL,
    transaction_type_id integer NOT NULL,
    customer_id integer NULL,
    invoice_id integer NULL,
    supplier_id integer NULL,
    purchase_order_id integer NULL,
    transaction_occurred_when timestamp NOT NULL,
    quantity numeric(18, 3) NOT NULL,
    last_edited_by integer NOT NULL,
    last_edited_when timestamp NOT NULL DEFAULT clock_timestamp(),
    CONSTRAINT pk_warehouse_stock_item_transactions PRIMARY KEY (stock_item_transaction_id)
);

-- Indexes
CREATE INDEX fk_warehouse_stock_item_transactions_stock_item_id ON warehouse.stock_item_transactions(stock_item_id);
CREATE INDEX fk_warehouse_stock_item_transactions_transaction_type_id ON warehouse.stock_item_transactions(transaction_type_id);
CREATE INDEX fk_warehouse_stock_item_transactions_customer_id ON warehouse.stock_item_transactions(customer_id);
CREATE INDEX fk_warehouse_stock_item_transactions_invoice_id ON warehouse.stock_item_transactions(invoice_id);
CREATE INDEX fk_warehouse_stock_item_transactions_supplier_id ON warehouse.stock_item_transactions(supplier_id);
CREATE INDEX fk_warehouse_stock_item_transactions_purchase_order_id ON warehouse.stock_item_transactions(purchase_order_id);

-- Comments
COMMENT ON TABLE warehouse.stock_item_transactions IS 'Transactions covering all movements of all stock items';
COMMENT ON COLUMN warehouse.stock_item_transactions.stock_item_transaction_id IS 'Numeric ID used to refer to a stock item transaction within the database';
COMMENT ON COLUMN warehouse.stock_item_transactions.stock_item_id IS 'StockItem for this transaction';
COMMENT ON COLUMN warehouse.stock_item_transactions.transaction_type_id IS 'Type of transaction';
COMMENT ON COLUMN warehouse.stock_item_transactions.customer_id IS 'Customer for this transaction (if applicable)';
COMMENT ON COLUMN warehouse.stock_item_transactions.invoice_id IS 'ID of an invoice (for transactions associated with an invoice)';
COMMENT ON COLUMN warehouse.stock_item_transactions.supplier_id IS 'Supplier for this stock transaction (if applicable)';
COMMENT ON COLUMN warehouse.stock_item_transactions.purchase_order_id IS 'ID of an purchase order (for transactions associated with a purchase order)';
COMMENT ON COLUMN warehouse.stock_item_transactions.transaction_occurred_when IS 'Date and time when the transaction occurred';
COMMENT ON COLUMN warehouse.stock_item_transactions.quantity IS 'Quantity of stock movement (positive is incoming stock, negative is outgoing)';

-- =============================================
-- Warehouse.ColdRoomTemperatures Table (Memory-Optimized in SQL Server)
-- =============================================
CREATE TABLE warehouse.cold_room_temperatures (
    cold_room_temperature_id bigserial NOT NULL,
    cold_room_sensor_number integer NOT NULL,
    recorded_when timestamp NOT NULL,
    temperature numeric(10, 2) NOT NULL,
    valid_from timestamp NOT NULL DEFAULT clock_timestamp(),
    valid_to timestamp NOT NULL DEFAULT '9999-12-31 23:59:59.9999999'::timestamp,
    CONSTRAINT pk_warehouse_cold_room_temperatures PRIMARY KEY (cold_room_temperature_id)
);

-- History table for temporal data
CREATE TABLE warehouse.cold_room_temperatures_archive (
    cold_room_temperature_id bigint NOT NULL,
    cold_room_sensor_number integer NOT NULL,
    recorded_when timestamp NOT NULL,
    temperature numeric(10, 2) NOT NULL,
    valid_from timestamp NOT NULL,
    valid_to timestamp NOT NULL
);

-- Indexes
CREATE INDEX ix_warehouse_cold_room_temperatures_cold_room_sensor_number ON warehouse.cold_room_temperatures(cold_room_sensor_number);

-- Comments
COMMENT ON TABLE warehouse.cold_room_temperatures IS 'Regularly recorded temperatures of cold room sensors';
COMMENT ON COLUMN warehouse.cold_room_temperatures.cold_room_temperature_id IS 'Instantaneous temperature readings for cold rooms (cold those for temperature monitoring)';
COMMENT ON COLUMN warehouse.cold_room_temperatures.cold_room_sensor_number IS 'Cold room sensor number';
COMMENT ON COLUMN warehouse.cold_room_temperatures.recorded_when IS 'Time when this temperature reading was taken';
COMMENT ON COLUMN warehouse.cold_room_temperatures.temperature IS 'Temperature at the time of reading';

-- =============================================
-- Warehouse.VehicleTemperatures Table (Memory-Optimized in SQL Server)
-- =============================================
CREATE TABLE warehouse.vehicle_temperatures (
    vehicle_temperature_id bigserial NOT NULL,
    vehicle_registration varchar(20) NOT NULL,
    chiller_sensor_number integer NOT NULL,
    recorded_when timestamp NOT NULL,
    temperature numeric(10, 2) NOT NULL,
    full_sensor_data varchar(1000) NULL,
    is_compressed boolean NOT NULL DEFAULT false,
    compressed_sensor_data bytea NULL,
    CONSTRAINT pk_warehouse_vehicle_temperatures PRIMARY KEY (vehicle_temperature_id)
);

-- Indexes
CREATE INDEX ix_warehouse_vehicle_temperatures_vehicle_registration ON warehouse.vehicle_temperatures(vehicle_registration);

-- Comments
COMMENT ON TABLE warehouse.vehicle_temperatures IS 'Regularly recorded temperatures of vehicle chillers';
COMMENT ON COLUMN warehouse.vehicle_temperatures.vehicle_temperature_id IS 'Instantaneous temperature readings for vehicle freezers';
COMMENT ON COLUMN warehouse.vehicle_temperatures.vehicle_registration IS 'Vehicle registration number';
COMMENT ON COLUMN warehouse.vehicle_temperatures.chiller_sensor_number IS 'Chiller sensor number';
COMMENT ON COLUMN warehouse.vehicle_temperatures.recorded_when IS 'Time when this temperature reading was taken';
COMMENT ON COLUMN warehouse.vehicle_temperatures.temperature IS 'Temperature at the time of reading';
COMMENT ON COLUMN warehouse.vehicle_temperatures.full_sensor_data IS 'Full JSON data received from sensor';
COMMENT ON COLUMN warehouse.vehicle_temperatures.is_compressed IS 'Is the sensor data compressed for archival storage?';
COMMENT ON COLUMN warehouse.vehicle_temperatures.compressed_sensor_data IS 'Compressed JSON data for archived readings';
