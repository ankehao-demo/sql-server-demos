-- Wide World Importers PostgreSQL Migration
-- Phase 2: OLTP Schema Migration
-- Temporal table triggers for maintaining history tables

-- ============================================================================
-- APPLICATION SCHEMA TEMPORAL TRIGGERS
-- ============================================================================

-- People temporal trigger function
CREATE OR REPLACE FUNCTION application.people_temporal_trigger()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'UPDATE' THEN
        INSERT INTO application.people_archive 
        SELECT OLD.person_id, OLD.full_name, OLD.preferred_name, OLD.search_name,
               OLD.is_permitted_to_logon, OLD.logon_name, OLD.is_external_logon_provider,
               OLD.hashed_password, OLD.is_system_user, OLD.is_employee, OLD.is_salesperson,
               OLD.user_preferences, OLD.phone_number, OLD.fax_number, OLD.email_address,
               OLD.photo, OLD.custom_fields, OLD.other_languages, OLD.last_edited_by,
               OLD.valid_from, clock_timestamp();
        NEW.valid_from := clock_timestamp();
        NEW.valid_to := '9999-12-31 23:59:59.999999'::timestamp;
        RETURN NEW;
    ELSIF TG_OP = 'DELETE' THEN
        INSERT INTO application.people_archive 
        SELECT OLD.person_id, OLD.full_name, OLD.preferred_name, OLD.search_name,
               OLD.is_permitted_to_logon, OLD.logon_name, OLD.is_external_logon_provider,
               OLD.hashed_password, OLD.is_system_user, OLD.is_employee, OLD.is_salesperson,
               OLD.user_preferences, OLD.phone_number, OLD.fax_number, OLD.email_address,
               OLD.photo, OLD.custom_fields, OLD.other_languages, OLD.last_edited_by,
               OLD.valid_from, clock_timestamp();
        RETURN OLD;
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_application_people_temporal
    BEFORE UPDATE OR DELETE ON application.people
    FOR EACH ROW EXECUTE FUNCTION application.people_temporal_trigger();

-- Countries temporal trigger function
CREATE OR REPLACE FUNCTION application.countries_temporal_trigger()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'UPDATE' THEN
        INSERT INTO application.countries_archive 
        SELECT OLD.country_id, OLD.country_name, OLD.formal_name, OLD.iso_alpha3_code,
               OLD.iso_numeric_code, OLD.country_type, OLD.latest_recorded_population,
               OLD.continent, OLD.region, OLD.subregion, OLD.border, OLD.last_edited_by,
               OLD.valid_from, clock_timestamp();
        NEW.valid_from := clock_timestamp();
        NEW.valid_to := '9999-12-31 23:59:59.999999'::timestamp;
        RETURN NEW;
    ELSIF TG_OP = 'DELETE' THEN
        INSERT INTO application.countries_archive 
        SELECT OLD.country_id, OLD.country_name, OLD.formal_name, OLD.iso_alpha3_code,
               OLD.iso_numeric_code, OLD.country_type, OLD.latest_recorded_population,
               OLD.continent, OLD.region, OLD.subregion, OLD.border, OLD.last_edited_by,
               OLD.valid_from, clock_timestamp();
        RETURN OLD;
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_application_countries_temporal
    BEFORE UPDATE OR DELETE ON application.countries
    FOR EACH ROW EXECUTE FUNCTION application.countries_temporal_trigger();

-- StateProvinces temporal trigger function
CREATE OR REPLACE FUNCTION application.state_provinces_temporal_trigger()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'UPDATE' THEN
        INSERT INTO application.state_provinces_archive 
        SELECT OLD.state_province_id, OLD.state_province_code, OLD.state_province_name,
               OLD.country_id, OLD.sales_territory, OLD.border, OLD.latest_recorded_population,
               OLD.last_edited_by, OLD.valid_from, clock_timestamp();
        NEW.valid_from := clock_timestamp();
        NEW.valid_to := '9999-12-31 23:59:59.999999'::timestamp;
        RETURN NEW;
    ELSIF TG_OP = 'DELETE' THEN
        INSERT INTO application.state_provinces_archive 
        SELECT OLD.state_province_id, OLD.state_province_code, OLD.state_province_name,
               OLD.country_id, OLD.sales_territory, OLD.border, OLD.latest_recorded_population,
               OLD.last_edited_by, OLD.valid_from, clock_timestamp();
        RETURN OLD;
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_application_state_provinces_temporal
    BEFORE UPDATE OR DELETE ON application.state_provinces
    FOR EACH ROW EXECUTE FUNCTION application.state_provinces_temporal_trigger();

-- Cities temporal trigger function
CREATE OR REPLACE FUNCTION application.cities_temporal_trigger()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'UPDATE' THEN
        INSERT INTO application.cities_archive 
        SELECT OLD.city_id, OLD.city_name, OLD.state_province_id, OLD.location,
               OLD.latest_recorded_population, OLD.last_edited_by,
               OLD.valid_from, clock_timestamp();
        NEW.valid_from := clock_timestamp();
        NEW.valid_to := '9999-12-31 23:59:59.999999'::timestamp;
        RETURN NEW;
    ELSIF TG_OP = 'DELETE' THEN
        INSERT INTO application.cities_archive 
        SELECT OLD.city_id, OLD.city_name, OLD.state_province_id, OLD.location,
               OLD.latest_recorded_population, OLD.last_edited_by,
               OLD.valid_from, clock_timestamp();
        RETURN OLD;
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_application_cities_temporal
    BEFORE UPDATE OR DELETE ON application.cities
    FOR EACH ROW EXECUTE FUNCTION application.cities_temporal_trigger();

-- DeliveryMethods temporal trigger function
CREATE OR REPLACE FUNCTION application.delivery_methods_temporal_trigger()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'UPDATE' THEN
        INSERT INTO application.delivery_methods_archive 
        SELECT OLD.delivery_method_id, OLD.delivery_method_name, OLD.last_edited_by,
               OLD.valid_from, clock_timestamp();
        NEW.valid_from := clock_timestamp();
        NEW.valid_to := '9999-12-31 23:59:59.999999'::timestamp;
        RETURN NEW;
    ELSIF TG_OP = 'DELETE' THEN
        INSERT INTO application.delivery_methods_archive 
        SELECT OLD.delivery_method_id, OLD.delivery_method_name, OLD.last_edited_by,
               OLD.valid_from, clock_timestamp();
        RETURN OLD;
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_application_delivery_methods_temporal
    BEFORE UPDATE OR DELETE ON application.delivery_methods
    FOR EACH ROW EXECUTE FUNCTION application.delivery_methods_temporal_trigger();

-- PaymentMethods temporal trigger function
CREATE OR REPLACE FUNCTION application.payment_methods_temporal_trigger()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'UPDATE' THEN
        INSERT INTO application.payment_methods_archive 
        SELECT OLD.payment_method_id, OLD.payment_method_name, OLD.last_edited_by,
               OLD.valid_from, clock_timestamp();
        NEW.valid_from := clock_timestamp();
        NEW.valid_to := '9999-12-31 23:59:59.999999'::timestamp;
        RETURN NEW;
    ELSIF TG_OP = 'DELETE' THEN
        INSERT INTO application.payment_methods_archive 
        SELECT OLD.payment_method_id, OLD.payment_method_name, OLD.last_edited_by,
               OLD.valid_from, clock_timestamp();
        RETURN OLD;
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_application_payment_methods_temporal
    BEFORE UPDATE OR DELETE ON application.payment_methods
    FOR EACH ROW EXECUTE FUNCTION application.payment_methods_temporal_trigger();

-- TransactionTypes temporal trigger function
CREATE OR REPLACE FUNCTION application.transaction_types_temporal_trigger()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'UPDATE' THEN
        INSERT INTO application.transaction_types_archive 
        SELECT OLD.transaction_type_id, OLD.transaction_type_name, OLD.last_edited_by,
               OLD.valid_from, clock_timestamp();
        NEW.valid_from := clock_timestamp();
        NEW.valid_to := '9999-12-31 23:59:59.999999'::timestamp;
        RETURN NEW;
    ELSIF TG_OP = 'DELETE' THEN
        INSERT INTO application.transaction_types_archive 
        SELECT OLD.transaction_type_id, OLD.transaction_type_name, OLD.last_edited_by,
               OLD.valid_from, clock_timestamp();
        RETURN OLD;
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_application_transaction_types_temporal
    BEFORE UPDATE OR DELETE ON application.transaction_types
    FOR EACH ROW EXECUTE FUNCTION application.transaction_types_temporal_trigger();

-- ============================================================================
-- PURCHASING SCHEMA TEMPORAL TRIGGERS
-- ============================================================================

-- SupplierCategories temporal trigger function
CREATE OR REPLACE FUNCTION purchasing.supplier_categories_temporal_trigger()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'UPDATE' THEN
        INSERT INTO purchasing.supplier_categories_archive 
        SELECT OLD.supplier_category_id, OLD.supplier_category_name, OLD.last_edited_by,
               OLD.valid_from, clock_timestamp();
        NEW.valid_from := clock_timestamp();
        NEW.valid_to := '9999-12-31 23:59:59.999999'::timestamp;
        RETURN NEW;
    ELSIF TG_OP = 'DELETE' THEN
        INSERT INTO purchasing.supplier_categories_archive 
        SELECT OLD.supplier_category_id, OLD.supplier_category_name, OLD.last_edited_by,
               OLD.valid_from, clock_timestamp();
        RETURN OLD;
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_purchasing_supplier_categories_temporal
    BEFORE UPDATE OR DELETE ON purchasing.supplier_categories
    FOR EACH ROW EXECUTE FUNCTION purchasing.supplier_categories_temporal_trigger();

-- Suppliers temporal trigger function
CREATE OR REPLACE FUNCTION purchasing.suppliers_temporal_trigger()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'UPDATE' THEN
        INSERT INTO purchasing.suppliers_archive 
        SELECT OLD.supplier_id, OLD.supplier_name, OLD.supplier_category_id,
               OLD.primary_contact_person_id, OLD.alternate_contact_person_id,
               OLD.delivery_method_id, OLD.delivery_city_id, OLD.postal_city_id,
               OLD.supplier_reference, OLD.bank_account_name, OLD.bank_account_branch,
               OLD.bank_account_code, OLD.bank_account_number, OLD.bank_international_code,
               OLD.payment_days, OLD.internal_comments, OLD.phone_number, OLD.fax_number,
               OLD.website_url, OLD.delivery_address_line1, OLD.delivery_address_line2,
               OLD.delivery_postal_code, OLD.delivery_location, OLD.postal_address_line1,
               OLD.postal_address_line2, OLD.postal_postal_code, OLD.last_edited_by,
               OLD.valid_from, clock_timestamp();
        NEW.valid_from := clock_timestamp();
        NEW.valid_to := '9999-12-31 23:59:59.999999'::timestamp;
        RETURN NEW;
    ELSIF TG_OP = 'DELETE' THEN
        INSERT INTO purchasing.suppliers_archive 
        SELECT OLD.supplier_id, OLD.supplier_name, OLD.supplier_category_id,
               OLD.primary_contact_person_id, OLD.alternate_contact_person_id,
               OLD.delivery_method_id, OLD.delivery_city_id, OLD.postal_city_id,
               OLD.supplier_reference, OLD.bank_account_name, OLD.bank_account_branch,
               OLD.bank_account_code, OLD.bank_account_number, OLD.bank_international_code,
               OLD.payment_days, OLD.internal_comments, OLD.phone_number, OLD.fax_number,
               OLD.website_url, OLD.delivery_address_line1, OLD.delivery_address_line2,
               OLD.delivery_postal_code, OLD.delivery_location, OLD.postal_address_line1,
               OLD.postal_address_line2, OLD.postal_postal_code, OLD.last_edited_by,
               OLD.valid_from, clock_timestamp();
        RETURN OLD;
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_purchasing_suppliers_temporal
    BEFORE UPDATE OR DELETE ON purchasing.suppliers
    FOR EACH ROW EXECUTE FUNCTION purchasing.suppliers_temporal_trigger();

-- ============================================================================
-- SALES SCHEMA TEMPORAL TRIGGERS
-- ============================================================================

-- BuyingGroups temporal trigger function
CREATE OR REPLACE FUNCTION sales.buying_groups_temporal_trigger()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'UPDATE' THEN
        INSERT INTO sales.buying_groups_archive 
        SELECT OLD.buying_group_id, OLD.buying_group_name, OLD.last_edited_by,
               OLD.valid_from, clock_timestamp();
        NEW.valid_from := clock_timestamp();
        NEW.valid_to := '9999-12-31 23:59:59.999999'::timestamp;
        RETURN NEW;
    ELSIF TG_OP = 'DELETE' THEN
        INSERT INTO sales.buying_groups_archive 
        SELECT OLD.buying_group_id, OLD.buying_group_name, OLD.last_edited_by,
               OLD.valid_from, clock_timestamp();
        RETURN OLD;
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_sales_buying_groups_temporal
    BEFORE UPDATE OR DELETE ON sales.buying_groups
    FOR EACH ROW EXECUTE FUNCTION sales.buying_groups_temporal_trigger();

-- CustomerCategories temporal trigger function
CREATE OR REPLACE FUNCTION sales.customer_categories_temporal_trigger()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'UPDATE' THEN
        INSERT INTO sales.customer_categories_archive 
        SELECT OLD.customer_category_id, OLD.customer_category_name, OLD.last_edited_by,
               OLD.valid_from, clock_timestamp();
        NEW.valid_from := clock_timestamp();
        NEW.valid_to := '9999-12-31 23:59:59.999999'::timestamp;
        RETURN NEW;
    ELSIF TG_OP = 'DELETE' THEN
        INSERT INTO sales.customer_categories_archive 
        SELECT OLD.customer_category_id, OLD.customer_category_name, OLD.last_edited_by,
               OLD.valid_from, clock_timestamp();
        RETURN OLD;
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_sales_customer_categories_temporal
    BEFORE UPDATE OR DELETE ON sales.customer_categories
    FOR EACH ROW EXECUTE FUNCTION sales.customer_categories_temporal_trigger();

-- Customers temporal trigger function
CREATE OR REPLACE FUNCTION sales.customers_temporal_trigger()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'UPDATE' THEN
        INSERT INTO sales.customers_archive 
        SELECT OLD.customer_id, OLD.customer_name, OLD.bill_to_customer_id,
               OLD.customer_category_id, OLD.buying_group_id, OLD.primary_contact_person_id,
               OLD.alternate_contact_person_id, OLD.delivery_method_id, OLD.delivery_city_id,
               OLD.postal_city_id, OLD.credit_limit, OLD.account_opened_date,
               OLD.standard_discount_percentage, OLD.is_statement_sent, OLD.is_on_credit_hold,
               OLD.payment_days, OLD.phone_number, OLD.fax_number, OLD.delivery_run,
               OLD.run_position, OLD.website_url, OLD.delivery_address_line1,
               OLD.delivery_address_line2, OLD.delivery_postal_code, OLD.delivery_location,
               OLD.postal_address_line1, OLD.postal_address_line2, OLD.postal_postal_code,
               OLD.last_edited_by, OLD.valid_from, clock_timestamp();
        NEW.valid_from := clock_timestamp();
        NEW.valid_to := '9999-12-31 23:59:59.999999'::timestamp;
        RETURN NEW;
    ELSIF TG_OP = 'DELETE' THEN
        INSERT INTO sales.customers_archive 
        SELECT OLD.customer_id, OLD.customer_name, OLD.bill_to_customer_id,
               OLD.customer_category_id, OLD.buying_group_id, OLD.primary_contact_person_id,
               OLD.alternate_contact_person_id, OLD.delivery_method_id, OLD.delivery_city_id,
               OLD.postal_city_id, OLD.credit_limit, OLD.account_opened_date,
               OLD.standard_discount_percentage, OLD.is_statement_sent, OLD.is_on_credit_hold,
               OLD.payment_days, OLD.phone_number, OLD.fax_number, OLD.delivery_run,
               OLD.run_position, OLD.website_url, OLD.delivery_address_line1,
               OLD.delivery_address_line2, OLD.delivery_postal_code, OLD.delivery_location,
               OLD.postal_address_line1, OLD.postal_address_line2, OLD.postal_postal_code,
               OLD.last_edited_by, OLD.valid_from, clock_timestamp();
        RETURN OLD;
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_sales_customers_temporal
    BEFORE UPDATE OR DELETE ON sales.customers
    FOR EACH ROW EXECUTE FUNCTION sales.customers_temporal_trigger();

-- ============================================================================
-- WAREHOUSE SCHEMA TEMPORAL TRIGGERS
-- ============================================================================

-- Colors temporal trigger function
CREATE OR REPLACE FUNCTION warehouse.colors_temporal_trigger()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'UPDATE' THEN
        INSERT INTO warehouse.colors_archive 
        SELECT OLD.color_id, OLD.color_name, OLD.last_edited_by,
               OLD.valid_from, clock_timestamp();
        NEW.valid_from := clock_timestamp();
        NEW.valid_to := '9999-12-31 23:59:59.999999'::timestamp;
        RETURN NEW;
    ELSIF TG_OP = 'DELETE' THEN
        INSERT INTO warehouse.colors_archive 
        SELECT OLD.color_id, OLD.color_name, OLD.last_edited_by,
               OLD.valid_from, clock_timestamp();
        RETURN OLD;
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_warehouse_colors_temporal
    BEFORE UPDATE OR DELETE ON warehouse.colors
    FOR EACH ROW EXECUTE FUNCTION warehouse.colors_temporal_trigger();

-- PackageTypes temporal trigger function
CREATE OR REPLACE FUNCTION warehouse.package_types_temporal_trigger()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'UPDATE' THEN
        INSERT INTO warehouse.package_types_archive 
        SELECT OLD.package_type_id, OLD.package_type_name, OLD.last_edited_by,
               OLD.valid_from, clock_timestamp();
        NEW.valid_from := clock_timestamp();
        NEW.valid_to := '9999-12-31 23:59:59.999999'::timestamp;
        RETURN NEW;
    ELSIF TG_OP = 'DELETE' THEN
        INSERT INTO warehouse.package_types_archive 
        SELECT OLD.package_type_id, OLD.package_type_name, OLD.last_edited_by,
               OLD.valid_from, clock_timestamp();
        RETURN OLD;
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_warehouse_package_types_temporal
    BEFORE UPDATE OR DELETE ON warehouse.package_types
    FOR EACH ROW EXECUTE FUNCTION warehouse.package_types_temporal_trigger();

-- StockGroups temporal trigger function
CREATE OR REPLACE FUNCTION warehouse.stock_groups_temporal_trigger()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'UPDATE' THEN
        INSERT INTO warehouse.stock_groups_archive 
        SELECT OLD.stock_group_id, OLD.stock_group_name, OLD.last_edited_by,
               OLD.valid_from, clock_timestamp();
        NEW.valid_from := clock_timestamp();
        NEW.valid_to := '9999-12-31 23:59:59.999999'::timestamp;
        RETURN NEW;
    ELSIF TG_OP = 'DELETE' THEN
        INSERT INTO warehouse.stock_groups_archive 
        SELECT OLD.stock_group_id, OLD.stock_group_name, OLD.last_edited_by,
               OLD.valid_from, clock_timestamp();
        RETURN OLD;
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_warehouse_stock_groups_temporal
    BEFORE UPDATE OR DELETE ON warehouse.stock_groups
    FOR EACH ROW EXECUTE FUNCTION warehouse.stock_groups_temporal_trigger();

-- StockItems temporal trigger function
CREATE OR REPLACE FUNCTION warehouse.stock_items_temporal_trigger()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'UPDATE' THEN
        INSERT INTO warehouse.stock_items_archive 
        SELECT OLD.stock_item_id, OLD.stock_item_name, OLD.supplier_id, OLD.color_id,
               OLD.unit_package_id, OLD.outer_package_id, OLD.brand, OLD.size,
               OLD.lead_time_days, OLD.quantity_per_outer, OLD.is_chiller_stock,
               OLD.barcode, OLD.tax_rate, OLD.unit_price, OLD.recommended_retail_price,
               OLD.typical_weight_per_unit, OLD.marketing_comments, OLD.internal_comments,
               OLD.photo, OLD.custom_fields, OLD.tags, OLD.search_details,
               OLD.last_edited_by, OLD.valid_from, clock_timestamp();
        NEW.valid_from := clock_timestamp();
        NEW.valid_to := '9999-12-31 23:59:59.999999'::timestamp;
        RETURN NEW;
    ELSIF TG_OP = 'DELETE' THEN
        INSERT INTO warehouse.stock_items_archive 
        SELECT OLD.stock_item_id, OLD.stock_item_name, OLD.supplier_id, OLD.color_id,
               OLD.unit_package_id, OLD.outer_package_id, OLD.brand, OLD.size,
               OLD.lead_time_days, OLD.quantity_per_outer, OLD.is_chiller_stock,
               OLD.barcode, OLD.tax_rate, OLD.unit_price, OLD.recommended_retail_price,
               OLD.typical_weight_per_unit, OLD.marketing_comments, OLD.internal_comments,
               OLD.photo, OLD.custom_fields, OLD.tags, OLD.search_details,
               OLD.last_edited_by, OLD.valid_from, clock_timestamp();
        RETURN OLD;
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_warehouse_stock_items_temporal
    BEFORE UPDATE OR DELETE ON warehouse.stock_items
    FOR EACH ROW EXECUTE FUNCTION warehouse.stock_items_temporal_trigger();

-- ColdRoomTemperatures temporal trigger function
CREATE OR REPLACE FUNCTION warehouse.cold_room_temperatures_temporal_trigger()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'UPDATE' THEN
        INSERT INTO warehouse.cold_room_temperatures_archive 
        SELECT OLD.cold_room_temperature_id, OLD.cold_room_sensor_number,
               OLD.recorded_when, OLD.temperature, OLD.valid_from, clock_timestamp();
        NEW.valid_from := clock_timestamp();
        NEW.valid_to := '9999-12-31 23:59:59.999999'::timestamp;
        RETURN NEW;
    ELSIF TG_OP = 'DELETE' THEN
        INSERT INTO warehouse.cold_room_temperatures_archive 
        SELECT OLD.cold_room_temperature_id, OLD.cold_room_sensor_number,
               OLD.recorded_when, OLD.temperature, OLD.valid_from, clock_timestamp();
        RETURN OLD;
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_warehouse_cold_room_temperatures_temporal
    BEFORE UPDATE OR DELETE ON warehouse.cold_room_temperatures
    FOR EACH ROW EXECUTE FUNCTION warehouse.cold_room_temperatures_temporal_trigger();
