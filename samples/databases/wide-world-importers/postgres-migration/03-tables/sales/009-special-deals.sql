-- Wide World Importers PostgreSQL Migration
-- Phase 2: OLTP Schema Migration
-- Sales.SpecialDeals table (non-temporal)
-- Note: References Warehouse.StockItems and Warehouse.StockGroups - FK constraints added later

CREATE TABLE sales.special_deals (
    special_deal_id INTEGER NOT NULL DEFAULT nextval('sequences.special_deal_id'),
    stock_item_id INTEGER NULL,
    customer_id INTEGER NULL,
    buying_group_id INTEGER NULL,
    customer_category_id INTEGER NULL,
    stock_group_id INTEGER NULL,
    deal_description VARCHAR(30) NOT NULL,
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    discount_amount NUMERIC(18, 2) NULL,
    discount_percentage NUMERIC(18, 3) NULL,
    unit_price NUMERIC(18, 2) NULL,
    last_edited_by INTEGER NOT NULL,
    last_edited_when TIMESTAMP NOT NULL DEFAULT clock_timestamp(),
    
    CONSTRAINT pk_sales_special_deals PRIMARY KEY (special_deal_id),
    CONSTRAINT ck_sales_special_deals_exactly_one_pricing_option 
        CHECK (
            (CASE WHEN discount_amount IS NULL THEN 0 ELSE 1 END +
             CASE WHEN discount_percentage IS NULL THEN 0 ELSE 1 END +
             CASE WHEN unit_price IS NULL THEN 0 ELSE 1 END) = 1
        ),
    CONSTRAINT ck_sales_special_deals_unit_price_requires_stock_item 
        CHECK (
            (stock_item_id IS NOT NULL AND unit_price IS NOT NULL) OR 
            unit_price IS NULL
        ),
    CONSTRAINT fk_sales_special_deals_customer 
        FOREIGN KEY (customer_id) REFERENCES sales.customers(customer_id),
    CONSTRAINT fk_sales_special_deals_buying_group 
        FOREIGN KEY (buying_group_id) REFERENCES sales.buying_groups(buying_group_id),
    CONSTRAINT fk_sales_special_deals_customer_category 
        FOREIGN KEY (customer_category_id) REFERENCES sales.customer_categories(customer_category_id),
    CONSTRAINT fk_sales_special_deals_last_edited_by 
        FOREIGN KEY (last_edited_by) REFERENCES application.people(person_id)
);

-- Indexes for foreign keys
CREATE INDEX ix_sales_special_deals_stock_item_id 
    ON sales.special_deals(stock_item_id);
CREATE INDEX ix_sales_special_deals_customer_id 
    ON sales.special_deals(customer_id);
CREATE INDEX ix_sales_special_deals_buying_group_id 
    ON sales.special_deals(buying_group_id);
CREATE INDEX ix_sales_special_deals_customer_category_id 
    ON sales.special_deals(customer_category_id);
CREATE INDEX ix_sales_special_deals_stock_group_id 
    ON sales.special_deals(stock_group_id);
