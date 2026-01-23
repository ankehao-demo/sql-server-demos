-- Wide World Importers PostgreSQL Migration
-- Script 002: Create Sequences
-- Migrated from SQL Server to PostgreSQL
-- SQL Server sequences map directly to PostgreSQL sequences

-- Application sequences
CREATE SEQUENCE IF NOT EXISTS application.person_id_seq START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE IF NOT EXISTS application.city_id_seq START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE IF NOT EXISTS application.country_id_seq START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE IF NOT EXISTS application.state_province_id_seq START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE IF NOT EXISTS application.delivery_method_id_seq START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE IF NOT EXISTS application.payment_method_id_seq START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE IF NOT EXISTS application.transaction_type_id_seq START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE IF NOT EXISTS application.system_parameter_id_seq START WITH 1 INCREMENT BY 1;

-- Sales sequences
CREATE SEQUENCE IF NOT EXISTS sales.customer_id_seq START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE IF NOT EXISTS sales.customer_category_id_seq START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE IF NOT EXISTS sales.buying_group_id_seq START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE IF NOT EXISTS sales.order_id_seq START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE IF NOT EXISTS sales.order_line_id_seq START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE IF NOT EXISTS sales.invoice_id_seq START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE IF NOT EXISTS sales.invoice_line_id_seq START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE IF NOT EXISTS sales.special_deal_id_seq START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE IF NOT EXISTS sales.transaction_id_seq START WITH 1 INCREMENT BY 1;

-- Purchasing sequences
CREATE SEQUENCE IF NOT EXISTS purchasing.supplier_id_seq START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE IF NOT EXISTS purchasing.supplier_category_id_seq START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE IF NOT EXISTS purchasing.purchase_order_id_seq START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE IF NOT EXISTS purchasing.purchase_order_line_id_seq START WITH 1 INCREMENT BY 1;

-- Warehouse sequences
CREATE SEQUENCE IF NOT EXISTS warehouse.stock_item_id_seq START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE IF NOT EXISTS warehouse.stock_group_id_seq START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE IF NOT EXISTS warehouse.stock_item_stock_group_id_seq START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE IF NOT EXISTS warehouse.color_id_seq START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE IF NOT EXISTS warehouse.package_type_id_seq START WITH 1 INCREMENT BY 1;
