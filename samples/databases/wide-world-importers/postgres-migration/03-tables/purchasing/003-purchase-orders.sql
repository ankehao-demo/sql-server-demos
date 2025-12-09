-- Wide World Importers PostgreSQL Migration
-- Phase 2: OLTP Schema Migration
-- Purchasing.PurchaseOrders table (non-temporal)

CREATE TABLE purchasing.purchase_orders (
    purchase_order_id INTEGER NOT NULL DEFAULT nextval('sequences.purchase_order_id'),
    supplier_id INTEGER NOT NULL,
    order_date DATE NOT NULL,
    delivery_method_id INTEGER NOT NULL,
    contact_person_id INTEGER NOT NULL,
    expected_delivery_date DATE NULL,
    supplier_reference VARCHAR(20) NULL,
    is_order_finalized BOOLEAN NOT NULL,
    comments TEXT NULL,
    internal_comments TEXT NULL,
    last_edited_by INTEGER NOT NULL,
    last_edited_when TIMESTAMP NOT NULL DEFAULT clock_timestamp(),
    
    CONSTRAINT pk_purchasing_purchase_orders PRIMARY KEY (purchase_order_id),
    CONSTRAINT fk_purchasing_purchase_orders_supplier 
        FOREIGN KEY (supplier_id) REFERENCES purchasing.suppliers(supplier_id),
    CONSTRAINT fk_purchasing_purchase_orders_delivery_method 
        FOREIGN KEY (delivery_method_id) REFERENCES application.delivery_methods(delivery_method_id),
    CONSTRAINT fk_purchasing_purchase_orders_contact_person 
        FOREIGN KEY (contact_person_id) REFERENCES application.people(person_id),
    CONSTRAINT fk_purchasing_purchase_orders_last_edited_by 
        FOREIGN KEY (last_edited_by) REFERENCES application.people(person_id)
);

-- Indexes for foreign keys
CREATE INDEX ix_purchasing_purchase_orders_supplier_id 
    ON purchasing.purchase_orders(supplier_id);
CREATE INDEX ix_purchasing_purchase_orders_delivery_method_id 
    ON purchasing.purchase_orders(delivery_method_id);
CREATE INDEX ix_purchasing_purchase_orders_contact_person_id 
    ON purchasing.purchase_orders(contact_person_id);
