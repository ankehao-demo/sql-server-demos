-- Wide World Importers PostgreSQL Migration
-- Sequence Creation Script
-- This script creates all sequences required for the Wide World Importers database

-- BuyingGroupID Sequence
CREATE SEQUENCE IF NOT EXISTS sequences.buyinggroupid
    AS integer
    START WITH 3
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
COMMENT ON SEQUENCE sequences.buyinggroupid IS 'Sequence for BuyingGroup IDs';

-- CityID Sequence
CREATE SEQUENCE IF NOT EXISTS sequences.cityid
    AS integer
    START WITH 38187
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
COMMENT ON SEQUENCE sequences.cityid IS 'Sequence for City IDs';

-- ColorID Sequence
CREATE SEQUENCE IF NOT EXISTS sequences.colorid
    AS integer
    START WITH 37
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
COMMENT ON SEQUENCE sequences.colorid IS 'Sequence for Color IDs';

-- CountryID Sequence
CREATE SEQUENCE IF NOT EXISTS sequences.countryid
    AS integer
    START WITH 242
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
COMMENT ON SEQUENCE sequences.countryid IS 'Sequence for Country IDs';

-- CustomerCategoryID Sequence
CREATE SEQUENCE IF NOT EXISTS sequences.customercategoryid
    AS integer
    START WITH 9
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
COMMENT ON SEQUENCE sequences.customercategoryid IS 'Sequence for CustomerCategory IDs';

-- CustomerID Sequence
CREATE SEQUENCE IF NOT EXISTS sequences.customerid
    AS integer
    START WITH 1110
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
COMMENT ON SEQUENCE sequences.customerid IS 'Sequence for Customer IDs';

-- DeliveryMethodID Sequence
CREATE SEQUENCE IF NOT EXISTS sequences.deliverymethodid
    AS integer
    START WITH 11
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
COMMENT ON SEQUENCE sequences.deliverymethodid IS 'Sequence for DeliveryMethod IDs';

-- InvoiceID Sequence
CREATE SEQUENCE IF NOT EXISTS sequences.invoiceid
    AS integer
    START WITH 70511
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
COMMENT ON SEQUENCE sequences.invoiceid IS 'Sequence for Invoice IDs';

-- InvoiceLineID Sequence
CREATE SEQUENCE IF NOT EXISTS sequences.invoicelineid
    AS integer
    START WITH 228266
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
COMMENT ON SEQUENCE sequences.invoicelineid IS 'Sequence for InvoiceLine IDs';

-- OrderID Sequence
CREATE SEQUENCE IF NOT EXISTS sequences.orderid
    AS integer
    START WITH 73596
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
COMMENT ON SEQUENCE sequences.orderid IS 'Sequence for Order IDs';

-- OrderLineID Sequence
CREATE SEQUENCE IF NOT EXISTS sequences.orderlineid
    AS integer
    START WITH 231413
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
COMMENT ON SEQUENCE sequences.orderlineid IS 'Sequence for OrderLine IDs';

-- PackageTypeID Sequence
CREATE SEQUENCE IF NOT EXISTS sequences.packagetypeid
    AS integer
    START WITH 15
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
COMMENT ON SEQUENCE sequences.packagetypeid IS 'Sequence for PackageType IDs';

-- PaymentMethodID Sequence
CREATE SEQUENCE IF NOT EXISTS sequences.paymentmethodid
    AS integer
    START WITH 5
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
COMMENT ON SEQUENCE sequences.paymentmethodid IS 'Sequence for PaymentMethod IDs';

-- PersonID Sequence
CREATE SEQUENCE IF NOT EXISTS sequences.personid
    AS integer
    START WITH 3262
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
COMMENT ON SEQUENCE sequences.personid IS 'Sequence for Person IDs';

-- PurchaseOrderID Sequence
CREATE SEQUENCE IF NOT EXISTS sequences.purchaseorderid
    AS integer
    START WITH 2075
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
COMMENT ON SEQUENCE sequences.purchaseorderid IS 'Sequence for PurchaseOrder IDs';

-- PurchaseOrderLineID Sequence
CREATE SEQUENCE IF NOT EXISTS sequences.purchaseorderlineid
    AS integer
    START WITH 8368
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
COMMENT ON SEQUENCE sequences.purchaseorderlineid IS 'Sequence for PurchaseOrderLine IDs';

-- SpecialDealID Sequence
CREATE SEQUENCE IF NOT EXISTS sequences.specialdealid
    AS integer
    START WITH 3
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
COMMENT ON SEQUENCE sequences.specialdealid IS 'Sequence for SpecialDeal IDs';

-- StateProvinceID Sequence
CREATE SEQUENCE IF NOT EXISTS sequences.stateprovinceid
    AS integer
    START WITH 54
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
COMMENT ON SEQUENCE sequences.stateprovinceid IS 'Sequence for StateProvince IDs';

-- StockGroupID Sequence
CREATE SEQUENCE IF NOT EXISTS sequences.stockgroupid
    AS integer
    START WITH 11
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
COMMENT ON SEQUENCE sequences.stockgroupid IS 'Sequence for StockGroup IDs';

-- StockItemID Sequence
CREATE SEQUENCE IF NOT EXISTS sequences.stockitemid
    AS integer
    START WITH 228
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
COMMENT ON SEQUENCE sequences.stockitemid IS 'Sequence for StockItem IDs';

-- StockItemStockGroupID Sequence
CREATE SEQUENCE IF NOT EXISTS sequences.stockitemstockgroupid
    AS integer
    START WITH 443
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
COMMENT ON SEQUENCE sequences.stockitemstockgroupid IS 'Sequence for StockItemStockGroup IDs';

-- SupplierCategoryID Sequence
CREATE SEQUENCE IF NOT EXISTS sequences.suppliercategoryid
    AS integer
    START WITH 10
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
COMMENT ON SEQUENCE sequences.suppliercategoryid IS 'Sequence for SupplierCategory IDs';

-- SupplierID Sequence
CREATE SEQUENCE IF NOT EXISTS sequences.supplierid
    AS integer
    START WITH 14
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
COMMENT ON SEQUENCE sequences.supplierid IS 'Sequence for Supplier IDs';

-- SystemParameterID Sequence
CREATE SEQUENCE IF NOT EXISTS sequences.systemparameterid
    AS integer
    START WITH 2
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
COMMENT ON SEQUENCE sequences.systemparameterid IS 'Sequence for SystemParameter IDs';

-- TransactionID Sequence
CREATE SEQUENCE IF NOT EXISTS sequences.transactionid
    AS integer
    START WITH 336253
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
COMMENT ON SEQUENCE sequences.transactionid IS 'Sequence for Transaction IDs';

-- TransactionTypeID Sequence
CREATE SEQUENCE IF NOT EXISTS sequences.transactiontypeid
    AS integer
    START WITH 14
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
COMMENT ON SEQUENCE sequences.transactiontypeid IS 'Sequence for TransactionType IDs';

-- Grant usage on sequences to appropriate roles
-- GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA sequences TO app_user;
