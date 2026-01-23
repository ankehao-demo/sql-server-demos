-- Wide World Importers PostgreSQL Migration
-- Script 007: Create Indexes
-- Migrated from SQL Server to PostgreSQL

-- Application schema indexes
CREATE INDEX IF NOT EXISTS ix_application_people_is_employee 
    ON application.people (is_employee);

CREATE INDEX IF NOT EXISTS ix_application_people_is_salesperson 
    ON application.people (is_salesperson);

CREATE INDEX IF NOT EXISTS ix_application_people_full_name 
    ON application.people (full_name);

CREATE INDEX IF NOT EXISTS ix_application_people_perf_20160301_05 
    ON application.people (is_permitted_to_logon, person_id) 
    INCLUDE (full_name, email_address);

CREATE INDEX IF NOT EXISTS ix_application_cities_state_province_id 
    ON application.cities (state_province_id);

CREATE INDEX IF NOT EXISTS ix_application_state_provinces_country_id 
    ON application.state_provinces (country_id);

-- Sales schema indexes
CREATE INDEX IF NOT EXISTS ix_sales_customers_customer_category_id 
    ON sales.customers (customer_category_id);

CREATE INDEX IF NOT EXISTS ix_sales_customers_buying_group_id 
    ON sales.customers (buying_group_id);

CREATE INDEX IF NOT EXISTS ix_sales_customers_primary_contact_person_id 
    ON sales.customers (primary_contact_person_id);

CREATE INDEX IF NOT EXISTS ix_sales_customers_alternate_contact_person_id 
    ON sales.customers (alternate_contact_person_id);

CREATE INDEX IF NOT EXISTS ix_sales_customers_delivery_method_id 
    ON sales.customers (delivery_method_id);

CREATE INDEX IF NOT EXISTS ix_sales_customers_delivery_city_id 
    ON sales.customers (delivery_city_id);

CREATE INDEX IF NOT EXISTS ix_sales_customers_postal_city_id 
    ON sales.customers (postal_city_id);

CREATE INDEX IF NOT EXISTS ix_sales_customers_perf_20160301_06 
    ON sales.customers (is_on_credit_hold, customer_id, bill_to_customer_id) 
    INCLUDE (primary_contact_person_id);

CREATE INDEX IF NOT EXISTS ix_sales_orders_customer_id 
    ON sales.orders (customer_id);

CREATE INDEX IF NOT EXISTS ix_sales_orders_salesperson_person_id 
    ON sales.orders (salesperson_person_id);

CREATE INDEX IF NOT EXISTS ix_sales_orders_picked_by_person_id 
    ON sales.orders (picked_by_person_id);

CREATE INDEX IF NOT EXISTS ix_sales_orders_contact_person_id 
    ON sales.orders (contact_person_id);

CREATE INDEX IF NOT EXISTS ix_sales_order_lines_order_id 
    ON sales.order_lines (order_id);

CREATE INDEX IF NOT EXISTS ix_sales_order_lines_stock_item_id 
    ON sales.order_lines (stock_item_id);

CREATE INDEX IF NOT EXISTS ix_sales_order_lines_package_type_id 
    ON sales.order_lines (package_type_id);

CREATE INDEX IF NOT EXISTS ix_sales_invoices_customer_id 
    ON sales.invoices (customer_id);

CREATE INDEX IF NOT EXISTS ix_sales_invoices_bill_to_customer_id 
    ON sales.invoices (bill_to_customer_id);

CREATE INDEX IF NOT EXISTS ix_sales_invoices_order_id 
    ON sales.invoices (order_id);

CREATE INDEX IF NOT EXISTS ix_sales_invoices_delivery_method_id 
    ON sales.invoices (delivery_method_id);

CREATE INDEX IF NOT EXISTS ix_sales_invoices_contact_person_id 
    ON sales.invoices (contact_person_id);

CREATE INDEX IF NOT EXISTS ix_sales_invoices_accounts_person_id 
    ON sales.invoices (accounts_person_id);

CREATE INDEX IF NOT EXISTS ix_sales_invoices_salesperson_person_id 
    ON sales.invoices (salesperson_person_id);

CREATE INDEX IF NOT EXISTS ix_sales_invoices_packed_by_person_id 
    ON sales.invoices (packed_by_person_id);

CREATE INDEX IF NOT EXISTS ix_sales_invoice_lines_invoice_id 
    ON sales.invoice_lines (invoice_id);

CREATE INDEX IF NOT EXISTS ix_sales_invoice_lines_stock_item_id 
    ON sales.invoice_lines (stock_item_id);

CREATE INDEX IF NOT EXISTS ix_sales_invoice_lines_package_type_id 
    ON sales.invoice_lines (package_type_id);

CREATE INDEX IF NOT EXISTS ix_sales_customer_transactions_customer_id 
    ON sales.customer_transactions (customer_id);

CREATE INDEX IF NOT EXISTS ix_sales_customer_transactions_transaction_type_id 
    ON sales.customer_transactions (transaction_type_id);

CREATE INDEX IF NOT EXISTS ix_sales_customer_transactions_invoice_id 
    ON sales.customer_transactions (invoice_id);

CREATE INDEX IF NOT EXISTS ix_sales_customer_transactions_payment_method_id 
    ON sales.customer_transactions (payment_method_id);

CREATE INDEX IF NOT EXISTS ix_sales_customer_transactions_transaction_date 
    ON sales.customer_transactions (transaction_date);

CREATE INDEX IF NOT EXISTS ix_sales_customer_transactions_is_finalized 
    ON sales.customer_transactions (is_finalized);

-- Purchasing schema indexes
CREATE INDEX IF NOT EXISTS ix_purchasing_suppliers_supplier_category_id 
    ON purchasing.suppliers (supplier_category_id);

CREATE INDEX IF NOT EXISTS ix_purchasing_suppliers_primary_contact_person_id 
    ON purchasing.suppliers (primary_contact_person_id);

CREATE INDEX IF NOT EXISTS ix_purchasing_suppliers_alternate_contact_person_id 
    ON purchasing.suppliers (alternate_contact_person_id);

CREATE INDEX IF NOT EXISTS ix_purchasing_suppliers_delivery_method_id 
    ON purchasing.suppliers (delivery_method_id);

CREATE INDEX IF NOT EXISTS ix_purchasing_suppliers_delivery_city_id 
    ON purchasing.suppliers (delivery_city_id);

CREATE INDEX IF NOT EXISTS ix_purchasing_suppliers_postal_city_id 
    ON purchasing.suppliers (postal_city_id);

CREATE INDEX IF NOT EXISTS ix_purchasing_purchase_orders_supplier_id 
    ON purchasing.purchase_orders (supplier_id);

CREATE INDEX IF NOT EXISTS ix_purchasing_purchase_orders_delivery_method_id 
    ON purchasing.purchase_orders (delivery_method_id);

CREATE INDEX IF NOT EXISTS ix_purchasing_purchase_orders_contact_person_id 
    ON purchasing.purchase_orders (contact_person_id);

CREATE INDEX IF NOT EXISTS ix_purchasing_purchase_order_lines_purchase_order_id 
    ON purchasing.purchase_order_lines (purchase_order_id);

CREATE INDEX IF NOT EXISTS ix_purchasing_purchase_order_lines_stock_item_id 
    ON purchasing.purchase_order_lines (stock_item_id);

CREATE INDEX IF NOT EXISTS ix_purchasing_purchase_order_lines_package_type_id 
    ON purchasing.purchase_order_lines (package_type_id);

CREATE INDEX IF NOT EXISTS ix_purchasing_supplier_transactions_supplier_id 
    ON purchasing.supplier_transactions (supplier_id);

CREATE INDEX IF NOT EXISTS ix_purchasing_supplier_transactions_transaction_type_id 
    ON purchasing.supplier_transactions (transaction_type_id);

CREATE INDEX IF NOT EXISTS ix_purchasing_supplier_transactions_purchase_order_id 
    ON purchasing.supplier_transactions (purchase_order_id);

CREATE INDEX IF NOT EXISTS ix_purchasing_supplier_transactions_payment_method_id 
    ON purchasing.supplier_transactions (payment_method_id);

CREATE INDEX IF NOT EXISTS ix_purchasing_supplier_transactions_transaction_date 
    ON purchasing.supplier_transactions (transaction_date);

-- Warehouse schema indexes
CREATE INDEX IF NOT EXISTS ix_warehouse_stock_items_supplier_id 
    ON warehouse.stock_items (supplier_id);

CREATE INDEX IF NOT EXISTS ix_warehouse_stock_items_color_id 
    ON warehouse.stock_items (color_id);

CREATE INDEX IF NOT EXISTS ix_warehouse_stock_items_unit_package_id 
    ON warehouse.stock_items (unit_package_id);

CREATE INDEX IF NOT EXISTS ix_warehouse_stock_items_outer_package_id 
    ON warehouse.stock_items (outer_package_id);

CREATE INDEX IF NOT EXISTS ix_warehouse_stock_item_stock_groups_stock_item_id 
    ON warehouse.stock_item_stock_groups (stock_item_id);

CREATE INDEX IF NOT EXISTS ix_warehouse_stock_item_stock_groups_stock_group_id 
    ON warehouse.stock_item_stock_groups (stock_group_id);

CREATE INDEX IF NOT EXISTS ix_warehouse_stock_item_transactions_stock_item_id 
    ON warehouse.stock_item_transactions (stock_item_id);

CREATE INDEX IF NOT EXISTS ix_warehouse_stock_item_transactions_transaction_type_id 
    ON warehouse.stock_item_transactions (transaction_type_id);

CREATE INDEX IF NOT EXISTS ix_warehouse_stock_item_transactions_customer_id 
    ON warehouse.stock_item_transactions (customer_id);

CREATE INDEX IF NOT EXISTS ix_warehouse_stock_item_transactions_invoice_id 
    ON warehouse.stock_item_transactions (invoice_id);

CREATE INDEX IF NOT EXISTS ix_warehouse_stock_item_transactions_supplier_id 
    ON warehouse.stock_item_transactions (supplier_id);

CREATE INDEX IF NOT EXISTS ix_warehouse_stock_item_transactions_purchase_order_id 
    ON warehouse.stock_item_transactions (purchase_order_id);

CREATE INDEX IF NOT EXISTS ix_warehouse_stock_item_transactions_occurred_when 
    ON warehouse.stock_item_transactions (transaction_occurred_when);

CREATE INDEX IF NOT EXISTS ix_warehouse_cold_room_temperatures_cold_room_sensor_number 
    ON warehouse.cold_room_temperatures (cold_room_sensor_number);

CREATE INDEX IF NOT EXISTS ix_warehouse_cold_room_temperatures_recorded_when 
    ON warehouse.cold_room_temperatures (recorded_when);

CREATE INDEX IF NOT EXISTS ix_warehouse_vehicle_temperatures_vehicle_registration 
    ON warehouse.vehicle_temperatures (vehicle_registration);

CREATE INDEX IF NOT EXISTS ix_warehouse_vehicle_temperatures_recorded_when 
    ON warehouse.vehicle_temperatures (recorded_when);

-- Spatial indexes using PostGIS GIST
CREATE INDEX IF NOT EXISTS ix_application_countries_border_gist 
    ON application.countries USING GIST (border);

CREATE INDEX IF NOT EXISTS ix_application_state_provinces_border_gist 
    ON application.state_provinces USING GIST (border);

CREATE INDEX IF NOT EXISTS ix_application_cities_location_gist 
    ON application.cities USING GIST (location);

CREATE INDEX IF NOT EXISTS ix_sales_customers_delivery_location_gist 
    ON sales.customers USING GIST (delivery_location);

CREATE INDEX IF NOT EXISTS ix_purchasing_suppliers_delivery_location_gist 
    ON purchasing.suppliers USING GIST (delivery_location);

-- Archive table indexes for temporal queries
CREATE INDEX IF NOT EXISTS ix_application_countries_archive_valid_from 
    ON application.countries_archive (valid_from);

CREATE INDEX IF NOT EXISTS ix_application_countries_archive_valid_to 
    ON application.countries_archive (valid_to);

CREATE INDEX IF NOT EXISTS ix_application_state_provinces_archive_valid_from 
    ON application.state_provinces_archive (valid_from);

CREATE INDEX IF NOT EXISTS ix_application_cities_archive_valid_from 
    ON application.cities_archive (valid_from);

CREATE INDEX IF NOT EXISTS ix_application_people_archive_valid_from 
    ON application.people_archive (valid_from);

CREATE INDEX IF NOT EXISTS ix_sales_customers_archive_valid_from 
    ON sales.customers_archive (valid_from);

CREATE INDEX IF NOT EXISTS ix_warehouse_stock_items_archive_valid_from 
    ON warehouse.stock_items_archive (valid_from);

-- Add comments for documentation
COMMENT ON INDEX application.ix_application_people_is_employee IS 'Allows quickly locating employees';
COMMENT ON INDEX application.ix_application_people_is_salesperson IS 'Allows quickly locating salespeople';
COMMENT ON INDEX application.ix_application_people_full_name IS 'Improves performance of name-related queries';
COMMENT ON INDEX application.ix_application_people_perf_20160301_05 IS 'Improves performance of order picking and invoicing';
COMMENT ON INDEX sales.ix_sales_customers_perf_20160301_06 IS 'Improves performance of order picking and invoicing';
