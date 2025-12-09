-- Wide World Importers PostgreSQL Migration
-- Phase 2: OLTP Schema Migration
-- Sales.Orders table (non-temporal)

CREATE TABLE sales.orders (
    order_id INTEGER NOT NULL DEFAULT nextval('sequences.order_id'),
    customer_id INTEGER NOT NULL,
    salesperson_person_id INTEGER NOT NULL,
    picked_by_person_id INTEGER NULL,
    contact_person_id INTEGER NOT NULL,
    backorder_order_id INTEGER NULL,
    order_date DATE NOT NULL,
    expected_delivery_date DATE NOT NULL,
    customer_purchase_order_number VARCHAR(20) NULL,
    is_undersupply_backordered BOOLEAN NOT NULL,
    comments TEXT NULL,
    delivery_instructions TEXT NULL,
    internal_comments TEXT NULL,
    picking_completed_when TIMESTAMP NULL,
    last_edited_by INTEGER NOT NULL,
    last_edited_when TIMESTAMP NOT NULL DEFAULT clock_timestamp(),
    
    CONSTRAINT pk_sales_orders PRIMARY KEY (order_id),
    CONSTRAINT fk_sales_orders_customer 
        FOREIGN KEY (customer_id) REFERENCES sales.customers(customer_id),
    CONSTRAINT fk_sales_orders_salesperson_person 
        FOREIGN KEY (salesperson_person_id) REFERENCES application.people(person_id),
    CONSTRAINT fk_sales_orders_picked_by_person 
        FOREIGN KEY (picked_by_person_id) REFERENCES application.people(person_id),
    CONSTRAINT fk_sales_orders_contact_person 
        FOREIGN KEY (contact_person_id) REFERENCES application.people(person_id),
    CONSTRAINT fk_sales_orders_last_edited_by 
        FOREIGN KEY (last_edited_by) REFERENCES application.people(person_id)
);

-- Self-referential foreign key for backorder_order_id
ALTER TABLE sales.orders 
    ADD CONSTRAINT fk_sales_orders_backorder_order 
    FOREIGN KEY (backorder_order_id) REFERENCES sales.orders(order_id);

-- Indexes for foreign keys
CREATE INDEX ix_sales_orders_customer_id 
    ON sales.orders(customer_id);
CREATE INDEX ix_sales_orders_salesperson_person_id 
    ON sales.orders(salesperson_person_id);
CREATE INDEX ix_sales_orders_picked_by_person_id 
    ON sales.orders(picked_by_person_id);
CREATE INDEX ix_sales_orders_contact_person_id 
    ON sales.orders(contact_person_id);
