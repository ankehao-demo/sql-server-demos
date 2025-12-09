-- Wide World Importers PostgreSQL Migration
-- Phase 2: OLTP Schema Migration
-- Sales.InvoiceLines table (non-temporal)
-- Note: References Warehouse.StockItems and Warehouse.PackageTypes - FK constraints added later

CREATE TABLE sales.invoice_lines (
    invoice_line_id INTEGER NOT NULL DEFAULT nextval('sequences.invoice_line_id'),
    invoice_id INTEGER NOT NULL,
    stock_item_id INTEGER NOT NULL,
    description VARCHAR(100) NOT NULL,
    package_type_id INTEGER NOT NULL,
    quantity INTEGER NOT NULL,
    unit_price NUMERIC(18, 2) NULL,
    tax_rate NUMERIC(18, 3) NOT NULL,
    tax_amount NUMERIC(18, 2) NOT NULL,
    line_profit NUMERIC(18, 2) NOT NULL,
    extended_price NUMERIC(18, 2) NOT NULL,
    last_edited_by INTEGER NOT NULL,
    last_edited_when TIMESTAMP NOT NULL DEFAULT clock_timestamp(),
    
    CONSTRAINT pk_sales_invoice_lines PRIMARY KEY (invoice_line_id),
    CONSTRAINT fk_sales_invoice_lines_invoice 
        FOREIGN KEY (invoice_id) REFERENCES sales.invoices(invoice_id),
    CONSTRAINT fk_sales_invoice_lines_last_edited_by 
        FOREIGN KEY (last_edited_by) REFERENCES application.people(person_id)
);

-- Indexes for foreign keys and performance
CREATE INDEX ix_sales_invoice_lines_invoice_id 
    ON sales.invoice_lines(invoice_id);
CREATE INDEX ix_sales_invoice_lines_stock_item_id 
    ON sales.invoice_lines(stock_item_id);
CREATE INDEX ix_sales_invoice_lines_package_type_id 
    ON sales.invoice_lines(package_type_id);
