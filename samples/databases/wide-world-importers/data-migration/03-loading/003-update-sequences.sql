-- Wide World Importers PostgreSQL Migration
-- Phase 6: Data Migration and Validation
-- File: 003-update-sequences.sql
-- Description: Update PostgreSQL sequences to values higher than migrated data
--
-- This script must be run AFTER data loading to ensure sequences
-- generate IDs that don't conflict with migrated data.
--
-- Usage: psql -d wideworldimporters -f 003-update-sequences.sql

\echo '============================================='
\echo 'Updating Sequences for OLTP Database'
\echo '============================================='

-- =============================================
-- Application Schema Sequences
-- =============================================

\echo 'Updating Application schema sequences...'

SELECT setval('sequences.personid', 
    COALESCE((SELECT MAX(personid) FROM application.people), 0) + 1, false);

SELECT setval('sequences.countryid', 
    COALESCE((SELECT MAX(countryid) FROM application.countries), 0) + 1, false);

SELECT setval('sequences.stateprovinceid', 
    COALESCE((SELECT MAX(stateprovinceid) FROM application.stateprovinces), 0) + 1, false);

SELECT setval('sequences.cityid', 
    COALESCE((SELECT MAX(cityid) FROM application.cities), 0) + 1, false);

SELECT setval('sequences.deliverymethodid', 
    COALESCE((SELECT MAX(deliverymethodid) FROM application.deliverymethods), 0) + 1, false);

SELECT setval('sequences.paymentmethodid', 
    COALESCE((SELECT MAX(paymentmethodid) FROM application.paymentmethods), 0) + 1, false);

SELECT setval('sequences.transactiontypeid', 
    COALESCE((SELECT MAX(transactiontypeid) FROM application.transactiontypes), 0) + 1, false);

SELECT setval('sequences.systemparameterid', 
    COALESCE((SELECT MAX(systemparameterid) FROM application.systemparameters), 0) + 1, false);

-- =============================================
-- Warehouse Schema Sequences
-- =============================================

\echo 'Updating Warehouse schema sequences...'

SELECT setval('sequences.colorid', 
    COALESCE((SELECT MAX(colorid) FROM warehouse.colors), 0) + 1, false);

SELECT setval('sequences.packagetypeid', 
    COALESCE((SELECT MAX(packagetypeid) FROM warehouse.packagetypes), 0) + 1, false);

SELECT setval('sequences.stockgroupid', 
    COALESCE((SELECT MAX(stockgroupid) FROM warehouse.stockgroups), 0) + 1, false);

SELECT setval('sequences.stockitemid', 
    COALESCE((SELECT MAX(stockitemid) FROM warehouse.stockitems), 0) + 1, false);

SELECT setval('sequences.stockitemstockgroupid', 
    COALESCE((SELECT MAX(stockitemstockgroupid) FROM warehouse.stockitemstockgroups), 0) + 1, false);

-- =============================================
-- Sales Schema Sequences
-- =============================================

\echo 'Updating Sales schema sequences...'

SELECT setval('sequences.buyinggroupid', 
    COALESCE((SELECT MAX(buyinggroupid) FROM sales.buyinggroups), 0) + 1, false);

SELECT setval('sequences.customercategoryid', 
    COALESCE((SELECT MAX(customercategoryid) FROM sales.customercategories), 0) + 1, false);

SELECT setval('sequences.customerid', 
    COALESCE((SELECT MAX(customerid) FROM sales.customers), 0) + 1, false);

SELECT setval('sequences.orderid', 
    COALESCE((SELECT MAX(orderid) FROM sales.orders), 0) + 1, false);

SELECT setval('sequences.orderlineid', 
    COALESCE((SELECT MAX(orderlineid) FROM sales.orderlines), 0) + 1, false);

SELECT setval('sequences.invoiceid', 
    COALESCE((SELECT MAX(invoiceid) FROM sales.invoices), 0) + 1, false);

SELECT setval('sequences.invoicelineid', 
    COALESCE((SELECT MAX(invoicelineid) FROM sales.invoicelines), 0) + 1, false);

SELECT setval('sequences.specialdealid', 
    COALESCE((SELECT MAX(specialdealid) FROM sales.specialdeals), 0) + 1, false);

-- =============================================
-- Purchasing Schema Sequences
-- =============================================

\echo 'Updating Purchasing schema sequences...'

SELECT setval('sequences.suppliercategoryid', 
    COALESCE((SELECT MAX(suppliercategoryid) FROM purchasing.suppliercategories), 0) + 1, false);

SELECT setval('sequences.supplierid', 
    COALESCE((SELECT MAX(supplierid) FROM purchasing.suppliers), 0) + 1, false);

SELECT setval('sequences.purchaseorderid', 
    COALESCE((SELECT MAX(purchaseorderid) FROM purchasing.purchaseorders), 0) + 1, false);

SELECT setval('sequences.purchaseorderlineid', 
    COALESCE((SELECT MAX(purchaseorderlineid) FROM purchasing.purchaseorderlines), 0) + 1, false);

-- =============================================
-- Shared Transaction Sequence
-- =============================================

\echo 'Updating shared transaction sequence...'

-- The transaction sequence is shared across CustomerTransactions, 
-- SupplierTransactions, and StockItemTransactions
SELECT setval('sequences.transactionid', 
    GREATEST(
        COALESCE((SELECT MAX(customertransactionid) FROM sales.customertransactions), 0),
        COALESCE((SELECT MAX(suppliertransactionid) FROM purchasing.suppliertransactions), 0),
        COALESCE((SELECT MAX(stockitemtransactionid) FROM warehouse.stockitemtransactions), 0)
    ) + 1, false);

-- =============================================
-- Verify Sequence Values
-- =============================================

\echo ''
\echo 'Sequence Values After Update:'
\echo '============================================='

SELECT 
    schemaname || '.' || sequencename AS sequence_name,
    last_value
FROM pg_sequences
WHERE schemaname = 'sequences'
ORDER BY sequencename;

\echo ''
\echo 'Sequence Update Complete!'
