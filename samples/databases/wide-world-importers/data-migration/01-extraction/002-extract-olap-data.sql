-- Wide World Importers PostgreSQL Migration
-- Phase 6: Data Migration and Validation
-- File: 002-extract-olap-data.sql
-- Description: SQL Server extraction queries for OLAP database (WideWorldImportersDW)
-- 
-- Usage: Run these queries against SQL Server to export data to CSV files
-- Use BCP or SQLCMD with -s "," -W options for CSV output

-- =============================================
-- Dimension Tables
-- =============================================

-- Dimension.City
SELECT 
    [City Key] AS city_key,
    [WWI City ID] AS wwi_city_id,
    City AS city,
    [State Province] AS state_province,
    Country AS country,
    Continent AS continent,
    [Sales Territory] AS sales_territory,
    Region AS region,
    Subregion AS subregion,
    Location.STAsText() AS location,
    [Latest Recorded Population] AS latest_recorded_population,
    [Valid From] AS valid_from,
    [Valid To] AS valid_to,
    [Lineage Key] AS lineage_key
FROM Dimension.City
ORDER BY [City Key];

-- Dimension.Customer
SELECT 
    [Customer Key] AS customer_key,
    [WWI Customer ID] AS wwi_customer_id,
    Customer AS customer,
    [Bill To Customer] AS bill_to_customer,
    Category AS category,
    [Buying Group] AS buying_group,
    [Primary Contact] AS primary_contact,
    [Postal Code] AS postal_code,
    [Valid From] AS valid_from,
    [Valid To] AS valid_to,
    [Lineage Key] AS lineage_key
FROM Dimension.Customer
ORDER BY [Customer Key];

-- Dimension.Date
SELECT 
    Date AS date,
    [Date Key] AS date_key,
    [Day Number] AS day_number,
    Day AS day,
    [Day of Year] AS day_of_year,
    [Day of Year Number] AS day_of_year_number,
    [Day of Week] AS day_of_week,
    [Day of Week Number] AS day_of_week_number,
    [Week of Year] AS week_of_year,
    Month AS month,
    [Short Month] AS short_month,
    Quarter AS quarter,
    [Half of Year] AS half_of_year,
    [Beginning of Month] AS beginning_of_month,
    [Beginning of Quarter] AS beginning_of_quarter,
    [Beginning of Half Year] AS beginning_of_half_year,
    [Beginning of Year] AS beginning_of_year,
    [Beginning of Month Label] AS beginning_of_month_label,
    [Beginning of Month Label Short] AS beginning_of_month_label_short,
    [Beginning of Quarter Label] AS beginning_of_quarter_label,
    [Beginning of Quarter Label Short] AS beginning_of_quarter_label_short,
    [Beginning of Half Year Label] AS beginning_of_half_year_label,
    [Beginning of Half Year Label Short] AS beginning_of_half_year_label_short,
    [Beginning of Year Label] AS beginning_of_year_label,
    [Beginning of Year Label Short] AS beginning_of_year_label_short,
    [Calendar Day Label] AS calendar_day_label,
    [Calendar Day Label Short] AS calendar_day_label_short,
    [Calendar Week Number] AS calendar_week_number,
    [Calendar Week Label] AS calendar_week_label,
    [Calendar Month Number] AS calendar_month_number,
    [Calendar Month Label] AS calendar_month_label,
    [Calendar Month Year Label] AS calendar_month_year_label,
    [Calendar Quarter Number] AS calendar_quarter_number,
    [Calendar Quarter Label] AS calendar_quarter_label,
    [Calendar Quarter Year Label] AS calendar_quarter_year_label,
    [Calendar Half of Year Number] AS calendar_half_of_year_number,
    [Calendar Half of Year Label] AS calendar_half_of_year_label,
    [Calendar Year Half of Year Label] AS calendar_year_half_of_year_label,
    [Calendar Year] AS calendar_year,
    [Calendar Year Label] AS calendar_year_label,
    [Fiscal Month Number] AS fiscal_month_number,
    [Fiscal Month Label] AS fiscal_month_label,
    [Fiscal Quarter Number] AS fiscal_quarter_number,
    [Fiscal Quarter Label] AS fiscal_quarter_label,
    [Fiscal Half of Year Number] AS fiscal_half_of_year_number,
    [Fiscal Half of Year Label] AS fiscal_half_of_year_label,
    [Fiscal Year] AS fiscal_year,
    [Fiscal Year Label] AS fiscal_year_label,
    [Date Key Alt] AS date_key_alt,
    [Year Week Key] AS year_week_key,
    [Year Month Key] AS year_month_key,
    [Year Quarter Key] AS year_quarter_key,
    [Year Half of Year Key] AS year_half_of_year_key,
    [Year Key] AS year_key,
    [Beginning of Month Key] AS beginning_of_month_key,
    [Beginning of Quarter Key] AS beginning_of_quarter_key,
    [Beginning of Half Year Key] AS beginning_of_half_year_key,
    [Beginning of Year Key] AS beginning_of_year_key,
    [Fiscal Year Month Key] AS fiscal_year_month_key,
    [Fiscal Year Quarter Key] AS fiscal_year_quarter_key,
    [Fiscal Year Half of Year Key] AS fiscal_year_half_of_year_key,
    [ISO Week Number] AS iso_week_number
FROM Dimension.Date
ORDER BY Date;

-- Dimension.Employee
SELECT 
    [Employee Key] AS employee_key,
    [WWI Employee ID] AS wwi_employee_id,
    Employee AS employee,
    [Preferred Name] AS preferred_name,
    [Is Salesperson] AS is_salesperson,
    CONVERT(VARCHAR(MAX), Photo, 1) AS photo,
    [Valid From] AS valid_from,
    [Valid To] AS valid_to,
    [Lineage Key] AS lineage_key
FROM Dimension.Employee
ORDER BY [Employee Key];

-- Dimension.[Payment Method]
SELECT 
    [Payment Method Key] AS payment_method_key,
    [WWI Payment Method ID] AS wwi_payment_method_id,
    [Payment Method] AS payment_method,
    [Valid From] AS valid_from,
    [Valid To] AS valid_to,
    [Lineage Key] AS lineage_key
FROM Dimension.[Payment Method]
ORDER BY [Payment Method Key];

-- Dimension.[Stock Item]
SELECT 
    [Stock Item Key] AS stock_item_key,
    [WWI Stock Item ID] AS wwi_stock_item_id,
    [Stock Item] AS stock_item,
    Color AS color,
    [Selling Package] AS selling_package,
    [Buying Package] AS buying_package,
    Brand AS brand,
    Size AS size,
    [Lead Time Days] AS lead_time_days,
    [Quantity Per Outer] AS quantity_per_outer,
    [Is Chiller Stock] AS is_chiller_stock,
    Barcode AS barcode,
    [Tax Rate] AS tax_rate,
    [Unit Price] AS unit_price,
    [Recommended Retail Price] AS recommended_retail_price,
    [Typical Weight Per Unit] AS typical_weight_per_unit,
    CONVERT(VARCHAR(MAX), Photo, 1) AS photo,
    [Valid From] AS valid_from,
    [Valid To] AS valid_to,
    [Lineage Key] AS lineage_key
FROM Dimension.[Stock Item]
ORDER BY [Stock Item Key];

-- Dimension.Supplier
SELECT 
    [Supplier Key] AS supplier_key,
    [WWI Supplier ID] AS wwi_supplier_id,
    Supplier AS supplier,
    Category AS category,
    [Primary Contact] AS primary_contact,
    [Supplier Reference] AS supplier_reference,
    [Payment Days] AS payment_days,
    [Postal Code] AS postal_code,
    [Valid From] AS valid_from,
    [Valid To] AS valid_to,
    [Lineage Key] AS lineage_key
FROM Dimension.Supplier
ORDER BY [Supplier Key];

-- Dimension.[Transaction Type]
SELECT 
    [Transaction Type Key] AS transaction_type_key,
    [WWI Transaction Type ID] AS wwi_transaction_type_id,
    [Transaction Type] AS transaction_type,
    [Valid From] AS valid_from,
    [Valid To] AS valid_to,
    [Lineage Key] AS lineage_key
FROM Dimension.[Transaction Type]
ORDER BY [Transaction Type Key];

-- =============================================
-- Fact Tables
-- =============================================

-- Fact.Sale
SELECT 
    [Sale Key] AS sale_key,
    [City Key] AS city_key,
    [Customer Key] AS customer_key,
    [Bill To Customer Key] AS bill_to_customer_key,
    [Stock Item Key] AS stock_item_key,
    [Invoice Date Key] AS invoice_date_key,
    [Delivery Date Key] AS delivery_date_key,
    [Salesperson Key] AS salesperson_key,
    [WWI Invoice ID] AS wwi_invoice_id,
    Description AS description,
    Package AS package,
    Quantity AS quantity,
    [Unit Price] AS unit_price,
    [Tax Rate] AS tax_rate,
    [Total Excluding Tax] AS total_excluding_tax,
    [Tax Amount] AS tax_amount,
    Profit AS profit,
    [Total Including Tax] AS total_including_tax,
    [Total Dry Items] AS total_dry_items,
    [Total Chiller Items] AS total_chiller_items,
    [Lineage Key] AS lineage_key
FROM Fact.Sale
ORDER BY [Sale Key];

-- Fact.[Order]
SELECT 
    [Order Key] AS order_key,
    [City Key] AS city_key,
    [Customer Key] AS customer_key,
    [Stock Item Key] AS stock_item_key,
    [Order Date Key] AS order_date_key,
    [Picked Date Key] AS picked_date_key,
    [Salesperson Key] AS salesperson_key,
    [Picker Key] AS picker_key,
    [WWI Order ID] AS wwi_order_id,
    [WWI Backorder ID] AS wwi_backorder_id,
    Description AS description,
    Package AS package,
    Quantity AS quantity,
    [Unit Price] AS unit_price,
    [Tax Rate] AS tax_rate,
    [Total Excluding Tax] AS total_excluding_tax,
    [Tax Amount] AS tax_amount,
    [Total Including Tax] AS total_including_tax,
    [Lineage Key] AS lineage_key
FROM Fact.[Order]
ORDER BY [Order Key];

-- Fact.Purchase
SELECT 
    [Purchase Key] AS purchase_key,
    [Date Key] AS date_key,
    [Supplier Key] AS supplier_key,
    [Stock Item Key] AS stock_item_key,
    [WWI Purchase Order ID] AS wwi_purchase_order_id,
    [Ordered Outers] AS ordered_outers,
    [Ordered Quantity] AS ordered_quantity,
    [Received Outers] AS received_outers,
    Package AS package,
    [Is Order Finalized] AS is_order_finalized,
    [Lineage Key] AS lineage_key
FROM Fact.Purchase
ORDER BY [Purchase Key];

-- Fact.Movement
SELECT 
    [Movement Key] AS movement_key,
    [Date Key] AS date_key,
    [Stock Item Key] AS stock_item_key,
    [Customer Key] AS customer_key,
    [Supplier Key] AS supplier_key,
    [Transaction Type Key] AS transaction_type_key,
    [WWI Stock Item Transaction ID] AS wwi_stock_item_transaction_id,
    [WWI Invoice ID] AS wwi_invoice_id,
    [WWI Purchase Order ID] AS wwi_purchase_order_id,
    Quantity AS quantity,
    [Lineage Key] AS lineage_key
FROM Fact.Movement
ORDER BY [Movement Key];

-- Fact.[Transaction]
SELECT 
    [Transaction Key] AS transaction_key,
    [Date Key] AS date_key,
    [Customer Key] AS customer_key,
    [Bill To Customer Key] AS bill_to_customer_key,
    [Supplier Key] AS supplier_key,
    [Transaction Type Key] AS transaction_type_key,
    [Payment Method Key] AS payment_method_key,
    [WWI Customer Transaction ID] AS wwi_customer_transaction_id,
    [WWI Supplier Transaction ID] AS wwi_supplier_transaction_id,
    [WWI Invoice ID] AS wwi_invoice_id,
    [WWI Purchase Order ID] AS wwi_purchase_order_id,
    [Supplier Invoice Number] AS supplier_invoice_number,
    [Total Excluding Tax] AS total_excluding_tax,
    [Tax Amount] AS tax_amount,
    [Total Including Tax] AS total_including_tax,
    [Outstanding Balance] AS outstanding_balance,
    [Is Finalized] AS is_finalized,
    [Lineage Key] AS lineage_key
FROM Fact.[Transaction]
ORDER BY [Transaction Key];

-- Fact.[Stock Holding]
SELECT 
    [Stock Holding Key] AS stock_holding_key,
    [Stock Item Key] AS stock_item_key,
    [Quantity On Hand] AS quantity_on_hand,
    [Bin Location] AS bin_location,
    [Last Stocktake Quantity] AS last_stocktake_quantity,
    [Last Cost Price] AS last_cost_price,
    [Reorder Level] AS reorder_level,
    [Target Stock Level] AS target_stock_level,
    [Lineage Key] AS lineage_key
FROM Fact.[Stock Holding]
ORDER BY [Stock Holding Key];

-- =============================================
-- Integration Tables (ETL Control)
-- =============================================

-- Integration.ETL Cutoff
SELECT 
    [Table Name] AS table_name,
    [Cutoff Time] AS cutoff_time
FROM Integration.[ETL Cutoff]
ORDER BY [Table Name];

-- Integration.Lineage
SELECT 
    [Lineage Key] AS lineage_key,
    [Data Load Started] AS data_load_started,
    [Table Name] AS table_name,
    [Data Load Completed] AS data_load_completed,
    [Was Successful] AS was_successful,
    [Source System Cutoff Time] AS source_system_cutoff_time
FROM Integration.Lineage
ORDER BY [Lineage Key];
