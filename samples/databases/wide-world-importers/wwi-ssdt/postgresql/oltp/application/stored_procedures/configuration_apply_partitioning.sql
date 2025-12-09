-- PostgreSQL equivalent of [Application].Configuration_ApplyPartitioning
-- Converted from T-SQL to PL/pgSQL
-- Note: PostgreSQL uses declarative partitioning (native since PostgreSQL 10)

CREATE OR REPLACE PROCEDURE application.configuration_apply_partitioning()
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    BEGIN
        RAISE NOTICE 'Applying table partitioning for analytical workloads...';
        
        -- Note: PostgreSQL partitioning requires creating new partitioned tables
        -- and migrating data. This is typically done during initial schema setup.
        -- The following demonstrates the partitioning strategy.
        
        -- Check if partitioned tables already exist
        IF EXISTS (
            SELECT 1 FROM pg_partitioned_table pt
            JOIN pg_class c ON pt.partrelid = c.oid
            JOIN pg_namespace n ON c.relnamespace = n.oid
            WHERE n.nspname = 'sales' AND c.relname = 'customer_transactions_partitioned'
        ) THEN
            RAISE NOTICE 'Partitioning already applied.';
            RETURN;
        END IF;
        
        -- Create partitioned version of Sales.CustomerTransactions
        -- Partitioned by transaction_date using RANGE partitioning
        CREATE TABLE IF NOT EXISTS sales.customer_transactions_partitioned (
            customer_transaction_id INTEGER NOT NULL,
            customer_id INTEGER NOT NULL,
            transaction_type_id INTEGER NOT NULL,
            invoice_id INTEGER,
            payment_method_id INTEGER,
            transaction_date DATE NOT NULL,
            amount_excluding_tax DECIMAL(18,2) NOT NULL,
            tax_amount DECIMAL(18,2) NOT NULL,
            transaction_amount DECIMAL(18,2) NOT NULL,
            outstanding_balance DECIMAL(18,2) NOT NULL,
            finalization_date DATE,
            is_finalized BOOLEAN,
            last_edited_by INTEGER NOT NULL,
            last_edited_when TIMESTAMP NOT NULL,
            PRIMARY KEY (customer_transaction_id, transaction_date)
        ) PARTITION BY RANGE (transaction_date);
        
        -- Create partitions for each year
        CREATE TABLE IF NOT EXISTS sales.customer_transactions_y2021 
            PARTITION OF sales.customer_transactions_partitioned
            FOR VALUES FROM ('2021-01-01') TO ('2022-01-01');
            
        CREATE TABLE IF NOT EXISTS sales.customer_transactions_y2022 
            PARTITION OF sales.customer_transactions_partitioned
            FOR VALUES FROM ('2022-01-01') TO ('2023-01-01');
            
        CREATE TABLE IF NOT EXISTS sales.customer_transactions_y2023 
            PARTITION OF sales.customer_transactions_partitioned
            FOR VALUES FROM ('2023-01-01') TO ('2024-01-01');
            
        CREATE TABLE IF NOT EXISTS sales.customer_transactions_y2024 
            PARTITION OF sales.customer_transactions_partitioned
            FOR VALUES FROM ('2024-01-01') TO ('2025-01-01');
            
        CREATE TABLE IF NOT EXISTS sales.customer_transactions_y2025 
            PARTITION OF sales.customer_transactions_partitioned
            FOR VALUES FROM ('2025-01-01') TO ('2026-01-01');
        
        -- Create indexes on partitioned table
        CREATE INDEX IF NOT EXISTS idx_ct_part_customer_id 
            ON sales.customer_transactions_partitioned (customer_id);
        CREATE INDEX IF NOT EXISTS idx_ct_part_invoice_id 
            ON sales.customer_transactions_partitioned (invoice_id);
        CREATE INDEX IF NOT EXISTS idx_ct_part_payment_method_id 
            ON sales.customer_transactions_partitioned (payment_method_id);
        CREATE INDEX IF NOT EXISTS idx_ct_part_transaction_type_id 
            ON sales.customer_transactions_partitioned (transaction_type_id);
        CREATE INDEX IF NOT EXISTS idx_ct_part_is_finalized 
            ON sales.customer_transactions_partitioned (is_finalized);
        
        -- Create partitioned version of Purchasing.SupplierTransactions
        CREATE TABLE IF NOT EXISTS purchasing.supplier_transactions_partitioned (
            supplier_transaction_id INTEGER NOT NULL,
            supplier_id INTEGER NOT NULL,
            transaction_type_id INTEGER NOT NULL,
            purchase_order_id INTEGER,
            payment_method_id INTEGER,
            supplier_invoice_number VARCHAR(20),
            transaction_date DATE NOT NULL,
            amount_excluding_tax DECIMAL(18,2) NOT NULL,
            tax_amount DECIMAL(18,2) NOT NULL,
            transaction_amount DECIMAL(18,2) NOT NULL,
            outstanding_balance DECIMAL(18,2) NOT NULL,
            finalization_date DATE,
            is_finalized BOOLEAN,
            last_edited_by INTEGER NOT NULL,
            last_edited_when TIMESTAMP NOT NULL,
            PRIMARY KEY (supplier_transaction_id, transaction_date)
        ) PARTITION BY RANGE (transaction_date);
        
        -- Create partitions for supplier transactions
        CREATE TABLE IF NOT EXISTS purchasing.supplier_transactions_y2021 
            PARTITION OF purchasing.supplier_transactions_partitioned
            FOR VALUES FROM ('2021-01-01') TO ('2022-01-01');
            
        CREATE TABLE IF NOT EXISTS purchasing.supplier_transactions_y2022 
            PARTITION OF purchasing.supplier_transactions_partitioned
            FOR VALUES FROM ('2022-01-01') TO ('2023-01-01');
            
        CREATE TABLE IF NOT EXISTS purchasing.supplier_transactions_y2023 
            PARTITION OF purchasing.supplier_transactions_partitioned
            FOR VALUES FROM ('2023-01-01') TO ('2024-01-01');
            
        CREATE TABLE IF NOT EXISTS purchasing.supplier_transactions_y2024 
            PARTITION OF purchasing.supplier_transactions_partitioned
            FOR VALUES FROM ('2024-01-01') TO ('2025-01-01');
            
        CREATE TABLE IF NOT EXISTS purchasing.supplier_transactions_y2025 
            PARTITION OF purchasing.supplier_transactions_partitioned
            FOR VALUES FROM ('2025-01-01') TO ('2026-01-01');
        
        -- Create indexes on partitioned supplier transactions
        CREATE INDEX IF NOT EXISTS idx_st_part_supplier_id 
            ON purchasing.supplier_transactions_partitioned (supplier_id);
        CREATE INDEX IF NOT EXISTS idx_st_part_purchase_order_id 
            ON purchasing.supplier_transactions_partitioned (purchase_order_id);
        CREATE INDEX IF NOT EXISTS idx_st_part_payment_method_id 
            ON purchasing.supplier_transactions_partitioned (payment_method_id);
        CREATE INDEX IF NOT EXISTS idx_st_part_transaction_type_id 
            ON purchasing.supplier_transactions_partitioned (transaction_type_id);
        CREATE INDEX IF NOT EXISTS idx_st_part_is_finalized 
            ON purchasing.supplier_transactions_partitioned (is_finalized);
        
        RAISE NOTICE 'Partitioning successfully enabled';
        RAISE NOTICE 'Note: Data migration to partitioned tables must be done separately';
        
    EXCEPTION WHEN OTHERS THEN
        RAISE NOTICE 'Unable to apply partitioning: %', SQLERRM;
        RAISE;
    END;
END;
$$;

COMMENT ON PROCEDURE application.configuration_apply_partitioning IS 'Creates partitioned tables for transaction data (PostgreSQL declarative partitioning)';
