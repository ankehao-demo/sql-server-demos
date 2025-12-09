-- Wide World Importers PostgreSQL Migration
-- Phase 2: OLTP Schema Migration
-- Script 002: Create Sequences
-- Migrated from SQL Server to PostgreSQL

-- Application sequences
CREATE SEQUENCE IF NOT EXISTS sequences.person_id
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

CREATE SEQUENCE IF NOT EXISTS sequences.city_id
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

CREATE SEQUENCE IF NOT EXISTS sequences.country_id
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

CREATE SEQUENCE IF NOT EXISTS sequences.state_province_id
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

CREATE SEQUENCE IF NOT EXISTS sequences.delivery_method_id
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

CREATE SEQUENCE IF NOT EXISTS sequences.payment_method_id
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

CREATE SEQUENCE IF NOT EXISTS sequences.transaction_type_id
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

CREATE SEQUENCE IF NOT EXISTS sequences.system_parameter_id
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

-- Sales sequences
CREATE SEQUENCE IF NOT EXISTS sequences.customer_id
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

CREATE SEQUENCE IF NOT EXISTS sequences.customer_category_id
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

CREATE SEQUENCE IF NOT EXISTS sequences.buying_group_id
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

CREATE SEQUENCE IF NOT EXISTS sequences.order_id
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

CREATE SEQUENCE IF NOT EXISTS sequences.order_line_id
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

CREATE SEQUENCE IF NOT EXISTS sequences.invoice_id
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

CREATE SEQUENCE IF NOT EXISTS sequences.invoice_line_id
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

CREATE SEQUENCE IF NOT EXISTS sequences.special_deal_id
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

CREATE SEQUENCE IF NOT EXISTS sequences.transaction_id
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

-- Purchasing sequences
CREATE SEQUENCE IF NOT EXISTS sequences.supplier_id
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

CREATE SEQUENCE IF NOT EXISTS sequences.supplier_category_id
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

CREATE SEQUENCE IF NOT EXISTS sequences.purchase_order_id
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

CREATE SEQUENCE IF NOT EXISTS sequences.purchase_order_line_id
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

-- Warehouse sequences
CREATE SEQUENCE IF NOT EXISTS sequences.color_id
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

CREATE SEQUENCE IF NOT EXISTS sequences.package_type_id
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

CREATE SEQUENCE IF NOT EXISTS sequences.stock_group_id
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

CREATE SEQUENCE IF NOT EXISTS sequences.stock_item_id
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

CREATE SEQUENCE IF NOT EXISTS sequences.stock_item_stock_group_id
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

-- Add sequence comments
COMMENT ON SEQUENCE sequences.person_id IS 'Sequence for Application.People.PersonID';
COMMENT ON SEQUENCE sequences.city_id IS 'Sequence for Application.Cities.CityID';
COMMENT ON SEQUENCE sequences.country_id IS 'Sequence for Application.Countries.CountryID';
COMMENT ON SEQUENCE sequences.state_province_id IS 'Sequence for Application.StateProvinces.StateProvinceID';
COMMENT ON SEQUENCE sequences.delivery_method_id IS 'Sequence for Application.DeliveryMethods.DeliveryMethodID';
COMMENT ON SEQUENCE sequences.payment_method_id IS 'Sequence for Application.PaymentMethods.PaymentMethodID';
COMMENT ON SEQUENCE sequences.transaction_type_id IS 'Sequence for Application.TransactionTypes.TransactionTypeID';
COMMENT ON SEQUENCE sequences.system_parameter_id IS 'Sequence for Application.SystemParameters.SystemParameterID';
COMMENT ON SEQUENCE sequences.customer_id IS 'Sequence for Sales.Customers.CustomerID';
COMMENT ON SEQUENCE sequences.customer_category_id IS 'Sequence for Sales.CustomerCategories.CustomerCategoryID';
COMMENT ON SEQUENCE sequences.buying_group_id IS 'Sequence for Sales.BuyingGroups.BuyingGroupID';
COMMENT ON SEQUENCE sequences.order_id IS 'Sequence for Sales.Orders.OrderID';
COMMENT ON SEQUENCE sequences.order_line_id IS 'Sequence for Sales.OrderLines.OrderLineID';
COMMENT ON SEQUENCE sequences.invoice_id IS 'Sequence for Sales.Invoices.InvoiceID';
COMMENT ON SEQUENCE sequences.invoice_line_id IS 'Sequence for Sales.InvoiceLines.InvoiceLineID';
COMMENT ON SEQUENCE sequences.special_deal_id IS 'Sequence for Sales.SpecialDeals.SpecialDealID';
COMMENT ON SEQUENCE sequences.transaction_id IS 'Sequence for transaction tables';
COMMENT ON SEQUENCE sequences.supplier_id IS 'Sequence for Purchasing.Suppliers.SupplierID';
COMMENT ON SEQUENCE sequences.supplier_category_id IS 'Sequence for Purchasing.SupplierCategories.SupplierCategoryID';
COMMENT ON SEQUENCE sequences.purchase_order_id IS 'Sequence for Purchasing.PurchaseOrders.PurchaseOrderID';
COMMENT ON SEQUENCE sequences.purchase_order_line_id IS 'Sequence for Purchasing.PurchaseOrderLines.PurchaseOrderLineID';
COMMENT ON SEQUENCE sequences.color_id IS 'Sequence for Warehouse.Colors.ColorID';
COMMENT ON SEQUENCE sequences.package_type_id IS 'Sequence for Warehouse.PackageTypes.PackageTypeID';
COMMENT ON SEQUENCE sequences.stock_group_id IS 'Sequence for Warehouse.StockGroups.StockGroupID';
COMMENT ON SEQUENCE sequences.stock_item_id IS 'Sequence for Warehouse.StockItems.StockItemID';
COMMENT ON SEQUENCE sequences.stock_item_stock_group_id IS 'Sequence for Warehouse.StockItemStockGroups.StockItemStockGroupID';
