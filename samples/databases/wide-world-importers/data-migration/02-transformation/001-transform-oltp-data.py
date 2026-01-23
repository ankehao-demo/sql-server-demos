#!/usr/bin/env python3
"""
Wide World Importers PostgreSQL Migration
Phase 6: Data Migration and Validation
File: 001-transform-oltp-data.py
Description: Transform extracted SQL Server data for PostgreSQL compatibility

This script handles the following transformations:
1. Binary data (varbinary) -> PostgreSQL bytea format (hex encoding)
2. Geography data (WKT) -> PostGIS geography format
3. Boolean values (0/1) -> PostgreSQL boolean (true/false)
4. DateTime2 -> PostgreSQL timestamp
5. NULL handling
6. Separating temporal data into current and archive tables
"""

import csv
import os
import sys
import re
from datetime import datetime
from pathlib import Path

# Configuration
INPUT_DIR = os.environ.get('INPUT_DIR', './extracted_data')
OUTPUT_DIR = os.environ.get('OUTPUT_DIR', './transformed_data')
DELIMITER = '|'
MAX_TIMESTAMP = '9999-12-31 23:59:59.999999'


def ensure_output_dirs():
    """Create output directories if they don't exist."""
    Path(f"{OUTPUT_DIR}/oltp/current").mkdir(parents=True, exist_ok=True)
    Path(f"{OUTPUT_DIR}/oltp/archive").mkdir(parents=True, exist_ok=True)
    Path(f"{OUTPUT_DIR}/olap").mkdir(parents=True, exist_ok=True)


def transform_binary(value):
    """Transform SQL Server binary hex string to PostgreSQL bytea format."""
    if not value or value.upper() == 'NULL' or value == '':
        return None
    # SQL Server outputs binary as 0x... hex string
    if value.startswith('0x') or value.startswith('0X'):
        # PostgreSQL bytea hex format: \x...
        return '\\x' + value[2:]
    return value


def transform_boolean(value):
    """Transform SQL Server bit (0/1) to PostgreSQL boolean."""
    if value is None or value == '' or value.upper() == 'NULL':
        return None
    if isinstance(value, bool):
        return value
    if str(value).lower() in ('1', 'true', 't', 'yes'):
        return True
    if str(value).lower() in ('0', 'false', 'f', 'no'):
        return False
    return None


def transform_geography(wkt_value):
    """Transform WKT geography to PostGIS format."""
    if not wkt_value or wkt_value.upper() == 'NULL' or wkt_value == '':
        return None
    # PostGIS accepts WKT directly with ST_GeogFromText
    # We'll store the WKT and let the load script handle conversion
    return wkt_value


def transform_timestamp(value):
    """Transform SQL Server datetime2 to PostgreSQL timestamp."""
    if not value or value.upper() == 'NULL' or value == '':
        return None
    # Handle various datetime formats
    try:
        # Try parsing common SQL Server formats
        for fmt in [
            '%Y-%m-%d %H:%M:%S.%f',
            '%Y-%m-%d %H:%M:%S',
            '%Y-%m-%dT%H:%M:%S.%f',
            '%Y-%m-%dT%H:%M:%S',
            '%b %d %Y %I:%M%p',
            '%Y-%m-%d'
        ]:
            try:
                dt = datetime.strptime(value.strip(), fmt)
                return dt.strftime('%Y-%m-%d %H:%M:%S.%f')
            except ValueError:
                continue
        return value  # Return as-is if no format matches
    except Exception:
        return value


def transform_null(value):
    """Handle NULL values consistently."""
    if value is None:
        return None
    if isinstance(value, str):
        if value.upper() == 'NULL' or value.strip() == '':
            return None
    return value


def is_current_record(valid_to):
    """Check if a temporal record is current (not archived)."""
    if not valid_to:
        return True
    try:
        vt = valid_to.strip()
        # Check if valid_to is the max timestamp (current record)
        return vt.startswith('9999-12-31')
    except Exception:
        return True


def split_temporal_data(input_file, current_file, archive_file, transform_func):
    """Split temporal table data into current and archive files."""
    if not os.path.exists(input_file):
        print(f"  Warning: Input file not found: {input_file}")
        return 0, 0
    
    current_count = 0
    archive_count = 0
    
    with open(input_file, 'r', encoding='utf-8') as infile, \
         open(current_file, 'w', encoding='utf-8', newline='') as curr_out, \
         open(archive_file, 'w', encoding='utf-8', newline='') as arch_out:
        
        reader = csv.reader(infile, delimiter=DELIMITER)
        curr_writer = csv.writer(curr_out, delimiter=DELIMITER, quoting=csv.QUOTE_MINIMAL)
        arch_writer = csv.writer(arch_out, delimiter=DELIMITER, quoting=csv.QUOTE_MINIMAL)
        
        for row in reader:
            if not row or all(not cell.strip() for cell in row):
                continue
            
            transformed_row = transform_func(row)
            if transformed_row is None:
                continue
            
            # ValidTo is typically the last column for temporal tables
            valid_to_idx = len(transformed_row) - 1
            valid_to = transformed_row[valid_to_idx] if valid_to_idx >= 0 else None
            
            if is_current_record(valid_to):
                curr_writer.writerow(transformed_row)
                current_count += 1
            else:
                arch_writer.writerow(transformed_row)
                archive_count += 1
    
    return current_count, archive_count


def transform_non_temporal(input_file, output_file, transform_func):
    """Transform non-temporal table data."""
    if not os.path.exists(input_file):
        print(f"  Warning: Input file not found: {input_file}")
        return 0
    
    count = 0
    with open(input_file, 'r', encoding='utf-8') as infile, \
         open(output_file, 'w', encoding='utf-8', newline='') as outfile:
        
        reader = csv.reader(infile, delimiter=DELIMITER)
        writer = csv.writer(outfile, delimiter=DELIMITER, quoting=csv.QUOTE_MINIMAL)
        
        for row in reader:
            if not row or all(not cell.strip() for cell in row):
                continue
            
            transformed_row = transform_func(row)
            if transformed_row is not None:
                writer.writerow(transformed_row)
                count += 1
    
    return count


# =============================================
# Application Schema Transformations
# =============================================

def transform_people(row):
    """Transform Application.People row."""
    if len(row) < 19:
        return None
    return [
        transform_null(row[0]),   # PersonID
        transform_null(row[1]),   # FullName
        transform_null(row[2]),   # PreferredName
        transform_boolean(row[3]), # IsPermittedToLogon
        transform_null(row[4]),   # LogonName
        transform_boolean(row[5]), # IsExternalLogonProvider
        transform_binary(row[6]),  # HashedPassword
        transform_boolean(row[7]), # IsSystemUser
        transform_boolean(row[8]), # IsEmployee
        transform_boolean(row[9]), # IsSalesperson
        transform_null(row[10]),  # UserPreferences
        transform_null(row[11]),  # PhoneNumber
        transform_null(row[12]),  # FaxNumber
        transform_null(row[13]),  # EmailAddress
        transform_binary(row[14]), # Photo
        transform_null(row[15]),  # CustomFields
        transform_null(row[16]),  # LastEditedBy
        transform_timestamp(row[17]), # ValidFrom
        transform_timestamp(row[18])  # ValidTo
    ]


def transform_countries(row):
    """Transform Application.Countries row."""
    if len(row) < 14:
        return None
    return [
        transform_null(row[0]),   # CountryID
        transform_null(row[1]),   # CountryName
        transform_null(row[2]),   # FormalName
        transform_null(row[3]),   # IsoAlpha3Code
        transform_null(row[4]),   # IsoNumericCode
        transform_null(row[5]),   # CountryType
        transform_null(row[6]),   # LatestRecordedPopulation
        transform_null(row[7]),   # Continent
        transform_null(row[8]),   # Region
        transform_null(row[9]),   # Subregion
        transform_geography(row[10]), # Border
        transform_null(row[11]),  # LastEditedBy
        transform_timestamp(row[12]), # ValidFrom
        transform_timestamp(row[13])  # ValidTo
    ]


def transform_stateprovinces(row):
    """Transform Application.StateProvinces row."""
    if len(row) < 10:
        return None
    return [
        transform_null(row[0]),   # StateProvinceID
        transform_null(row[1]),   # StateProvinceCode
        transform_null(row[2]),   # StateProvinceName
        transform_null(row[3]),   # CountryID
        transform_null(row[4]),   # SalesTerritory
        transform_geography(row[5]), # Border
        transform_null(row[6]),   # LatestRecordedPopulation
        transform_null(row[7]),   # LastEditedBy
        transform_timestamp(row[8]), # ValidFrom
        transform_timestamp(row[9])  # ValidTo
    ]


def transform_cities(row):
    """Transform Application.Cities row."""
    if len(row) < 8:
        return None
    return [
        transform_null(row[0]),   # CityID
        transform_null(row[1]),   # CityName
        transform_null(row[2]),   # StateProvinceID
        transform_geography(row[3]), # Location
        transform_null(row[4]),   # LatestRecordedPopulation
        transform_null(row[5]),   # LastEditedBy
        transform_timestamp(row[6]), # ValidFrom
        transform_timestamp(row[7])  # ValidTo
    ]


def transform_deliverymethods(row):
    """Transform Application.DeliveryMethods row."""
    if len(row) < 5:
        return None
    return [
        transform_null(row[0]),   # DeliveryMethodID
        transform_null(row[1]),   # DeliveryMethodName
        transform_null(row[2]),   # LastEditedBy
        transform_timestamp(row[3]), # ValidFrom
        transform_timestamp(row[4])  # ValidTo
    ]


def transform_paymentmethods(row):
    """Transform Application.PaymentMethods row."""
    if len(row) < 5:
        return None
    return [
        transform_null(row[0]),   # PaymentMethodID
        transform_null(row[1]),   # PaymentMethodName
        transform_null(row[2]),   # LastEditedBy
        transform_timestamp(row[3]), # ValidFrom
        transform_timestamp(row[4])  # ValidTo
    ]


def transform_transactiontypes(row):
    """Transform Application.TransactionTypes row."""
    if len(row) < 5:
        return None
    return [
        transform_null(row[0]),   # TransactionTypeID
        transform_null(row[1]),   # TransactionTypeName
        transform_null(row[2]),   # LastEditedBy
        transform_timestamp(row[3]), # ValidFrom
        transform_timestamp(row[4])  # ValidTo
    ]


def transform_systemparameters(row):
    """Transform Application.SystemParameters row."""
    if len(row) < 13:
        return None
    return [
        transform_null(row[0]),   # SystemParameterID
        transform_null(row[1]),   # DeliveryAddressLine1
        transform_null(row[2]),   # DeliveryAddressLine2
        transform_null(row[3]),   # DeliveryCityID
        transform_null(row[4]),   # DeliveryPostalCode
        transform_geography(row[5]), # DeliveryLocation
        transform_null(row[6]),   # PostalAddressLine1
        transform_null(row[7]),   # PostalAddressLine2
        transform_null(row[8]),   # PostalCityID
        transform_null(row[9]),   # PostalPostalCode
        transform_null(row[10]),  # ApplicationSettings
        transform_null(row[11]),  # LastEditedBy
        transform_timestamp(row[12])  # LastEditedWhen
    ]


# =============================================
# Warehouse Schema Transformations
# =============================================

def transform_colors(row):
    """Transform Warehouse.Colors row."""
    if len(row) < 5:
        return None
    return [
        transform_null(row[0]),   # ColorID
        transform_null(row[1]),   # ColorName
        transform_null(row[2]),   # LastEditedBy
        transform_timestamp(row[3]), # ValidFrom
        transform_timestamp(row[4])  # ValidTo
    ]


def transform_packagetypes(row):
    """Transform Warehouse.PackageTypes row."""
    if len(row) < 5:
        return None
    return [
        transform_null(row[0]),   # PackageTypeID
        transform_null(row[1]),   # PackageTypeName
        transform_null(row[2]),   # LastEditedBy
        transform_timestamp(row[3]), # ValidFrom
        transform_timestamp(row[4])  # ValidTo
    ]


def transform_stockgroups(row):
    """Transform Warehouse.StockGroups row."""
    if len(row) < 5:
        return None
    return [
        transform_null(row[0]),   # StockGroupID
        transform_null(row[1]),   # StockGroupName
        transform_null(row[2]),   # LastEditedBy
        transform_timestamp(row[3]), # ValidFrom
        transform_timestamp(row[4])  # ValidTo
    ]


def transform_stockitems(row):
    """Transform Warehouse.StockItems row."""
    if len(row) < 23:
        return None
    return [
        transform_null(row[0]),   # StockItemID
        transform_null(row[1]),   # StockItemName
        transform_null(row[2]),   # SupplierID
        transform_null(row[3]),   # ColorID
        transform_null(row[4]),   # UnitPackageID
        transform_null(row[5]),   # OuterPackageID
        transform_null(row[6]),   # Brand
        transform_null(row[7]),   # Size
        transform_null(row[8]),   # LeadTimeDays
        transform_null(row[9]),   # QuantityPerOuter
        transform_boolean(row[10]), # IsChillerStock
        transform_null(row[11]),  # Barcode
        transform_null(row[12]),  # TaxRate
        transform_null(row[13]),  # UnitPrice
        transform_null(row[14]),  # RecommendedRetailPrice
        transform_null(row[15]),  # TypicalWeightPerUnit
        transform_null(row[16]),  # MarketingComments
        transform_null(row[17]),  # InternalComments
        transform_binary(row[18]), # Photo
        transform_null(row[19]),  # CustomFields
        transform_null(row[20]),  # LastEditedBy
        transform_timestamp(row[21]), # ValidFrom
        transform_timestamp(row[22])  # ValidTo
    ]


def transform_stockitemholdings(row):
    """Transform Warehouse.StockItemHoldings row."""
    if len(row) < 9:
        return None
    return [
        transform_null(row[0]),   # StockItemID
        transform_null(row[1]),   # QuantityOnHand
        transform_null(row[2]),   # BinLocation
        transform_null(row[3]),   # LastStocktakeQuantity
        transform_null(row[4]),   # LastCostPrice
        transform_null(row[5]),   # ReorderLevel
        transform_null(row[6]),   # TargetStockLevel
        transform_null(row[7]),   # LastEditedBy
        transform_timestamp(row[8])  # LastEditedWhen
    ]


def transform_stockitemstockgroups(row):
    """Transform Warehouse.StockItemStockGroups row."""
    if len(row) < 5:
        return None
    return [
        transform_null(row[0]),   # StockItemStockGroupID
        transform_null(row[1]),   # StockItemID
        transform_null(row[2]),   # StockGroupID
        transform_null(row[3]),   # LastEditedBy
        transform_timestamp(row[4])  # LastEditedWhen
    ]


def transform_stockitemtransactions(row):
    """Transform Warehouse.StockItemTransactions row."""
    if len(row) < 11:
        return None
    return [
        transform_null(row[0]),   # StockItemTransactionID
        transform_null(row[1]),   # StockItemID
        transform_null(row[2]),   # TransactionTypeID
        transform_null(row[3]),   # CustomerID
        transform_null(row[4]),   # InvoiceID
        transform_null(row[5]),   # SupplierID
        transform_null(row[6]),   # PurchaseOrderID
        transform_timestamp(row[7]), # TransactionOccurredWhen
        transform_null(row[8]),   # Quantity
        transform_null(row[9]),   # LastEditedBy
        transform_timestamp(row[10])  # LastEditedWhen
    ]


def transform_coldroomtemperatures(row):
    """Transform Warehouse.ColdRoomTemperatures row."""
    if len(row) < 6:
        return None
    return [
        transform_null(row[0]),   # ColdRoomTemperatureID
        transform_null(row[1]),   # ColdRoomSensorNumber
        transform_timestamp(row[2]), # RecordedWhen
        transform_null(row[3]),   # Temperature
        transform_timestamp(row[4]), # ValidFrom
        transform_timestamp(row[5])  # ValidTo
    ]


def transform_vehicletemperatures(row):
    """Transform Warehouse.VehicleTemperatures row."""
    if len(row) < 8:
        return None
    return [
        transform_null(row[0]),   # VehicleTemperatureID
        transform_null(row[1]),   # VehicleRegistration
        transform_null(row[2]),   # ChillerSensorNumber
        transform_timestamp(row[3]), # RecordedWhen
        transform_null(row[4]),   # Temperature
        transform_null(row[5]),   # FullSensorData
        transform_boolean(row[6]), # IsCompressed
        transform_binary(row[7])   # CompressedSensorData
    ]


# =============================================
# Sales Schema Transformations
# =============================================

def transform_buyinggroups(row):
    """Transform Sales.BuyingGroups row."""
    if len(row) < 5:
        return None
    return [
        transform_null(row[0]),   # BuyingGroupID
        transform_null(row[1]),   # BuyingGroupName
        transform_null(row[2]),   # LastEditedBy
        transform_timestamp(row[3]), # ValidFrom
        transform_timestamp(row[4])  # ValidTo
    ]


def transform_customercategories(row):
    """Transform Sales.CustomerCategories row."""
    if len(row) < 5:
        return None
    return [
        transform_null(row[0]),   # CustomerCategoryID
        transform_null(row[1]),   # CustomerCategoryName
        transform_null(row[2]),   # LastEditedBy
        transform_timestamp(row[3]), # ValidFrom
        transform_timestamp(row[4])  # ValidTo
    ]


def transform_customers(row):
    """Transform Sales.Customers row."""
    if len(row) < 31:
        return None
    return [
        transform_null(row[0]),   # CustomerID
        transform_null(row[1]),   # CustomerName
        transform_null(row[2]),   # BillToCustomerID
        transform_null(row[3]),   # CustomerCategoryID
        transform_null(row[4]),   # BuyingGroupID
        transform_null(row[5]),   # PrimaryContactPersonID
        transform_null(row[6]),   # AlternateContactPersonID
        transform_null(row[7]),   # DeliveryMethodID
        transform_null(row[8]),   # DeliveryCityID
        transform_null(row[9]),   # PostalCityID
        transform_null(row[10]),  # CreditLimit
        transform_null(row[11]),  # AccountOpenedDate
        transform_null(row[12]),  # StandardDiscountPercentage
        transform_boolean(row[13]), # IsStatementSent
        transform_boolean(row[14]), # IsOnCreditHold
        transform_null(row[15]),  # PaymentDays
        transform_null(row[16]),  # PhoneNumber
        transform_null(row[17]),  # FaxNumber
        transform_null(row[18]),  # DeliveryRun
        transform_null(row[19]),  # RunPosition
        transform_null(row[20]),  # WebsiteURL
        transform_null(row[21]),  # DeliveryAddressLine1
        transform_null(row[22]),  # DeliveryAddressLine2
        transform_null(row[23]),  # DeliveryPostalCode
        transform_geography(row[24]), # DeliveryLocation
        transform_null(row[25]),  # PostalAddressLine1
        transform_null(row[26]),  # PostalAddressLine2
        transform_null(row[27]),  # PostalPostalCode
        transform_null(row[28]),  # LastEditedBy
        transform_timestamp(row[29]), # ValidFrom
        transform_timestamp(row[30])  # ValidTo
    ]


def transform_orders(row):
    """Transform Sales.Orders row."""
    if len(row) < 16:
        return None
    return [
        transform_null(row[0]),   # OrderID
        transform_null(row[1]),   # CustomerID
        transform_null(row[2]),   # SalespersonPersonID
        transform_null(row[3]),   # PickedByPersonID
        transform_null(row[4]),   # ContactPersonID
        transform_null(row[5]),   # BackorderOrderID
        transform_null(row[6]),   # OrderDate
        transform_null(row[7]),   # ExpectedDeliveryDate
        transform_null(row[8]),   # CustomerPurchaseOrderNumber
        transform_boolean(row[9]), # IsUndersupplyBackordered
        transform_null(row[10]),  # Comments
        transform_null(row[11]),  # DeliveryInstructions
        transform_null(row[12]),  # InternalComments
        transform_timestamp(row[13]), # PickingCompletedWhen
        transform_null(row[14]),  # LastEditedBy
        transform_timestamp(row[15])  # LastEditedWhen
    ]


def transform_orderlines(row):
    """Transform Sales.OrderLines row."""
    if len(row) < 12:
        return None
    return [
        transform_null(row[0]),   # OrderLineID
        transform_null(row[1]),   # OrderID
        transform_null(row[2]),   # StockItemID
        transform_null(row[3]),   # Description
        transform_null(row[4]),   # PackageTypeID
        transform_null(row[5]),   # Quantity
        transform_null(row[6]),   # UnitPrice
        transform_null(row[7]),   # TaxRate
        transform_null(row[8]),   # PickedQuantity
        transform_timestamp(row[9]), # PickingCompletedWhen
        transform_null(row[10]),  # LastEditedBy
        transform_timestamp(row[11])  # LastEditedWhen
    ]


def transform_invoices(row):
    """Transform Sales.Invoices row."""
    if len(row) < 22:
        return None
    return [
        transform_null(row[0]),   # InvoiceID
        transform_null(row[1]),   # CustomerID
        transform_null(row[2]),   # BillToCustomerID
        transform_null(row[3]),   # OrderID
        transform_null(row[4]),   # DeliveryMethodID
        transform_null(row[5]),   # ContactPersonID
        transform_null(row[6]),   # AccountsPersonID
        transform_null(row[7]),   # SalespersonPersonID
        transform_null(row[8]),   # PackedByPersonID
        transform_null(row[9]),   # InvoiceDate
        transform_null(row[10]),  # CustomerPurchaseOrderNumber
        transform_boolean(row[11]), # IsCreditNote
        transform_null(row[12]),  # CreditNoteReason
        transform_null(row[13]),  # Comments
        transform_null(row[14]),  # DeliveryInstructions
        transform_null(row[15]),  # InternalComments
        transform_null(row[16]),  # TotalDryItems
        transform_null(row[17]),  # TotalChillerItems
        transform_null(row[18]),  # DeliveryRun
        transform_null(row[19]),  # RunPosition
        transform_null(row[20]),  # ReturnedDeliveryData
        transform_null(row[21]),  # LastEditedBy
        transform_timestamp(row[22]) if len(row) > 22 else None  # LastEditedWhen
    ]


def transform_invoicelines(row):
    """Transform Sales.InvoiceLines row."""
    if len(row) < 13:
        return None
    return [
        transform_null(row[0]),   # InvoiceLineID
        transform_null(row[1]),   # InvoiceID
        transform_null(row[2]),   # StockItemID
        transform_null(row[3]),   # Description
        transform_null(row[4]),   # PackageTypeID
        transform_null(row[5]),   # Quantity
        transform_null(row[6]),   # UnitPrice
        transform_null(row[7]),   # TaxRate
        transform_null(row[8]),   # TaxAmount
        transform_null(row[9]),   # LineProfit
        transform_null(row[10]),  # ExtendedPrice
        transform_null(row[11]),  # LastEditedBy
        transform_timestamp(row[12])  # LastEditedWhen
    ]


def transform_specialdeals(row):
    """Transform Sales.SpecialDeals row."""
    if len(row) < 14:
        return None
    return [
        transform_null(row[0]),   # SpecialDealID
        transform_null(row[1]),   # StockItemID
        transform_null(row[2]),   # CustomerID
        transform_null(row[3]),   # BuyingGroupID
        transform_null(row[4]),   # CustomerCategoryID
        transform_null(row[5]),   # StockGroupID
        transform_null(row[6]),   # DealDescription
        transform_null(row[7]),   # StartDate
        transform_null(row[8]),   # EndDate
        transform_null(row[9]),   # DiscountAmount
        transform_null(row[10]),  # DiscountPercentage
        transform_null(row[11]),  # UnitPrice
        transform_null(row[12]),  # LastEditedBy
        transform_timestamp(row[13])  # LastEditedWhen
    ]


def transform_customertransactions(row):
    """Transform Sales.CustomerTransactions row."""
    if len(row) < 13:
        return None
    return [
        transform_null(row[0]),   # CustomerTransactionID
        transform_null(row[1]),   # CustomerID
        transform_null(row[2]),   # TransactionTypeID
        transform_null(row[3]),   # InvoiceID
        transform_null(row[4]),   # PaymentMethodID
        transform_null(row[5]),   # TransactionDate
        transform_null(row[6]),   # AmountExcludingTax
        transform_null(row[7]),   # TaxAmount
        transform_null(row[8]),   # TransactionAmount
        transform_null(row[9]),   # OutstandingBalance
        transform_null(row[10]),  # FinalizationDate
        transform_null(row[11]),  # LastEditedBy
        transform_timestamp(row[12])  # LastEditedWhen
    ]


# =============================================
# Purchasing Schema Transformations
# =============================================

def transform_suppliercategories(row):
    """Transform Purchasing.SupplierCategories row."""
    if len(row) < 5:
        return None
    return [
        transform_null(row[0]),   # SupplierCategoryID
        transform_null(row[1]),   # SupplierCategoryName
        transform_null(row[2]),   # LastEditedBy
        transform_timestamp(row[3]), # ValidFrom
        transform_timestamp(row[4])  # ValidTo
    ]


def transform_suppliers(row):
    """Transform Purchasing.Suppliers row."""
    if len(row) < 28:
        return None
    return [
        transform_null(row[0]),   # SupplierID
        transform_null(row[1]),   # SupplierName
        transform_null(row[2]),   # SupplierCategoryID
        transform_null(row[3]),   # PrimaryContactPersonID
        transform_null(row[4]),   # AlternateContactPersonID
        transform_null(row[5]),   # DeliveryMethodID
        transform_null(row[6]),   # DeliveryCityID
        transform_null(row[7]),   # PostalCityID
        transform_null(row[8]),   # SupplierReference
        transform_null(row[9]),   # BankAccountName
        transform_null(row[10]),  # BankAccountBranch
        transform_null(row[11]),  # BankAccountCode
        transform_null(row[12]),  # BankAccountNumber
        transform_null(row[13]),  # BankInternationalCode
        transform_null(row[14]),  # PaymentDays
        transform_null(row[15]),  # InternalComments
        transform_null(row[16]),  # PhoneNumber
        transform_null(row[17]),  # FaxNumber
        transform_null(row[18]),  # WebsiteURL
        transform_null(row[19]),  # DeliveryAddressLine1
        transform_null(row[20]),  # DeliveryAddressLine2
        transform_null(row[21]),  # DeliveryPostalCode
        transform_geography(row[22]), # DeliveryLocation
        transform_null(row[23]),  # PostalAddressLine1
        transform_null(row[24]),  # PostalAddressLine2
        transform_null(row[25]),  # PostalPostalCode
        transform_null(row[26]),  # LastEditedBy
        transform_timestamp(row[27]), # ValidFrom
        transform_timestamp(row[28]) if len(row) > 28 else None  # ValidTo
    ]


def transform_purchaseorders(row):
    """Transform Purchasing.PurchaseOrders row."""
    if len(row) < 12:
        return None
    return [
        transform_null(row[0]),   # PurchaseOrderID
        transform_null(row[1]),   # SupplierID
        transform_null(row[2]),   # OrderDate
        transform_null(row[3]),   # DeliveryMethodID
        transform_null(row[4]),   # ContactPersonID
        transform_null(row[5]),   # ExpectedDeliveryDate
        transform_null(row[6]),   # SupplierReference
        transform_boolean(row[7]), # IsOrderFinalized
        transform_null(row[8]),   # Comments
        transform_null(row[9]),   # InternalComments
        transform_null(row[10]),  # LastEditedBy
        transform_timestamp(row[11])  # LastEditedWhen
    ]


def transform_purchaseorderlines(row):
    """Transform Purchasing.PurchaseOrderLines row."""
    if len(row) < 12:
        return None
    return [
        transform_null(row[0]),   # PurchaseOrderLineID
        transform_null(row[1]),   # PurchaseOrderID
        transform_null(row[2]),   # StockItemID
        transform_null(row[3]),   # OrderedOuters
        transform_null(row[4]),   # Description
        transform_null(row[5]),   # ReceivedOuters
        transform_null(row[6]),   # PackageTypeID
        transform_null(row[7]),   # ExpectedUnitPricePerOuter
        transform_null(row[8]),   # LastReceiptDate
        transform_boolean(row[9]), # IsOrderLineFinalized
        transform_null(row[10]),  # LastEditedBy
        transform_timestamp(row[11])  # LastEditedWhen
    ]


def transform_suppliertransactions(row):
    """Transform Purchasing.SupplierTransactions row."""
    if len(row) < 14:
        return None
    return [
        transform_null(row[0]),   # SupplierTransactionID
        transform_null(row[1]),   # SupplierID
        transform_null(row[2]),   # TransactionTypeID
        transform_null(row[3]),   # PurchaseOrderID
        transform_null(row[4]),   # PaymentMethodID
        transform_null(row[5]),   # SupplierInvoiceNumber
        transform_null(row[6]),   # TransactionDate
        transform_null(row[7]),   # AmountExcludingTax
        transform_null(row[8]),   # TaxAmount
        transform_null(row[9]),   # TransactionAmount
        transform_null(row[10]),  # OutstandingBalance
        transform_null(row[11]),  # FinalizationDate
        transform_null(row[12]),  # LastEditedBy
        transform_timestamp(row[13])  # LastEditedWhen
    ]


def main():
    """Main transformation function."""
    print("=" * 60)
    print("Wide World Importers Data Transformation")
    print("=" * 60)
    print(f"Input Directory: {INPUT_DIR}")
    print(f"Output Directory: {OUTPUT_DIR}")
    print("=" * 60)
    
    ensure_output_dirs()
    
    # Temporal tables (split into current and archive)
    temporal_tables = [
        ('application_people', transform_people),
        ('application_countries', transform_countries),
        ('application_stateprovinces', transform_stateprovinces),
        ('application_cities', transform_cities),
        ('application_deliverymethods', transform_deliverymethods),
        ('application_paymentmethods', transform_paymentmethods),
        ('application_transactiontypes', transform_transactiontypes),
        ('warehouse_colors', transform_colors),
        ('warehouse_packagetypes', transform_packagetypes),
        ('warehouse_stockgroups', transform_stockgroups),
        ('warehouse_stockitems', transform_stockitems),
        ('warehouse_coldroomtemperatures', transform_coldroomtemperatures),
        ('sales_buyinggroups', transform_buyinggroups),
        ('sales_customercategories', transform_customercategories),
        ('sales_customers', transform_customers),
        ('purchasing_suppliercategories', transform_suppliercategories),
        ('purchasing_suppliers', transform_suppliers),
    ]
    
    print("\nTransforming temporal tables...")
    for table_name, transform_func in temporal_tables:
        input_file = f"{INPUT_DIR}/oltp/{table_name}.csv"
        current_file = f"{OUTPUT_DIR}/oltp/current/{table_name}.csv"
        archive_file = f"{OUTPUT_DIR}/oltp/archive/{table_name}_archive.csv"
        
        curr_count, arch_count = split_temporal_data(
            input_file, current_file, archive_file, transform_func
        )
        print(f"  {table_name}: {curr_count} current, {arch_count} archive")
    
    # Non-temporal tables
    non_temporal_tables = [
        ('application_systemparameters', transform_systemparameters),
        ('warehouse_stockitemholdings', transform_stockitemholdings),
        ('warehouse_stockitemstockgroups', transform_stockitemstockgroups),
        ('warehouse_stockitemtransactions', transform_stockitemtransactions),
        ('warehouse_vehicletemperatures', transform_vehicletemperatures),
        ('sales_orders', transform_orders),
        ('sales_orderlines', transform_orderlines),
        ('sales_invoices', transform_invoices),
        ('sales_invoicelines', transform_invoicelines),
        ('sales_specialdeals', transform_specialdeals),
        ('sales_customertransactions', transform_customertransactions),
        ('purchasing_purchaseorders', transform_purchaseorders),
        ('purchasing_purchaseorderlines', transform_purchaseorderlines),
        ('purchasing_suppliertransactions', transform_suppliertransactions),
    ]
    
    print("\nTransforming non-temporal tables...")
    for table_name, transform_func in non_temporal_tables:
        input_file = f"{INPUT_DIR}/oltp/{table_name}.csv"
        output_file = f"{OUTPUT_DIR}/oltp/current/{table_name}.csv"
        
        count = transform_non_temporal(input_file, output_file, transform_func)
        print(f"  {table_name}: {count} rows")
    
    print("\n" + "=" * 60)
    print("Transformation Complete!")
    print("=" * 60)


if __name__ == '__main__':
    main()
