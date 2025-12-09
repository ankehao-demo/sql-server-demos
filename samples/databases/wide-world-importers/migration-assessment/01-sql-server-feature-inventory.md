# Wide World Importers - SQL Server Feature Inventory

## Executive Summary

This document provides a comprehensive inventory of SQL Server-specific features used in the Wide World Importers database project. The project consists of two main databases:

1. **WideWorldImporters (OLTP)** - Located in `wwi-ssdt/wwi-ssdt/`
2. **WideWorldImportersDW (OLAP)** - Located in `wwi-dw-ssdt/wwi-dw-ssdt/`

Additionally, the project includes:
- **SSIS ETL Packages** - Located in `wwi-ssis/`
- **Analysis Services Cubes** - Located in `wwi-ssasmd/`

---

## 1. Temporal Tables (System-Versioned Tables)

SQL Server's temporal tables feature provides automatic tracking of data changes over time. PostgreSQL does not have native temporal table support and will require trigger-based implementation.

### OLTP Database Temporal Tables

| Schema | Table | History Table | File Location |
|--------|-------|---------------|---------------|
| Application | Cities | Cities_Archive | `Application/Tables/Cities.sql` |
| Application | Countries | Countries_Archive | `Application/Tables/Countries.sql` |
| Application | DeliveryMethods | DeliveryMethods_Archive | `Application/Tables/DeliveryMethods.sql` |
| Application | PaymentMethods | PaymentMethods_Archive | `Application/Tables/PaymentMethods.sql` |
| Application | People | People_Archive | `Application/Tables/People.sql` |
| Application | StateProvinces | StateProvinces_Archive | `Application/Tables/StateProvinces.sql` |
| Application | TransactionTypes | TransactionTypes_Archive | `Application/Tables/TransactionTypes.sql` |
| Purchasing | SupplierCategories | SupplierCategories_Archive | `Purchasing/Tables/SupplierCategories.sql` |
| Purchasing | Suppliers | Suppliers_Archive | `Purchasing/Tables/Suppliers.sql` |
| Sales | BuyingGroups | BuyingGroups_Archive | `Sales/Tables/BuyingGroups.sql` |
| Sales | CustomerCategories | CustomerCategories_Archive | `Sales/Tables/CustomerCategories.sql` |
| Sales | Customers | Customers_Archive | `Sales/Tables/Customers.sql` |
| Warehouse | ColdRoomTemperatures | ColdRoomTemperatures_Archive | `Warehouse/Tables/ColdRoomTemperatures.sql` |
| Warehouse | Colors | Colors_Archive | `Warehouse/Tables/Colors.sql` |
| Warehouse | PackageTypes | PackageTypes_Archive | `Warehouse/Tables/PackageTypes.sql` |
| Warehouse | StockGroups | StockGroups_Archive | `Warehouse/Tables/StockGroups.sql` |
| Warehouse | StockItems | StockItems_Archive | `Warehouse/Tables/StockItems.sql` |

### Temporal Table Syntax Example

From `Application/Tables/People.sql`:
```sql
CREATE TABLE [Application].[People] (
    [PersonID] INT NOT NULL,
    -- ... other columns ...
    [ValidFrom] DATETIME2 (7) GENERATED ALWAYS AS ROW START NOT NULL,
    [ValidTo]   DATETIME2 (7) GENERATED ALWAYS AS ROW END   NOT NULL,
    PERIOD FOR SYSTEM_TIME ([ValidFrom], [ValidTo])
)
WITH (SYSTEM_VERSIONING = ON (HISTORY_TABLE=[Application].[People_Archive], DATA_CONSISTENCY_CHECK=ON));
```

### Related Stored Procedures

- `DataLoadSimulation/Stored Procedures/DeactivateTemporalTablesBeforeDataLoad.sql` - Disables temporal versioning for bulk data loads
- `DataLoadSimulation/Stored Procedures/ReactivateTemporalTablesAfterDataLoad.sql` - Re-enables temporal versioning after data loads

---

## 2. Memory-Optimized Tables (In-Memory OLTP)

SQL Server's In-Memory OLTP feature provides memory-optimized tables for high-performance scenarios. PostgreSQL does not have an equivalent feature.

### Memory-Optimized Tables

| Schema | Table | Features | File Location |
|--------|-------|----------|---------------|
| Warehouse | ColdRoomTemperatures | Memory-optimized + Temporal | `Warehouse/Tables/ColdRoomTemperatures.sql` |
| Warehouse | VehicleTemperatures | Memory-optimized only | `Warehouse/Tables/VehicleTemperatures.sql` |

### Memory-Optimized Table Syntax Example

From `Warehouse/Tables/ColdRoomTemperatures.sql`:
```sql
CREATE TABLE [Warehouse].[ColdRoomTemperatures] (
    [ColdRoomTemperatureID] BIGINT IDENTITY (1, 1) NOT NULL,
    [ColdRoomSensorNumber]  INT NOT NULL,
    [RecordedWhen]          DATETIME2 (7) NOT NULL,
    [Temperature]           DECIMAL (10, 2) NOT NULL,
    [ValidFrom]             DATETIME2 (7) GENERATED ALWAYS AS ROW START NOT NULL,
    [ValidTo]               DATETIME2 (7) GENERATED ALWAYS AS ROW END   NOT NULL,
    CONSTRAINT [PK_Warehouse_ColdRoomTemperatures] PRIMARY KEY NONCLUSTERED ([ColdRoomTemperatureID] ASC),
    PERIOD FOR SYSTEM_TIME ([ValidFrom], [ValidTo])
)
WITH (MEMORY_OPTIMIZED = ON, SYSTEM_VERSIONING = ON (HISTORY_TABLE=[Warehouse].[ColdRoomTemperatures_Archive]));
```

### Memory-Optimized User-Defined Table Types

| Schema | Type Name | File Location |
|--------|-----------|---------------|
| Website | OrderIDList | `Website/User Defined Types/OrderIDList.sql` |
| Website | OrderList | `Website/User Defined Types/OrderList.sql` |
| Website | OrderLineList | `Website/User Defined Types/OrderLineList.sql` |
| Website | SensorDataList | `Website/User Defined Types/SensorDataList.sql` |

### Memory-Optimized Filegroup

File: `Storage/WWI_MemoryOptimized_Data.sql`
```sql
ALTER DATABASE [$(DatabaseName)]
    ADD FILEGROUP [WWI_MemoryOptimized_Data] CONTAINS MEMORY_OPTIMIZED_DATA;
```

### Related Configuration Procedures

- `Application/Stored Procedures/Configuration_EnableInMemory.sql` - Enables in-memory OLTP features
- `Application/Stored Procedures/Configuration_DisableInMemory.sql` - Disables in-memory OLTP features

---

## 3. Stored Procedures

### Application Schema Stored Procedures

| Procedure Name | Purpose | File Location |
|----------------|---------|---------------|
| AddRoleMemberIfNonexistent | Adds role member if not exists | `Application/Stored Procedures/AddRoleMemberIfNonexistent.sql` |
| Configuration_ApplyAuditing | Configures SQL Server auditing | `Application/Stored Procedures/Configuration_ApplyAuditing.sql` |
| Configuration_ApplyColumnstoreIndexing | Applies columnstore indexes | `Application/Stored Procedures/Configuration_ApplyColumnstoreIndexing.sql` |
| Configuration_ApplyFullTextIndexing | Configures full-text search | `Application/Stored Procedures/Configuration_ApplyFullTextIndexing.sql` |
| Configuration_ApplyPartitioning | Applies table partitioning | `Application/Stored Procedures/Configuration_ApplyPartitioning.sql` |
| Configuration_ApplyRowLevelSecurity | Configures row-level security | `Application/Stored Procedures/Configuration_ApplyRowLevelSecurity.sql` |
| Configuration_ConfigureForEnterpriseEdition | Enterprise edition features | `Application/Stored Procedures/Configuration_ConfigureForEnterpriseEdition.sql` |
| Configuration_EnableInMemory | Enables in-memory OLTP | `Application/Stored Procedures/Configuration_EnableInMemory.sql` |
| Configuration_DisableInMemory | Disables in-memory OLTP | `Application/Stored Procedures/Configuration_DisableInMemory.sql` |
| Configuration_RemoveAuditing | Removes auditing | `Application/Stored Procedures/Configuration_RemoveAuditing.sql` |
| Configuration_RemoveColumnstoreIndexing | Removes columnstore indexes | `Application/Stored Procedures/Configuration_RemoveColumnstoreIndexing.sql` |
| Configuration_RemoveRowLevelSecurity | Removes RLS | `Application/Stored Procedures/Configuration_RemoveRowLevelSecurity.sql` |
| CreateRoleIfNonexistent | Creates role if not exists | `Application/Stored Procedures/CreateRoleIfNonexistent.sql` |

### DataLoadSimulation Schema Stored Procedures

| Procedure Name | Purpose | File Location |
|----------------|---------|---------------|
| PopulateDataToCurrentDate | Main data generation procedure | `DataLoadSimulation/Stored Procedures/PopulateDataToCurrentDate.sql` |
| DailyProcessToCreateHistory | Daily data simulation | `DataLoadSimulation/Stored Procedures/DailyProcessToCreateHistory.sql` |
| DeactivateTemporalTablesBeforeDataLoad | Disables temporal tables | `DataLoadSimulation/Stored Procedures/DeactivateTemporalTablesBeforeDataLoad.sql` |
| ReactivateTemporalTablesAfterDataLoad | Re-enables temporal tables | `DataLoadSimulation/Stored Procedures/ReactivateTemporalTablesAfterDataLoad.sql` |
| CreateCustomerOrders | Creates customer orders | `DataLoadSimulation/Stored Procedures/CreateCustomerOrders.sql` |
| InvoicePickedOrders | Invoices picked orders | `DataLoadSimulation/Stored Procedures/InvoicePickedOrders.sql` |
| PickStockForCustomerOrders | Picks stock for orders | `DataLoadSimulation/Stored Procedures/PickStockForCustomerOrders.sql` |
| PlaceSupplierOrders | Places supplier orders | `DataLoadSimulation/Stored Procedures/PlaceSupplierOrders.sql` |
| ReceivePurchaseOrders | Receives purchase orders | `DataLoadSimulation/Stored Procedures/ReceivePurchaseOrders.sql` |
| ProcessCustomerPayments | Processes customer payments | `DataLoadSimulation/Stored Procedures/ProcessCustomerPayments.sql` |
| PaySuppliers | Pays suppliers | `DataLoadSimulation/Stored Procedures/PaySuppliers.sql` |
| PerformStocktake | Performs stocktake | `DataLoadSimulation/Stored Procedures/PerformStocktake.sql` |
| RecordDeliveryVanTemperatures | Records van temperatures | `DataLoadSimulation/Stored Procedures/RecordDeliveryVanTemperatures.sql` |
| RecordInvoiceDeliveries | Records invoice deliveries | `DataLoadSimulation/Stored Procedures/RecordInvoiceDeliveries.sql` |
| AddSpecialDeals | Adds special deals | `DataLoadSimulation/Stored Procedures/AddSpecialDeals.sql` |
| GetRandomCustomer | Gets random customer | `DataLoadSimulation/Stored Procedures/GetRandomCustomer.sql` |
| GetRandomStockItemToAdjust | Gets random stock item | `DataLoadSimulation/Stored Procedures/GetRandomStockItemToAdjust.sql` |

### Website Schema Stored Procedures

| Procedure Name | Purpose | File Location |
|----------------|---------|---------------|
| SearchForPeople | Full-text search for people | `Website/Stored Procedures/SearchForPeople.sql` |
| SearchForSuppliers | Full-text search for suppliers | `Website/Stored Procedures/SearchForSuppliers.sql` |
| SearchForCustomers | Full-text search for customers | `Website/Stored Procedures/SearchForCustomers.sql` |
| SearchForStockItems | Full-text search for stock items | `Website/Stored Procedures/SearchForStockItems.sql` |
| SearchForStockItemsByTags | Search stock items by tags | `Website/Stored Procedures/SearchForStockItemsByTags.sql` |
| RecordVehicleTemperature | Records vehicle temperature | `Website/Stored Procedures/RecordVehicleTemperature.sql` |
| RecordColdRoomTemperatures | Records cold room temperatures | `Website/Stored Procedures/RecordColdRoomTemperatures.sql` |
| InvoiceCustomerOrders | Invoices customer orders | `Website/Stored Procedures/InvoiceCustomerOrders.sql` |
| InsertCustomerOrders | Inserts customer orders | `Website/Stored Procedures/InsertCustomerOrders.sql` |
| ActivateWebsiteLogon | Activates website logon | `Website/Stored Procedures/ActivateWebsiteLogon.sql` |
| ChangePassword | Changes password | `Website/Stored Procedures/ChangePassword.sql` |

### Integration Schema Stored Procedures (OLTP)

| Procedure Name | Purpose | File Location |
|----------------|---------|---------------|
| GetCityUpdates | Gets city updates for ETL | `Integration/Stored Procedures/GetCityUpdates.sql` |
| GetCustomerUpdates | Gets customer updates for ETL | `Integration/Stored Procedures/GetCustomerUpdates.sql` |
| GetEmployeeUpdates | Gets employee updates for ETL | `Integration/Stored Procedures/GetEmployeeUpdates.sql` |
| GetPaymentMethodUpdates | Gets payment method updates | `Integration/Stored Procedures/GetPaymentMethodUpdates.sql` |
| GetStockItemUpdates | Gets stock item updates | `Integration/Stored Procedures/GetStockItemUpdates.sql` |
| GetSupplierUpdates | Gets supplier updates | `Integration/Stored Procedures/GetSupplierUpdates.sql` |
| GetTransactionTypeUpdates | Gets transaction type updates | `Integration/Stored Procedures/GetTransactionTypeUpdates.sql` |
| GetMovementUpdates | Gets movement updates | `Integration/Stored Procedures/GetMovementUpdates.sql` |
| GetOrderUpdates | Gets order updates | `Integration/Stored Procedures/GetOrderUpdates.sql` |
| GetPurchaseUpdates | Gets purchase updates | `Integration/Stored Procedures/GetPurchaseUpdates.sql` |
| GetSaleUpdates | Gets sale updates | `Integration/Stored Procedures/GetSaleUpdates.sql` |
| GetStockHoldingUpdates | Gets stock holding updates | `Integration/Stored Procedures/GetStockHoldingUpdates.sql` |
| GetTransactionUpdates | Gets transaction updates | `Integration/Stored Procedures/GetTransactionUpdates.sql` |

### Natively Compiled Stored Procedures

The following procedure uses native compilation for memory-optimized tables:

From `Application/Stored Procedures/Configuration_EnableInMemory.sql`:
```sql
CREATE PROCEDURE Website.RecordColdRoomTemperatures
@SensorReadings Website.SensorDataList READONLY
WITH NATIVE_COMPILATION, SCHEMABINDING, EXECUTE AS OWNER
AS
BEGIN ATOMIC WITH
(
    TRANSACTION ISOLATION LEVEL = SNAPSHOT,
    LANGUAGE = N'English'
)
    -- procedure body
END;
```

---

## 4. SQL Server-Specific Data Types

### Data Types Used

| SQL Server Type | PostgreSQL Equivalent | Usage Examples |
|-----------------|----------------------|----------------|
| `DATETIME2(7)` | `TIMESTAMP(6)` | ValidFrom, ValidTo, LastEditedWhen |
| `DATE` | `DATE` | OrderDate, InvoiceDate |
| `NVARCHAR(n)` | `VARCHAR(n)` | CustomerName, SupplierName |
| `NVARCHAR(MAX)` | `TEXT` | Comments, CustomFields, MarketingComments |
| `VARBINARY(MAX)` | `BYTEA` | Photo, HashedPassword, CompressedSensorData |
| `BIT` | `BOOLEAN` | IsEmployee, IsSalesperson, IsChillerStock |
| `DECIMAL(18,2)` | `NUMERIC(18,2)` | UnitPrice, TaxRate |
| `BIGINT` | `BIGINT` | ColdRoomTemperatureID, VehicleTemperatureID |
| `INT` | `INTEGER` | CustomerID, OrderID |
| `geography` | `GEOGRAPHY` (PostGIS) | Location, DeliveryLocation |
| `HIERARCHYID` | Custom implementation | Not used in this database |

### Geography Data Type Usage

Tables using `sys.geography`:
- `Application.Cities` - Location column
- `Application.Countries` - Border column
- `Application.StateProvinces` - Border column
- `Sales.Customers` - DeliveryLocation column
- `Purchasing.Suppliers` - DeliveryLocation column

---

## 5. SQL Server-Specific Functions

### Built-in Functions Used

| Function | PostgreSQL Equivalent | Usage |
|----------|----------------------|-------|
| `SYSDATETIME()` | `CURRENT_TIMESTAMP` | Default values, LastEditedWhen |
| `GETDATE()` | `CURRENT_TIMESTAMP` | Date/time operations |
| `DATEADD()` | `+ INTERVAL` | Date arithmetic |
| `DATEDIFF()` | `DATE_PART()` or `-` | Date differences |
| `CONVERT()` | `CAST()` or `TO_CHAR()` | Type conversion |
| `TRY_CONVERT()` | `CAST()` with error handling | Safe type conversion |
| `ISNULL()` | `COALESCE()` | Null handling |
| `COALESCE()` | `COALESCE()` | Null handling |
| `QUOTENAME()` | `quote_ident()` | Identifier quoting |
| `OBJECT_ID()` | `to_regclass()` | Object existence check |
| `SERVERPROPERTY()` | Custom function | Server properties |
| `IS_ROLEMEMBER()` | `pg_has_role()` | Role membership check |
| `ORIGINAL_LOGIN()` | `session_user` | Original login name |
| `SESSION_CONTEXT()` | `current_setting()` | Session context values |

### JSON Functions Used

| Function | PostgreSQL Equivalent | Usage |
|----------|----------------------|-------|
| `JSON_VALUE()` | `->>'` or `jsonb_extract_path_text()` | Extract scalar value |
| `JSON_QUERY()` | `->` or `jsonb_extract_path()` | Extract JSON object/array |
| `JSON_MODIFY()` | `jsonb_set()` | Modify JSON |
| `ISJSON()` | Custom function | Validate JSON |
| `FOR JSON AUTO` | `json_agg()` / `row_to_json()` | Generate JSON output |
| `FOR JSON PATH` | `json_build_object()` | Generate JSON output |

### Full-Text Search Functions

| Function | PostgreSQL Equivalent | Usage |
|----------|----------------------|-------|
| `FREETEXTTABLE()` | `to_tsvector()` / `to_tsquery()` | Full-text search |
| `CONTAINSTABLE()` | `to_tsvector()` / `to_tsquery()` | Full-text search |
| `FREETEXT()` | `@@` operator | Full-text predicate |
| `CONTAINS()` | `@@` operator | Full-text predicate |

---

## 6. Security Features

### Row-Level Security (RLS)

File: `Security/FilterCustomersBySalesTerritoryRole.sql`
```sql
CREATE SECURITY POLICY [Application].[FilterCustomersBySalesTerritoryRole]
    ADD FILTER PREDICATE [Application].[DetermineCustomerAccess]([DeliveryCityID]) ON [Sales].[Customers],
    ADD BLOCK PREDICATE [Application].[DetermineCustomerAccess]([DeliveryCityID]) ON [Sales].[Customers] AFTER UPDATE
    WITH (STATE = ON);
```

### RLS Predicate Function

File: `Application/Functions/DetermineCustomerAccess.sql`
```sql
CREATE FUNCTION [Application].DetermineCustomerAccess(@CityID int)
RETURNS TABLE
WITH SCHEMABINDING
AS
RETURN (SELECT 1 AS AccessResult
        WHERE IS_ROLEMEMBER(N'db_owner') <> 0
        OR IS_ROLEMEMBER((SELECT sp.SalesTerritory
                          FROM [Application].Cities AS c
                          INNER JOIN [Application].StateProvinces AS sp
                          ON c.StateProvinceID = sp.StateProvinceID
                          WHERE c.CityID = @CityID) + N' Sales') <> 0
        OR ((ORIGINAL_LOGIN() = N'Website' OR ORIGINAL_LOGIN() = N'WebApi')
            AND EXISTS (SELECT 1
                        FROM [Application].Cities AS c
                        INNER JOIN [Application].StateProvinces AS sp
                        ON c.StateProvinceID = sp.StateProvinceID
                        WHERE c.CityID = @CityID
                        AND sp.SalesTerritory = SESSION_CONTEXT(N'SalesTerritory'))));
```

### Database Roles (Sales Territory Roles)

| Role Name | File Location |
|-----------|---------------|
| External Sales | `Security/External Sales.sql` |
| Far West Sales | `Security/Far West Sales.sql` |
| Great Lakes Sales | `Security/Great Lakes Sales.sql` |
| Mideast Sales | `Security/Mideast Sales.sql` |
| New England Sales | `Security/New England Sales.sql` |
| Plains Sales | `Security/Plains Sales.sql` |
| Rocky Mountain Sales | `Security/Rocky Mountain Sales.sql` |
| Southeast Sales | `Security/Southeast Sales.sql` |
| Southwest Sales | `Security/Southwest Sales.sql` |

### Schema Roles

| Schema | File Location |
|--------|---------------|
| Application | `Security/Application.sql` |
| DataLoadSimulation | `Security/DataLoadSimulation.sql` |
| Integration | `Security/Integration.sql` |
| PowerBI | `Security/PowerBI.sql` |
| Purchasing | `Security/Purchasing.sql` |
| Reports | `Security/Reports.sql` |
| Sales | `Security/Sales.sql` |
| Sequences | `Security/Sequences.sql` |
| Warehouse | `Security/Warehouse.sql` |
| Website | `Security/Website.sql` |
| WebApi | `Security/WebApi.sql` |

### Dynamic Data Masking

File: `Purchasing/Tables/Suppliers.sql`
```sql
[BankAccountName]       NVARCHAR (50) MASKED WITH (FUNCTION = 'default()') NULL,
[BankAccountBranch]     NVARCHAR (50) MASKED WITH (FUNCTION = 'default()') NULL,
[BankAccountCode]       NVARCHAR (20) MASKED WITH (FUNCTION = 'default()') NULL,
[BankAccountNumber]     NVARCHAR (20) MASKED WITH (FUNCTION = 'default()') NULL,
[BankInternationalCode] NVARCHAR (20) MASKED WITH (FUNCTION = 'default()') NULL,
```

---

## 7. Indexing Features

### Columnstore Indexes

| Table | Index Name | Type | File Location |
|-------|------------|------|---------------|
| Sales.OrderLines | NCCX_Sales_OrderLines | Non-clustered columnstore | `Sales/Tables/OrderLines.sql` |
| Fact.Sale | CCX_Fact_Sale | Clustered columnstore | `wwi-dw-ssdt/Fact/Tables/Sale.sql` |
| Fact.Order | CCX_Fact_Order | Clustered columnstore | `wwi-dw-ssdt/Fact/Tables/Order.sql` |
| Fact.Purchase | CCX_Fact_Purchase | Clustered columnstore | `wwi-dw-ssdt/Fact/Tables/Purchase.sql` |
| Fact.Movement | CCX_Fact_Movement | Clustered columnstore | `wwi-dw-ssdt/Fact/Tables/Movement.sql` |
| Fact.Transaction | CCX_Fact_Transaction | Clustered columnstore | `wwi-dw-ssdt/Fact/Tables/Transaction.sql` |
| Fact.Stock Holding | CCX_Fact_Stock_Holding | Clustered columnstore | `wwi-dw-ssdt/Fact/Tables/Stock Holding.sql` |

### Full-Text Indexes

Configured via `Application/Stored Procedures/Configuration_ApplyFullTextIndexing.sql`:
- `Application.People` - SearchName, CustomFields, OtherLanguages
- `Sales.Customers` - CustomerName
- `Purchasing.Suppliers` - SupplierName
- `Warehouse.StockItems` - SearchDetails, CustomFields, Tags

---

## 8. Partitioning

### OLAP Database Partitioning

Partition Function: `wwi-dw-ssdt/Storage/PF_Date.sql`
```sql
CREATE PARTITION FUNCTION [PF_Date](DATE)
    AS RANGE RIGHT
    FOR VALUES ('01/01/2012', '01/01/2013', '01/01/2014', '01/01/2015', '01/01/2016', '01/01/2017');
```

Partition Scheme: `wwi-dw-ssdt/Storage/PS_Date.sql`
```sql
CREATE PARTITION SCHEME [PS_Date]
    AS PARTITION [PF_Date]
    TO ([USERDATA], [USERDATA], [USERDATA], [USERDATA], [USERDATA], [USERDATA], [USERDATA], [USERDATA]);
```

### Partitioned Tables (OLAP)

All fact tables are partitioned by date:
- Fact.Sale - Partitioned on [Invoice Date Key]
- Fact.Order - Partitioned on [Order Date Key]
- Fact.Purchase - Partitioned on [Date Key]
- Fact.Movement - Partitioned on [Date Key]
- Fact.Transaction - Partitioned on [Date Key]
- Fact.Stock Holding - Partitioned on [As Of Date]

---

## 9. Sequences

All sequences are defined in `Sequences/Sequences/`:

| Sequence Name | Start Value | File Location |
|---------------|-------------|---------------|
| BuyingGroupID | 3 | `Sequences/Sequences/BuyingGroupID.sql` |
| CityID | 38188 | `Sequences/Sequences/CityID.sql` |
| ColorID | 37 | `Sequences/Sequences/ColorID.sql` |
| CountryID | 242 | `Sequences/Sequences/CountryID.sql` |
| CustomerCategoryID | 9 | `Sequences/Sequences/CustomerCategoryID.sql` |
| CustomerID | 1110 | `Sequences/Sequences/CustomerID.sql` |
| DeliveryMethodID | 11 | `Sequences/Sequences/DeliveryMethodID.sql` |
| InvoiceID | 70511 | `Sequences/Sequences/InvoiceID.sql` |
| InvoiceLineID | 228266 | `Sequences/Sequences/InvoiceLineID.sql` |
| OrderID | 73596 | `Sequences/Sequences/OrderID.sql` |
| OrderLineID | 231413 | `Sequences/Sequences/OrderLineID.sql` |
| PackageTypeID | 15 | `Sequences/Sequences/PackageTypeID.sql` |
| PaymentMethodID | 5 | `Sequences/Sequences/PaymentMethodID.sql` |
| PersonID | 3262 | `Sequences/Sequences/PersonID.sql` |
| PurchaseOrderID | 2075 | `Sequences/Sequences/PurchaseOrderID.sql` |
| PurchaseOrderLineID | 8368 | `Sequences/Sequences/PurchaseOrderLineID.sql` |
| SpecialDealID | 3 | `Sequences/Sequences/SpecialDealID.sql` |
| StateProvinceID | 54 | `Sequences/Sequences/StateProvinceID.sql` |
| StockGroupID | 11 | `Sequences/Sequences/StockGroupID.sql` |
| StockItemID | 228 | `Sequences/Sequences/StockItemID.sql` |
| StockItemStockGroupID | 443 | `Sequences/Sequences/StockItemStockGroupID.sql` |
| SupplierCategoryID | 10 | `Sequences/Sequences/SupplierCategoryID.sql` |
| SupplierID | 14 | `Sequences/Sequences/SupplierID.sql` |
| SystemParameterID | 2 | `Sequences/Sequences/SystemParameterID.sql` |
| TransactionID | 336253 | `Sequences/Sequences/TransactionID.sql` |
| TransactionTypeID | 14 | `Sequences/Sequences/TransactionTypeID.sql` |

---

## 10. Computed Columns

### Persisted Computed Columns

| Table | Column | Expression | File Location |
|-------|--------|------------|---------------|
| Application.People | SearchName | `concat([PreferredName],N' ',[FullName])` | `Application/Tables/People.sql` |
| Warehouse.StockItems | SearchDetails | `concat([StockItemName],N' ',[MarketingComments])` | `Warehouse/Tables/StockItems.sql` |

### Non-Persisted Computed Columns (JSON-based)

| Table | Column | Expression | File Location |
|-------|--------|------------|---------------|
| Application.People | OtherLanguages | `json_query([CustomFields],N'$.OtherLanguages')` | `Application/Tables/People.sql` |
| Warehouse.StockItems | Tags | `json_query([CustomFields],N'$.Tags')` | `Warehouse/Tables/StockItems.sql` |
| Sales.Invoices | ConfirmedDeliveryTime | `TRY_CONVERT([datetime2](7),json_value([ReturnedDeliveryData],N'$.DeliveredWhen'),(126))` | `Sales/Tables/Invoices.sql` |
| Sales.Invoices | ConfirmedReceivedBy | `json_value([ReturnedDeliveryData],N'$.ReceivedBy')` | `Sales/Tables/Invoices.sql` |

---

## 11. Constraints

### JSON Validation Constraints

File: `Sales/Tables/Invoices.sql`
```sql
CONSTRAINT [CK_Sales_Invoices_ReturnedDeliveryData_Must_Be_Valid_JSON] 
    CHECK ([ReturnedDeliveryData] IS NULL OR isjson([ReturnedDeliveryData])<>(0))
```

---

## 12. Extended Properties

Extended properties are used extensively for documentation. Example from `Application/Tables/People.sql`:
```sql
EXECUTE sp_addextendedproperty @name = N'Description', 
    @value = N'People known to the application (staff, customer contacts, supplier contacts)', 
    @level0type = N'SCHEMA', @level0name = N'Application', 
    @level1type = N'TABLE', @level1name = N'People';
```

PostgreSQL equivalent: `COMMENT ON TABLE/COLUMN`

---

## 13. ETL Components (SSIS)

Location: `wwi-ssis/wwi-ssis/`

### SSIS Packages

| Package | Purpose |
|---------|---------|
| DailyETLMain.dtsx | Main daily ETL package |

### Connection Managers

| Connection | Purpose |
|------------|---------|
| WWI_Source_DB.conmgr | Source OLTP database connection |
| WWI_DW_Destination_DB.conmgr | Destination DW database connection |

---

## 14. Analysis Services Components (SSAS)

Location: `wwi-ssasmd/wwi-ssasmd/`

### Dimensions

| Dimension | File |
|-----------|------|
| City | City.dim |
| Customer | Customer.dim |
| Date | Date.dim |
| Employee | Employee.dim |
| Payment Method | Payment Method.dim |
| Stock Item | Stock Item.dim |
| Supplier | Supplier.dim |
| Transaction Type | Transaction Type.dim |
| Purchase Finalized | Purchase Finalized.dim |
| Transaction Finalized | Transaction Finalized.dim |

### Cubes

| Cube | File |
|------|------|
| Wide World Importers | Wide World Importers.cube |

### Data Sources

| Data Source | File |
|-------------|------|
| WideWorldImportersDW | WideWorldImportersDW.ds |

---

## Summary Statistics

| Category | Count |
|----------|-------|
| Temporal Tables (OLTP) | 17 |
| Memory-Optimized Tables | 2 |
| Memory-Optimized Table Types | 4 |
| Stored Procedures (OLTP) | 50+ |
| Stored Procedures (OLAP) | 16 |
| Sequences | 26 |
| Database Roles | 20+ |
| Columnstore Indexes | 7 |
| Full-Text Indexed Tables | 4 |
| Partitioned Tables (OLAP) | 6 |
| SSIS Packages | 1 |
| SSAS Dimensions | 10 |
| SSAS Cubes | 1 |
