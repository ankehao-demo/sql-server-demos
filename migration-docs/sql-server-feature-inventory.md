# SQL Server Feature Inventory - Wide World Importers

This document catalogs all SQL Server-specific features used in the Wide World Importers OLTP and OLAP databases that need to be considered for PostgreSQL migration.

## 1. Stored Procedures

### Application Schema (14 procedures)

| Procedure Name | Purpose | SQL Server-Specific Features |
|----------------|---------|------------------------------|
| `AddRoleMemberIfNonexistent` | Adds role members safely | Dynamic SQL, `IS_ROLEMEMBER()` |
| `Configuration_ApplyAuditing` | Enables SQL Server Audit | SQL Server Audit feature |
| `Configuration_ApplyColumnstoreIndexing` | Adds columnstore indexes | Columnstore indexes |
| `Configuration_ApplyFullTextIndexing` | Enables full-text search | Full-text catalogs and indexes |
| `Configuration_ApplyPartitioning` | Applies table partitioning | Partition functions/schemes |
| `Configuration_ApplyRowLevelSecurity` | Enables RLS | Security policies, `SESSION_CONTEXT()` |
| `Configuration_ConfigureForEnterpriseEdition` | Enterprise features | Edition-specific features |
| `Configuration_DisableInMemory` | Disables In-Memory OLTP | Memory-optimized tables |
| `Configuration_EnableInMemory` | Enables In-Memory OLTP | Memory-optimized tables, natively compiled procedures |
| `Configuration_PrepareForAzureStandard` | Azure SQL preparation | Azure-specific configurations |
| `Configuration_RemoveAuditing` | Removes auditing | SQL Server Audit |
| `Configuration_RemoveColumnstoreIndexing` | Removes columnstore | Columnstore indexes |
| `Configuration_RemoveRowLevelSecurity` | Removes RLS | Security policies |
| `CreateRoleIfNonexistent` | Creates roles safely | Dynamic SQL |

### DataLoadSimulation Schema (41 procedures)

| Procedure Name | Purpose | SQL Server-Specific Features |
|----------------|---------|------------------------------|
| `ActivateWebsiteLogons` | Activates user logons | `HASHBYTES()` |
| `AddCustomers` | Adds customer data | Sequences, `NEXT VALUE FOR` |
| `AddSpecialDeals` | Creates special deals | Sequences |
| `AddStockItems` | Adds stock items | Sequences, JSON functions |
| `ChangePasswords` | Updates passwords | `HASHBYTES()` |
| `CreateCustomerOrders` | Creates orders | Sequences, transactions |
| `DailyProcessToCreateHistory` | Simulates daily operations | Temporal table manipulation |
| `DeactivateTemporalTablesBeforeDataLoad` | Disables temporal tables | `SYSTEM_VERSIONING` |
| `GetBogativePostalCode` | Generates postal codes | String functions |
| `GetBuyingGroupDomain` | Gets domain info | String manipulation |
| `GetFicticiousName` | Generates names | Random functions |
| `GetRandomBuyingGroup` | Random selection | `NEWID()` for randomization |
| `GetRandomBuyingGroupNotInUse` | Random selection | `NEWID()` |
| `GetRandomCity` | Random city selection | `NEWID()` |
| `GetRandomCustomer` | Random customer | `NEWID()` |
| `GetRandomCustomerCategory` | Random category | `NEWID()` |
| `GetRandomDeliveryMethod` | Random delivery | `NEWID()` |
| `GetRandomEmployeePerson` | Random employee | `NEWID()` |
| `GetRandomPaymentDays` | Random payment terms | `NEWID()` |
| `GetRandomSalesPersonID` | Random salesperson | `NEWID()` |
| `GetRandomSecondaryAddress` | Random address | `NEWID()` |
| `GetRandomStockItemToAdjust` | Random stock item | `NEWID()` |
| `GetRandomStreet` | Random street | `NEWID()` |
| `GetRandomStreetName` | Random street name | `NEWID()` |
| `GetRandomStreetSuffix` | Random suffix | `NEWID()` |
| `InvoicePickedOrders` | Invoices orders | Sequences, JSON functions |
| `MakeTemporalChanges` | Updates temporal data | Temporal table operations |
| `PaySuppliers` | Processes payments | Sequences |
| `PerformStocktake` | Stock inventory | Transactions |
| `PickStockForCustomerOrders` | Order picking | Sequences |
| `PlaceSupplierOrders` | Creates POs | Sequences |
| `PopulateColdRoomTemperatures_temp` | Temperature data | Memory-optimized tables |
| `PopulateDataTo180DaysAgo` | Historical data | Date functions |
| `PopulateDataToCurrentDate` | Current data | `SYSDATETIME()` |
| `PopulateOneDayOfHistory` | Daily history | Temporal operations |
| `ProcessCustomerPayments` | Payment processing | Sequences |
| `ReactivateTemporalTablesAfterDataLoad` | Re-enables temporal | `SYSTEM_VERSIONING` |
| `ReceivePurchaseOrders` | PO receipt | Sequences |
| `RecordColdRoomTemperatures` | Temperature logging | Memory-optimized tables |
| `RecordDeliveryVanTemperatures` | Van temperatures | Memory-optimized tables |
| `RecordInvoiceDeliveries` | Delivery records | JSON functions |
| `UpdateCustomFields` | Updates JSON fields | `JSON_MODIFY()` |

### Integration Schema (13 procedures)

| Procedure Name | Purpose | SQL Server-Specific Features |
|----------------|---------|------------------------------|
| `GetCityUpdates` | ETL city data | Temporal table queries (`FOR SYSTEM_TIME`) |
| `GetCustomerUpdates` | ETL customer data | Temporal queries |
| `GetEmployeeUpdates` | ETL employee data | Temporal queries |
| `GetMovementUpdates` | ETL movement data | Temporal queries |
| `GetOrderUpdates` | ETL order data | Temporal queries |
| `GetPaymentMethodUpdates` | ETL payment methods | Temporal queries |
| `GetPurchaseUpdates` | ETL purchase data | Temporal queries |
| `GetSaleUpdates` | ETL sale data | Temporal queries |
| `GetStockHoldingUpdates` | ETL stock holdings | Temporal queries |
| `GetStockItemUpdates` | ETL stock items | Temporal queries |
| `GetSupplierUpdates` | ETL supplier data | Temporal queries |
| `GetTransactionTypeUpdates` | ETL transaction types | Temporal queries |
| `GetTransactionUpdates` | ETL transactions | Temporal queries |

### Website Schema (11 procedures)

| Procedure Name | Purpose | SQL Server-Specific Features |
|----------------|---------|------------------------------|
| `ActivateWebsiteLogon` | User activation | `HASHBYTES()` |
| `ChangePassword` | Password change | `HASHBYTES()` |
| `InsertCustomerOrders` | Order insertion | Table-valued parameters, memory-optimized TVPs |
| `InvoiceCustomerOrders` | Order invoicing | Table-valued parameters, sequences |
| `RecordColdRoomTemperatures` | Temperature recording | Natively compiled procedure, `BEGIN ATOMIC` |
| `RecordVehicleTemperature` | Vehicle temps | Memory-optimized tables |
| `SearchForCustomers` | Customer search | Full-text search (`CONTAINS`) |
| `SearchForPeople` | People search | Full-text search |
| `SearchForStockItems` | Stock search | Full-text search |
| `SearchForStockItemsByTags` | Tag search | JSON functions, full-text |
| `SearchForSuppliers` | Supplier search | Full-text search |

## 2. Functions

### Application Schema (1 function)

| Function Name | Type | Purpose | SQL Server-Specific Features |
|---------------|------|---------|------------------------------|
| `DetermineCustomerAccess` | Inline TVF | Row-level security predicate | `IS_ROLEMEMBER()`, `ORIGINAL_LOGIN()`, `SESSION_CONTEXT()` |

### DataLoadSimulation Schema (10 functions)

| Function Name | Type | Purpose | SQL Server-Specific Features |
|---------------|------|---------|------------------------------|
| `GetAreaCode` | Scalar | Area code lookup | Standard SQL |
| `GetBogativePhoneNumber` | Scalar | Phone generation | String functions |
| `GetCityLocation` | Scalar | Geography lookup | `geography` data type |
| `GetCustomerCount` | Scalar | Customer counting | Standard SQL |
| `GetDeliveryMethodID` | Scalar | ID lookup | Standard SQL |
| `GetPaymentMethodID` | Scalar | ID lookup | Standard SQL |
| `GetPersonID` | Scalar | ID lookup | Standard SQL |
| `GetStateProvinceID` | Scalar | ID lookup | Standard SQL |
| `GetSupplierCategoryID` | Scalar | ID lookup | Standard SQL |
| `GetTransactionTypeID` | Scalar | ID lookup | Standard SQL |

### Website Schema (1 function)

| Function Name | Type | Purpose | SQL Server-Specific Features |
|---------------|------|---------|------------------------------|
| `CalculateCustomerPrice` | Scalar | Price calculation | Standard SQL |

## 3. Temporal Tables (System-Versioned)

The following tables use SQL Server's temporal table feature with `SYSTEM_VERSIONING`:

### Application Schema
| Main Table | History Table | Purpose |
|------------|---------------|---------|
| `Cities` | `Cities_Archive` | City reference data |
| `Countries` | `Countries_Archive` | Country reference data |
| `DeliveryMethods` | `DeliveryMethods_Archive` | Delivery method reference |
| `PaymentMethods` | `PaymentMethods_Archive` | Payment method reference |
| `People` | `People_Archive` | Person/contact data |
| `StateProvinces` | `StateProvinces_Archive` | State/province reference |
| `TransactionTypes` | `TransactionTypes_Archive` | Transaction type reference |

### Sales Schema
| Main Table | History Table | Purpose |
|------------|---------------|---------|
| `BuyingGroups` | `BuyingGroups_Archive` | Buying group reference |
| `CustomerCategories` | `CustomerCategories_Archive` | Customer category reference |
| `Customers` | `Customers_Archive` | Customer master data |

### Warehouse Schema
| Main Table | History Table | Purpose |
|------------|---------------|---------|
| `ColdRoomTemperatures` | `ColdRoomTemperatures_Archive` | Temperature monitoring (also memory-optimized) |
| `Colors` | `Colors_Archive` | Color reference |
| `PackageTypes` | `PackageTypes_Archive` | Package type reference |
| `StockGroups` | `StockGroups_Archive` | Stock group reference |
| `StockItems` | `StockItems_Archive` | Stock item master data |

### Purchasing Schema
| Main Table | History Table | Purpose |
|------------|---------------|---------|
| `SupplierCategories` | `SupplierCategories_Archive` | Supplier category reference |
| `Suppliers` | `Suppliers_Archive` | Supplier master data |

**Temporal Table Features Used:**
- `GENERATED ALWAYS AS ROW START/END` columns
- `PERIOD FOR SYSTEM_TIME` clause
- `SYSTEM_VERSIONING = ON` with history table specification
- `FOR SYSTEM_TIME AS OF` queries in Integration procedures

## 4. Memory-Optimized Tables

### Tables with `MEMORY_OPTIMIZED = ON`

| Schema | Table | Features |
|--------|-------|----------|
| `Warehouse` | `ColdRoomTemperatures` | Memory-optimized + temporal |
| `Warehouse` | `VehicleTemperatures` | Memory-optimized only |

### Memory-Optimized Table-Valued Types

| Schema | Type Name | Purpose |
|--------|-----------|---------|
| `Website` | `OrderIDList` | Order ID collection for batch operations |
| `Website` | `OrderList` | Order header collection |
| `Website` | `OrderLineList` | Order line collection |
| `Website` | `SensorDataList` | Sensor reading collection |

### Natively Compiled Procedures

| Schema | Procedure | Features |
|--------|-----------|----------|
| `Website` | `RecordColdRoomTemperatures` | `NATIVE_COMPILATION`, `BEGIN ATOMIC`, `SCHEMABINDING` |

## 5. SQL Server-Specific Data Types

| Data Type | Usage | PostgreSQL Equivalent |
|-----------|-------|----------------------|
| `geography` | Spatial data (Cities, Customers, Suppliers) | PostGIS `geography` |
| `datetime2(7)` | High-precision timestamps | `timestamp(6)` |
| `nvarchar(max)` | Unicode text | `text` |
| `varbinary(max)` | Binary data (photos, hashed passwords) | `bytea` |
| `hierarchyid` | Not used in WWI | N/A |
| `xml` | Not used in WWI | N/A |

## 6. Security Implementations

### Row-Level Security (RLS)

**Security Policy:** `Application.FilterCustomersBySalesTerritoryRole`

**Predicate Function:** `Application.DetermineCustomerAccess`

**Protected Table:** `Sales.Customers`

**Access Logic:**
1. `db_owner` role members have full access
2. Sales territory role members see their territory's customers
3. Website/WebApi users see customers based on `SESSION_CONTEXT('SalesTerritory')`

### Database Roles (Sales Territory-Based)

| Role Name | Purpose |
|-----------|---------|
| `External Sales` | External sales territory access |
| `Far West Sales` | Far West region access |
| `Great Lakes Sales` | Great Lakes region access |
| `Mideast Sales` | Mideast region access |
| `New England Sales` | New England region access |
| `Plains Sales` | Plains region access |
| `Rocky Mountain Sales` | Rocky Mountain region access |
| `Southeast Sales` | Southeast region access |
| `Southwest Sales` | Southwest region access |

### Application Roles

| Role Name | Purpose |
|-----------|---------|
| `Application` | Application schema access |
| `DataLoadSimulation` | Data simulation access |
| `Integration` | ETL integration access |
| `PowerBI` | Power BI reporting access |
| `Purchasing` | Purchasing operations |
| `Reports` | Report generation |
| `Sales` | Sales operations |
| `Warehouse` | Warehouse operations |
| `WebApi` | Web API access |
| `Website` | Website access |

## 7. Sequences

The database uses 26 sequences for ID generation:

| Sequence Name | Used By |
|---------------|---------|
| `BuyingGroupID` | Sales.BuyingGroups |
| `CityID` | Application.Cities |
| `ColorID` | Warehouse.Colors |
| `CountryID` | Application.Countries |
| `CustomerCategoryID` | Sales.CustomerCategories |
| `CustomerID` | Sales.Customers |
| `DeliveryMethodID` | Application.DeliveryMethods |
| `InvoiceID` | Sales.Invoices |
| `InvoiceLineID` | Sales.InvoiceLines |
| `OrderID` | Sales.Orders |
| `OrderLineID` | Sales.OrderLines |
| `PackageTypeID` | Warehouse.PackageTypes |
| `PaymentMethodID` | Application.PaymentMethods |
| `PersonID` | Application.People |
| `PurchaseOrderID` | Purchasing.PurchaseOrders |
| `PurchaseOrderLineID` | Purchasing.PurchaseOrderLines |
| `SpecialDealID` | Sales.SpecialDeals |
| `StateProvinceID` | Application.StateProvinces |
| `StockGroupID` | Warehouse.StockGroups |
| `StockItemID` | Warehouse.StockItems |
| `StockItemStockGroupID` | Warehouse.StockItemStockGroups |
| `SupplierCategoryID` | Purchasing.SupplierCategories |
| `SupplierID` | Purchasing.Suppliers |
| `SystemParameterID` | Application.SystemParameters |
| `TransactionID` | Sales/Purchasing Transactions |
| `TransactionTypeID` | Application.TransactionTypes |

## 8. JSON Features

### JSON Functions Used

| Function | Usage |
|----------|-------|
| `JSON_QUERY()` | Extract JSON arrays (Tags, OtherLanguages) |
| `JSON_MODIFY()` | Update JSON data (ReturnedDeliveryData) |
| `JSON_VALUE()` | Extract scalar values from JSON |
| `OPENJSON()` | Parse JSON arrays |

### Tables with JSON Columns

| Table | Column | Purpose |
|-------|--------|---------|
| `Application.People` | `CustomFields` | Employee custom data |
| `Application.People` | `UserPreferences` | User settings |
| `Warehouse.StockItems` | `CustomFields` | Stock item attributes |
| `Sales.Invoices` | `ReturnedDeliveryData` | Delivery tracking events |

### Computed Columns from JSON

| Table | Column | Expression |
|-------|--------|------------|
| `Application.People` | `OtherLanguages` | `json_query([CustomFields],N'$.OtherLanguages')` |
| `Warehouse.StockItems` | `Tags` | `json_query([CustomFields],N'$.Tags')` |

## 9. Full-Text Search

### Full-Text Catalogs
- `FTCatalog` (main catalog for searchable content)

### Full-Text Indexes

| Table | Indexed Columns |
|-------|-----------------|
| `Application.People` | `SearchName`, `CustomFields` |
| `Sales.Customers` | `CustomerName` |
| `Purchasing.Suppliers` | `SupplierName` |
| `Warehouse.StockItems` | `SearchDetails`, `CustomFields` |

## 10. Columnstore Indexes (OLAP Database)

### Clustered Columnstore Indexes

| Table | Index Name |
|-------|------------|
| `Fact.Sale` | `CCX_Fact_Sale` |
| `Fact.Order` | `CCX_Fact_Order` |
| `Fact.Purchase` | `CCX_Fact_Purchase` |
| `Fact.Movement` | `CCX_Fact_Movement` |
| `Fact.Transaction` | `CCX_Fact_Transaction` |
| `Fact.Stock Holding` | `CCX_Fact_Stock_Holding` |

## 11. Partitioning (OLAP Database)

### Partition Function
- `PF_Date` - Partitions by date ranges

### Partition Scheme
- `PS_Date` - Maps partitions to `USERDATA` filegroup

### Partitioned Tables
All fact tables are partitioned by date:
- `Fact.Sale` (by `Invoice Date Key`)
- `Fact.Order` (by `Order Date Key`)
- `Fact.Purchase` (by `Date Key`)
- `Fact.Movement` (by `Date Key`)
- `Fact.Transaction` (by `Date Key`)
- `Fact.Stock Holding` (by `As Of Date`)

## 12. Extended Properties

The database extensively uses `sp_addextendedproperty` to document:
- Table descriptions
- Column descriptions
- Index purposes
- Constraint explanations

## 13. Other SQL Server Features

### Features Used
- `EXECUTE AS OWNER` - Procedure execution context
- `SET XACT_ABORT ON` - Transaction abort behavior
- `SERVERPROPERTY()` - Server configuration queries
- `HASHBYTES()` - Password hashing
- `NEWID()` - GUID generation for randomization
- `SYSDATETIME()` - High-precision current timestamp
- `COMPRESS()`/`DECOMPRESS()` - Data compression
- `COLLATE` - Collation specifications

### Default Constraints with Sequences
Tables use `DEFAULT (NEXT VALUE FOR [Sequences].[SequenceName])` for auto-generated IDs.

### Computed Columns
- `Application.People.SearchName` - Concatenated search field (PERSISTED)
- `Application.People.OtherLanguages` - JSON extraction
- `Warehouse.StockItems.Tags` - JSON extraction
- `Warehouse.StockItems.SearchDetails` - Concatenated search field
