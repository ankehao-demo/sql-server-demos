-- Wide World Importers DW PostgreSQL Migration
-- Phase 4: OLAP Schema Migration
-- File: 001-constraints.sql
-- Description: Create foreign key constraints for star schema relationships
-- Note: Foreign keys in data warehouses are often not enforced for performance
-- but are documented here for referential integrity documentation

-- =============================================
-- Fact.Sale Foreign Keys
-- =============================================
ALTER TABLE fact.sale
    ADD CONSTRAINT fk_fact_sale_city_key 
    FOREIGN KEY (city_key) REFERENCES dimension.city (city_key);

ALTER TABLE fact.sale
    ADD CONSTRAINT fk_fact_sale_customer_key 
    FOREIGN KEY (customer_key) REFERENCES dimension.customer (customer_key);

ALTER TABLE fact.sale
    ADD CONSTRAINT fk_fact_sale_bill_to_customer_key 
    FOREIGN KEY (bill_to_customer_key) REFERENCES dimension.customer (customer_key);

ALTER TABLE fact.sale
    ADD CONSTRAINT fk_fact_sale_stock_item_key 
    FOREIGN KEY (stock_item_key) REFERENCES dimension.stock_item (stock_item_key);

ALTER TABLE fact.sale
    ADD CONSTRAINT fk_fact_sale_invoice_date_key 
    FOREIGN KEY (invoice_date_key) REFERENCES dimension.date (date);

ALTER TABLE fact.sale
    ADD CONSTRAINT fk_fact_sale_delivery_date_key 
    FOREIGN KEY (delivery_date_key) REFERENCES dimension.date (date);

ALTER TABLE fact.sale
    ADD CONSTRAINT fk_fact_sale_salesperson_key 
    FOREIGN KEY (salesperson_key) REFERENCES dimension.employee (employee_key);

-- =============================================
-- Fact.Order Foreign Keys
-- =============================================
ALTER TABLE fact.order
    ADD CONSTRAINT fk_fact_order_city_key 
    FOREIGN KEY (city_key) REFERENCES dimension.city (city_key);

ALTER TABLE fact.order
    ADD CONSTRAINT fk_fact_order_customer_key 
    FOREIGN KEY (customer_key) REFERENCES dimension.customer (customer_key);

ALTER TABLE fact.order
    ADD CONSTRAINT fk_fact_order_stock_item_key 
    FOREIGN KEY (stock_item_key) REFERENCES dimension.stock_item (stock_item_key);

ALTER TABLE fact.order
    ADD CONSTRAINT fk_fact_order_order_date_key 
    FOREIGN KEY (order_date_key) REFERENCES dimension.date (date);

ALTER TABLE fact.order
    ADD CONSTRAINT fk_fact_order_picked_date_key 
    FOREIGN KEY (picked_date_key) REFERENCES dimension.date (date);

ALTER TABLE fact.order
    ADD CONSTRAINT fk_fact_order_salesperson_key 
    FOREIGN KEY (salesperson_key) REFERENCES dimension.employee (employee_key);

ALTER TABLE fact.order
    ADD CONSTRAINT fk_fact_order_picker_key 
    FOREIGN KEY (picker_key) REFERENCES dimension.employee (employee_key);

-- =============================================
-- Fact.Purchase Foreign Keys
-- =============================================
ALTER TABLE fact.purchase
    ADD CONSTRAINT fk_fact_purchase_date_key 
    FOREIGN KEY (date_key) REFERENCES dimension.date (date);

ALTER TABLE fact.purchase
    ADD CONSTRAINT fk_fact_purchase_supplier_key 
    FOREIGN KEY (supplier_key) REFERENCES dimension.supplier (supplier_key);

ALTER TABLE fact.purchase
    ADD CONSTRAINT fk_fact_purchase_stock_item_key 
    FOREIGN KEY (stock_item_key) REFERENCES dimension.stock_item (stock_item_key);

-- =============================================
-- Fact.Movement Foreign Keys
-- =============================================
ALTER TABLE fact.movement
    ADD CONSTRAINT fk_fact_movement_date_key 
    FOREIGN KEY (date_key) REFERENCES dimension.date (date);

ALTER TABLE fact.movement
    ADD CONSTRAINT fk_fact_movement_stock_item_key 
    FOREIGN KEY (stock_item_key) REFERENCES dimension.stock_item (stock_item_key);

ALTER TABLE fact.movement
    ADD CONSTRAINT fk_fact_movement_customer_key 
    FOREIGN KEY (customer_key) REFERENCES dimension.customer (customer_key);

ALTER TABLE fact.movement
    ADD CONSTRAINT fk_fact_movement_supplier_key 
    FOREIGN KEY (supplier_key) REFERENCES dimension.supplier (supplier_key);

ALTER TABLE fact.movement
    ADD CONSTRAINT fk_fact_movement_transaction_type_key 
    FOREIGN KEY (transaction_type_key) REFERENCES dimension.transaction_type (transaction_type_key);

-- =============================================
-- Fact.Transaction Foreign Keys
-- =============================================
ALTER TABLE fact.transaction
    ADD CONSTRAINT fk_fact_transaction_date_key 
    FOREIGN KEY (date_key) REFERENCES dimension.date (date);

ALTER TABLE fact.transaction
    ADD CONSTRAINT fk_fact_transaction_customer_key 
    FOREIGN KEY (customer_key) REFERENCES dimension.customer (customer_key);

ALTER TABLE fact.transaction
    ADD CONSTRAINT fk_fact_transaction_bill_to_customer_key 
    FOREIGN KEY (bill_to_customer_key) REFERENCES dimension.customer (customer_key);

ALTER TABLE fact.transaction
    ADD CONSTRAINT fk_fact_transaction_supplier_key 
    FOREIGN KEY (supplier_key) REFERENCES dimension.supplier (supplier_key);

ALTER TABLE fact.transaction
    ADD CONSTRAINT fk_fact_transaction_transaction_type_key 
    FOREIGN KEY (transaction_type_key) REFERENCES dimension.transaction_type (transaction_type_key);

ALTER TABLE fact.transaction
    ADD CONSTRAINT fk_fact_transaction_payment_method_key 
    FOREIGN KEY (payment_method_key) REFERENCES dimension.payment_method (payment_method_key);

-- =============================================
-- Fact.Stock_Holding Foreign Keys
-- =============================================
ALTER TABLE fact.stock_holding
    ADD CONSTRAINT fk_fact_stock_holding_stock_item_key 
    FOREIGN KEY (stock_item_key) REFERENCES dimension.stock_item (stock_item_key);
