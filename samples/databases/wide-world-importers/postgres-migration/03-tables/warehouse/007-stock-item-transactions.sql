-- Wide World Importers PostgreSQL Migration
-- Phase 2: OLTP Schema Migration
-- Warehouse.StockItemTransactions table (non-temporal, originally had columnstore index)

CREATE TABLE warehouse.stock_item_transactions (
    stock_item_transaction_id INTEGER NOT NULL DEFAULT nextval('sequences.transaction_id'),
    stock_item_id INTEGER NOT NULL,
    transaction_type_id INTEGER NOT NULL,
    customer_id INTEGER NULL,
    invoice_id INTEGER NULL,
    supplier_id INTEGER NULL,
    purchase_order_id INTEGER NULL,
    transaction_occurred_when TIMESTAMP NOT NULL,
    quantity NUMERIC(18, 3) NOT NULL,
    last_edited_by INTEGER NOT NULL,
    last_edited_when TIMESTAMP NOT NULL DEFAULT clock_timestamp(),
    
    CONSTRAINT pk_warehouse_stock_item_transactions PRIMARY KEY (stock_item_transaction_id),
    CONSTRAINT fk_warehouse_stock_item_transactions_stock_item 
        FOREIGN KEY (stock_item_id) REFERENCES warehouse.stock_items(stock_item_id),
    CONSTRAINT fk_warehouse_stock_item_transactions_transaction_type 
        FOREIGN KEY (transaction_type_id) REFERENCES application.transaction_types(transaction_type_id),
    CONSTRAINT fk_warehouse_stock_item_transactions_customer 
        FOREIGN KEY (customer_id) REFERENCES sales.customers(customer_id),
    CONSTRAINT fk_warehouse_stock_item_transactions_invoice 
        FOREIGN KEY (invoice_id) REFERENCES sales.invoices(invoice_id),
    CONSTRAINT fk_warehouse_stock_item_transactions_supplier 
        FOREIGN KEY (supplier_id) REFERENCES purchasing.suppliers(supplier_id),
    CONSTRAINT fk_warehouse_stock_item_transactions_purchase_order 
        FOREIGN KEY (purchase_order_id) REFERENCES purchasing.purchase_orders(purchase_order_id),
    CONSTRAINT fk_warehouse_stock_item_transactions_last_edited_by 
        FOREIGN KEY (last_edited_by) REFERENCES application.people(person_id)
);

-- Indexes for foreign keys
CREATE INDEX ix_warehouse_stock_item_transactions_stock_item_id 
    ON warehouse.stock_item_transactions(stock_item_id);
CREATE INDEX ix_warehouse_stock_item_transactions_transaction_type_id 
    ON warehouse.stock_item_transactions(transaction_type_id);
CREATE INDEX ix_warehouse_stock_item_transactions_customer_id 
    ON warehouse.stock_item_transactions(customer_id);
CREATE INDEX ix_warehouse_stock_item_transactions_invoice_id 
    ON warehouse.stock_item_transactions(invoice_id);
CREATE INDEX ix_warehouse_stock_item_transactions_supplier_id 
    ON warehouse.stock_item_transactions(supplier_id);
CREATE INDEX ix_warehouse_stock_item_transactions_purchase_order_id 
    ON warehouse.stock_item_transactions(purchase_order_id);
