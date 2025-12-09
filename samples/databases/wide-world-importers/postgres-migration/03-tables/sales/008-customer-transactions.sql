-- Wide World Importers PostgreSQL Migration
-- Phase 2: OLTP Schema Migration
-- Sales.CustomerTransactions table (non-temporal, originally partitioned)

CREATE TABLE sales.customer_transactions (
    customer_transaction_id INTEGER NOT NULL DEFAULT nextval('sequences.transaction_id'),
    customer_id INTEGER NOT NULL,
    transaction_type_id INTEGER NOT NULL,
    invoice_id INTEGER NULL,
    payment_method_id INTEGER NULL,
    transaction_date DATE NOT NULL,
    amount_excluding_tax NUMERIC(18, 2) NOT NULL,
    tax_amount NUMERIC(18, 2) NOT NULL,
    transaction_amount NUMERIC(18, 2) NOT NULL,
    outstanding_balance NUMERIC(18, 2) NOT NULL,
    finalization_date DATE NULL,
    is_finalized BOOLEAN GENERATED ALWAYS AS (finalization_date IS NOT NULL) STORED,
    last_edited_by INTEGER NOT NULL,
    last_edited_when TIMESTAMP NOT NULL DEFAULT clock_timestamp(),
    
    CONSTRAINT pk_sales_customer_transactions PRIMARY KEY (customer_transaction_id),
    CONSTRAINT fk_sales_customer_transactions_customer 
        FOREIGN KEY (customer_id) REFERENCES sales.customers(customer_id),
    CONSTRAINT fk_sales_customer_transactions_transaction_type 
        FOREIGN KEY (transaction_type_id) REFERENCES application.transaction_types(transaction_type_id),
    CONSTRAINT fk_sales_customer_transactions_invoice 
        FOREIGN KEY (invoice_id) REFERENCES sales.invoices(invoice_id),
    CONSTRAINT fk_sales_customer_transactions_payment_method 
        FOREIGN KEY (payment_method_id) REFERENCES application.payment_methods(payment_method_id),
    CONSTRAINT fk_sales_customer_transactions_last_edited_by 
        FOREIGN KEY (last_edited_by) REFERENCES application.people(person_id)
);

-- Indexes for foreign keys and performance
CREATE INDEX ix_sales_customer_transactions_transaction_date 
    ON sales.customer_transactions(transaction_date);
CREATE INDEX ix_sales_customer_transactions_customer_id 
    ON sales.customer_transactions(customer_id);
CREATE INDEX ix_sales_customer_transactions_transaction_type_id 
    ON sales.customer_transactions(transaction_type_id);
CREATE INDEX ix_sales_customer_transactions_invoice_id 
    ON sales.customer_transactions(invoice_id);
CREATE INDEX ix_sales_customer_transactions_payment_method_id 
    ON sales.customer_transactions(payment_method_id);
CREATE INDEX ix_sales_customer_transactions_is_finalized 
    ON sales.customer_transactions(is_finalized);
