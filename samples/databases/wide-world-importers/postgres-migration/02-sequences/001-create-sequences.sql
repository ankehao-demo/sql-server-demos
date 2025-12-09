-- Wide World Importers PostgreSQL Migration
-- Phase 2: OLTP Schema Migration
-- File: 001-create-sequences.sql
-- Description: Create all sequences for ID generation

-- Application schema sequences
CREATE SEQUENCE IF NOT EXISTS sequences.cityid START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE IF NOT EXISTS sequences.countryid START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE IF NOT EXISTS sequences.deliverymethodid START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE IF NOT EXISTS sequences.paymentmethodid START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE IF NOT EXISTS sequences.personid START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE IF NOT EXISTS sequences.stateprovinceid START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE IF NOT EXISTS sequences.systemparameterid START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE IF NOT EXISTS sequences.transactiontypeid START WITH 1 INCREMENT BY 1;

-- Warehouse schema sequences
CREATE SEQUENCE IF NOT EXISTS sequences.colorid START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE IF NOT EXISTS sequences.packagetypeid START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE IF NOT EXISTS sequences.stockgroupid START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE IF NOT EXISTS sequences.stockitemid START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE IF NOT EXISTS sequences.stockitemstockgroupid START WITH 1 INCREMENT BY 1;

-- Sales schema sequences
CREATE SEQUENCE IF NOT EXISTS sequences.buyinggroupid START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE IF NOT EXISTS sequences.customercategoryid START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE IF NOT EXISTS sequences.customerid START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE IF NOT EXISTS sequences.invoiceid START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE IF NOT EXISTS sequences.invoicelineid START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE IF NOT EXISTS sequences.orderid START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE IF NOT EXISTS sequences.orderlineid START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE IF NOT EXISTS sequences.specialdealid START WITH 1 INCREMENT BY 1;

-- Purchasing schema sequences
CREATE SEQUENCE IF NOT EXISTS sequences.purchaseorderid START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE IF NOT EXISTS sequences.purchaseorderlineid START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE IF NOT EXISTS sequences.suppliercategoryid START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE IF NOT EXISTS sequences.supplierid START WITH 1 INCREMENT BY 1;

-- Shared transaction sequence (used by CustomerTransactions, SupplierTransactions, StockItemTransactions)
CREATE SEQUENCE IF NOT EXISTS sequences.transactionid START WITH 1 INCREMENT BY 1;
