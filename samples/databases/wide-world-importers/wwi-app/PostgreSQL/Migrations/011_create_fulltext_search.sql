-- Wide World Importers PostgreSQL Migration
-- Script 011: Create Full-Text Search
-- Migrated from SQL Server to PostgreSQL
--
-- SQL Server uses Full-Text Indexes with CONTAINS/FREETEXT predicates
-- PostgreSQL uses tsvector/tsquery with GIN indexes for full-text search

-- Create text search configuration for English (default)
-- PostgreSQL comes with built-in configurations, we'll use 'english'

-- Add tsvector columns for full-text search on key tables

-- People: Add search vector column
ALTER TABLE application.people 
    ADD COLUMN IF NOT EXISTS search_vector tsvector;

-- Create function to update people search vector
CREATE OR REPLACE FUNCTION application.update_people_search_vector()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    NEW.search_vector := 
        setweight(to_tsvector('english', COALESCE(NEW.full_name, '')), 'A') ||
        setweight(to_tsvector('english', COALESCE(NEW.preferred_name, '')), 'A') ||
        setweight(to_tsvector('english', COALESCE(NEW.email_address, '')), 'B') ||
        setweight(to_tsvector('english', COALESCE(NEW.logon_name, '')), 'C');
    RETURN NEW;
END;
$$;

-- Create trigger for people search vector
DROP TRIGGER IF EXISTS tr_people_search_vector ON application.people;
CREATE TRIGGER tr_people_search_vector
    BEFORE INSERT OR UPDATE OF full_name, preferred_name, email_address, logon_name
    ON application.people
    FOR EACH ROW EXECUTE FUNCTION application.update_people_search_vector();

-- Create GIN index for people full-text search
CREATE INDEX IF NOT EXISTS ix_application_people_search_vector 
    ON application.people USING GIN (search_vector);

-- Customers: Add search vector column
ALTER TABLE sales.customers 
    ADD COLUMN IF NOT EXISTS search_vector tsvector;

-- Create function to update customers search vector
CREATE OR REPLACE FUNCTION sales.update_customers_search_vector()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    NEW.search_vector := 
        setweight(to_tsvector('english', COALESCE(NEW.customer_name, '')), 'A') ||
        setweight(to_tsvector('english', COALESCE(NEW.phone_number, '')), 'B') ||
        setweight(to_tsvector('english', COALESCE(NEW.website_url, '')), 'C') ||
        setweight(to_tsvector('english', COALESCE(NEW.delivery_address_line_1, '')), 'C') ||
        setweight(to_tsvector('english', COALESCE(NEW.delivery_address_line_2, '')), 'D');
    RETURN NEW;
END;
$$;

-- Create trigger for customers search vector
DROP TRIGGER IF EXISTS tr_customers_search_vector ON sales.customers;
CREATE TRIGGER tr_customers_search_vector
    BEFORE INSERT OR UPDATE OF customer_name, phone_number, website_url, delivery_address_line_1, delivery_address_line_2
    ON sales.customers
    FOR EACH ROW EXECUTE FUNCTION sales.update_customers_search_vector();

-- Create GIN index for customers full-text search
CREATE INDEX IF NOT EXISTS ix_sales_customers_search_vector 
    ON sales.customers USING GIN (search_vector);

-- Suppliers: Add search vector column
ALTER TABLE purchasing.suppliers 
    ADD COLUMN IF NOT EXISTS search_vector tsvector;

-- Create function to update suppliers search vector
CREATE OR REPLACE FUNCTION purchasing.update_suppliers_search_vector()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    NEW.search_vector := 
        setweight(to_tsvector('english', COALESCE(NEW.supplier_name, '')), 'A') ||
        setweight(to_tsvector('english', COALESCE(NEW.phone_number, '')), 'B') ||
        setweight(to_tsvector('english', COALESCE(NEW.website_url, '')), 'C') ||
        setweight(to_tsvector('english', COALESCE(NEW.delivery_address_line_1, '')), 'C') ||
        setweight(to_tsvector('english', COALESCE(NEW.internal_comments, '')), 'D');
    RETURN NEW;
END;
$$;

-- Create trigger for suppliers search vector
DROP TRIGGER IF EXISTS tr_suppliers_search_vector ON purchasing.suppliers;
CREATE TRIGGER tr_suppliers_search_vector
    BEFORE INSERT OR UPDATE OF supplier_name, phone_number, website_url, delivery_address_line_1, internal_comments
    ON purchasing.suppliers
    FOR EACH ROW EXECUTE FUNCTION purchasing.update_suppliers_search_vector();

-- Create GIN index for suppliers full-text search
CREATE INDEX IF NOT EXISTS ix_purchasing_suppliers_search_vector 
    ON purchasing.suppliers USING GIN (search_vector);

-- Stock Items: Add search vector column
ALTER TABLE warehouse.stock_items 
    ADD COLUMN IF NOT EXISTS search_vector tsvector;

-- Create function to update stock items search vector
CREATE OR REPLACE FUNCTION warehouse.update_stock_items_search_vector()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    NEW.search_vector := 
        setweight(to_tsvector('english', COALESCE(NEW.stock_item_name, '')), 'A') ||
        setweight(to_tsvector('english', COALESCE(NEW.brand, '')), 'A') ||
        setweight(to_tsvector('english', COALESCE(NEW.marketing_comments, '')), 'B') ||
        setweight(to_tsvector('english', COALESCE(NEW.barcode, '')), 'B') ||
        setweight(to_tsvector('english', COALESCE(NEW.internal_comments, '')), 'D');
    RETURN NEW;
END;
$$;

-- Create trigger for stock items search vector
DROP TRIGGER IF EXISTS tr_stock_items_search_vector ON warehouse.stock_items;
CREATE TRIGGER tr_stock_items_search_vector
    BEFORE INSERT OR UPDATE OF stock_item_name, brand, marketing_comments, barcode, internal_comments
    ON warehouse.stock_items
    FOR EACH ROW EXECUTE FUNCTION warehouse.update_stock_items_search_vector();

-- Create GIN index for stock items full-text search
CREATE INDEX IF NOT EXISTS ix_warehouse_stock_items_search_vector 
    ON warehouse.stock_items USING GIN (search_vector);

-- Cities: Add search vector column
ALTER TABLE application.cities 
    ADD COLUMN IF NOT EXISTS search_vector tsvector;

-- Create function to update cities search vector
CREATE OR REPLACE FUNCTION application.update_cities_search_vector()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    NEW.search_vector := to_tsvector('english', COALESCE(NEW.city_name, ''));
    RETURN NEW;
END;
$$;

-- Create trigger for cities search vector
DROP TRIGGER IF EXISTS tr_cities_search_vector ON application.cities;
CREATE TRIGGER tr_cities_search_vector
    BEFORE INSERT OR UPDATE OF city_name
    ON application.cities
    FOR EACH ROW EXECUTE FUNCTION application.update_cities_search_vector();

-- Create GIN index for cities full-text search
CREATE INDEX IF NOT EXISTS ix_application_cities_search_vector 
    ON application.cities USING GIN (search_vector);

-- Countries: Add search vector column
ALTER TABLE application.countries 
    ADD COLUMN IF NOT EXISTS search_vector tsvector;

-- Create function to update countries search vector
CREATE OR REPLACE FUNCTION application.update_countries_search_vector()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    NEW.search_vector := 
        setweight(to_tsvector('english', COALESCE(NEW.country_name, '')), 'A') ||
        setweight(to_tsvector('english', COALESCE(NEW.formal_name, '')), 'A') ||
        setweight(to_tsvector('english', COALESCE(NEW.continent, '')), 'B') ||
        setweight(to_tsvector('english', COALESCE(NEW.region, '')), 'B') ||
        setweight(to_tsvector('english', COALESCE(NEW.subregion, '')), 'C');
    RETURN NEW;
END;
$$;

-- Create trigger for countries search vector
DROP TRIGGER IF EXISTS tr_countries_search_vector ON application.countries;
CREATE TRIGGER tr_countries_search_vector
    BEFORE INSERT OR UPDATE OF country_name, formal_name, continent, region, subregion
    ON application.countries
    FOR EACH ROW EXECUTE FUNCTION application.update_countries_search_vector();

-- Create GIN index for countries full-text search
CREATE INDEX IF NOT EXISTS ix_application_countries_search_vector 
    ON application.countries USING GIN (search_vector);

-- Full-text search helper functions

-- Function to search people using full-text search
CREATE OR REPLACE FUNCTION website.fts_search_people(
    p_search_text TEXT,
    p_maximum_rows INTEGER DEFAULT 100
)
RETURNS JSON
LANGUAGE plpgsql
AS $$
DECLARE
    v_query tsquery;
    v_result JSON;
BEGIN
    -- Convert search text to tsquery (handles multiple words with AND)
    v_query := plainto_tsquery('english', p_search_text);
    
    SELECT json_build_object('People', json_agg(people_data))
    INTO v_result
    FROM (
        SELECT 
            p.person_id AS "PersonID",
            p.full_name AS "FullName",
            p.preferred_name AS "PreferredName",
            p.email_address AS "EmailAddress",
            p.phone_number AS "PhoneNumber",
            ts_rank(p.search_vector, v_query) AS rank
        FROM application.people p
        WHERE p.search_vector @@ v_query
        ORDER BY rank DESC, p.full_name
        LIMIT p_maximum_rows
    ) AS people_data;

    RETURN COALESCE(v_result, '{"People": []}');
END;
$$;

-- Function to search customers using full-text search
CREATE OR REPLACE FUNCTION website.fts_search_customers(
    p_search_text TEXT,
    p_maximum_rows INTEGER DEFAULT 100
)
RETURNS JSON
LANGUAGE plpgsql
AS $$
DECLARE
    v_query tsquery;
    v_result JSON;
BEGIN
    v_query := plainto_tsquery('english', p_search_text);
    
    SELECT json_build_object('Customers', json_agg(customer_data))
    INTO v_result
    FROM (
        SELECT 
            c.customer_id AS "CustomerID",
            c.customer_name AS "CustomerName",
            ct.city_name AS "CityName",
            c.phone_number AS "PhoneNumber",
            ts_rank(c.search_vector, v_query) AS rank
        FROM sales.customers c
        LEFT JOIN application.cities ct ON c.delivery_city_id = ct.city_id
        WHERE c.search_vector @@ v_query
        ORDER BY rank DESC, c.customer_name
        LIMIT p_maximum_rows
    ) AS customer_data;

    RETURN COALESCE(v_result, '{"Customers": []}');
END;
$$;

-- Function to search suppliers using full-text search
CREATE OR REPLACE FUNCTION website.fts_search_suppliers(
    p_search_text TEXT,
    p_maximum_rows INTEGER DEFAULT 100
)
RETURNS JSON
LANGUAGE plpgsql
AS $$
DECLARE
    v_query tsquery;
    v_result JSON;
BEGIN
    v_query := plainto_tsquery('english', p_search_text);
    
    SELECT json_build_object('Suppliers', json_agg(supplier_data))
    INTO v_result
    FROM (
        SELECT 
            s.supplier_id AS "SupplierID",
            s.supplier_name AS "SupplierName",
            sc.supplier_category_name AS "SupplierCategoryName",
            s.phone_number AS "PhoneNumber",
            ts_rank(s.search_vector, v_query) AS rank
        FROM purchasing.suppliers s
        LEFT JOIN purchasing.supplier_categories sc ON s.supplier_category_id = sc.supplier_category_id
        WHERE s.search_vector @@ v_query
        ORDER BY rank DESC, s.supplier_name
        LIMIT p_maximum_rows
    ) AS supplier_data;

    RETURN COALESCE(v_result, '{"Suppliers": []}');
END;
$$;

-- Function to search stock items using full-text search
CREATE OR REPLACE FUNCTION website.fts_search_stock_items(
    p_search_text TEXT,
    p_maximum_rows INTEGER DEFAULT 100
)
RETURNS JSON
LANGUAGE plpgsql
AS $$
DECLARE
    v_query tsquery;
    v_result JSON;
BEGIN
    v_query := plainto_tsquery('english', p_search_text);
    
    SELECT json_build_object('StockItems', json_agg(stock_data))
    INTO v_result
    FROM (
        SELECT 
            si.stock_item_id AS "StockItemID",
            si.stock_item_name AS "StockItemName",
            si.brand AS "Brand",
            si.unit_price AS "UnitPrice",
            ts_rank(si.search_vector, v_query) AS rank
        FROM warehouse.stock_items si
        WHERE si.search_vector @@ v_query
        ORDER BY rank DESC, si.stock_item_name
        LIMIT p_maximum_rows
    ) AS stock_data;

    RETURN COALESCE(v_result, '{"StockItems": []}');
END;
$$;

-- Function for phrase search (exact phrase matching)
CREATE OR REPLACE FUNCTION website.fts_phrase_search(
    p_table_name TEXT,
    p_search_phrase TEXT,
    p_maximum_rows INTEGER DEFAULT 100
)
RETURNS JSON
LANGUAGE plpgsql
AS $$
DECLARE
    v_query tsquery;
    v_result JSON;
BEGIN
    -- Use phraseto_tsquery for exact phrase matching
    v_query := phraseto_tsquery('english', p_search_phrase);
    
    CASE p_table_name
        WHEN 'people' THEN
            SELECT json_build_object('Results', json_agg(data))
            INTO v_result
            FROM (
                SELECT person_id AS id, full_name AS name, ts_rank(search_vector, v_query) AS rank
                FROM application.people
                WHERE search_vector @@ v_query
                ORDER BY rank DESC
                LIMIT p_maximum_rows
            ) AS data;
        WHEN 'customers' THEN
            SELECT json_build_object('Results', json_agg(data))
            INTO v_result
            FROM (
                SELECT customer_id AS id, customer_name AS name, ts_rank(search_vector, v_query) AS rank
                FROM sales.customers
                WHERE search_vector @@ v_query
                ORDER BY rank DESC
                LIMIT p_maximum_rows
            ) AS data;
        WHEN 'suppliers' THEN
            SELECT json_build_object('Results', json_agg(data))
            INTO v_result
            FROM (
                SELECT supplier_id AS id, supplier_name AS name, ts_rank(search_vector, v_query) AS rank
                FROM purchasing.suppliers
                WHERE search_vector @@ v_query
                ORDER BY rank DESC
                LIMIT p_maximum_rows
            ) AS data;
        WHEN 'stock_items' THEN
            SELECT json_build_object('Results', json_agg(data))
            INTO v_result
            FROM (
                SELECT stock_item_id AS id, stock_item_name AS name, ts_rank(search_vector, v_query) AS rank
                FROM warehouse.stock_items
                WHERE search_vector @@ v_query
                ORDER BY rank DESC
                LIMIT p_maximum_rows
            ) AS data;
        ELSE
            v_result := '{"error": "Unknown table name"}';
    END CASE;

    RETURN COALESCE(v_result, '{"Results": []}');
END;
$$;

-- Function for websearch (Google-like search syntax)
CREATE OR REPLACE FUNCTION website.fts_websearch(
    p_table_name TEXT,
    p_search_text TEXT,
    p_maximum_rows INTEGER DEFAULT 100
)
RETURNS JSON
LANGUAGE plpgsql
AS $$
DECLARE
    v_query tsquery;
    v_result JSON;
BEGIN
    -- Use websearch_to_tsquery for Google-like search syntax
    -- Supports: "quoted phrases", -negation, OR
    v_query := websearch_to_tsquery('english', p_search_text);
    
    CASE p_table_name
        WHEN 'people' THEN
            SELECT json_build_object('Results', json_agg(data))
            INTO v_result
            FROM (
                SELECT person_id AS id, full_name AS name, 
                       ts_headline('english', full_name || ' ' || COALESCE(preferred_name, ''), v_query) AS headline,
                       ts_rank(search_vector, v_query) AS rank
                FROM application.people
                WHERE search_vector @@ v_query
                ORDER BY rank DESC
                LIMIT p_maximum_rows
            ) AS data;
        WHEN 'customers' THEN
            SELECT json_build_object('Results', json_agg(data))
            INTO v_result
            FROM (
                SELECT customer_id AS id, customer_name AS name,
                       ts_headline('english', customer_name, v_query) AS headline,
                       ts_rank(search_vector, v_query) AS rank
                FROM sales.customers
                WHERE search_vector @@ v_query
                ORDER BY rank DESC
                LIMIT p_maximum_rows
            ) AS data;
        WHEN 'suppliers' THEN
            SELECT json_build_object('Results', json_agg(data))
            INTO v_result
            FROM (
                SELECT supplier_id AS id, supplier_name AS name,
                       ts_headline('english', supplier_name, v_query) AS headline,
                       ts_rank(search_vector, v_query) AS rank
                FROM purchasing.suppliers
                WHERE search_vector @@ v_query
                ORDER BY rank DESC
                LIMIT p_maximum_rows
            ) AS data;
        WHEN 'stock_items' THEN
            SELECT json_build_object('Results', json_agg(data))
            INTO v_result
            FROM (
                SELECT stock_item_id AS id, stock_item_name AS name,
                       ts_headline('english', stock_item_name || ' ' || COALESCE(marketing_comments, ''), v_query) AS headline,
                       ts_rank(search_vector, v_query) AS rank
                FROM warehouse.stock_items
                WHERE search_vector @@ v_query
                ORDER BY rank DESC
                LIMIT p_maximum_rows
            ) AS data;
        ELSE
            v_result := '{"error": "Unknown table name"}';
    END CASE;

    RETURN COALESCE(v_result, '{"Results": []}');
END;
$$;

-- Add comments for documentation
COMMENT ON FUNCTION website.fts_search_people IS 'Full-text search for people using PostgreSQL tsvector';
COMMENT ON FUNCTION website.fts_search_customers IS 'Full-text search for customers using PostgreSQL tsvector';
COMMENT ON FUNCTION website.fts_search_suppliers IS 'Full-text search for suppliers using PostgreSQL tsvector';
COMMENT ON FUNCTION website.fts_search_stock_items IS 'Full-text search for stock items using PostgreSQL tsvector';
COMMENT ON FUNCTION website.fts_phrase_search IS 'Exact phrase search across tables';
COMMENT ON FUNCTION website.fts_websearch IS 'Google-like search syntax across tables';

-- Example usage:
-- SELECT * FROM website.fts_search_customers('tailspin toys', 10);
-- SELECT * FROM website.fts_websearch('stock_items', '"USB" OR "flash" -broken', 20);
