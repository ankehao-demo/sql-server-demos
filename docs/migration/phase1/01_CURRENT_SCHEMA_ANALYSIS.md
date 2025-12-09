# Wide World Importers - Current SQL Server Schema Analysis

This document provides a comprehensive analysis of the existing Wide World Importers SQL Server database structure, including all tables, relationships, constraints, indexes, stored procedures, views, triggers, and Row-Level Security implementations.

## Executive Summary

The Wide World Importers database is a sample OLTP database that demonstrates many SQL Server features. It represents a wholesale novelty goods importer and distributor operating from the San Francisco bay area. The database contains 33 tables organized across 7 schemas, with extensive use of SQL Server-specific features including temporal tables, memory-optimized tables, columnstore indexes, full-text search, JSON support, spatial data types, Row-Level Security, and Dynamic Data Masking.

## Database Schemas

The database is organized into the following schemas:

| Schema | Purpose | Table Count |
|--------|---------|-------------|
| Application | Core reference data (people, locations, system parameters) | 10 tables |
| Sales | Customer orders, invoices, and transactions | 10 tables |
| Purchasing | Supplier orders and transactions | 7 tables |
| Warehouse | Stock items, inventory, and temperature monitoring | 10 tables |
| DataLoadSimulation | Data generation for testing | 4 tables |
| Integration | ETL support for data warehouse | 0 tables (stored procedures only) |
| Sequences | ID generation sequences | 0 tables (sequences only) |
| WebApi | API views and stored procedures | 0 tables (views only) |
| Website | Web application support | 0 tables (views and procedures) |

## Table Inventory

### Application Schema

#### Application.People
Primary entity table for all people in the system (staff, customer contacts, supplier contacts).

| Column | Data Type | Nullable | Description |
|--------|-----------|----------|-------------|
| PersonID | INT | NOT NULL | Primary key (sequence-generated) |
| FullName | NVARCHAR(50) | NOT NULL | Full name |
| PreferredName | NVARCHAR(50) | NOT NULL | Preferred name |
| SearchName | AS (computed) | NOT NULL | Computed: concat(PreferredName, ' ', FullName) PERSISTED |
| IsPermittedToLogon | BIT | NOT NULL | Login permission flag |
| LogonName | NVARCHAR(256) | NULL | System logon name |
| IsExternalLogonProvider | BIT | NOT NULL | External auth flag |
| HashedPassword | VARBINARY(MAX) | NULL | Password hash |
| IsSystemUser | BIT | NOT NULL | System user flag |
| IsEmployee | BIT | NOT NULL | Employee flag |
| IsSalesperson | BIT | NOT NULL | Salesperson flag |
| UserPreferences | NVARCHAR(MAX) | NULL | JSON user preferences |
| PhoneNumber | NVARCHAR(20) | NULL | Phone number |
| FaxNumber | NVARCHAR(20) | NULL | Fax number |
| EmailAddress | NVARCHAR(256) | NULL | Email address |
| Photo | VARBINARY(MAX) | NULL | Photo binary data |
| CustomFields | NVARCHAR(MAX) | NULL | JSON custom fields |
| OtherLanguages | AS (computed) | - | Computed: json_query(CustomFields, '$.OtherLanguages') |
| LastEditedBy | INT | NOT NULL | FK to People |
| ValidFrom | DATETIME2(7) | NOT NULL | Temporal: row start |
| ValidTo | DATETIME2(7) | NOT NULL | Temporal: row end |

**Constraints:**
- PK_Application_People (PRIMARY KEY on PersonID)
- FK_Application_People_Application_People (FOREIGN KEY LastEditedBy -> PersonID)

**Indexes:**
- IX_Application_People_IsEmployee (IsEmployee)
- IX_Application_People_IsSalesperson (IsSalesperson)
- IX_Application_People_FullName (FullName)
- IX_Application_People_Perf_20160301_05 (IsPermittedToLogon, PersonID) INCLUDE (FullName, EmailAddress)

**Special Features:**
- Temporal table with history in Application.People_Archive
- Computed columns using JSON functions
- Full-text index on SearchName, CustomFields, OtherLanguages

#### Application.Countries
Countries reference table with geographic boundaries.

| Column | Data Type | Nullable | Description |
|--------|-----------|----------|-------------|
| CountryID | INT | NOT NULL | Primary key (sequence-generated) |
| CountryName | NVARCHAR(60) | NOT NULL | Country name |
| FormalName | NVARCHAR(60) | NOT NULL | UN formal name |
| IsoAlpha3Code | NVARCHAR(3) | NULL | ISO 3-letter code |
| IsoNumericCode | INT | NULL | ISO numeric code |
| CountryType | NVARCHAR(20) | NULL | Country type |
| LatestRecordedPopulation | BIGINT | NULL | Population |
| Continent | NVARCHAR(30) | NOT NULL | Continent name |
| Region | NVARCHAR(30) | NOT NULL | Region name |
| Subregion | NVARCHAR(30) | NOT NULL | Subregion name |
| Border | geography | NULL | Geographic boundary |
| LastEditedBy | INT | NOT NULL | FK to People |
| ValidFrom | DATETIME2(7) | NOT NULL | Temporal: row start |
| ValidTo | DATETIME2(7) | NOT NULL | Temporal: row end |

**Constraints:**
- PK_Application_Countries (PRIMARY KEY on CountryID)
- UQ_Application_Countries_CountryName (UNIQUE on CountryName)
- UQ_Application_Countries_FormalName (UNIQUE on FormalName)
- FK_Application_Countries_Application_People (FOREIGN KEY LastEditedBy -> People.PersonID)

**Special Features:**
- Temporal table with history in Application.Countries_Archive
- Geography data type for spatial boundaries

#### Application.StateProvinces
States/provinces with sales territory assignments.

| Column | Data Type | Nullable | Description |
|--------|-----------|----------|-------------|
| StateProvinceID | INT | NOT NULL | Primary key (sequence-generated) |
| StateProvinceCode | NVARCHAR(5) | NOT NULL | State code (e.g., WA) |
| StateProvinceName | NVARCHAR(50) | NOT NULL | State name |
| CountryID | INT | NOT NULL | FK to Countries |
| SalesTerritory | NVARCHAR(50) | NOT NULL | Sales territory name |
| Border | geography | NULL | Geographic boundary |
| LatestRecordedPopulation | BIGINT | NULL | Population |
| LastEditedBy | INT | NOT NULL | FK to People |
| ValidFrom | DATETIME2(7) | NOT NULL | Temporal: row start |
| ValidTo | DATETIME2(7) | NOT NULL | Temporal: row end |

**Constraints:**
- PK_Application_StateProvinces (PRIMARY KEY on StateProvinceID)
- UQ_Application_StateProvinces_StateProvinceName (UNIQUE on StateProvinceName)
- FK_Application_StateProvinces_CountryID_Application_Countries (FOREIGN KEY CountryID -> Countries.CountryID)
- FK_Application_StateProvinces_Application_People (FOREIGN KEY LastEditedBy -> People.PersonID)

**Indexes:**
- FK_Application_StateProvinces_CountryID (CountryID)
- IX_Application_StateProvinces_SalesTerritory (SalesTerritory)

**Special Features:**
- Temporal table with history in Application.StateProvinces_Archive
- Geography data type for spatial boundaries
- SalesTerritory used for Row-Level Security

#### Application.Cities
Cities with geographic locations.

| Column | Data Type | Nullable | Description |
|--------|-----------|----------|-------------|
| CityID | INT | NOT NULL | Primary key (sequence-generated) |
| CityName | NVARCHAR(50) | NOT NULL | City name |
| StateProvinceID | INT | NOT NULL | FK to StateProvinces |
| Location | geography | NULL | Geographic point location |
| LatestRecordedPopulation | BIGINT | NULL | Population |
| LastEditedBy | INT | NOT NULL | FK to People |
| ValidFrom | DATETIME2(7) | NOT NULL | Temporal: row start |
| ValidTo | DATETIME2(7) | NOT NULL | Temporal: row end |

**Constraints:**
- PK_Application_Cities (PRIMARY KEY on CityID)
- FK_Application_Cities_StateProvinceID_Application_StateProvinces (FOREIGN KEY StateProvinceID -> StateProvinces.StateProvinceID)
- FK_Application_Cities_Application_People (FOREIGN KEY LastEditedBy -> People.PersonID)

**Indexes:**
- FK_Application_Cities_StateProvinceID (StateProvinceID)

**Special Features:**
- Temporal table with history in Application.Cities_Archive
- Geography data type for spatial location
- Used in Row-Level Security predicate function

#### Application.DeliveryMethods
Delivery method reference table.

| Column | Data Type | Nullable | Description |
|--------|-----------|----------|-------------|
| DeliveryMethodID | INT | NOT NULL | Primary key (sequence-generated) |
| DeliveryMethodName | NVARCHAR(50) | NOT NULL | Method name |
| LastEditedBy | INT | NOT NULL | FK to People |
| ValidFrom | DATETIME2(7) | NOT NULL | Temporal: row start |
| ValidTo | DATETIME2(7) | NOT NULL | Temporal: row end |

**Special Features:**
- Temporal table with history in Application.DeliveryMethods_Archive

#### Application.PaymentMethods
Payment method reference table.

| Column | Data Type | Nullable | Description |
|--------|-----------|----------|-------------|
| PaymentMethodID | INT | NOT NULL | Primary key (sequence-generated) |
| PaymentMethodName | NVARCHAR(50) | NOT NULL | Method name |
| LastEditedBy | INT | NOT NULL | FK to People |
| ValidFrom | DATETIME2(7) | NOT NULL | Temporal: row start |
| ValidTo | DATETIME2(7) | NOT NULL | Temporal: row end |

**Special Features:**
- Temporal table with history in Application.PaymentMethods_Archive

#### Application.TransactionTypes
Transaction type reference table.

| Column | Data Type | Nullable | Description |
|--------|-----------|----------|-------------|
| TransactionTypeID | INT | NOT NULL | Primary key (sequence-generated) |
| TransactionTypeName | NVARCHAR(50) | NOT NULL | Type name |
| LastEditedBy | INT | NOT NULL | FK to People |
| ValidFrom | DATETIME2(7) | NOT NULL | Temporal: row start |
| ValidTo | DATETIME2(7) | NOT NULL | Temporal: row end |

**Special Features:**
- Temporal table with history in Application.TransactionTypes_Archive

#### Application.SystemParameters
System configuration parameters.

| Column | Data Type | Nullable | Description |
|--------|-----------|----------|-------------|
| SystemParameterID | INT | NOT NULL | Primary key |
| DeliveryAddressLine1 | NVARCHAR(60) | NOT NULL | Company address line 1 |
| DeliveryAddressLine2 | NVARCHAR(60) | NULL | Company address line 2 |
| DeliveryCityID | INT | NOT NULL | FK to Cities |
| DeliveryPostalCode | NVARCHAR(10) | NOT NULL | Postal code |
| DeliveryLocation | geography | NOT NULL | Geographic location |
| PostalAddressLine1 | NVARCHAR(60) | NOT NULL | Postal address line 1 |
| PostalAddressLine2 | NVARCHAR(60) | NULL | Postal address line 2 |
| PostalCityID | INT | NOT NULL | FK to Cities |
| PostalPostalCode | NVARCHAR(10) | NOT NULL | Postal code |
| ApplicationSettings | NVARCHAR(MAX) | NOT NULL | JSON application settings |
| LastEditedBy | INT | NOT NULL | FK to People |
| LastEditedWhen | DATETIME2(7) | NOT NULL | Last edit timestamp |

#### Application.Logs
Application logging table.

| Column | Data Type | Nullable | Description |
|--------|-----------|----------|-------------|
| LogID | BIGINT | NOT NULL | Primary key (identity) |
| LoggedWhen | DATETIME2(7) | NOT NULL | Log timestamp |
| LoggedBy | NVARCHAR(256) | NOT NULL | User who logged |
| LogText | NVARCHAR(MAX) | NOT NULL | Log message |

### Sales Schema

#### Sales.Customers
Main customer entity table.

| Column | Data Type | Nullable | Description |
|--------|-----------|----------|-------------|
| CustomerID | INT | NOT NULL | Primary key (sequence-generated) |
| CustomerName | NVARCHAR(100) | NOT NULL | Customer name |
| BillToCustomerID | INT | NOT NULL | FK to Customers (self-reference) |
| CustomerCategoryID | INT | NOT NULL | FK to CustomerCategories |
| BuyingGroupID | INT | NULL | FK to BuyingGroups |
| PrimaryContactPersonID | INT | NOT NULL | FK to People |
| AlternateContactPersonID | INT | NULL | FK to People |
| DeliveryMethodID | INT | NOT NULL | FK to DeliveryMethods |
| DeliveryCityID | INT | NOT NULL | FK to Cities |
| PostalCityID | INT | NOT NULL | FK to Cities |
| CreditLimit | DECIMAL(18,2) | NULL | Credit limit |
| AccountOpenedDate | DATE | NOT NULL | Account opened date |
| StandardDiscountPercentage | DECIMAL(18,3) | NOT NULL | Standard discount |
| IsStatementSent | BIT | NOT NULL | Statement sent flag |
| IsOnCreditHold | BIT | NOT NULL | Credit hold flag |
| PaymentDays | INT | NOT NULL | Payment terms (days) |
| PhoneNumber | NVARCHAR(20) | NOT NULL | Phone number |
| FaxNumber | NVARCHAR(20) | NOT NULL | Fax number |
| DeliveryRun | NVARCHAR(5) | NULL | Delivery run |
| RunPosition | NVARCHAR(5) | NULL | Position in run |
| WebsiteURL | NVARCHAR(256) | NOT NULL | Website URL |
| DeliveryAddressLine1 | NVARCHAR(60) | NOT NULL | Delivery address line 1 |
| DeliveryAddressLine2 | NVARCHAR(60) | NULL | Delivery address line 2 |
| DeliveryPostalCode | NVARCHAR(10) | NOT NULL | Delivery postal code |
| DeliveryLocation | geography | NULL | Delivery geographic location |
| PostalAddressLine1 | NVARCHAR(60) | NOT NULL | Postal address line 1 |
| PostalAddressLine2 | NVARCHAR(60) | NULL | Postal address line 2 |
| PostalPostalCode | NVARCHAR(10) | NOT NULL | Postal postal code |
| LastEditedBy | INT | NOT NULL | FK to People |
| ValidFrom | DATETIME2(7) | NOT NULL | Temporal: row start |
| ValidTo | DATETIME2(7) | NOT NULL | Temporal: row end |

**Constraints:**
- PK_Sales_Customers (PRIMARY KEY on CustomerID)
- UQ_Sales_Customers_CustomerName (UNIQUE on CustomerName)
- FK_Sales_Customers_BillToCustomerID_Sales_Customers (self-referential FK)
- FK_Sales_Customers_CustomerCategoryID_Sales_CustomerCategories
- FK_Sales_Customers_BuyingGroupID_Sales_BuyingGroups
- FK_Sales_Customers_PrimaryContactPersonID_Application_People
- FK_Sales_Customers_AlternateContactPersonID_Application_People
- FK_Sales_Customers_DeliveryMethodID_Application_DeliveryMethods
- FK_Sales_Customers_DeliveryCityID_Application_Cities
- FK_Sales_Customers_PostalCityID_Application_Cities
- FK_Sales_Customers_Application_People (LastEditedBy)

**Indexes:**
- FK_Sales_Customers_CustomerCategoryID
- FK_Sales_Customers_BuyingGroupID
- FK_Sales_Customers_PrimaryContactPersonID
- FK_Sales_Customers_AlternateContactPersonID
- FK_Sales_Customers_DeliveryMethodID
- FK_Sales_Customers_DeliveryCityID
- FK_Sales_Customers_PostalCityID
- IX_Sales_Customers_Perf_20160301_06 (IsOnCreditHold, CustomerID, BillToCustomerID) INCLUDE (PrimaryContactPersonID)

**Special Features:**
- Temporal table with history in Sales.Customers_Archive
- Geography data type for delivery location
- Full-text index on CustomerName
- Row-Level Security policy applied (FilterCustomersBySalesTerritoryRole)

#### Sales.CustomerCategories
Customer category reference table.

| Column | Data Type | Nullable | Description |
|--------|-----------|----------|-------------|
| CustomerCategoryID | INT | NOT NULL | Primary key (sequence-generated) |
| CustomerCategoryName | NVARCHAR(50) | NOT NULL | Category name |
| LastEditedBy | INT | NOT NULL | FK to People |
| ValidFrom | DATETIME2(7) | NOT NULL | Temporal: row start |
| ValidTo | DATETIME2(7) | NOT NULL | Temporal: row end |

**Special Features:**
- Temporal table with history in Sales.CustomerCategories_Archive

#### Sales.BuyingGroups
Buying group reference table.

| Column | Data Type | Nullable | Description |
|--------|-----------|----------|-------------|
| BuyingGroupID | INT | NOT NULL | Primary key (sequence-generated) |
| BuyingGroupName | NVARCHAR(50) | NOT NULL | Group name |
| LastEditedBy | INT | NOT NULL | FK to People |
| ValidFrom | DATETIME2(7) | NOT NULL | Temporal: row start |
| ValidTo | DATETIME2(7) | NOT NULL | Temporal: row end |

**Special Features:**
- Temporal table with history in Sales.BuyingGroups_Archive

#### Sales.Orders
Customer order header table.

| Column | Data Type | Nullable | Description |
|--------|-----------|----------|-------------|
| OrderID | INT | NOT NULL | Primary key (sequence-generated) |
| CustomerID | INT | NOT NULL | FK to Customers |
| SalespersonPersonID | INT | NOT NULL | FK to People |
| PickedByPersonID | INT | NULL | FK to People |
| ContactPersonID | INT | NOT NULL | FK to People |
| BackorderOrderID | INT | NULL | FK to Orders (self-reference) |
| OrderDate | DATE | NOT NULL | Order date |
| ExpectedDeliveryDate | DATE | NOT NULL | Expected delivery date |
| CustomerPurchaseOrderNumber | NVARCHAR(20) | NULL | Customer PO number |
| IsUndersupplyBackordered | BIT | NOT NULL | Backorder flag |
| Comments | NVARCHAR(MAX) | NULL | Comments |
| DeliveryInstructions | NVARCHAR(MAX) | NULL | Delivery instructions |
| InternalComments | NVARCHAR(MAX) | NULL | Internal comments |
| PickingCompletedWhen | DATETIME2(7) | NULL | Picking completion time |
| LastEditedBy | INT | NOT NULL | FK to People |
| LastEditedWhen | DATETIME2(7) | NOT NULL | Last edit timestamp |

**Constraints:**
- PK_Sales_Orders (PRIMARY KEY on OrderID)
- FK_Sales_Orders_CustomerID_Sales_Customers
- FK_Sales_Orders_SalespersonPersonID_Application_People
- FK_Sales_Orders_PickedByPersonID_Application_People
- FK_Sales_Orders_ContactPersonID_Application_People
- FK_Sales_Orders_BackorderOrderID_Sales_Orders (self-referential)
- FK_Sales_Orders_Application_People (LastEditedBy)

**Indexes:**
- FK_Sales_Orders_CustomerID
- FK_Sales_Orders_SalespersonPersonID
- FK_Sales_Orders_PickedByPersonID
- FK_Sales_Orders_ContactPersonID

#### Sales.OrderLines
Order line items.

| Column | Data Type | Nullable | Description |
|--------|-----------|----------|-------------|
| OrderLineID | INT | NOT NULL | Primary key (sequence-generated) |
| OrderID | INT | NOT NULL | FK to Orders |
| StockItemID | INT | NOT NULL | FK to StockItems |
| Description | NVARCHAR(100) | NOT NULL | Item description |
| PackageTypeID | INT | NOT NULL | FK to PackageTypes |
| Quantity | INT | NOT NULL | Quantity ordered |
| UnitPrice | DECIMAL(18,2) | NULL | Unit price |
| TaxRate | DECIMAL(18,3) | NOT NULL | Tax rate |
| PickedQuantity | INT | NOT NULL | Quantity picked |
| PickingCompletedWhen | DATETIME2(7) | NULL | Picking completion time |
| LastEditedBy | INT | NOT NULL | FK to People |
| LastEditedWhen | DATETIME2(7) | NOT NULL | Last edit timestamp |

**Indexes:**
- FK_Sales_OrderLines_OrderID
- FK_Sales_OrderLines_PackageTypeID
- IX_Sales_OrderLines_AllocatedStockItems (StockItemID) INCLUDE (PickedQuantity)
- IX_Sales_OrderLines_Perf_20160301_01 (PickingCompletedWhen, OrderID, OrderLineID) INCLUDE (Quantity, StockItemID)
- IX_Sales_OrderLines_Perf_20160301_02 (StockItemID, PickingCompletedWhen) INCLUDE (OrderID, PickedQuantity)
- NCCX_Sales_OrderLines (COLUMNSTORE INDEX on OrderID, StockItemID, Description, Quantity, UnitPrice, PickedQuantity, PackageTypeID)

**Special Features:**
- Non-clustered columnstore index for analytics

#### Sales.Invoices
Customer invoice header table.

| Column | Data Type | Nullable | Description |
|--------|-----------|----------|-------------|
| InvoiceID | INT | NOT NULL | Primary key (sequence-generated) |
| CustomerID | INT | NOT NULL | FK to Customers |
| BillToCustomerID | INT | NOT NULL | FK to Customers |
| OrderID | INT | NULL | FK to Orders |
| DeliveryMethodID | INT | NOT NULL | FK to DeliveryMethods |
| ContactPersonID | INT | NOT NULL | FK to People |
| AccountsPersonID | INT | NOT NULL | FK to People |
| SalespersonPersonID | INT | NOT NULL | FK to People |
| PackedByPersonID | INT | NOT NULL | FK to People |
| InvoiceDate | DATE | NOT NULL | Invoice date |
| CustomerPurchaseOrderNumber | NVARCHAR(20) | NULL | Customer PO number |
| IsCreditNote | BIT | NOT NULL | Credit note flag |
| CreditNoteReason | NVARCHAR(MAX) | NULL | Credit note reason |
| Comments | NVARCHAR(MAX) | NULL | Comments |
| DeliveryInstructions | NVARCHAR(MAX) | NULL | Delivery instructions |
| InternalComments | NVARCHAR(MAX) | NULL | Internal comments |
| TotalDryItems | INT | NOT NULL | Total dry items count |
| TotalChillerItems | INT | NOT NULL | Total chiller items count |
| DeliveryRun | NVARCHAR(5) | NULL | Delivery run |
| RunPosition | NVARCHAR(5) | NULL | Position in run |
| ReturnedDeliveryData | NVARCHAR(MAX) | NULL | JSON delivery data |
| ConfirmedDeliveryTime | AS (computed) | - | Computed: TRY_CONVERT(datetime2(7), json_value(ReturnedDeliveryData, '$.DeliveredWhen'), 126) |
| ConfirmedReceivedBy | AS (computed) | - | Computed: json_value(ReturnedDeliveryData, '$.ReceivedBy') |
| LastEditedBy | INT | NOT NULL | FK to People |
| LastEditedWhen | DATETIME2(7) | NOT NULL | Last edit timestamp |

**Constraints:**
- CK_Sales_Invoices_ReturnedDeliveryData_Must_Be_Valid_JSON (CHECK: ReturnedDeliveryData IS NULL OR isjson(ReturnedDeliveryData) <> 0)

**Indexes:**
- IX_Sales_Invoices_ConfirmedDeliveryTime (ConfirmedDeliveryTime) INCLUDE (ConfirmedReceivedBy)

**Special Features:**
- JSON validation check constraint
- Computed columns extracting data from JSON

#### Sales.InvoiceLines
Invoice line items.

| Column | Data Type | Nullable | Description |
|--------|-----------|----------|-------------|
| InvoiceLineID | INT | NOT NULL | Primary key (sequence-generated) |
| InvoiceID | INT | NOT NULL | FK to Invoices |
| StockItemID | INT | NOT NULL | FK to StockItems |
| Description | NVARCHAR(100) | NOT NULL | Item description |
| PackageTypeID | INT | NOT NULL | FK to PackageTypes |
| Quantity | INT | NOT NULL | Quantity |
| UnitPrice | DECIMAL(18,2) | NULL | Unit price |
| TaxRate | DECIMAL(18,3) | NOT NULL | Tax rate |
| TaxAmount | DECIMAL(18,2) | NOT NULL | Tax amount |
| LineProfit | DECIMAL(18,2) | NOT NULL | Line profit |
| ExtendedPrice | DECIMAL(18,2) | NOT NULL | Extended price |
| LastEditedBy | INT | NOT NULL | FK to People |
| LastEditedWhen | DATETIME2(7) | NOT NULL | Last edit timestamp |

**Indexes:**
- NCCX_Sales_InvoiceLines (COLUMNSTORE INDEX on InvoiceID, StockItemID, Quantity, UnitPrice, LineProfit, LastEditedWhen)

**Special Features:**
- Non-clustered columnstore index for analytics

#### Sales.CustomerTransactions
Customer financial transactions.

| Column | Data Type | Nullable | Description |
|--------|-----------|----------|-------------|
| CustomerTransactionID | INT | NOT NULL | Primary key (sequence-generated) |
| CustomerID | INT | NOT NULL | FK to Customers |
| TransactionTypeID | INT | NOT NULL | FK to TransactionTypes |
| InvoiceID | INT | NULL | FK to Invoices |
| PaymentMethodID | INT | NULL | FK to PaymentMethods |
| TransactionDate | DATE | NOT NULL | Transaction date |
| AmountExcludingTax | DECIMAL(18,2) | NOT NULL | Amount excluding tax |
| TaxAmount | DECIMAL(18,2) | NOT NULL | Tax amount |
| TransactionAmount | DECIMAL(18,2) | NOT NULL | Total transaction amount |
| OutstandingBalance | DECIMAL(18,2) | NOT NULL | Outstanding balance |
| FinalizationDate | DATE | NULL | Finalization date |
| IsFinalized | AS (computed) | - | Computed: CASE WHEN FinalizationDate IS NULL THEN 0 ELSE 1 END |
| LastEditedBy | INT | NOT NULL | FK to People |
| LastEditedWhen | DATETIME2(7) | NOT NULL | Last edit timestamp |

#### Sales.SpecialDeals
Special pricing deals.

| Column | Data Type | Nullable | Description |
|--------|-----------|----------|-------------|
| SpecialDealID | INT | NOT NULL | Primary key (sequence-generated) |
| StockItemID | INT | NULL | FK to StockItems |
| CustomerID | INT | NULL | FK to Customers |
| BuyingGroupID | INT | NULL | FK to BuyingGroups |
| CustomerCategoryID | INT | NULL | FK to CustomerCategories |
| StockGroupID | INT | NULL | FK to StockGroups |
| DealDescription | NVARCHAR(30) | NOT NULL | Deal description |
| StartDate | DATE | NOT NULL | Start date |
| EndDate | DATE | NOT NULL | End date |
| DiscountAmount | DECIMAL(18,2) | NULL | Discount amount |
| DiscountPercentage | DECIMAL(18,3) | NULL | Discount percentage |
| UnitPrice | DECIMAL(18,2) | NULL | Special unit price |
| LastEditedBy | INT | NOT NULL | FK to People |
| LastEditedWhen | DATETIME2(7) | NOT NULL | Last edit timestamp |

### Purchasing Schema

#### Purchasing.Suppliers
Main supplier entity table.

| Column | Data Type | Nullable | Description |
|--------|-----------|----------|-------------|
| SupplierID | INT | NOT NULL | Primary key (sequence-generated) |
| SupplierName | NVARCHAR(100) | NOT NULL | Supplier name |
| SupplierCategoryID | INT | NOT NULL | FK to SupplierCategories |
| PrimaryContactPersonID | INT | NOT NULL | FK to People |
| AlternateContactPersonID | INT | NOT NULL | FK to People |
| DeliveryMethodID | INT | NULL | FK to DeliveryMethods |
| DeliveryCityID | INT | NOT NULL | FK to Cities |
| PostalCityID | INT | NOT NULL | FK to Cities |
| SupplierReference | NVARCHAR(20) | NULL | Supplier reference |
| BankAccountName | NVARCHAR(50) MASKED | NULL | Bank account name (MASKED) |
| BankAccountBranch | NVARCHAR(50) MASKED | NULL | Bank branch (MASKED) |
| BankAccountCode | NVARCHAR(20) MASKED | NULL | Bank code (MASKED) |
| BankAccountNumber | NVARCHAR(20) MASKED | NULL | Bank account number (MASKED) |
| BankInternationalCode | NVARCHAR(20) MASKED | NULL | SWIFT code (MASKED) |
| PaymentDays | INT | NOT NULL | Payment terms (days) |
| InternalComments | NVARCHAR(MAX) | NULL | Internal comments |
| PhoneNumber | NVARCHAR(20) | NOT NULL | Phone number |
| FaxNumber | NVARCHAR(20) | NOT NULL | Fax number |
| WebsiteURL | NVARCHAR(256) | NOT NULL | Website URL |
| DeliveryAddressLine1 | NVARCHAR(60) | NOT NULL | Delivery address line 1 |
| DeliveryAddressLine2 | NVARCHAR(60) | NULL | Delivery address line 2 |
| DeliveryPostalCode | NVARCHAR(10) | NOT NULL | Delivery postal code |
| DeliveryLocation | geography | NULL | Delivery geographic location |
| PostalAddressLine1 | NVARCHAR(60) | NOT NULL | Postal address line 1 |
| PostalAddressLine2 | NVARCHAR(60) | NULL | Postal address line 2 |
| PostalPostalCode | NVARCHAR(10) | NOT NULL | Postal postal code |
| LastEditedBy | INT | NOT NULL | FK to People |
| ValidFrom | DATETIME2(7) | NOT NULL | Temporal: row start |
| ValidTo | DATETIME2(7) | NOT NULL | Temporal: row end |

**Special Features:**
- Temporal table with history in Purchasing.Suppliers_Archive
- Dynamic Data Masking on bank account columns
- Full-text index on SupplierName
- Geography data type for delivery location

#### Purchasing.SupplierCategories
Supplier category reference table.

| Column | Data Type | Nullable | Description |
|--------|-----------|----------|-------------|
| SupplierCategoryID | INT | NOT NULL | Primary key (sequence-generated) |
| SupplierCategoryName | NVARCHAR(50) | NOT NULL | Category name |
| LastEditedBy | INT | NOT NULL | FK to People |
| ValidFrom | DATETIME2(7) | NOT NULL | Temporal: row start |
| ValidTo | DATETIME2(7) | NOT NULL | Temporal: row end |

**Special Features:**
- Temporal table with history in Purchasing.SupplierCategories_Archive

#### Purchasing.PurchaseOrders
Purchase order header table.

| Column | Data Type | Nullable | Description |
|--------|-----------|----------|-------------|
| PurchaseOrderID | INT | NOT NULL | Primary key (sequence-generated) |
| SupplierID | INT | NOT NULL | FK to Suppliers |
| OrderDate | DATE | NOT NULL | Order date |
| DeliveryMethodID | INT | NOT NULL | FK to DeliveryMethods |
| ContactPersonID | INT | NOT NULL | FK to People |
| ExpectedDeliveryDate | DATE | NULL | Expected delivery date |
| SupplierReference | NVARCHAR(20) | NULL | Supplier reference |
| IsOrderFinalized | BIT | NOT NULL | Finalized flag |
| Comments | NVARCHAR(MAX) | NULL | Comments |
| InternalComments | NVARCHAR(MAX) | NULL | Internal comments |
| LastEditedBy | INT | NOT NULL | FK to People |
| LastEditedWhen | DATETIME2(7) | NOT NULL | Last edit timestamp |

#### Purchasing.PurchaseOrderLines
Purchase order line items.

| Column | Data Type | Nullable | Description |
|--------|-----------|----------|-------------|
| PurchaseOrderLineID | INT | NOT NULL | Primary key (sequence-generated) |
| PurchaseOrderID | INT | NOT NULL | FK to PurchaseOrders |
| StockItemID | INT | NOT NULL | FK to StockItems |
| OrderedOuters | INT | NOT NULL | Ordered outers |
| Description | NVARCHAR(100) | NOT NULL | Item description |
| ReceivedOuters | INT | NOT NULL | Received outers |
| PackageTypeID | INT | NOT NULL | FK to PackageTypes |
| ExpectedUnitPricePerOuter | DECIMAL(18,2) | NULL | Expected unit price |
| LastReceiptDate | DATE | NULL | Last receipt date |
| IsOrderLineFinalized | BIT | NOT NULL | Finalized flag |
| LastEditedBy | INT | NOT NULL | FK to People |
| LastEditedWhen | DATETIME2(7) | NOT NULL | Last edit timestamp |

#### Purchasing.SupplierTransactions
Supplier financial transactions.

| Column | Data Type | Nullable | Description |
|--------|-----------|----------|-------------|
| SupplierTransactionID | INT | NOT NULL | Primary key (sequence-generated) |
| SupplierID | INT | NOT NULL | FK to Suppliers |
| TransactionTypeID | INT | NOT NULL | FK to TransactionTypes |
| PurchaseOrderID | INT | NULL | FK to PurchaseOrders |
| PaymentMethodID | INT | NULL | FK to PaymentMethods |
| SupplierInvoiceNumber | NVARCHAR(20) | NULL | Supplier invoice number |
| TransactionDate | DATE | NOT NULL | Transaction date |
| AmountExcludingTax | DECIMAL(18,2) | NOT NULL | Amount excluding tax |
| TaxAmount | DECIMAL(18,2) | NOT NULL | Tax amount |
| TransactionAmount | DECIMAL(18,2) | NOT NULL | Total transaction amount |
| OutstandingBalance | DECIMAL(18,2) | NOT NULL | Outstanding balance |
| FinalizationDate | DATE | NULL | Finalization date |
| IsFinalized | AS (computed) | - | Computed: CASE WHEN FinalizationDate IS NULL THEN 0 ELSE 1 END |
| LastEditedBy | INT | NOT NULL | FK to People |
| LastEditedWhen | DATETIME2(7) | NOT NULL | Last edit timestamp |

### Warehouse Schema

#### Warehouse.StockItems
Main stock item entity table.

| Column | Data Type | Nullable | Description |
|--------|-----------|----------|-------------|
| StockItemID | INT | NOT NULL | Primary key (sequence-generated) |
| StockItemName | NVARCHAR(100) | NOT NULL | Stock item name |
| SupplierID | INT | NOT NULL | FK to Suppliers |
| ColorID | INT | NULL | FK to Colors |
| UnitPackageID | INT | NOT NULL | FK to PackageTypes |
| OuterPackageID | INT | NOT NULL | FK to PackageTypes |
| Brand | NVARCHAR(50) | NULL | Brand name |
| Size | NVARCHAR(20) | NULL | Size |
| LeadTimeDays | INT | NOT NULL | Lead time in days |
| QuantityPerOuter | INT | NOT NULL | Quantity per outer |
| IsChillerStock | BIT | NOT NULL | Chiller stock flag |
| Barcode | NVARCHAR(50) | NULL | Barcode |
| TaxRate | DECIMAL(18,3) | NOT NULL | Tax rate |
| UnitPrice | DECIMAL(18,2) | NOT NULL | Unit price |
| RecommendedRetailPrice | DECIMAL(18,2) | NULL | RRP |
| TypicalWeightPerUnit | DECIMAL(18,3) | NOT NULL | Typical weight |
| MarketingComments | NVARCHAR(MAX) | NULL | Marketing comments |
| InternalComments | NVARCHAR(MAX) | NULL | Internal comments |
| Photo | VARBINARY(MAX) | NULL | Photo binary data |
| CustomFields | NVARCHAR(MAX) | NULL | JSON custom fields |
| Tags | AS (computed) | - | Computed: json_query(CustomFields, '$.Tags') |
| SearchDetails | AS (computed) | - | Computed: concat(StockItemName, ' ', MarketingComments) |
| LastEditedBy | INT | NOT NULL | FK to People |
| ValidFrom | DATETIME2(7) | NOT NULL | Temporal: row start |
| ValidTo | DATETIME2(7) | NOT NULL | Temporal: row end |

**Special Features:**
- Temporal table with history in Warehouse.StockItems_Archive
- Computed columns using JSON functions
- Full-text index on SearchDetails, CustomFields, Tags

#### Warehouse.StockGroups
Stock group reference table.

| Column | Data Type | Nullable | Description |
|--------|-----------|----------|-------------|
| StockGroupID | INT | NOT NULL | Primary key (sequence-generated) |
| StockGroupName | NVARCHAR(50) | NOT NULL | Group name |
| LastEditedBy | INT | NOT NULL | FK to People |
| ValidFrom | DATETIME2(7) | NOT NULL | Temporal: row start |
| ValidTo | DATETIME2(7) | NOT NULL | Temporal: row end |

**Special Features:**
- Temporal table with history in Warehouse.StockGroups_Archive

#### Warehouse.StockItemStockGroups
Many-to-many relationship between stock items and stock groups.

| Column | Data Type | Nullable | Description |
|--------|-----------|----------|-------------|
| StockItemStockGroupID | INT | NOT NULL | Primary key (sequence-generated) |
| StockItemID | INT | NOT NULL | FK to StockItems |
| StockGroupID | INT | NOT NULL | FK to StockGroups |
| LastEditedBy | INT | NOT NULL | FK to People |
| LastEditedWhen | DATETIME2(7) | NOT NULL | Last edit timestamp |

#### Warehouse.Colors
Color reference table.

| Column | Data Type | Nullable | Description |
|--------|-----------|----------|-------------|
| ColorID | INT | NOT NULL | Primary key (sequence-generated) |
| ColorName | NVARCHAR(20) | NOT NULL | Color name |
| LastEditedBy | INT | NOT NULL | FK to People |
| ValidFrom | DATETIME2(7) | NOT NULL | Temporal: row start |
| ValidTo | DATETIME2(7) | NOT NULL | Temporal: row end |

**Special Features:**
- Temporal table with history in Warehouse.Colors_Archive

#### Warehouse.PackageTypes
Package type reference table.

| Column | Data Type | Nullable | Description |
|--------|-----------|----------|-------------|
| PackageTypeID | INT | NOT NULL | Primary key (sequence-generated) |
| PackageTypeName | NVARCHAR(50) | NOT NULL | Package type name |
| LastEditedBy | INT | NOT NULL | FK to People |
| ValidFrom | DATETIME2(7) | NOT NULL | Temporal: row start |
| ValidTo | DATETIME2(7) | NOT NULL | Temporal: row end |

**Special Features:**
- Temporal table with history in Warehouse.PackageTypes_Archive

#### Warehouse.StockItemHoldings
Current stock holdings (one row per stock item).

| Column | Data Type | Nullable | Description |
|--------|-----------|----------|-------------|
| StockItemID | INT | NOT NULL | Primary key, FK to StockItems |
| QuantityOnHand | INT | NOT NULL | Quantity on hand |
| BinLocation | NVARCHAR(20) | NOT NULL | Bin location |
| LastStocktakeQuantity | INT | NOT NULL | Last stocktake quantity |
| LastCostPrice | DECIMAL(18,2) | NOT NULL | Last cost price |
| ReorderLevel | INT | NOT NULL | Reorder level |
| TargetStockLevel | INT | NOT NULL | Target stock level |
| LastEditedBy | INT | NOT NULL | FK to People |
| LastEditedWhen | DATETIME2(7) | NOT NULL | Last edit timestamp |

#### Warehouse.StockItemTransactions
Stock item transaction history.

| Column | Data Type | Nullable | Description |
|--------|-----------|----------|-------------|
| StockItemTransactionID | INT | NOT NULL | Primary key (sequence-generated) |
| StockItemID | INT | NOT NULL | FK to StockItems |
| TransactionTypeID | INT | NOT NULL | FK to TransactionTypes |
| CustomerID | INT | NULL | FK to Customers |
| InvoiceID | INT | NULL | FK to Invoices |
| SupplierID | INT | NULL | FK to Suppliers |
| PurchaseOrderID | INT | NULL | FK to PurchaseOrders |
| TransactionOccurredWhen | DATETIME2(7) | NOT NULL | Transaction timestamp |
| Quantity | DECIMAL(18,3) | NOT NULL | Quantity |
| LastEditedBy | INT | NOT NULL | FK to People |
| LastEditedWhen | DATETIME2(7) | NOT NULL | Last edit timestamp |

#### Warehouse.ColdRoomTemperatures
Cold room temperature monitoring (memory-optimized table).

| Column | Data Type | Nullable | Description |
|--------|-----------|----------|-------------|
| ColdRoomTemperatureID | BIGINT | NOT NULL | Primary key (identity) |
| ColdRoomSensorNumber | INT | NOT NULL | Sensor number |
| RecordedWhen | DATETIME2(7) | NOT NULL | Recording timestamp |
| Temperature | DECIMAL(10,2) | NOT NULL | Temperature reading |
| ValidFrom | DATETIME2(7) | NOT NULL | Temporal: row start |
| ValidTo | DATETIME2(7) | NOT NULL | Temporal: row end |

**Special Features:**
- Memory-optimized table (MEMORY_OPTIMIZED = ON)
- Temporal table with history in Warehouse.ColdRoomTemperatures_Archive
- Non-clustered primary key

#### Warehouse.VehicleTemperatures
Vehicle temperature monitoring.

| Column | Data Type | Nullable | Description |
|--------|-----------|----------|-------------|
| VehicleTemperatureID | BIGINT | NOT NULL | Primary key (identity) |
| VehicleRegistration | NVARCHAR(20) | NOT NULL | Vehicle registration |
| ChillerSensorNumber | INT | NOT NULL | Sensor number |
| RecordedWhen | DATETIME2(7) | NOT NULL | Recording timestamp |
| Temperature | DECIMAL(10,2) | NOT NULL | Temperature reading |
| FullSensorData | NVARCHAR(1000) | NULL | Full sensor data (JSON) |
| IsCompressed | BIT | NOT NULL | Compression flag |
| CompressedSensorData | VARBINARY(MAX) | NULL | Compressed sensor data |

## SQL Server-Specific Features

### 1. Temporal Tables (System-Versioned)

The following tables use SQL Server temporal tables for automatic history tracking:

| Table | History Table |
|-------|---------------|
| Application.People | Application.People_Archive |
| Application.Countries | Application.Countries_Archive |
| Application.StateProvinces | Application.StateProvinces_Archive |
| Application.Cities | Application.Cities_Archive |
| Application.DeliveryMethods | Application.DeliveryMethods_Archive |
| Application.PaymentMethods | Application.PaymentMethods_Archive |
| Application.TransactionTypes | Application.TransactionTypes_Archive |
| Sales.Customers | Sales.Customers_Archive |
| Sales.CustomerCategories | Sales.CustomerCategories_Archive |
| Sales.BuyingGroups | Sales.BuyingGroups_Archive |
| Purchasing.Suppliers | Purchasing.Suppliers_Archive |
| Purchasing.SupplierCategories | Purchasing.SupplierCategories_Archive |
| Warehouse.StockItems | Warehouse.StockItems_Archive |
| Warehouse.StockGroups | Warehouse.StockGroups_Archive |
| Warehouse.Colors | Warehouse.Colors_Archive |
| Warehouse.PackageTypes | Warehouse.PackageTypes_Archive |
| Warehouse.ColdRoomTemperatures | Warehouse.ColdRoomTemperatures_Archive |

### 2. Memory-Optimized Tables

- Warehouse.ColdRoomTemperatures - Uses In-Memory OLTP for high-performance temperature recording

### 3. Columnstore Indexes

- Sales.OrderLines - NCCX_Sales_OrderLines (non-clustered columnstore)
- Sales.InvoiceLines - NCCX_Sales_InvoiceLines (non-clustered columnstore)

### 4. Full-Text Search

Full-text indexes are configured on:
- Application.People (SearchName, CustomFields, OtherLanguages)
- Sales.Customers (CustomerName)
- Purchasing.Suppliers (SupplierName)
- Warehouse.StockItems (SearchDetails, CustomFields, Tags)

### 5. Geography Data Type (Spatial)

Used in the following tables:
- Application.Countries (Border)
- Application.StateProvinces (Border)
- Application.Cities (Location)
- Application.SystemParameters (DeliveryLocation)
- Sales.Customers (DeliveryLocation)
- Purchasing.Suppliers (DeliveryLocation)

### 6. JSON Support

JSON functions used in:
- Application.People (OtherLanguages computed column)
- Warehouse.StockItems (Tags computed column)
- Sales.Invoices (ConfirmedDeliveryTime, ConfirmedReceivedBy computed columns)
- Sales.Invoices (ReturnedDeliveryData with JSON validation constraint)
- WebApi.Customers view (DeliveryLocation as GeoJSON)

### 7. Dynamic Data Masking

Applied to Purchasing.Suppliers:
- BankAccountName
- BankAccountBranch
- BankAccountCode
- BankAccountNumber
- BankInternationalCode

### 8. Row-Level Security

Security policy: Application.FilterCustomersBySalesTerritoryRole

Predicate function: Application.DetermineCustomerAccess(@CityID)

Applied to: Sales.Customers table

The RLS implementation:
1. Allows db_owner role members full access
2. Allows users in sales territory roles (e.g., "Far West Sales", "Great Lakes Sales") to see customers in their territory
3. Allows Website and WebApi logins to see customers based on SESSION_CONTEXT('SalesTerritory')

### 9. Sequences

The database uses sequences for ID generation instead of IDENTITY columns:

- Sequences.BuyingGroupID
- Sequences.CityID
- Sequences.ColorID
- Sequences.CountryID
- Sequences.CustomerCategoryID
- Sequences.CustomerID
- Sequences.DeliveryMethodID
- Sequences.InvoiceID
- Sequences.InvoiceLineID
- Sequences.OrderID
- Sequences.OrderLineID
- Sequences.PackageTypeID
- Sequences.PaymentMethodID
- Sequences.PersonID
- Sequences.PurchaseOrderID
- Sequences.PurchaseOrderLineID
- Sequences.SpecialDealID
- Sequences.StateProvinceID
- Sequences.StockGroupID
- Sequences.StockItemID
- Sequences.StockItemStockGroupID
- Sequences.SupplierCategoryID
- Sequences.SupplierID
- Sequences.SystemParameterID
- Sequences.TransactionID
- Sequences.TransactionTypeID

## Stored Procedures

### Application Schema

| Procedure | Purpose |
|-----------|---------|
| Configuration_ApplyRowLevelSecurity | Applies Row-Level Security policy |
| Configuration_RemoveRowLevelSecurity | Removes Row-Level Security policy |
| Configuration_ApplyFullTextIndexing | Creates full-text indexes and search procedures |
| Configuration_ApplyColumnstoreIndexing | Creates columnstore indexes |
| Configuration_RemoveColumnstoreIndexing | Removes columnstore indexes |
| Configuration_ApplyPartitioning | Applies table partitioning |
| Configuration_ApplyAuditing | Configures SQL Server Audit |
| Configuration_RemoveAuditing | Removes SQL Server Audit |
| Configuration_EnableInMemory | Enables In-Memory OLTP features |
| Configuration_DisableInMemory | Disables In-Memory OLTP features |
| Configuration_ConfigureForEnterpriseEdition | Configures Enterprise Edition features |
| Configuration_PrepareForAzureStandard | Prepares database for Azure SQL Database |
| CreateRoleIfNonexistent | Creates a database role if it doesn't exist |
| AddRoleMemberIfNonexistent | Adds a member to a role if not already a member |

### Integration Schema

| Procedure | Purpose |
|-----------|---------|
| GetCityUpdates | Gets city changes for ETL |
| GetCustomerUpdates | Gets customer changes for ETL |
| GetEmployeeUpdates | Gets employee changes for ETL |
| GetMovementUpdates | Gets stock movement changes for ETL |
| GetOrderUpdates | Gets order changes for ETL |
| GetPaymentMethodUpdates | Gets payment method changes for ETL |
| GetPurchaseUpdates | Gets purchase changes for ETL |
| GetSaleUpdates | Gets sale changes for ETL |
| GetStockHoldingUpdates | Gets stock holding changes for ETL |
| GetStockItemUpdates | Gets stock item changes for ETL |
| GetSupplierUpdates | Gets supplier changes for ETL |
| GetTransactionTypeUpdates | Gets transaction type changes for ETL |
| GetTransactionUpdates | Gets transaction changes for ETL |

### Website Schema

| Procedure | Purpose |
|-----------|---------|
| ActivateWebsiteLogon | Activates website logon for a person |
| ChangePassword | Changes user password |
| InsertCustomerOrders | Inserts customer orders from website |
| InvoiceCustomerOrders | Creates invoices for customer orders |
| RecordColdRoomTemperatures | Records cold room temperature readings |
| RecordVehicleTemperature | Records vehicle temperature readings |
| SearchForCustomers | Full-text search for customers |
| SearchForPeople | Full-text search for people |
| SearchForStockItems | Full-text search for stock items |
| SearchForStockItemsByTags | Full-text search for stock items by tags |
| SearchForSuppliers | Full-text search for suppliers |

### WebApi Schema

| Procedure | Purpose |
|-----------|---------|
| Login | Authenticates WebApi users |
| SearchForStockItems | Full-text search for stock items |
| Insert*FromJson | Insert procedures for various entities |
| Update*FromJson | Update procedures for various entities |
| Delete* | Delete procedures for various entities |

### DataLoadSimulation Schema

| Procedure | Purpose |
|-----------|---------|
| PopulateDataToCurrentDate | Populates data up to current date |
| PopulateDataTo180DaysAgo | Populates data up to 180 days ago |
| PopulateOneDayOfHistory | Populates one day of historical data |
| DailyProcessToCreateHistory | Daily process for creating history |
| CreateCustomerOrders | Creates simulated customer orders |
| PickStockForCustomerOrders | Simulates stock picking |
| InvoicePickedOrders | Creates invoices for picked orders |
| RecordInvoiceDeliveries | Records invoice deliveries |
| ProcessCustomerPayments | Processes customer payments |
| PlaceSupplierOrders | Places supplier orders |
| ReceivePurchaseOrders | Receives purchase orders |
| PaySuppliers | Processes supplier payments |
| AddCustomers | Adds simulated customers |
| AddStockItems | Adds simulated stock items |
| AddSpecialDeals | Adds simulated special deals |
| RecordColdRoomTemperatures | Records cold room temperatures |
| RecordDeliveryVanTemperatures | Records delivery van temperatures |
| PerformStocktake | Performs stock take |
| UpdateCustomFields | Updates custom fields |
| MakeTemporalChanges | Makes temporal table changes |
| ActivateWebsiteLogons | Activates website logons |
| ChangePasswords | Changes passwords |
| DeactivateTemporalTablesBeforeDataLoad | Deactivates temporal tables |
| ReactivateTemporalTablesAfterDataLoad | Reactivates temporal tables |

### Sequences Schema

| Procedure | Purpose |
|-----------|---------|
| ReseedAllSequences | Reseeds all sequences |
| ReseedSequenceBeyondTableValues | Reseeds a sequence beyond table values |

## Views

### Website Schema

| View | Purpose |
|------|---------|
| Customers | Customer information for website |
| Suppliers | Supplier information for website |
| VehicleTemperatures | Vehicle temperature data |

### WebApi Schema

| View | Purpose |
|------|---------|
| BuyingGroups | Buying groups for API |
| Cities | Cities for API |
| Colors | Colors for API |
| Countries | Countries for API |
| CustomerCategories | Customer categories for API |
| Customers | Customers for API (with GeoJSON) |
| CustomerTransactions | Customer transactions for API |
| DeliveryMethods | Delivery methods for API |
| Invoices | Invoices for API |
| PackageTypes | Package types for API |
| PaymentMethods | Payment methods for API |
| PurchaseOrderLines | Purchase order lines for API |
| PurchaseOrders | Purchase orders for API |
| SalesOrderLines | Sales order lines for API |
| SalesOrders | Sales orders for API |
| SpecialDeals | Special deals for API |
| StateProvinces | State provinces for API |
| StockGroups | Stock groups for API |
| StockItems | Stock items for API |
| SupplierCategories | Supplier categories for API |
| Suppliers | Suppliers for API |
| SupplierTransactions | Supplier transactions for API |
| TransactionTypes | Transaction types for API |

## User-Defined Types

### Website Schema

| Type | Purpose |
|------|---------|
| OrderIDList | Table type for order IDs |
| OrderList | Table type for orders |
| OrderLineList | Table type for order lines |
| SensorDataList | Table type for sensor data |

## Database Roles

The database includes the following custom roles for Row-Level Security:

- Far West Sales
- Great Lakes Sales
- Mideast Sales
- New England Sales
- Plains Sales
- Rocky Mountain Sales
- Southeast Sales
- Southwest Sales
- External Sales

## ETL Process Overview

The database includes an ETL process using SSIS to migrate data from WideWorldImporters (OLTP) to WideWorldImportersDW (OLAP/Data Warehouse).

### ETL Workflow

1. **Expression Task**: Calculates cutoff time
2. **Date Dimension**: Populates date dimension table
3. **Dimension Loading**: Loads dimension tables (City, Customer, Employee, Payment Method, Stock Item, Supplier, Transaction Type)
4. **Fact Loading**: Loads fact tables (Movement, Order, Purchase, Sale, Stock Holding, Transaction)

### Staging Tables (in WideWorldImportersDW)

- Integration.City_Staging
- Integration.Customer_Staging
- Integration.Employee_Staging
- Integration.Movement_Staging
- Integration.Order_Staging
- Integration.PaymentMethod_Staging
- Integration.Purchase_Staging
- Integration.Sale_Staging
- Integration.StockHolding_Staging
- Integration.StockItem_Staging
- Integration.Supplier_Staging
- Integration.Transaction_Staging
- Integration.TransactionType_Staging

### Migration Stored Procedures (in WideWorldImportersDW)

- Integration.MigrateStagedCityData
- Integration.MigrateStagedCustomerData
- Integration.MigrateStagedEmployeeData
- Integration.MigrateStagedMovementData
- Integration.MigrateStagedOrderData
- Integration.MigrateStagedPaymentMethodData
- Integration.MigrateStagedPurchaseData
- Integration.MigrateStagedSaleData
- Integration.MigrateStagedStockHoldingData
- Integration.MigrateStagedStockItemData
- Integration.MigrateStagedSupplierData
- Integration.MigrateStagedTransactionData
- Integration.MigrateStagedTransactionTypeData

## Relationship Diagram Summary

The database follows a star-like schema with the following key relationships:

### Core Entity Relationships

```
Application.Countries (1) --> (N) Application.StateProvinces
Application.StateProvinces (1) --> (N) Application.Cities
Application.Cities (1) --> (N) Sales.Customers (DeliveryCityID, PostalCityID)
Application.Cities (1) --> (N) Purchasing.Suppliers (DeliveryCityID, PostalCityID)
Application.People (1) --> (N) [All tables via LastEditedBy]
Application.People (1) --> (N) Sales.Customers (PrimaryContactPersonID, AlternateContactPersonID)
Application.People (1) --> (N) Purchasing.Suppliers (PrimaryContactPersonID, AlternateContactPersonID)
```

### Sales Relationships

```
Sales.Customers (1) --> (N) Sales.Orders
Sales.Orders (1) --> (N) Sales.OrderLines
Sales.Customers (1) --> (N) Sales.Invoices
Sales.Invoices (1) --> (N) Sales.InvoiceLines
Sales.Customers (1) --> (N) Sales.CustomerTransactions
Sales.CustomerCategories (1) --> (N) Sales.Customers
Sales.BuyingGroups (1) --> (N) Sales.Customers
```

### Purchasing Relationships

```
Purchasing.Suppliers (1) --> (N) Purchasing.PurchaseOrders
Purchasing.PurchaseOrders (1) --> (N) Purchasing.PurchaseOrderLines
Purchasing.Suppliers (1) --> (N) Purchasing.SupplierTransactions
Purchasing.SupplierCategories (1) --> (N) Purchasing.Suppliers
```

### Warehouse Relationships

```
Warehouse.StockItems (1) --> (N) Sales.OrderLines
Warehouse.StockItems (1) --> (N) Sales.InvoiceLines
Warehouse.StockItems (1) --> (N) Purchasing.PurchaseOrderLines
Warehouse.StockItems (1) --> (1) Warehouse.StockItemHoldings
Warehouse.StockItems (1) --> (N) Warehouse.StockItemTransactions
Warehouse.StockItems (N) <--> (N) Warehouse.StockGroups (via StockItemStockGroups)
Warehouse.Colors (1) --> (N) Warehouse.StockItems
Warehouse.PackageTypes (1) --> (N) Warehouse.StockItems (UnitPackageID, OuterPackageID)
Purchasing.Suppliers (1) --> (N) Warehouse.StockItems
```

## Conclusion

The Wide World Importers database is a comprehensive sample database that demonstrates many SQL Server features. The migration to PostgreSQL will require careful consideration of:

1. **Temporal Tables**: PostgreSQL does not have native temporal tables; this will need to be implemented using triggers or extensions
2. **Memory-Optimized Tables**: PostgreSQL does not have an equivalent; standard tables will be used
3. **Columnstore Indexes**: PostgreSQL does not have columnstore indexes; consider using BRIN indexes or partitioning for analytics
4. **Geography Data Type**: PostGIS extension provides equivalent functionality
5. **Full-Text Search**: PostgreSQL has native full-text search capabilities
6. **JSON Support**: PostgreSQL has excellent JSONB support
7. **Dynamic Data Masking**: PostgreSQL does not have native DDM; consider using views or RLS
8. **Row-Level Security**: PostgreSQL has native RLS support
9. **Sequences**: PostgreSQL has native sequence support
