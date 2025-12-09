"""
Wide World Importers ETL Configuration
PostgreSQL-compatible ETL solution replacing SQL Server SSIS packages
"""

import os
from dataclasses import dataclass
from typing import Optional


@dataclass
class DatabaseConfig:
    """Database connection configuration"""
    host: str
    port: int
    database: str
    user: str
    password: str
    
    @property
    def connection_string(self) -> str:
        return f"postgresql://{self.user}:{self.password}@{self.host}:{self.port}/{self.database}"


@dataclass
class ETLConfig:
    """ETL process configuration"""
    oltp_db: DatabaseConfig
    olap_db: DatabaseConfig
    batch_size: int = 10000
    log_level: str = "INFO"
    
    @classmethod
    def from_env(cls) -> "ETLConfig":
        """Create configuration from environment variables"""
        oltp_db = DatabaseConfig(
            host=os.getenv("OLTP_DB_HOST", "localhost"),
            port=int(os.getenv("OLTP_DB_PORT", "5432")),
            database=os.getenv("OLTP_DB_NAME", "wideworldimporters"),
            user=os.getenv("OLTP_DB_USER", "webapi"),
            password=os.getenv("OLTP_DB_PASSWORD", ""),
        )
        
        olap_db = DatabaseConfig(
            host=os.getenv("OLAP_DB_HOST", "localhost"),
            port=int(os.getenv("OLAP_DB_PORT", "5432")),
            database=os.getenv("OLAP_DB_NAME", "wideworldimportersdw"),
            user=os.getenv("OLAP_DB_USER", "webapi"),
            password=os.getenv("OLAP_DB_PASSWORD", ""),
        )
        
        return cls(
            oltp_db=oltp_db,
            olap_db=olap_db,
            batch_size=int(os.getenv("ETL_BATCH_SIZE", "10000")),
            log_level=os.getenv("ETL_LOG_LEVEL", "INFO"),
        )


# Dimension ETL configurations
DIMENSION_CONFIGS = {
    "City": {
        "extract_procedure": "integration.get_city_updates",
        "staging_table": "integration.city_staging",
        "migrate_procedure": "integration.migrate_staged_city_data",
        "staging_columns": [
            "wwi_city_id", "city", "state_province", "country", "continent",
            "sales_territory", "region", "subregion", "location",
            "latest_recorded_population", "valid_from", "valid_to"
        ],
    },
    "Customer": {
        "extract_procedure": "integration.get_customer_updates",
        "staging_table": "integration.customer_staging",
        "migrate_procedure": "integration.migrate_staged_customer_data",
        "staging_columns": [
            "wwi_customer_id", "customer", "bill_to_customer", "category",
            "buying_group", "primary_contact", "postal_code",
            "valid_from", "valid_to"
        ],
    },
    "Employee": {
        "extract_procedure": "integration.get_employee_updates",
        "staging_table": "integration.employee_staging",
        "migrate_procedure": "integration.migrate_staged_employee_data",
        "staging_columns": [
            "wwi_employee_id", "employee", "preferred_name", "is_salesperson",
            "photo", "valid_from", "valid_to"
        ],
    },
    "Payment Method": {
        "extract_procedure": "integration.get_payment_method_updates",
        "staging_table": "integration.payment_method_staging",
        "migrate_procedure": "integration.migrate_staged_payment_method_data",
        "staging_columns": [
            "wwi_payment_method_id", "payment_method", "valid_from", "valid_to"
        ],
    },
    "Stock Item": {
        "extract_procedure": "integration.get_stock_item_updates",
        "staging_table": "integration.stock_item_staging",
        "migrate_procedure": "integration.migrate_staged_stock_item_data",
        "staging_columns": [
            "wwi_stock_item_id", "stock_item", "color", "selling_package",
            "buying_package", "brand", "size", "lead_time_days",
            "quantity_per_outer", "is_chiller_stock", "barcode", "tax_rate",
            "unit_price", "recommended_retail_price", "typical_weight_per_unit",
            "photo", "valid_from", "valid_to"
        ],
    },
    "Supplier": {
        "extract_procedure": "integration.get_supplier_updates",
        "staging_table": "integration.supplier_staging",
        "migrate_procedure": "integration.migrate_staged_supplier_data",
        "staging_columns": [
            "wwi_supplier_id", "supplier", "category", "primary_contact",
            "supplier_reference", "payment_days", "postal_code",
            "valid_from", "valid_to"
        ],
    },
    "Transaction Type": {
        "extract_procedure": "integration.get_transaction_type_updates",
        "staging_table": "integration.transaction_type_staging",
        "migrate_procedure": "integration.migrate_staged_transaction_type_data",
        "staging_columns": [
            "wwi_transaction_type_id", "transaction_type", "valid_from", "valid_to"
        ],
    },
}

# Fact ETL configurations
FACT_CONFIGS = {
    "Sale": {
        "extract_procedure": "integration.get_sale_updates",
        "staging_table": "integration.sale_staging",
        "migrate_procedure": "integration.migrate_staged_sale_data",
        "staging_columns": [
            "wwi_invoice_id", "wwi_customer_id", "wwi_bill_to_customer_id",
            "wwi_salesperson_id", "wwi_city_id", "wwi_stock_item_id",
            "invoice_date_key", "delivery_date_key", "description", "package",
            "quantity", "unit_price", "tax_rate", "total_excluding_tax",
            "tax_amount", "profit", "total_including_tax",
            "total_dry_items", "total_chiller_items", "last_modified_when"
        ],
    },
    "Order": {
        "extract_procedure": "integration.get_order_updates",
        "staging_table": "integration.order_staging",
        "migrate_procedure": "integration.migrate_staged_order_data",
        "staging_columns": [
            "wwi_order_id", "wwi_backorder_id", "wwi_customer_id",
            "wwi_salesperson_id", "wwi_picker_id", "wwi_city_id",
            "wwi_stock_item_id", "order_date_key", "picked_date_key",
            "description", "package", "quantity", "unit_price", "tax_rate",
            "total_excluding_tax", "tax_amount", "total_including_tax",
            "last_modified_when"
        ],
    },
    "Purchase": {
        "extract_procedure": "integration.get_purchase_updates",
        "staging_table": "integration.purchase_staging",
        "migrate_procedure": "integration.migrate_staged_purchase_data",
        "staging_columns": [
            "wwi_purchase_order_id", "wwi_supplier_id", "wwi_stock_item_id",
            "date_key", "ordered_outers", "ordered_quantity", "received_outers",
            "package", "is_order_finalized", "last_modified_when"
        ],
    },
    "Movement": {
        "extract_procedure": "integration.get_movement_updates",
        "staging_table": "integration.movement_staging",
        "migrate_procedure": "integration.migrate_staged_movement_data",
        "staging_columns": [
            "wwi_stock_item_transaction_id", "wwi_stock_item_id",
            "wwi_transaction_type_id", "wwi_customer_id", "wwi_invoice_id",
            "wwi_supplier_id", "wwi_purchase_order_id", "date_key",
            "quantity", "last_modified_when"
        ],
    },
    "Transaction": {
        "extract_procedure": "integration.get_transaction_updates",
        "staging_table": "integration.transaction_staging",
        "migrate_procedure": "integration.migrate_staged_transaction_data",
        "staging_columns": [
            "wwi_customer_transaction_id", "wwi_supplier_transaction_id",
            "wwi_customer_id", "wwi_bill_to_customer_id", "wwi_supplier_id",
            "wwi_transaction_type_id", "wwi_payment_method_id",
            "wwi_invoice_id", "wwi_purchase_order_id", "date_key",
            "supplier_invoice_number", "total_excluding_tax", "tax_amount",
            "total_including_tax", "outstanding_balance", "is_finalized",
            "last_modified_when"
        ],
    },
    "Stock Holding": {
        "extract_procedure": "integration.get_stock_holding_updates",
        "staging_table": "integration.stock_holding_staging",
        "migrate_procedure": "integration.migrate_staged_stock_holding_data",
        "staging_columns": [
            "wwi_stock_item_id", "quantity_on_hand", "bin_location",
            "last_stocktake_quantity", "last_cost_price", "reorder_level",
            "target_stock_level", "last_modified_when"
        ],
    },
}

# ETL execution order (dimensions first, then facts)
ETL_EXECUTION_ORDER = [
    # Dimensions
    "City",
    "Customer", 
    "Employee",
    "Payment Method",
    "Stock Item",
    "Supplier",
    "Transaction Type",
    # Facts
    "Sale",
    "Order",
    "Purchase",
    "Movement",
    "Transaction",
    "Stock Holding",
]
