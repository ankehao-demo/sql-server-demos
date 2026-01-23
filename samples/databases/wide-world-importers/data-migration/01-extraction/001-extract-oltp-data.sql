-- Wide World Importers PostgreSQL Migration
-- Phase 6: Data Migration and Validation
-- File: 001-extract-oltp-data.sql
-- Description: SQL Server extraction queries for OLTP database (WideWorldImporters)
-- 
-- Usage: Run these queries against SQL Server to export data to CSV files
-- Use BCP or SQLCMD with -s "," -W options for CSV output
-- Example: sqlcmd -S localhost -d WideWorldImporters -Q "SELECT ... " -o output.csv -s "," -W

-- =============================================
-- Application Schema Tables
-- =============================================

-- Application.People (temporal table - extract both current and archive)
-- Note: SearchName is a computed column, we exclude it
SELECT 
    PersonID,
    FullName,
    PreferredName,
    IsPermittedToLogon,
    LogonName,
    IsExternalLogonProvider,
    CONVERT(VARCHAR(MAX), HashedPassword, 1) AS HashedPassword, -- Convert binary to hex string
    IsSystemUser,
    IsEmployee,
    IsSalesperson,
    UserPreferences,
    PhoneNumber,
    FaxNumber,
    EmailAddress,
    CONVERT(VARCHAR(MAX), Photo, 1) AS Photo, -- Convert binary to hex string
    CustomFields,
    LastEditedBy,
    ValidFrom,
    ValidTo
FROM Application.People
FOR SYSTEM_TIME ALL
ORDER BY PersonID, ValidFrom;

-- Application.Countries (temporal table)
SELECT 
    CountryID,
    CountryName,
    FormalName,
    IsoAlpha3Code,
    IsoNumericCode,
    CountryType,
    LatestRecordedPopulation,
    Continent,
    Region,
    Subregion,
    Border.STAsText() AS Border, -- Convert geography to WKT
    LastEditedBy,
    ValidFrom,
    ValidTo
FROM Application.Countries
FOR SYSTEM_TIME ALL
ORDER BY CountryID, ValidFrom;

-- Application.StateProvinces (temporal table)
SELECT 
    StateProvinceID,
    StateProvinceCode,
    StateProvinceName,
    CountryID,
    SalesTerritory,
    Border.STAsText() AS Border, -- Convert geography to WKT
    LatestRecordedPopulation,
    LastEditedBy,
    ValidFrom,
    ValidTo
FROM Application.StateProvinces
FOR SYSTEM_TIME ALL
ORDER BY StateProvinceID, ValidFrom;

-- Application.Cities (temporal table)
SELECT 
    CityID,
    CityName,
    StateProvinceID,
    Location.STAsText() AS Location, -- Convert geography to WKT
    LatestRecordedPopulation,
    LastEditedBy,
    ValidFrom,
    ValidTo
FROM Application.Cities
FOR SYSTEM_TIME ALL
ORDER BY CityID, ValidFrom;

-- Application.DeliveryMethods (temporal table)
SELECT 
    DeliveryMethodID,
    DeliveryMethodName,
    LastEditedBy,
    ValidFrom,
    ValidTo
FROM Application.DeliveryMethods
FOR SYSTEM_TIME ALL
ORDER BY DeliveryMethodID, ValidFrom;

-- Application.PaymentMethods (temporal table)
SELECT 
    PaymentMethodID,
    PaymentMethodName,
    LastEditedBy,
    ValidFrom,
    ValidTo
FROM Application.PaymentMethods
FOR SYSTEM_TIME ALL
ORDER BY PaymentMethodID, ValidFrom;

-- Application.TransactionTypes (temporal table)
SELECT 
    TransactionTypeID,
    TransactionTypeName,
    LastEditedBy,
    ValidFrom,
    ValidTo
FROM Application.TransactionTypes
FOR SYSTEM_TIME ALL
ORDER BY TransactionTypeID, ValidFrom;

-- Application.SystemParameters (non-temporal)
SELECT 
    SystemParameterID,
    DeliveryAddressLine1,
    DeliveryAddressLine2,
    DeliveryCityID,
    DeliveryPostalCode,
    DeliveryLocation.STAsText() AS DeliveryLocation,
    PostalAddressLine1,
    PostalAddressLine2,
    PostalCityID,
    PostalPostalCode,
    ApplicationSettings,
    LastEditedBy,
    LastEditedWhen
FROM Application.SystemParameters
ORDER BY SystemParameterID;

-- =============================================
-- Warehouse Schema Tables
-- =============================================

-- Warehouse.Colors (temporal table)
SELECT 
    ColorID,
    ColorName,
    LastEditedBy,
    ValidFrom,
    ValidTo
FROM Warehouse.Colors
FOR SYSTEM_TIME ALL
ORDER BY ColorID, ValidFrom;

-- Warehouse.PackageTypes (temporal table)
SELECT 
    PackageTypeID,
    PackageTypeName,
    LastEditedBy,
    ValidFrom,
    ValidTo
FROM Warehouse.PackageTypes
FOR SYSTEM_TIME ALL
ORDER BY PackageTypeID, ValidFrom;

-- Warehouse.StockGroups (temporal table)
SELECT 
    StockGroupID,
    StockGroupName,
    LastEditedBy,
    ValidFrom,
    ValidTo
FROM Warehouse.StockGroups
FOR SYSTEM_TIME ALL
ORDER BY StockGroupID, ValidFrom;

-- Warehouse.StockItems (temporal table)
-- Note: SearchDetails and Tags are computed columns
SELECT 
    StockItemID,
    StockItemName,
    SupplierID,
    ColorID,
    UnitPackageID,
    OuterPackageID,
    Brand,
    Size,
    LeadTimeDays,
    QuantityPerOuter,
    IsChillerStock,
    Barcode,
    TaxRate,
    UnitPrice,
    RecommendedRetailPrice,
    TypicalWeightPerUnit,
    MarketingComments,
    InternalComments,
    CONVERT(VARCHAR(MAX), Photo, 1) AS Photo,
    CustomFields,
    LastEditedBy,
    ValidFrom,
    ValidTo
FROM Warehouse.StockItems
FOR SYSTEM_TIME ALL
ORDER BY StockItemID, ValidFrom;

-- Warehouse.StockItemHoldings (non-temporal)
SELECT 
    StockItemID,
    QuantityOnHand,
    BinLocation,
    LastStocktakeQuantity,
    LastCostPrice,
    ReorderLevel,
    TargetStockLevel,
    LastEditedBy,
    LastEditedWhen
FROM Warehouse.StockItemHoldings
ORDER BY StockItemID;

-- Warehouse.StockItemStockGroups (non-temporal)
SELECT 
    StockItemStockGroupID,
    StockItemID,
    StockGroupID,
    LastEditedBy,
    LastEditedWhen
FROM Warehouse.StockItemStockGroups
ORDER BY StockItemStockGroupID;

-- Warehouse.StockItemTransactions (non-temporal)
SELECT 
    StockItemTransactionID,
    StockItemID,
    TransactionTypeID,
    CustomerID,
    InvoiceID,
    SupplierID,
    PurchaseOrderID,
    TransactionOccurredWhen,
    Quantity,
    LastEditedBy,
    LastEditedWhen
FROM Warehouse.StockItemTransactions
ORDER BY StockItemTransactionID;

-- Warehouse.ColdRoomTemperatures (temporal, was memory-optimized)
SELECT 
    ColdRoomTemperatureID,
    ColdRoomSensorNumber,
    RecordedWhen,
    Temperature,
    ValidFrom,
    ValidTo
FROM Warehouse.ColdRoomTemperatures
FOR SYSTEM_TIME ALL
ORDER BY ColdRoomTemperatureID, ValidFrom;

-- Warehouse.VehicleTemperatures (non-temporal, was memory-optimized)
SELECT 
    VehicleTemperatureID,
    VehicleRegistration,
    ChillerSensorNumber,
    RecordedWhen,
    Temperature,
    FullSensorData,
    IsCompressed,
    CONVERT(VARCHAR(MAX), CompressedSensorData, 1) AS CompressedSensorData
FROM Warehouse.VehicleTemperatures
ORDER BY VehicleTemperatureID;

-- =============================================
-- Sales Schema Tables
-- =============================================

-- Sales.BuyingGroups (temporal table)
SELECT 
    BuyingGroupID,
    BuyingGroupName,
    LastEditedBy,
    ValidFrom,
    ValidTo
FROM Sales.BuyingGroups
FOR SYSTEM_TIME ALL
ORDER BY BuyingGroupID, ValidFrom;

-- Sales.CustomerCategories (temporal table)
SELECT 
    CustomerCategoryID,
    CustomerCategoryName,
    LastEditedBy,
    ValidFrom,
    ValidTo
FROM Sales.CustomerCategories
FOR SYSTEM_TIME ALL
ORDER BY CustomerCategoryID, ValidFrom;

-- Sales.Customers (temporal table)
SELECT 
    CustomerID,
    CustomerName,
    BillToCustomerID,
    CustomerCategoryID,
    BuyingGroupID,
    PrimaryContactPersonID,
    AlternateContactPersonID,
    DeliveryMethodID,
    DeliveryCityID,
    PostalCityID,
    CreditLimit,
    AccountOpenedDate,
    StandardDiscountPercentage,
    IsStatementSent,
    IsOnCreditHold,
    PaymentDays,
    PhoneNumber,
    FaxNumber,
    DeliveryRun,
    RunPosition,
    WebsiteURL,
    DeliveryAddressLine1,
    DeliveryAddressLine2,
    DeliveryPostalCode,
    DeliveryLocation.STAsText() AS DeliveryLocation,
    PostalAddressLine1,
    PostalAddressLine2,
    PostalPostalCode,
    LastEditedBy,
    ValidFrom,
    ValidTo
FROM Sales.Customers
FOR SYSTEM_TIME ALL
ORDER BY CustomerID, ValidFrom;

-- Sales.Orders (non-temporal)
SELECT 
    OrderID,
    CustomerID,
    SalespersonPersonID,
    PickedByPersonID,
    ContactPersonID,
    BackorderOrderID,
    OrderDate,
    ExpectedDeliveryDate,
    CustomerPurchaseOrderNumber,
    IsUndersupplyBackordered,
    Comments,
    DeliveryInstructions,
    InternalComments,
    PickingCompletedWhen,
    LastEditedBy,
    LastEditedWhen
FROM Sales.Orders
ORDER BY OrderID;

-- Sales.OrderLines (non-temporal)
SELECT 
    OrderLineID,
    OrderID,
    StockItemID,
    Description,
    PackageTypeID,
    Quantity,
    UnitPrice,
    TaxRate,
    PickedQuantity,
    PickingCompletedWhen,
    LastEditedBy,
    LastEditedWhen
FROM Sales.OrderLines
ORDER BY OrderLineID;

-- Sales.Invoices (non-temporal)
-- Note: ConfirmedDeliveryTime and ConfirmedReceivedBy are computed columns
SELECT 
    InvoiceID,
    CustomerID,
    BillToCustomerID,
    OrderID,
    DeliveryMethodID,
    ContactPersonID,
    AccountsPersonID,
    SalespersonPersonID,
    PackedByPersonID,
    InvoiceDate,
    CustomerPurchaseOrderNumber,
    IsCreditNote,
    CreditNoteReason,
    Comments,
    DeliveryInstructions,
    InternalComments,
    TotalDryItems,
    TotalChillerItems,
    DeliveryRun,
    RunPosition,
    ReturnedDeliveryData,
    LastEditedBy,
    LastEditedWhen
FROM Sales.Invoices
ORDER BY InvoiceID;

-- Sales.InvoiceLines (non-temporal)
SELECT 
    InvoiceLineID,
    InvoiceID,
    StockItemID,
    Description,
    PackageTypeID,
    Quantity,
    UnitPrice,
    TaxRate,
    TaxAmount,
    LineProfit,
    ExtendedPrice,
    LastEditedBy,
    LastEditedWhen
FROM Sales.InvoiceLines
ORDER BY InvoiceLineID;

-- Sales.SpecialDeals (non-temporal)
SELECT 
    SpecialDealID,
    StockItemID,
    CustomerID,
    BuyingGroupID,
    CustomerCategoryID,
    StockGroupID,
    DealDescription,
    StartDate,
    EndDate,
    DiscountAmount,
    DiscountPercentage,
    UnitPrice,
    LastEditedBy,
    LastEditedWhen
FROM Sales.SpecialDeals
ORDER BY SpecialDealID;

-- Sales.CustomerTransactions (non-temporal)
-- Note: IsFinalized is a computed column
SELECT 
    CustomerTransactionID,
    CustomerID,
    TransactionTypeID,
    InvoiceID,
    PaymentMethodID,
    TransactionDate,
    AmountExcludingTax,
    TaxAmount,
    TransactionAmount,
    OutstandingBalance,
    FinalizationDate,
    LastEditedBy,
    LastEditedWhen
FROM Sales.CustomerTransactions
ORDER BY CustomerTransactionID;

-- =============================================
-- Purchasing Schema Tables
-- =============================================

-- Purchasing.SupplierCategories (temporal table)
SELECT 
    SupplierCategoryID,
    SupplierCategoryName,
    LastEditedBy,
    ValidFrom,
    ValidTo
FROM Purchasing.SupplierCategories
FOR SYSTEM_TIME ALL
ORDER BY SupplierCategoryID, ValidFrom;

-- Purchasing.Suppliers (temporal table)
SELECT 
    SupplierID,
    SupplierName,
    SupplierCategoryID,
    PrimaryContactPersonID,
    AlternateContactPersonID,
    DeliveryMethodID,
    DeliveryCityID,
    PostalCityID,
    SupplierReference,
    BankAccountName,
    BankAccountBranch,
    BankAccountCode,
    BankAccountNumber,
    BankInternationalCode,
    PaymentDays,
    InternalComments,
    PhoneNumber,
    FaxNumber,
    WebsiteURL,
    DeliveryAddressLine1,
    DeliveryAddressLine2,
    DeliveryPostalCode,
    DeliveryLocation.STAsText() AS DeliveryLocation,
    PostalAddressLine1,
    PostalAddressLine2,
    PostalPostalCode,
    LastEditedBy,
    ValidFrom,
    ValidTo
FROM Purchasing.Suppliers
FOR SYSTEM_TIME ALL
ORDER BY SupplierID, ValidFrom;

-- Purchasing.PurchaseOrders (non-temporal)
SELECT 
    PurchaseOrderID,
    SupplierID,
    OrderDate,
    DeliveryMethodID,
    ContactPersonID,
    ExpectedDeliveryDate,
    SupplierReference,
    IsOrderFinalized,
    Comments,
    InternalComments,
    LastEditedBy,
    LastEditedWhen
FROM Purchasing.PurchaseOrders
ORDER BY PurchaseOrderID;

-- Purchasing.PurchaseOrderLines (non-temporal)
SELECT 
    PurchaseOrderLineID,
    PurchaseOrderID,
    StockItemID,
    OrderedOuters,
    Description,
    ReceivedOuters,
    PackageTypeID,
    ExpectedUnitPricePerOuter,
    LastReceiptDate,
    IsOrderLineFinalized,
    LastEditedBy,
    LastEditedWhen
FROM Purchasing.PurchaseOrderLines
ORDER BY PurchaseOrderLineID;

-- Purchasing.SupplierTransactions (non-temporal)
-- Note: IsFinalized is a computed column
SELECT 
    SupplierTransactionID,
    SupplierID,
    TransactionTypeID,
    PurchaseOrderID,
    PaymentMethodID,
    SupplierInvoiceNumber,
    TransactionDate,
    AmountExcludingTax,
    TaxAmount,
    TransactionAmount,
    OutstandingBalance,
    FinalizationDate,
    LastEditedBy,
    LastEditedWhen
FROM Purchasing.SupplierTransactions
ORDER BY SupplierTransactionID;
