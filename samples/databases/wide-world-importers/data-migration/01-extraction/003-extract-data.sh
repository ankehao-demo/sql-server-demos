#!/bin/bash
# Wide World Importers PostgreSQL Migration
# Phase 6: Data Migration and Validation
# File: 003-extract-data.sh
# Description: Shell script to extract data from SQL Server using BCP
#
# Prerequisites:
# - SQL Server tools (sqlcmd, bcp) installed
# - Access to SQL Server instance
# - Environment variables set: SQL_SERVER_HOST, SQL_SERVER_USER, SQL_SERVER_PASSWORD

set -e

# Configuration
SQL_SERVER="${SQL_SERVER_HOST:-localhost}"
SQL_USER="${SQL_SERVER_USER:-sa}"
SQL_PASSWORD="${SQL_SERVER_PASSWORD}"
OLTP_DB="WideWorldImporters"
OLAP_DB="WideWorldImportersDW"
OUTPUT_DIR="${1:-./extracted_data}"
DELIMITER="|"  # Using pipe delimiter to avoid issues with commas in data

# Create output directories
mkdir -p "$OUTPUT_DIR/oltp"
mkdir -p "$OUTPUT_DIR/olap"

echo "============================================="
echo "Wide World Importers Data Extraction"
echo "============================================="
echo "SQL Server: $SQL_SERVER"
echo "Output Directory: $OUTPUT_DIR"
echo "============================================="

# Function to extract table data using BCP
extract_table() {
    local db=$1
    local schema=$2
    local table=$3
    local query=$4
    local output_file=$5
    
    echo "Extracting $schema.$table..."
    
    # Use sqlcmd for complex queries, bcp for simple table exports
    if [ -n "$query" ]; then
        sqlcmd -S "$SQL_SERVER" -U "$SQL_USER" -P "$SQL_PASSWORD" -d "$db" \
            -Q "$query" -s "$DELIMITER" -W -h -1 -o "$output_file" -C 2>/dev/null || {
            echo "  Warning: Failed to extract $schema.$table"
            return 1
        }
    else
        bcp "$db.$schema.$table" out "$output_file" \
            -S "$SQL_SERVER" -U "$SQL_USER" -P "$SQL_PASSWORD" \
            -c -t "$DELIMITER" -C 65001 2>/dev/null || {
            echo "  Warning: Failed to extract $schema.$table"
            return 1
        }
    fi
    
    # Count rows
    local rows=$(wc -l < "$output_file" 2>/dev/null || echo "0")
    echo "  Extracted $rows rows"
}

# Function to extract temporal table (current + history)
extract_temporal_table() {
    local db=$1
    local schema=$2
    local table=$3
    local columns=$4
    local output_file=$5
    
    echo "Extracting temporal table $schema.$table..."
    
    local query="SELECT $columns FROM $schema.$table FOR SYSTEM_TIME ALL ORDER BY 1, ValidFrom"
    
    sqlcmd -S "$SQL_SERVER" -U "$SQL_USER" -P "$SQL_PASSWORD" -d "$db" \
        -Q "$query" -s "$DELIMITER" -W -h -1 -o "$output_file" -C 2>/dev/null || {
        echo "  Warning: Failed to extract $schema.$table"
        return 1
    }
    
    local rows=$(wc -l < "$output_file" 2>/dev/null || echo "0")
    echo "  Extracted $rows rows (including history)"
}

echo ""
echo "============================================="
echo "Extracting OLTP Database: $OLTP_DB"
echo "============================================="

# Application Schema - Temporal Tables
extract_temporal_table "$OLTP_DB" "Application" "People" \
    "PersonID, FullName, PreferredName, IsPermittedToLogon, LogonName, IsExternalLogonProvider, CONVERT(VARCHAR(MAX), HashedPassword, 1), IsSystemUser, IsEmployee, IsSalesperson, UserPreferences, PhoneNumber, FaxNumber, EmailAddress, CONVERT(VARCHAR(MAX), Photo, 1), CustomFields, LastEditedBy, ValidFrom, ValidTo" \
    "$OUTPUT_DIR/oltp/application_people.csv"

extract_temporal_table "$OLTP_DB" "Application" "Countries" \
    "CountryID, CountryName, FormalName, IsoAlpha3Code, IsoNumericCode, CountryType, LatestRecordedPopulation, Continent, Region, Subregion, Border.STAsText(), LastEditedBy, ValidFrom, ValidTo" \
    "$OUTPUT_DIR/oltp/application_countries.csv"

extract_temporal_table "$OLTP_DB" "Application" "StateProvinces" \
    "StateProvinceID, StateProvinceCode, StateProvinceName, CountryID, SalesTerritory, Border.STAsText(), LatestRecordedPopulation, LastEditedBy, ValidFrom, ValidTo" \
    "$OUTPUT_DIR/oltp/application_stateprovinces.csv"

extract_temporal_table "$OLTP_DB" "Application" "Cities" \
    "CityID, CityName, StateProvinceID, Location.STAsText(), LatestRecordedPopulation, LastEditedBy, ValidFrom, ValidTo" \
    "$OUTPUT_DIR/oltp/application_cities.csv"

extract_temporal_table "$OLTP_DB" "Application" "DeliveryMethods" \
    "DeliveryMethodID, DeliveryMethodName, LastEditedBy, ValidFrom, ValidTo" \
    "$OUTPUT_DIR/oltp/application_deliverymethods.csv"

extract_temporal_table "$OLTP_DB" "Application" "PaymentMethods" \
    "PaymentMethodID, PaymentMethodName, LastEditedBy, ValidFrom, ValidTo" \
    "$OUTPUT_DIR/oltp/application_paymentmethods.csv"

extract_temporal_table "$OLTP_DB" "Application" "TransactionTypes" \
    "TransactionTypeID, TransactionTypeName, LastEditedBy, ValidFrom, ValidTo" \
    "$OUTPUT_DIR/oltp/application_transactiontypes.csv"

# Application Schema - Non-temporal Tables
extract_table "$OLTP_DB" "Application" "SystemParameters" \
    "SELECT SystemParameterID, DeliveryAddressLine1, DeliveryAddressLine2, DeliveryCityID, DeliveryPostalCode, DeliveryLocation.STAsText(), PostalAddressLine1, PostalAddressLine2, PostalCityID, PostalPostalCode, ApplicationSettings, LastEditedBy, LastEditedWhen FROM Application.SystemParameters" \
    "$OUTPUT_DIR/oltp/application_systemparameters.csv"

# Warehouse Schema - Temporal Tables
extract_temporal_table "$OLTP_DB" "Warehouse" "Colors" \
    "ColorID, ColorName, LastEditedBy, ValidFrom, ValidTo" \
    "$OUTPUT_DIR/oltp/warehouse_colors.csv"

extract_temporal_table "$OLTP_DB" "Warehouse" "PackageTypes" \
    "PackageTypeID, PackageTypeName, LastEditedBy, ValidFrom, ValidTo" \
    "$OUTPUT_DIR/oltp/warehouse_packagetypes.csv"

extract_temporal_table "$OLTP_DB" "Warehouse" "StockGroups" \
    "StockGroupID, StockGroupName, LastEditedBy, ValidFrom, ValidTo" \
    "$OUTPUT_DIR/oltp/warehouse_stockgroups.csv"

extract_temporal_table "$OLTP_DB" "Warehouse" "StockItems" \
    "StockItemID, StockItemName, SupplierID, ColorID, UnitPackageID, OuterPackageID, Brand, Size, LeadTimeDays, QuantityPerOuter, IsChillerStock, Barcode, TaxRate, UnitPrice, RecommendedRetailPrice, TypicalWeightPerUnit, MarketingComments, InternalComments, CONVERT(VARCHAR(MAX), Photo, 1), CustomFields, LastEditedBy, ValidFrom, ValidTo" \
    "$OUTPUT_DIR/oltp/warehouse_stockitems.csv"

extract_temporal_table "$OLTP_DB" "Warehouse" "ColdRoomTemperatures" \
    "ColdRoomTemperatureID, ColdRoomSensorNumber, RecordedWhen, Temperature, ValidFrom, ValidTo" \
    "$OUTPUT_DIR/oltp/warehouse_coldroomtemperatures.csv"

# Warehouse Schema - Non-temporal Tables
extract_table "$OLTP_DB" "Warehouse" "StockItemHoldings" "" \
    "$OUTPUT_DIR/oltp/warehouse_stockitemholdings.csv"

extract_table "$OLTP_DB" "Warehouse" "StockItemStockGroups" "" \
    "$OUTPUT_DIR/oltp/warehouse_stockitemstockgroups.csv"

extract_table "$OLTP_DB" "Warehouse" "StockItemTransactions" "" \
    "$OUTPUT_DIR/oltp/warehouse_stockitemtransactions.csv"

extract_table "$OLTP_DB" "Warehouse" "VehicleTemperatures" \
    "SELECT VehicleTemperatureID, VehicleRegistration, ChillerSensorNumber, RecordedWhen, Temperature, FullSensorData, IsCompressed, CONVERT(VARCHAR(MAX), CompressedSensorData, 1) FROM Warehouse.VehicleTemperatures" \
    "$OUTPUT_DIR/oltp/warehouse_vehicletemperatures.csv"

# Sales Schema - Temporal Tables
extract_temporal_table "$OLTP_DB" "Sales" "BuyingGroups" \
    "BuyingGroupID, BuyingGroupName, LastEditedBy, ValidFrom, ValidTo" \
    "$OUTPUT_DIR/oltp/sales_buyinggroups.csv"

extract_temporal_table "$OLTP_DB" "Sales" "CustomerCategories" \
    "CustomerCategoryID, CustomerCategoryName, LastEditedBy, ValidFrom, ValidTo" \
    "$OUTPUT_DIR/oltp/sales_customercategories.csv"

extract_temporal_table "$OLTP_DB" "Sales" "Customers" \
    "CustomerID, CustomerName, BillToCustomerID, CustomerCategoryID, BuyingGroupID, PrimaryContactPersonID, AlternateContactPersonID, DeliveryMethodID, DeliveryCityID, PostalCityID, CreditLimit, AccountOpenedDate, StandardDiscountPercentage, IsStatementSent, IsOnCreditHold, PaymentDays, PhoneNumber, FaxNumber, DeliveryRun, RunPosition, WebsiteURL, DeliveryAddressLine1, DeliveryAddressLine2, DeliveryPostalCode, DeliveryLocation.STAsText(), PostalAddressLine1, PostalAddressLine2, PostalPostalCode, LastEditedBy, ValidFrom, ValidTo" \
    "$OUTPUT_DIR/oltp/sales_customers.csv"

# Sales Schema - Non-temporal Tables
extract_table "$OLTP_DB" "Sales" "Orders" "" \
    "$OUTPUT_DIR/oltp/sales_orders.csv"

extract_table "$OLTP_DB" "Sales" "OrderLines" "" \
    "$OUTPUT_DIR/oltp/sales_orderlines.csv"

extract_table "$OLTP_DB" "Sales" "Invoices" \
    "SELECT InvoiceID, CustomerID, BillToCustomerID, OrderID, DeliveryMethodID, ContactPersonID, AccountsPersonID, SalespersonPersonID, PackedByPersonID, InvoiceDate, CustomerPurchaseOrderNumber, IsCreditNote, CreditNoteReason, Comments, DeliveryInstructions, InternalComments, TotalDryItems, TotalChillerItems, DeliveryRun, RunPosition, ReturnedDeliveryData, LastEditedBy, LastEditedWhen FROM Sales.Invoices" \
    "$OUTPUT_DIR/oltp/sales_invoices.csv"

extract_table "$OLTP_DB" "Sales" "InvoiceLines" "" \
    "$OUTPUT_DIR/oltp/sales_invoicelines.csv"

extract_table "$OLTP_DB" "Sales" "SpecialDeals" "" \
    "$OUTPUT_DIR/oltp/sales_specialdeals.csv"

extract_table "$OLTP_DB" "Sales" "CustomerTransactions" \
    "SELECT CustomerTransactionID, CustomerID, TransactionTypeID, InvoiceID, PaymentMethodID, TransactionDate, AmountExcludingTax, TaxAmount, TransactionAmount, OutstandingBalance, FinalizationDate, LastEditedBy, LastEditedWhen FROM Sales.CustomerTransactions" \
    "$OUTPUT_DIR/oltp/sales_customertransactions.csv"

# Purchasing Schema - Temporal Tables
extract_temporal_table "$OLTP_DB" "Purchasing" "SupplierCategories" \
    "SupplierCategoryID, SupplierCategoryName, LastEditedBy, ValidFrom, ValidTo" \
    "$OUTPUT_DIR/oltp/purchasing_suppliercategories.csv"

extract_temporal_table "$OLTP_DB" "Purchasing" "Suppliers" \
    "SupplierID, SupplierName, SupplierCategoryID, PrimaryContactPersonID, AlternateContactPersonID, DeliveryMethodID, DeliveryCityID, PostalCityID, SupplierReference, BankAccountName, BankAccountBranch, BankAccountCode, BankAccountNumber, BankInternationalCode, PaymentDays, InternalComments, PhoneNumber, FaxNumber, WebsiteURL, DeliveryAddressLine1, DeliveryAddressLine2, DeliveryPostalCode, DeliveryLocation.STAsText(), PostalAddressLine1, PostalAddressLine2, PostalPostalCode, LastEditedBy, ValidFrom, ValidTo" \
    "$OUTPUT_DIR/oltp/purchasing_suppliers.csv"

# Purchasing Schema - Non-temporal Tables
extract_table "$OLTP_DB" "Purchasing" "PurchaseOrders" "" \
    "$OUTPUT_DIR/oltp/purchasing_purchaseorders.csv"

extract_table "$OLTP_DB" "Purchasing" "PurchaseOrderLines" "" \
    "$OUTPUT_DIR/oltp/purchasing_purchaseorderlines.csv"

extract_table "$OLTP_DB" "Purchasing" "SupplierTransactions" \
    "SELECT SupplierTransactionID, SupplierID, TransactionTypeID, PurchaseOrderID, PaymentMethodID, SupplierInvoiceNumber, TransactionDate, AmountExcludingTax, TaxAmount, TransactionAmount, OutstandingBalance, FinalizationDate, LastEditedBy, LastEditedWhen FROM Purchasing.SupplierTransactions" \
    "$OUTPUT_DIR/oltp/purchasing_suppliertransactions.csv"

echo ""
echo "============================================="
echo "Extracting OLAP Database: $OLAP_DB"
echo "============================================="

# Dimension Tables
extract_table "$OLAP_DB" "Dimension" "City" \
    "SELECT [City Key], [WWI City ID], City, [State Province], Country, Continent, [Sales Territory], Region, Subregion, Location.STAsText(), [Latest Recorded Population], [Valid From], [Valid To], [Lineage Key] FROM Dimension.City" \
    "$OUTPUT_DIR/olap/dimension_city.csv"

extract_table "$OLAP_DB" "Dimension" "Customer" "" \
    "$OUTPUT_DIR/olap/dimension_customer.csv"

extract_table "$OLAP_DB" "Dimension" "Date" "" \
    "$OUTPUT_DIR/olap/dimension_date.csv"

extract_table "$OLAP_DB" "Dimension" "Employee" \
    "SELECT [Employee Key], [WWI Employee ID], Employee, [Preferred Name], [Is Salesperson], CONVERT(VARCHAR(MAX), Photo, 1), [Valid From], [Valid To], [Lineage Key] FROM Dimension.Employee" \
    "$OUTPUT_DIR/olap/dimension_employee.csv"

extract_table "$OLAP_DB" "Dimension" "[Payment Method]" "" \
    "$OUTPUT_DIR/olap/dimension_payment_method.csv"

extract_table "$OLAP_DB" "Dimension" "[Stock Item]" \
    "SELECT [Stock Item Key], [WWI Stock Item ID], [Stock Item], Color, [Selling Package], [Buying Package], Brand, Size, [Lead Time Days], [Quantity Per Outer], [Is Chiller Stock], Barcode, [Tax Rate], [Unit Price], [Recommended Retail Price], [Typical Weight Per Unit], CONVERT(VARCHAR(MAX), Photo, 1), [Valid From], [Valid To], [Lineage Key] FROM Dimension.[Stock Item]" \
    "$OUTPUT_DIR/olap/dimension_stock_item.csv"

extract_table "$OLAP_DB" "Dimension" "Supplier" "" \
    "$OUTPUT_DIR/olap/dimension_supplier.csv"

extract_table "$OLAP_DB" "Dimension" "[Transaction Type]" "" \
    "$OUTPUT_DIR/olap/dimension_transaction_type.csv"

# Fact Tables
extract_table "$OLAP_DB" "Fact" "Sale" "" \
    "$OUTPUT_DIR/olap/fact_sale.csv"

extract_table "$OLAP_DB" "Fact" "[Order]" "" \
    "$OUTPUT_DIR/olap/fact_order.csv"

extract_table "$OLAP_DB" "Fact" "Purchase" "" \
    "$OUTPUT_DIR/olap/fact_purchase.csv"

extract_table "$OLAP_DB" "Fact" "Movement" "" \
    "$OUTPUT_DIR/olap/fact_movement.csv"

extract_table "$OLAP_DB" "Fact" "[Transaction]" "" \
    "$OUTPUT_DIR/olap/fact_transaction.csv"

extract_table "$OLAP_DB" "Fact" "[Stock Holding]" "" \
    "$OUTPUT_DIR/olap/fact_stock_holding.csv"

# Integration Tables
extract_table "$OLAP_DB" "Integration" "[ETL Cutoff]" "" \
    "$OUTPUT_DIR/olap/integration_etl_cutoff.csv"

extract_table "$OLAP_DB" "Integration" "Lineage" "" \
    "$OUTPUT_DIR/olap/integration_lineage.csv"

echo ""
echo "============================================="
echo "Extraction Complete!"
echo "============================================="
echo "Data files saved to: $OUTPUT_DIR"
echo ""

# Generate extraction summary
echo "Generating extraction summary..."
{
    echo "Wide World Importers Data Extraction Summary"
    echo "============================================="
    echo "Extraction Date: $(date)"
    echo ""
    echo "OLTP Files:"
    for f in "$OUTPUT_DIR/oltp"/*.csv; do
        if [ -f "$f" ]; then
            rows=$(wc -l < "$f")
            echo "  $(basename "$f"): $rows rows"
        fi
    done
    echo ""
    echo "OLAP Files:"
    for f in "$OUTPUT_DIR/olap"/*.csv; do
        if [ -f "$f" ]; then
            rows=$(wc -l < "$f")
            echo "  $(basename "$f"): $rows rows"
        fi
    done
} > "$OUTPUT_DIR/extraction_summary.txt"

cat "$OUTPUT_DIR/extraction_summary.txt"
