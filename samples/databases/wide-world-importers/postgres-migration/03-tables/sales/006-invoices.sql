-- Wide World Importers PostgreSQL Migration
-- Phase 2: OLTP Schema Migration
-- Sales.Invoices table (non-temporal)

CREATE TABLE sales.invoices (
    invoice_id INTEGER NOT NULL DEFAULT nextval('sequences.invoice_id'),
    customer_id INTEGER NOT NULL,
    bill_to_customer_id INTEGER NOT NULL,
    order_id INTEGER NULL,
    delivery_method_id INTEGER NOT NULL,
    contact_person_id INTEGER NOT NULL,
    accounts_person_id INTEGER NOT NULL,
    salesperson_person_id INTEGER NOT NULL,
    packed_by_person_id INTEGER NOT NULL,
    invoice_date DATE NOT NULL,
    customer_purchase_order_number VARCHAR(20) NULL,
    is_credit_note BOOLEAN NOT NULL,
    credit_note_reason TEXT NULL,
    comments TEXT NULL,
    delivery_instructions TEXT NULL,
    internal_comments TEXT NULL,
    total_dry_items INTEGER NOT NULL,
    total_chiller_items INTEGER NOT NULL,
    delivery_run VARCHAR(5) NULL,
    run_position VARCHAR(5) NULL,
    returned_delivery_data JSONB NULL,
    confirmed_delivery_time TIMESTAMP GENERATED ALWAYS AS (
        CASE 
            WHEN returned_delivery_data IS NOT NULL 
            THEN (returned_delivery_data->>'DeliveredWhen')::timestamp 
            ELSE NULL 
        END
    ) STORED,
    confirmed_received_by VARCHAR(4000) GENERATED ALWAYS AS (
        returned_delivery_data->>'ReceivedBy'
    ) STORED,
    last_edited_by INTEGER NOT NULL,
    last_edited_when TIMESTAMP NOT NULL DEFAULT clock_timestamp(),
    
    CONSTRAINT pk_sales_invoices PRIMARY KEY (invoice_id),
    CONSTRAINT ck_sales_invoices_returned_delivery_data_valid_json 
        CHECK (returned_delivery_data IS NULL OR jsonb_typeof(returned_delivery_data) IS NOT NULL),
    CONSTRAINT fk_sales_invoices_customer 
        FOREIGN KEY (customer_id) REFERENCES sales.customers(customer_id),
    CONSTRAINT fk_sales_invoices_bill_to_customer 
        FOREIGN KEY (bill_to_customer_id) REFERENCES sales.customers(customer_id),
    CONSTRAINT fk_sales_invoices_order 
        FOREIGN KEY (order_id) REFERENCES sales.orders(order_id),
    CONSTRAINT fk_sales_invoices_delivery_method 
        FOREIGN KEY (delivery_method_id) REFERENCES application.delivery_methods(delivery_method_id),
    CONSTRAINT fk_sales_invoices_contact_person 
        FOREIGN KEY (contact_person_id) REFERENCES application.people(person_id),
    CONSTRAINT fk_sales_invoices_accounts_person 
        FOREIGN KEY (accounts_person_id) REFERENCES application.people(person_id),
    CONSTRAINT fk_sales_invoices_salesperson_person 
        FOREIGN KEY (salesperson_person_id) REFERENCES application.people(person_id),
    CONSTRAINT fk_sales_invoices_packed_by_person 
        FOREIGN KEY (packed_by_person_id) REFERENCES application.people(person_id),
    CONSTRAINT fk_sales_invoices_last_edited_by 
        FOREIGN KEY (last_edited_by) REFERENCES application.people(person_id)
);

-- Indexes for foreign keys and performance
CREATE INDEX ix_sales_invoices_customer_id 
    ON sales.invoices(customer_id);
CREATE INDEX ix_sales_invoices_bill_to_customer_id 
    ON sales.invoices(bill_to_customer_id);
CREATE INDEX ix_sales_invoices_order_id 
    ON sales.invoices(order_id);
CREATE INDEX ix_sales_invoices_delivery_method_id 
    ON sales.invoices(delivery_method_id);
CREATE INDEX ix_sales_invoices_contact_person_id 
    ON sales.invoices(contact_person_id);
CREATE INDEX ix_sales_invoices_accounts_person_id 
    ON sales.invoices(accounts_person_id);
CREATE INDEX ix_sales_invoices_salesperson_person_id 
    ON sales.invoices(salesperson_person_id);
CREATE INDEX ix_sales_invoices_packed_by_person_id 
    ON sales.invoices(packed_by_person_id);
CREATE INDEX ix_sales_invoices_confirmed_delivery_time 
    ON sales.invoices(confirmed_delivery_time) 
    INCLUDE (confirmed_received_by);
