-- Wide World Importers PostgreSQL Migration
-- Phase 2: OLTP Schema Migration
-- Script 007: Foreign Keys and Constraints
-- Migrated from SQL Server to PostgreSQL

-- =============================================
-- Application Schema Foreign Keys
-- =============================================

-- Application.People
ALTER TABLE application.people
    ADD CONSTRAINT fk_application_people_application_people
    FOREIGN KEY (last_edited_by) REFERENCES application.people(person_id);

-- Application.Countries
ALTER TABLE application.countries
    ADD CONSTRAINT fk_application_countries_application_people
    FOREIGN KEY (last_edited_by) REFERENCES application.people(person_id);

-- Application.StateProvinces
ALTER TABLE application.state_provinces
    ADD CONSTRAINT fk_application_state_provinces_country_id_application_countries
    FOREIGN KEY (country_id) REFERENCES application.countries(country_id);

ALTER TABLE application.state_provinces
    ADD CONSTRAINT fk_application_state_provinces_application_people
    FOREIGN KEY (last_edited_by) REFERENCES application.people(person_id);

-- Application.Cities
ALTER TABLE application.cities
    ADD CONSTRAINT fk_application_cities_state_province_id_application_state_provinces
    FOREIGN KEY (state_province_id) REFERENCES application.state_provinces(state_province_id);

ALTER TABLE application.cities
    ADD CONSTRAINT fk_application_cities_application_people
    FOREIGN KEY (last_edited_by) REFERENCES application.people(person_id);

-- Application.DeliveryMethods
ALTER TABLE application.delivery_methods
    ADD CONSTRAINT fk_application_delivery_methods_application_people
    FOREIGN KEY (last_edited_by) REFERENCES application.people(person_id);

-- Application.PaymentMethods
ALTER TABLE application.payment_methods
    ADD CONSTRAINT fk_application_payment_methods_application_people
    FOREIGN KEY (last_edited_by) REFERENCES application.people(person_id);

-- Application.TransactionTypes
ALTER TABLE application.transaction_types
    ADD CONSTRAINT fk_application_transaction_types_application_people
    FOREIGN KEY (last_edited_by) REFERENCES application.people(person_id);

-- Application.SystemParameters
ALTER TABLE application.system_parameters
    ADD CONSTRAINT fk_application_system_parameters_delivery_city_id_application_cities
    FOREIGN KEY (delivery_city_id) REFERENCES application.cities(city_id);

ALTER TABLE application.system_parameters
    ADD CONSTRAINT fk_application_system_parameters_postal_city_id_application_cities
    FOREIGN KEY (postal_city_id) REFERENCES application.cities(city_id);

ALTER TABLE application.system_parameters
    ADD CONSTRAINT fk_application_system_parameters_application_people
    FOREIGN KEY (last_edited_by) REFERENCES application.people(person_id);

-- =============================================
-- Sales Schema Foreign Keys
-- =============================================

-- Sales.BuyingGroups
ALTER TABLE sales.buying_groups
    ADD CONSTRAINT fk_sales_buying_groups_application_people
    FOREIGN KEY (last_edited_by) REFERENCES application.people(person_id);

-- Sales.CustomerCategories
ALTER TABLE sales.customer_categories
    ADD CONSTRAINT fk_sales_customer_categories_application_people
    FOREIGN KEY (last_edited_by) REFERENCES application.people(person_id);

-- Sales.Customers
ALTER TABLE sales.customers
    ADD CONSTRAINT fk_sales_customers_bill_to_customer_id_sales_customers
    FOREIGN KEY (bill_to_customer_id) REFERENCES sales.customers(customer_id);

ALTER TABLE sales.customers
    ADD CONSTRAINT fk_sales_customers_customer_category_id_sales_customer_categories
    FOREIGN KEY (customer_category_id) REFERENCES sales.customer_categories(customer_category_id);

ALTER TABLE sales.customers
    ADD CONSTRAINT fk_sales_customers_buying_group_id_sales_buying_groups
    FOREIGN KEY (buying_group_id) REFERENCES sales.buying_groups(buying_group_id);

ALTER TABLE sales.customers
    ADD CONSTRAINT fk_sales_customers_primary_contact_person_id_application_people
    FOREIGN KEY (primary_contact_person_id) REFERENCES application.people(person_id);

ALTER TABLE sales.customers
    ADD CONSTRAINT fk_sales_customers_alternate_contact_person_id_application_people
    FOREIGN KEY (alternate_contact_person_id) REFERENCES application.people(person_id);

ALTER TABLE sales.customers
    ADD CONSTRAINT fk_sales_customers_delivery_method_id_application_delivery_methods
    FOREIGN KEY (delivery_method_id) REFERENCES application.delivery_methods(delivery_method_id);

ALTER TABLE sales.customers
    ADD CONSTRAINT fk_sales_customers_delivery_city_id_application_cities
    FOREIGN KEY (delivery_city_id) REFERENCES application.cities(city_id);

ALTER TABLE sales.customers
    ADD CONSTRAINT fk_sales_customers_postal_city_id_application_cities
    FOREIGN KEY (postal_city_id) REFERENCES application.cities(city_id);

ALTER TABLE sales.customers
    ADD CONSTRAINT fk_sales_customers_application_people
    FOREIGN KEY (last_edited_by) REFERENCES application.people(person_id);

-- Sales.Orders
ALTER TABLE sales.orders
    ADD CONSTRAINT fk_sales_orders_customer_id_sales_customers
    FOREIGN KEY (customer_id) REFERENCES sales.customers(customer_id);

ALTER TABLE sales.orders
    ADD CONSTRAINT fk_sales_orders_salesperson_person_id_application_people
    FOREIGN KEY (salesperson_person_id) REFERENCES application.people(person_id);

ALTER TABLE sales.orders
    ADD CONSTRAINT fk_sales_orders_picked_by_person_id_application_people
    FOREIGN KEY (picked_by_person_id) REFERENCES application.people(person_id);

ALTER TABLE sales.orders
    ADD CONSTRAINT fk_sales_orders_contact_person_id_application_people
    FOREIGN KEY (contact_person_id) REFERENCES application.people(person_id);

ALTER TABLE sales.orders
    ADD CONSTRAINT fk_sales_orders_backorder_order_id_sales_orders
    FOREIGN KEY (backorder_order_id) REFERENCES sales.orders(order_id);

ALTER TABLE sales.orders
    ADD CONSTRAINT fk_sales_orders_application_people
    FOREIGN KEY (last_edited_by) REFERENCES application.people(person_id);

-- Sales.OrderLines
ALTER TABLE sales.order_lines
    ADD CONSTRAINT fk_sales_order_lines_order_id_sales_orders
    FOREIGN KEY (order_id) REFERENCES sales.orders(order_id);

ALTER TABLE sales.order_lines
    ADD CONSTRAINT fk_sales_order_lines_stock_item_id_warehouse_stock_items
    FOREIGN KEY (stock_item_id) REFERENCES warehouse.stock_items(stock_item_id);

ALTER TABLE sales.order_lines
    ADD CONSTRAINT fk_sales_order_lines_package_type_id_warehouse_package_types
    FOREIGN KEY (package_type_id) REFERENCES warehouse.package_types(package_type_id);

ALTER TABLE sales.order_lines
    ADD CONSTRAINT fk_sales_order_lines_application_people
    FOREIGN KEY (last_edited_by) REFERENCES application.people(person_id);

-- Sales.Invoices
ALTER TABLE sales.invoices
    ADD CONSTRAINT fk_sales_invoices_customer_id_sales_customers
    FOREIGN KEY (customer_id) REFERENCES sales.customers(customer_id);

ALTER TABLE sales.invoices
    ADD CONSTRAINT fk_sales_invoices_bill_to_customer_id_sales_customers
    FOREIGN KEY (bill_to_customer_id) REFERENCES sales.customers(customer_id);

ALTER TABLE sales.invoices
    ADD CONSTRAINT fk_sales_invoices_order_id_sales_orders
    FOREIGN KEY (order_id) REFERENCES sales.orders(order_id);

ALTER TABLE sales.invoices
    ADD CONSTRAINT fk_sales_invoices_delivery_method_id_application_delivery_methods
    FOREIGN KEY (delivery_method_id) REFERENCES application.delivery_methods(delivery_method_id);

ALTER TABLE sales.invoices
    ADD CONSTRAINT fk_sales_invoices_contact_person_id_application_people
    FOREIGN KEY (contact_person_id) REFERENCES application.people(person_id);

ALTER TABLE sales.invoices
    ADD CONSTRAINT fk_sales_invoices_accounts_person_id_application_people
    FOREIGN KEY (accounts_person_id) REFERENCES application.people(person_id);

ALTER TABLE sales.invoices
    ADD CONSTRAINT fk_sales_invoices_salesperson_person_id_application_people
    FOREIGN KEY (salesperson_person_id) REFERENCES application.people(person_id);

ALTER TABLE sales.invoices
    ADD CONSTRAINT fk_sales_invoices_packed_by_person_id_application_people
    FOREIGN KEY (packed_by_person_id) REFERENCES application.people(person_id);

ALTER TABLE sales.invoices
    ADD CONSTRAINT fk_sales_invoices_application_people
    FOREIGN KEY (last_edited_by) REFERENCES application.people(person_id);

-- Sales.InvoiceLines
ALTER TABLE sales.invoice_lines
    ADD CONSTRAINT fk_sales_invoice_lines_invoice_id_sales_invoices
    FOREIGN KEY (invoice_id) REFERENCES sales.invoices(invoice_id);

ALTER TABLE sales.invoice_lines
    ADD CONSTRAINT fk_sales_invoice_lines_stock_item_id_warehouse_stock_items
    FOREIGN KEY (stock_item_id) REFERENCES warehouse.stock_items(stock_item_id);

ALTER TABLE sales.invoice_lines
    ADD CONSTRAINT fk_sales_invoice_lines_package_type_id_warehouse_package_types
    FOREIGN KEY (package_type_id) REFERENCES warehouse.package_types(package_type_id);

ALTER TABLE sales.invoice_lines
    ADD CONSTRAINT fk_sales_invoice_lines_application_people
    FOREIGN KEY (last_edited_by) REFERENCES application.people(person_id);

-- Sales.CustomerTransactions
ALTER TABLE sales.customer_transactions
    ADD CONSTRAINT fk_sales_customer_transactions_customer_id_sales_customers
    FOREIGN KEY (customer_id) REFERENCES sales.customers(customer_id);

ALTER TABLE sales.customer_transactions
    ADD CONSTRAINT fk_sales_customer_transactions_transaction_type_id_application_transaction_types
    FOREIGN KEY (transaction_type_id) REFERENCES application.transaction_types(transaction_type_id);

ALTER TABLE sales.customer_transactions
    ADD CONSTRAINT fk_sales_customer_transactions_invoice_id_sales_invoices
    FOREIGN KEY (invoice_id) REFERENCES sales.invoices(invoice_id);

ALTER TABLE sales.customer_transactions
    ADD CONSTRAINT fk_sales_customer_transactions_payment_method_id_application_payment_methods
    FOREIGN KEY (payment_method_id) REFERENCES application.payment_methods(payment_method_id);

ALTER TABLE sales.customer_transactions
    ADD CONSTRAINT fk_sales_customer_transactions_application_people
    FOREIGN KEY (last_edited_by) REFERENCES application.people(person_id);

-- Sales.SpecialDeals
ALTER TABLE sales.special_deals
    ADD CONSTRAINT fk_sales_special_deals_stock_item_id_warehouse_stock_items
    FOREIGN KEY (stock_item_id) REFERENCES warehouse.stock_items(stock_item_id);

ALTER TABLE sales.special_deals
    ADD CONSTRAINT fk_sales_special_deals_customer_id_sales_customers
    FOREIGN KEY (customer_id) REFERENCES sales.customers(customer_id);

ALTER TABLE sales.special_deals
    ADD CONSTRAINT fk_sales_special_deals_buying_group_id_sales_buying_groups
    FOREIGN KEY (buying_group_id) REFERENCES sales.buying_groups(buying_group_id);

ALTER TABLE sales.special_deals
    ADD CONSTRAINT fk_sales_special_deals_customer_category_id_sales_customer_categories
    FOREIGN KEY (customer_category_id) REFERENCES sales.customer_categories(customer_category_id);

ALTER TABLE sales.special_deals
    ADD CONSTRAINT fk_sales_special_deals_stock_group_id_warehouse_stock_groups
    FOREIGN KEY (stock_group_id) REFERENCES warehouse.stock_groups(stock_group_id);

ALTER TABLE sales.special_deals
    ADD CONSTRAINT fk_sales_special_deals_application_people
    FOREIGN KEY (last_edited_by) REFERENCES application.people(person_id);

-- =============================================
-- Purchasing Schema Foreign Keys
-- =============================================

-- Purchasing.SupplierCategories
ALTER TABLE purchasing.supplier_categories
    ADD CONSTRAINT fk_purchasing_supplier_categories_application_people
    FOREIGN KEY (last_edited_by) REFERENCES application.people(person_id);

-- Purchasing.Suppliers
ALTER TABLE purchasing.suppliers
    ADD CONSTRAINT fk_purchasing_suppliers_supplier_category_id_purchasing_supplier_categories
    FOREIGN KEY (supplier_category_id) REFERENCES purchasing.supplier_categories(supplier_category_id);

ALTER TABLE purchasing.suppliers
    ADD CONSTRAINT fk_purchasing_suppliers_primary_contact_person_id_application_people
    FOREIGN KEY (primary_contact_person_id) REFERENCES application.people(person_id);

ALTER TABLE purchasing.suppliers
    ADD CONSTRAINT fk_purchasing_suppliers_alternate_contact_person_id_application_people
    FOREIGN KEY (alternate_contact_person_id) REFERENCES application.people(person_id);

ALTER TABLE purchasing.suppliers
    ADD CONSTRAINT fk_purchasing_suppliers_delivery_method_id_application_delivery_methods
    FOREIGN KEY (delivery_method_id) REFERENCES application.delivery_methods(delivery_method_id);

ALTER TABLE purchasing.suppliers
    ADD CONSTRAINT fk_purchasing_suppliers_delivery_city_id_application_cities
    FOREIGN KEY (delivery_city_id) REFERENCES application.cities(city_id);

ALTER TABLE purchasing.suppliers
    ADD CONSTRAINT fk_purchasing_suppliers_postal_city_id_application_cities
    FOREIGN KEY (postal_city_id) REFERENCES application.cities(city_id);

ALTER TABLE purchasing.suppliers
    ADD CONSTRAINT fk_purchasing_suppliers_application_people
    FOREIGN KEY (last_edited_by) REFERENCES application.people(person_id);

-- Purchasing.PurchaseOrders
ALTER TABLE purchasing.purchase_orders
    ADD CONSTRAINT fk_purchasing_purchase_orders_supplier_id_purchasing_suppliers
    FOREIGN KEY (supplier_id) REFERENCES purchasing.suppliers(supplier_id);

ALTER TABLE purchasing.purchase_orders
    ADD CONSTRAINT fk_purchasing_purchase_orders_delivery_method_id_application_delivery_methods
    FOREIGN KEY (delivery_method_id) REFERENCES application.delivery_methods(delivery_method_id);

ALTER TABLE purchasing.purchase_orders
    ADD CONSTRAINT fk_purchasing_purchase_orders_contact_person_id_application_people
    FOREIGN KEY (contact_person_id) REFERENCES application.people(person_id);

ALTER TABLE purchasing.purchase_orders
    ADD CONSTRAINT fk_purchasing_purchase_orders_application_people
    FOREIGN KEY (last_edited_by) REFERENCES application.people(person_id);

-- Purchasing.PurchaseOrderLines
ALTER TABLE purchasing.purchase_order_lines
    ADD CONSTRAINT fk_purchasing_purchase_order_lines_purchase_order_id_purchasing_purchase_orders
    FOREIGN KEY (purchase_order_id) REFERENCES purchasing.purchase_orders(purchase_order_id);

ALTER TABLE purchasing.purchase_order_lines
    ADD CONSTRAINT fk_purchasing_purchase_order_lines_stock_item_id_warehouse_stock_items
    FOREIGN KEY (stock_item_id) REFERENCES warehouse.stock_items(stock_item_id);

ALTER TABLE purchasing.purchase_order_lines
    ADD CONSTRAINT fk_purchasing_purchase_order_lines_package_type_id_warehouse_package_types
    FOREIGN KEY (package_type_id) REFERENCES warehouse.package_types(package_type_id);

ALTER TABLE purchasing.purchase_order_lines
    ADD CONSTRAINT fk_purchasing_purchase_order_lines_application_people
    FOREIGN KEY (last_edited_by) REFERENCES application.people(person_id);

-- Purchasing.SupplierTransactions
ALTER TABLE purchasing.supplier_transactions
    ADD CONSTRAINT fk_purchasing_supplier_transactions_supplier_id_purchasing_suppliers
    FOREIGN KEY (supplier_id) REFERENCES purchasing.suppliers(supplier_id);

ALTER TABLE purchasing.supplier_transactions
    ADD CONSTRAINT fk_purchasing_supplier_transactions_transaction_type_id_application_transaction_types
    FOREIGN KEY (transaction_type_id) REFERENCES application.transaction_types(transaction_type_id);

ALTER TABLE purchasing.supplier_transactions
    ADD CONSTRAINT fk_purchasing_supplier_transactions_purchase_order_id_purchasing_purchase_orders
    FOREIGN KEY (purchase_order_id) REFERENCES purchasing.purchase_orders(purchase_order_id);

ALTER TABLE purchasing.supplier_transactions
    ADD CONSTRAINT fk_purchasing_supplier_transactions_payment_method_id_application_payment_methods
    FOREIGN KEY (payment_method_id) REFERENCES application.payment_methods(payment_method_id);

ALTER TABLE purchasing.supplier_transactions
    ADD CONSTRAINT fk_purchasing_supplier_transactions_application_people
    FOREIGN KEY (last_edited_by) REFERENCES application.people(person_id);

-- =============================================
-- Warehouse Schema Foreign Keys
-- =============================================

-- Warehouse.Colors
ALTER TABLE warehouse.colors
    ADD CONSTRAINT fk_warehouse_colors_application_people
    FOREIGN KEY (last_edited_by) REFERENCES application.people(person_id);

-- Warehouse.PackageTypes
ALTER TABLE warehouse.package_types
    ADD CONSTRAINT fk_warehouse_package_types_application_people
    FOREIGN KEY (last_edited_by) REFERENCES application.people(person_id);

-- Warehouse.StockGroups
ALTER TABLE warehouse.stock_groups
    ADD CONSTRAINT fk_warehouse_stock_groups_application_people
    FOREIGN KEY (last_edited_by) REFERENCES application.people(person_id);

-- Warehouse.StockItems
ALTER TABLE warehouse.stock_items
    ADD CONSTRAINT fk_warehouse_stock_items_supplier_id_purchasing_suppliers
    FOREIGN KEY (supplier_id) REFERENCES purchasing.suppliers(supplier_id);

ALTER TABLE warehouse.stock_items
    ADD CONSTRAINT fk_warehouse_stock_items_color_id_warehouse_colors
    FOREIGN KEY (color_id) REFERENCES warehouse.colors(color_id);

ALTER TABLE warehouse.stock_items
    ADD CONSTRAINT fk_warehouse_stock_items_unit_package_id_warehouse_package_types
    FOREIGN KEY (unit_package_id) REFERENCES warehouse.package_types(package_type_id);

ALTER TABLE warehouse.stock_items
    ADD CONSTRAINT fk_warehouse_stock_items_outer_package_id_warehouse_package_types
    FOREIGN KEY (outer_package_id) REFERENCES warehouse.package_types(package_type_id);

ALTER TABLE warehouse.stock_items
    ADD CONSTRAINT fk_warehouse_stock_items_application_people
    FOREIGN KEY (last_edited_by) REFERENCES application.people(person_id);

-- Warehouse.StockItemStockGroups
ALTER TABLE warehouse.stock_item_stock_groups
    ADD CONSTRAINT fk_warehouse_stock_item_stock_groups_stock_item_id_warehouse_stock_items
    FOREIGN KEY (stock_item_id) REFERENCES warehouse.stock_items(stock_item_id);

ALTER TABLE warehouse.stock_item_stock_groups
    ADD CONSTRAINT fk_warehouse_stock_item_stock_groups_stock_group_id_warehouse_stock_groups
    FOREIGN KEY (stock_group_id) REFERENCES warehouse.stock_groups(stock_group_id);

ALTER TABLE warehouse.stock_item_stock_groups
    ADD CONSTRAINT fk_warehouse_stock_item_stock_groups_application_people
    FOREIGN KEY (last_edited_by) REFERENCES application.people(person_id);

-- Warehouse.StockItemHoldings
ALTER TABLE warehouse.stock_item_holdings
    ADD CONSTRAINT fk_warehouse_stock_item_holdings_stock_item_id_warehouse_stock_items
    FOREIGN KEY (stock_item_id) REFERENCES warehouse.stock_items(stock_item_id);

ALTER TABLE warehouse.stock_item_holdings
    ADD CONSTRAINT fk_warehouse_stock_item_holdings_application_people
    FOREIGN KEY (last_edited_by) REFERENCES application.people(person_id);

-- Warehouse.StockItemTransactions
ALTER TABLE warehouse.stock_item_transactions
    ADD CONSTRAINT fk_warehouse_stock_item_transactions_stock_item_id_warehouse_stock_items
    FOREIGN KEY (stock_item_id) REFERENCES warehouse.stock_items(stock_item_id);

ALTER TABLE warehouse.stock_item_transactions
    ADD CONSTRAINT fk_warehouse_stock_item_transactions_transaction_type_id_application_transaction_types
    FOREIGN KEY (transaction_type_id) REFERENCES application.transaction_types(transaction_type_id);

ALTER TABLE warehouse.stock_item_transactions
    ADD CONSTRAINT fk_warehouse_stock_item_transactions_customer_id_sales_customers
    FOREIGN KEY (customer_id) REFERENCES sales.customers(customer_id);

ALTER TABLE warehouse.stock_item_transactions
    ADD CONSTRAINT fk_warehouse_stock_item_transactions_invoice_id_sales_invoices
    FOREIGN KEY (invoice_id) REFERENCES sales.invoices(invoice_id);

ALTER TABLE warehouse.stock_item_transactions
    ADD CONSTRAINT fk_warehouse_stock_item_transactions_supplier_id_purchasing_suppliers
    FOREIGN KEY (supplier_id) REFERENCES purchasing.suppliers(supplier_id);

ALTER TABLE warehouse.stock_item_transactions
    ADD CONSTRAINT fk_warehouse_stock_item_transactions_purchase_order_id_purchasing_purchase_orders
    FOREIGN KEY (purchase_order_id) REFERENCES purchasing.purchase_orders(purchase_order_id);

ALTER TABLE warehouse.stock_item_transactions
    ADD CONSTRAINT fk_warehouse_stock_item_transactions_application_people
    FOREIGN KEY (last_edited_by) REFERENCES application.people(person_id);
