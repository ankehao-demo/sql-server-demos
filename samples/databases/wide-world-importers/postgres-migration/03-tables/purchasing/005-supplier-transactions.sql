-- Wide World Importers PostgreSQL Migration
-- Phase 2: OLTP Schema Migration
-- Purchasing.SupplierTransactions table (non-temporal, originally partitioned)

CREATE TABLE purchasing.supplier_transactions (
    supplier_transaction_id INTEGER NOT NULL DEFAULT nextval('sequences.transaction_id'),
    supplier_id INTEGER NOT NULL,
    transaction_type_id INTEGER NOT NULL,
    purchase_order_id INTEGER NULL,
    payment_method_id INTEGER NULL,
    supplier_invoice_number VARCHAR(20) NULL,
    transaction_date DATE NOT NULL,
    amount_excluding_tax NUMERIC(18, 2) NOT NULL,
    tax_amount NUMERIC(18, 2) NOT NULL,
    transaction_amount NUMERIC(18, 2) NOT NULL,
    outstanding_balance NUMERIC(18, 2) NOT NULL,
    finalization_date DATE NULL,
    is_finalized BOOLEAN GENERATED ALWAYS AS (finalization_date IS NOT NULL) STORED,
    last_edited_by INTEGER NOT NULL,
    last_edited_when TIMESTAMP NOT NULL DEFAULT clock_timestamp(),
    
    CONSTRAINT pk_purchasing_supplier_transactions PRIMARY KEY (supplier_transaction_id),
    CONSTRAINT fk_purchasing_supplier_transactions_supplier 
        FOREIGN KEY (supplier_id) REFERENCES purchasing.suppliers(supplier_id),
    CONSTRAINT fk_purchasing_supplier_transactions_transaction_type 
        FOREIGN KEY (transaction_type_id) REFERENCES application.transaction_types(transaction_type_id),
    CONSTRAINT fk_purchasing_supplier_transactions_purchase_order 
        FOREIGN KEY (purchase_order_id) REFERENCES purchasing.purchase_orders(purchase_order_id),
    CONSTRAINT fk_purchasing_supplier_transactions_payment_method 
        FOREIGN KEY (payment_method_id) REFERENCES application.payment_methods(payment_method_id),
    CONSTRAINT fk_purchasing_supplier_transactions_last_edited_by 
        FOREIGN KEY (last_edited_by) REFERENCES application.people(person_id)
);

-- Indexes for foreign keys and performance
CREATE INDEX ix_purchasing_supplier_transactions_transaction_date 
    ON purchasing.supplier_transactions(transaction_date);
CREATE INDEX ix_purchasing_supplier_transactions_supplier_id 
    ON purchasing.supplier_transactions(supplier_id);
CREATE INDEX ix_purchasing_supplier_transactions_transaction_type_id 
    ON purchasing.supplier_transactions(transaction_type_id);
CREATE INDEX ix_purchasing_supplier_transactions_purchase_order_id 
    ON purchasing.supplier_transactions(purchase_order_id);
CREATE INDEX ix_purchasing_supplier_transactions_payment_method_id 
    ON purchasing.supplier_transactions(payment_method_id);
CREATE INDEX ix_purchasing_supplier_transactions_is_finalized 
    ON purchasing.supplier_transactions(is_finalized);
