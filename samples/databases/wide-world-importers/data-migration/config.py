"""
Phase 6: Data Migration and Validation
Configuration settings for SQL Server to PostgreSQL migration
"""

import os

# SQL Server connection settings (source)
SQL_SERVER_CONFIG = {
    'server': os.environ.get('SQL_SERVER_HOST', 'localhost'),
    'port': int(os.environ.get('SQL_SERVER_PORT', 1433)),
    'username': os.environ.get('SQL_SERVER_USER', 'sa'),
    'password': os.environ.get('SQL_SERVER_PASSWORD', ''),
    'driver': '{ODBC Driver 18 for SQL Server}',
    'trust_server_certificate': 'yes',
}

# OLTP Database (WideWorldImporters)
SQL_SERVER_OLTP_DB = 'WideWorldImporters'

# OLAP Database (WideWorldImportersDW)
SQL_SERVER_OLAP_DB = 'WideWorldImportersDW'

# PostgreSQL connection settings (target)
POSTGRES_CONFIG = {
    'host': os.environ.get('POSTGRES_HOST', 'localhost'),
    'port': int(os.environ.get('POSTGRES_PORT', 5432)),
    'user': os.environ.get('POSTGRES_USER', 'webapi'),
    'password': os.environ.get('POSTGRES_PASSWORD', ''),
}

# OLTP Database
POSTGRES_OLTP_DB = 'wideworldimporters'

# OLAP Database
POSTGRES_OLAP_DB = 'wideworldimportersdw'

# Data directory for intermediate files
DATA_DIR = os.path.join(os.path.dirname(__file__), 'data')
LOGS_DIR = os.path.join(os.path.dirname(__file__), 'logs')

# Batch size for data extraction and loading
BATCH_SIZE = 10000

# Number of parallel workers for loading
MAX_WORKERS = 4

# OLTP Tables to migrate (in dependency order)
OLTP_TABLES = {
    'application': [
        ('people', 'People', True),  # (pg_table, sql_table, is_temporal)
        ('countries', 'Countries', True),
        ('stateprovinces', 'StateProvinces', True),
        ('cities', 'Cities', True),
        ('deliverymethods', 'DeliveryMethods', True),
        ('paymentmethods', 'PaymentMethods', True),
        ('transactiontypes', 'TransactionTypes', True),
        ('systemparameters', 'SystemParameters', False),
    ],
    'warehouse': [
        ('colors', 'Colors', True),
        ('packagetypes', 'PackageTypes', True),
        ('stockgroups', 'StockGroups', True),
        ('stockitems', 'StockItems', True),
        ('stockitemholdings', 'StockItemHoldings', False),
        ('stockitemstockgroups', 'StockItemStockGroups', False),
        ('stockitemtransactions', 'StockItemTransactions', False),
        ('coldroomtemperatures', 'ColdRoomTemperatures', True),
        ('vehicletemperatures', 'VehicleTemperatures', False),
    ],
    'sales': [
        ('buyinggroups', 'BuyingGroups', True),
        ('customercategories', 'CustomerCategories', True),
        ('customers', 'Customers', True),
        ('orders', 'Orders', False),
        ('orderlines', 'OrderLines', False),
        ('invoices', 'Invoices', False),
        ('invoicelines', 'InvoiceLines', False),
        ('customertransactions', 'CustomerTransactions', False),
        ('specialdeals', 'SpecialDeals', False),
    ],
    'purchasing': [
        ('suppliercategories', 'SupplierCategories', True),
        ('suppliers', 'Suppliers', True),
        ('purchaseorders', 'PurchaseOrders', False),
        ('purchaseorderlines', 'PurchaseOrderLines', False),
        ('suppliertransactions', 'SupplierTransactions', False),
    ],
}

# Archive tables for temporal data
ARCHIVE_TABLES = {
    'application': [
        'people_archive',
        'countries_archive',
        'stateprovinces_archive',
        'cities_archive',
        'deliverymethods_archive',
        'paymentmethods_archive',
        'transactiontypes_archive',
    ],
    'warehouse': [
        'colors_archive',
        'packagetypes_archive',
        'stockgroups_archive',
        'stockitems_archive',
        'coldroomtemperatures_archive',
    ],
    'sales': [
        'buyinggroups_archive',
        'customercategories_archive',
        'customers_archive',
    ],
    'purchasing': [
        'suppliercategories_archive',
        'suppliers_archive',
    ],
}

# OLAP Tables to migrate (in dependency order)
OLAP_TABLES = {
    'dimension': [
        ('city', 'City'),
        ('customer', 'Customer'),
        ('date', 'Date'),
        ('employee', 'Employee'),
        ('payment_method', 'Payment Method'),
        ('stock_item', 'Stock Item'),
        ('supplier', 'Supplier'),
        ('transaction_type', 'Transaction Type'),
    ],
    'fact': [
        ('sale', 'Sale'),
        ('order', 'Order'),
        ('purchase', 'Purchase'),
        ('movement', 'Movement'),
        ('transaction', 'Transaction'),
        ('stock_holding', 'Stock Holding'),
    ],
    'integration': [
        ('etl_cutoff', 'ETL Cutoff'),
        ('lineage', 'Lineage'),
    ],
}

# Sequences to reset after data load (OLTP)
OLTP_SEQUENCES = {
    'sequences.personid': ('application.people', 'personid'),
    'sequences.countryid': ('application.countries', 'countryid'),
    'sequences.stateprovinceid': ('application.stateprovinces', 'stateprovinceid'),
    'sequences.cityid': ('application.cities', 'cityid'),
    'sequences.deliverymethodid': ('application.deliverymethods', 'deliverymethodid'),
    'sequences.paymentmethodid': ('application.paymentmethods', 'paymentmethodid'),
    'sequences.transactiontypeid': ('application.transactiontypes', 'transactiontypeid'),
    'sequences.systemparameterid': ('application.systemparameters', 'systemparameterid'),
    'sequences.colorid': ('warehouse.colors', 'colorid'),
    'sequences.packagetypeid': ('warehouse.packagetypes', 'packagetypeid'),
    'sequences.stockgroupid': ('warehouse.stockgroups', 'stockgroupid'),
    'sequences.stockitemid': ('warehouse.stockitems', 'stockitemid'),
    'sequences.stockitemstockgroupid': ('warehouse.stockitemstockgroups', 'stockitemstockgroupid'),
    'sequences.buyinggroupid': ('sales.buyinggroups', 'buyinggroupid'),
    'sequences.customercategoryid': ('sales.customercategories', 'customercategoryid'),
    'sequences.customerid': ('sales.customers', 'customerid'),
    'sequences.orderid': ('sales.orders', 'orderid'),
    'sequences.orderlineid': ('sales.orderlines', 'orderlineid'),
    'sequences.invoiceid': ('sales.invoices', 'invoiceid'),
    'sequences.invoicelineid': ('sales.invoicelines', 'invoicelineid'),
    'sequences.specialdealid': ('sales.specialdeals', 'specialdealid'),
    'sequences.suppliercategoryid': ('purchasing.suppliercategories', 'suppliercategoryid'),
    'sequences.supplierid': ('purchasing.suppliers', 'supplierid'),
    'sequences.purchaseorderid': ('purchasing.purchaseorders', 'purchaseorderid'),
    'sequences.purchaseorderlineid': ('purchasing.purchaseorderlines', 'purchaseorderlineid'),
    'sequences.transactionid': [
        ('sales.customertransactions', 'customertransactionid'),
        ('purchasing.suppliertransactions', 'suppliertransactionid'),
        ('warehouse.stockitemtransactions', 'stockitemtransactionid'),
    ],
}

# OLAP Sequences to reset
OLAP_SEQUENCES = {
    'sequences.city_key': ('dimension.city', 'city_key'),
    'sequences.customer_key': ('dimension.customer', 'customer_key'),
    'sequences.employee_key': ('dimension.employee', 'employee_key'),
    'sequences.payment_method_key': ('dimension.payment_method', 'payment_method_key'),
    'sequences.stock_item_key': ('dimension.stock_item', 'stock_item_key'),
    'sequences.supplier_key': ('dimension.supplier', 'supplier_key'),
    'sequences.transaction_type_key': ('dimension.transaction_type', 'transaction_type_key'),
    'sequences.lineage_key': ('integration.lineage', 'lineage_key'),
}

# Column mappings for data type transformations
# Format: (sql_server_column, postgres_column, transformation_function)
COLUMN_TRANSFORMATIONS = {
    # Geography columns need special handling
    'geography': 'convert_geography',
    # Binary columns need base64 encoding/decoding
    'varbinary': 'convert_binary',
    # Bit columns need boolean conversion
    'bit': 'convert_boolean',
    # JSON columns
    'nvarchar_json': 'convert_json',
}

# Tables with geography columns
GEOGRAPHY_COLUMNS = {
    'application.countries': ['border'],
    'application.stateprovinces': ['border'],
    'application.cities': ['location'],
    'application.systemparameters': ['deliverylocation'],
    'sales.customers': ['deliverylocation'],
    'purchasing.suppliers': ['deliverylocation'],
    'dimension.city': ['location'],
}

# Tables with binary columns
BINARY_COLUMNS = {
    'application.people': ['hashedpassword', 'photo'],
    'warehouse.stockitems': ['photo'],
    'warehouse.vehicletemperatures': ['compressedsensordata'],
    'dimension.employee': ['photo'],
    'dimension.stock_item': ['photo'],
}

# Tables with JSON columns
JSON_COLUMNS = {
    'warehouse.stockitems': ['tags'],
    'sales.invoices': ['returneddeliverydata'],
}

# Computed columns to skip during extraction (they are generated in PostgreSQL)
COMPUTED_COLUMNS = {
    'application.people': ['searchname'],
    'warehouse.stockitems': ['searchdetails'],
    'sales.customertransactions': ['isfinalized'],
    'purchasing.suppliertransactions': ['isfinalized'],
}

# Validation thresholds
VALIDATION_CONFIG = {
    'row_count_tolerance': 0,  # Exact match required
    'sample_size': 100,  # Number of rows to sample for data comparison
    'checksum_columns': ['id', 'name'],  # Columns to include in checksum
}
