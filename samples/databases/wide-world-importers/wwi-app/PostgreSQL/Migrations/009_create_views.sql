-- Wide World Importers PostgreSQL Migration
-- Script 009: Create Views
-- Migrated from SQL Server to PostgreSQL

-- Website.Customers view
CREATE OR REPLACE VIEW website.customers AS
SELECT 
    s.customer_id,
    s.customer_name,
    sc.customer_category_name,
    pp.full_name AS primary_contact,
    ap.full_name AS alternate_contact,
    s.phone_number,
    s.fax_number,
    bg.buying_group_name,
    s.website_url,
    dm.delivery_method_name AS delivery_method,
    c.city_name,
    s.delivery_location,
    s.delivery_run,
    s.run_position
FROM sales.customers AS s
LEFT OUTER JOIN sales.customer_categories AS sc ON s.customer_category_id = sc.customer_category_id
LEFT OUTER JOIN application.people AS pp ON s.primary_contact_person_id = pp.person_id
LEFT OUTER JOIN application.people AS ap ON s.alternate_contact_person_id = ap.person_id
LEFT OUTER JOIN sales.buying_groups AS bg ON s.buying_group_id = bg.buying_group_id
LEFT OUTER JOIN application.delivery_methods AS dm ON s.delivery_method_id = dm.delivery_method_id
LEFT OUTER JOIN application.cities AS c ON s.delivery_city_id = c.city_id;

COMMENT ON VIEW website.customers IS 'Customer information view for website display';

-- Website.Suppliers view
CREATE OR REPLACE VIEW website.suppliers AS
SELECT 
    s.supplier_id,
    s.supplier_name,
    sc.supplier_category_name,
    pp.full_name AS primary_contact,
    ap.full_name AS alternate_contact,
    s.phone_number,
    s.fax_number,
    s.website_url,
    dm.delivery_method_name AS delivery_method,
    c.city_name,
    s.delivery_location,
    s.delivery_run
FROM purchasing.suppliers AS s
LEFT OUTER JOIN purchasing.supplier_categories AS sc ON s.supplier_category_id = sc.supplier_category_id
LEFT OUTER JOIN application.people AS pp ON s.primary_contact_person_id = pp.person_id
LEFT OUTER JOIN application.people AS ap ON s.alternate_contact_person_id = ap.person_id
LEFT OUTER JOIN application.delivery_methods AS dm ON s.delivery_method_id = dm.delivery_method_id
LEFT OUTER JOIN application.cities AS c ON s.delivery_city_id = c.city_id;

COMMENT ON VIEW website.suppliers IS 'Supplier information view for website display';

-- Website.VehicleTemperatures view
CREATE OR REPLACE VIEW website.vehicle_temperatures AS
SELECT 
    vt.vehicle_temperature_id,
    vt.vehicle_registration,
    vt.chiller_sensor_number,
    vt.recorded_when,
    vt.temperature,
    CASE 
        WHEN vt.is_compressed THEN 'Compressed'
        ELSE 'Uncompressed'
    END AS compression_status
FROM warehouse.vehicle_temperatures AS vt;

COMMENT ON VIEW website.vehicle_temperatures IS 'Vehicle temperature readings view for website display';

-- WebApi views for REST API endpoints
-- These views provide data for the OData/REST API

-- WebApi.Customers view
CREATE OR REPLACE VIEW webapi.customers AS
SELECT 
    c.customer_id,
    c.customer_name,
    c.customer_category_id,
    cc.customer_category_name,
    c.buying_group_id,
    bg.buying_group_name,
    c.primary_contact_person_id,
    pp.full_name AS primary_contact_name,
    c.delivery_method_id,
    dm.delivery_method_name,
    c.delivery_city_id,
    dc.city_name AS delivery_city_name,
    c.postal_city_id,
    pc.city_name AS postal_city_name,
    c.credit_limit,
    c.account_opened_date,
    c.standard_discount_percentage,
    c.is_statement_sent,
    c.is_on_credit_hold,
    c.payment_days,
    c.phone_number,
    c.fax_number,
    c.website_url,
    c.delivery_address_line_1,
    c.delivery_address_line_2,
    c.delivery_postal_code,
    ST_Y(c.delivery_location::geometry) AS delivery_latitude,
    ST_X(c.delivery_location::geometry) AS delivery_longitude,
    c.postal_address_line_1,
    c.postal_address_line_2,
    c.postal_postal_code,
    c.valid_from,
    c.valid_to
FROM sales.customers c
LEFT JOIN sales.customer_categories cc ON c.customer_category_id = cc.customer_category_id
LEFT JOIN sales.buying_groups bg ON c.buying_group_id = bg.buying_group_id
LEFT JOIN application.people pp ON c.primary_contact_person_id = pp.person_id
LEFT JOIN application.delivery_methods dm ON c.delivery_method_id = dm.delivery_method_id
LEFT JOIN application.cities dc ON c.delivery_city_id = dc.city_id
LEFT JOIN application.cities pc ON c.postal_city_id = pc.city_id;

COMMENT ON VIEW webapi.customers IS 'Customer data view for WebAPI/OData endpoints';

-- WebApi.Suppliers view
CREATE OR REPLACE VIEW webapi.suppliers AS
SELECT 
    s.supplier_id,
    s.supplier_name,
    s.supplier_category_id,
    sc.supplier_category_name,
    s.primary_contact_person_id,
    pp.full_name AS primary_contact_name,
    s.delivery_method_id,
    dm.delivery_method_name,
    s.delivery_city_id,
    dc.city_name AS delivery_city_name,
    s.postal_city_id,
    pc.city_name AS postal_city_name,
    s.supplier_reference,
    s.payment_days,
    s.phone_number,
    s.fax_number,
    s.website_url,
    s.delivery_address_line_1,
    s.delivery_address_line_2,
    s.delivery_postal_code,
    ST_Y(s.delivery_location::geometry) AS delivery_latitude,
    ST_X(s.delivery_location::geometry) AS delivery_longitude,
    s.postal_address_line_1,
    s.postal_address_line_2,
    s.postal_postal_code,
    s.valid_from,
    s.valid_to
FROM purchasing.suppliers s
LEFT JOIN purchasing.supplier_categories sc ON s.supplier_category_id = sc.supplier_category_id
LEFT JOIN application.people pp ON s.primary_contact_person_id = pp.person_id
LEFT JOIN application.delivery_methods dm ON s.delivery_method_id = dm.delivery_method_id
LEFT JOIN application.cities dc ON s.delivery_city_id = dc.city_id
LEFT JOIN application.cities pc ON s.postal_city_id = pc.city_id;

COMMENT ON VIEW webapi.suppliers IS 'Supplier data view for WebAPI/OData endpoints';

-- WebApi.StockItems view
CREATE OR REPLACE VIEW webapi.stock_items AS
SELECT 
    si.stock_item_id,
    si.stock_item_name,
    si.supplier_id,
    s.supplier_name,
    si.color_id,
    c.color_name,
    si.unit_package_id,
    up.package_type_name AS unit_package_name,
    si.outer_package_id,
    op.package_type_name AS outer_package_name,
    si.brand,
    si.size,
    si.lead_time_days,
    si.quantity_per_outer,
    si.is_chiller_stock,
    si.barcode,
    si.tax_rate,
    si.unit_price,
    si.recommended_retail_price,
    si.typical_weight_per_unit,
    si.marketing_comments,
    si.custom_fields,
    sih.quantity_on_hand,
    sih.bin_location,
    sih.last_stocktake_quantity,
    sih.last_cost_price,
    sih.reorder_level,
    sih.target_stock_level,
    si.valid_from,
    si.valid_to
FROM warehouse.stock_items si
LEFT JOIN purchasing.suppliers s ON si.supplier_id = s.supplier_id
LEFT JOIN warehouse.colors c ON si.color_id = c.color_id
LEFT JOIN warehouse.package_types up ON si.unit_package_id = up.package_type_id
LEFT JOIN warehouse.package_types op ON si.outer_package_id = op.package_type_id
LEFT JOIN warehouse.stock_item_holdings sih ON si.stock_item_id = sih.stock_item_id;

COMMENT ON VIEW webapi.stock_items IS 'Stock item data view for WebAPI/OData endpoints';

-- WebApi.Orders view
CREATE OR REPLACE VIEW webapi.orders AS
SELECT 
    o.order_id,
    o.customer_id,
    c.customer_name,
    o.salesperson_person_id,
    sp.full_name AS salesperson_name,
    o.picked_by_person_id,
    pb.full_name AS picked_by_name,
    o.contact_person_id,
    cp.full_name AS contact_person_name,
    o.backorder_order_id,
    o.order_date,
    o.expected_delivery_date,
    o.customer_purchase_order_number,
    o.is_undersupply_backordered,
    o.comments,
    o.delivery_instructions,
    o.picking_completed_when,
    o.last_edited_when
FROM sales.orders o
LEFT JOIN sales.customers c ON o.customer_id = c.customer_id
LEFT JOIN application.people sp ON o.salesperson_person_id = sp.person_id
LEFT JOIN application.people pb ON o.picked_by_person_id = pb.person_id
LEFT JOIN application.people cp ON o.contact_person_id = cp.person_id;

COMMENT ON VIEW webapi.orders IS 'Order data view for WebAPI/OData endpoints';

-- WebApi.Invoices view
CREATE OR REPLACE VIEW webapi.invoices AS
SELECT 
    i.invoice_id,
    i.customer_id,
    c.customer_name,
    i.bill_to_customer_id,
    btc.customer_name AS bill_to_customer_name,
    i.order_id,
    i.delivery_method_id,
    dm.delivery_method_name,
    i.contact_person_id,
    cp.full_name AS contact_person_name,
    i.salesperson_person_id,
    sp.full_name AS salesperson_name,
    i.invoice_date,
    i.customer_purchase_order_number,
    i.is_credit_note,
    i.credit_note_reason,
    i.total_dry_items,
    i.total_chiller_items,
    i.confirmed_delivery_time,
    i.confirmed_received_by,
    i.last_edited_when
FROM sales.invoices i
LEFT JOIN sales.customers c ON i.customer_id = c.customer_id
LEFT JOIN sales.customers btc ON i.bill_to_customer_id = btc.customer_id
LEFT JOIN application.delivery_methods dm ON i.delivery_method_id = dm.delivery_method_id
LEFT JOIN application.people cp ON i.contact_person_id = cp.person_id
LEFT JOIN application.people sp ON i.salesperson_person_id = sp.person_id;

COMMENT ON VIEW webapi.invoices IS 'Invoice data view for WebAPI/OData endpoints';

-- WebApi.PurchaseOrders view
CREATE OR REPLACE VIEW webapi.purchase_orders AS
SELECT 
    po.purchase_order_id,
    po.supplier_id,
    s.supplier_name,
    po.order_date,
    po.delivery_method_id,
    dm.delivery_method_name,
    po.contact_person_id,
    cp.full_name AS contact_person_name,
    po.expected_delivery_date,
    po.supplier_reference,
    po.is_order_finalized,
    po.comments,
    po.last_edited_when
FROM purchasing.purchase_orders po
LEFT JOIN purchasing.suppliers s ON po.supplier_id = s.supplier_id
LEFT JOIN application.delivery_methods dm ON po.delivery_method_id = dm.delivery_method_id
LEFT JOIN application.people cp ON po.contact_person_id = cp.person_id;

COMMENT ON VIEW webapi.purchase_orders IS 'Purchase order data view for WebAPI/OData endpoints';

-- WebApi.People view
CREATE OR REPLACE VIEW webapi.people AS
SELECT 
    p.person_id,
    p.full_name,
    p.preferred_name,
    p.is_permitted_to_logon,
    p.logon_name,
    p.is_external_logon_provider,
    p.is_system_user,
    p.is_employee,
    p.is_salesperson,
    p.phone_number,
    p.fax_number,
    p.email_address,
    p.valid_from,
    p.valid_to
FROM application.people p;

COMMENT ON VIEW webapi.people IS 'People data view for WebAPI/OData endpoints';

-- WebApi.Cities view
CREATE OR REPLACE VIEW webapi.cities AS
SELECT 
    c.city_id,
    c.city_name,
    c.state_province_id,
    sp.state_province_name,
    sp.state_province_code,
    sp.sales_territory,
    co.country_id,
    co.country_name,
    ST_Y(c.location::geometry) AS latitude,
    ST_X(c.location::geometry) AS longitude,
    c.latest_recorded_population,
    c.valid_from,
    c.valid_to
FROM application.cities c
LEFT JOIN application.state_provinces sp ON c.state_province_id = sp.state_province_id
LEFT JOIN application.countries co ON sp.country_id = co.country_id;

COMMENT ON VIEW webapi.cities IS 'City data view for WebAPI/OData endpoints';

-- WebApi.Countries view
CREATE OR REPLACE VIEW webapi.countries AS
SELECT 
    c.country_id,
    c.country_name,
    c.formal_name,
    c.iso_alpha3_code,
    c.iso_numeric_code,
    c.country_type,
    c.latest_recorded_population,
    c.continent,
    c.region,
    c.subregion,
    c.valid_from,
    c.valid_to
FROM application.countries c;

COMMENT ON VIEW webapi.countries IS 'Country data view for WebAPI/OData endpoints';

-- WebApi.StateProvinces view
CREATE OR REPLACE VIEW webapi.state_provinces AS
SELECT 
    sp.state_province_id,
    sp.state_province_code,
    sp.state_province_name,
    sp.country_id,
    c.country_name,
    sp.sales_territory,
    sp.latest_recorded_population,
    sp.valid_from,
    sp.valid_to
FROM application.state_provinces sp
LEFT JOIN application.countries c ON sp.country_id = c.country_id;

COMMENT ON VIEW webapi.state_provinces IS 'State/Province data view for WebAPI/OData endpoints';
