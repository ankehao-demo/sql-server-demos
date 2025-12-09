-- Wide World Importers PostgreSQL Migration
-- Phase 2: OLTP Schema Migration
-- File: 004-purchasing-tables.sql
-- Description: Create Purchasing schema tables

-- Note: Tables are created without foreign keys first to avoid dependency issues
-- Foreign keys are added in a separate file after all tables are created

-- Purchasing.SupplierCategories table (temporal)
CREATE TABLE purchasing.suppliercategories (
    suppliercategoryid integer NOT NULL DEFAULT nextval('sequences.suppliercategoryid'),
    suppliercategoryname varchar(50) NOT NULL,
    lasteditedby integer NOT NULL,
    validfrom timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
    validto timestamp NOT NULL DEFAULT '9999-12-31 23:59:59.999999',
    CONSTRAINT pk_purchasing_suppliercategories PRIMARY KEY (suppliercategoryid),
    CONSTRAINT uq_purchasing_suppliercategories_suppliercategoryname UNIQUE (suppliercategoryname)
);

-- Purchasing.Suppliers table (temporal)
-- Note: SQL Server uses MASKED WITH for bank account columns, PostgreSQL doesn't have native data masking
CREATE TABLE purchasing.suppliers (
    supplierid integer NOT NULL DEFAULT nextval('sequences.supplierid'),
    suppliername varchar(100) NOT NULL,
    suppliercategoryid integer NOT NULL,
    primarycontactpersonid integer NOT NULL,
    alternatecontactpersonid integer NOT NULL,
    deliverymethodid integer NULL,
    deliverycityid integer NOT NULL,
    postalcityid integer NOT NULL,
    supplierreference varchar(20) NULL,
    bankaccountname varchar(50) NULL,
    bankaccountbranch varchar(50) NULL,
    bankaccountcode varchar(20) NULL,
    bankaccountnumber varchar(20) NULL,
    bankinternationalcode varchar(20) NULL,
    paymentdays integer NOT NULL,
    internalcomments text NULL,
    phonenumber varchar(20) NOT NULL,
    faxnumber varchar(20) NOT NULL,
    websiteurl varchar(256) NOT NULL,
    deliveryaddressline1 varchar(60) NOT NULL,
    deliveryaddressline2 varchar(60) NULL,
    deliverypostalcode varchar(10) NOT NULL,
    deliverylocation geography NULL,
    postaladdressline1 varchar(60) NOT NULL,
    postaladdressline2 varchar(60) NULL,
    postalpostalcode varchar(10) NOT NULL,
    lasteditedby integer NOT NULL,
    validfrom timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
    validto timestamp NOT NULL DEFAULT '9999-12-31 23:59:59.999999',
    CONSTRAINT pk_purchasing_suppliers PRIMARY KEY (supplierid),
    CONSTRAINT uq_purchasing_suppliers_suppliername UNIQUE (suppliername)
);

-- Purchasing.PurchaseOrders table (non-temporal)
CREATE TABLE purchasing.purchaseorders (
    purchaseorderid integer NOT NULL DEFAULT nextval('sequences.purchaseorderid'),
    supplierid integer NOT NULL,
    orderdate date NOT NULL,
    deliverymethodid integer NOT NULL,
    contactpersonid integer NOT NULL,
    expecteddeliverydate date NULL,
    supplierreference varchar(20) NULL,
    isorderfinalized boolean NOT NULL,
    comments text NULL,
    internalcomments text NULL,
    lasteditedby integer NOT NULL,
    lasteditedwhen timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT pk_purchasing_purchaseorders PRIMARY KEY (purchaseorderid)
);

-- Purchasing.PurchaseOrderLines table (non-temporal)
CREATE TABLE purchasing.purchaseorderlines (
    purchaseorderlineid integer NOT NULL DEFAULT nextval('sequences.purchaseorderlineid'),
    purchaseorderid integer NOT NULL,
    stockitemid integer NOT NULL,
    orderedouters integer NOT NULL,
    description varchar(100) NOT NULL,
    receivedouters integer NOT NULL,
    packagetypeid integer NOT NULL,
    expectedunitpriceperouter numeric(18,2) NULL,
    lastreceiptdate date NULL,
    isorderlinefinalized boolean NOT NULL,
    lasteditedby integer NOT NULL,
    lasteditedwhen timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT pk_purchasing_purchaseorderlines PRIMARY KEY (purchaseorderlineid)
);

-- Purchasing.SupplierTransactions table (non-temporal)
-- Note: IsFinalized is a computed column
CREATE TABLE purchasing.suppliertransactions (
    suppliertransactionid integer NOT NULL DEFAULT nextval('sequences.transactionid'),
    supplierid integer NOT NULL,
    transactiontypeid integer NOT NULL,
    purchaseorderid integer NULL,
    paymentmethodid integer NULL,
    supplierinvoicenumber varchar(20) NULL,
    transactiondate date NOT NULL,
    amountexcludingtax numeric(18,2) NOT NULL,
    taxamount numeric(18,2) NOT NULL,
    transactionamount numeric(18,2) NOT NULL,
    outstandingbalance numeric(18,2) NOT NULL,
    finalizationdate date NULL,
    isfinalized boolean GENERATED ALWAYS AS (finalizationdate IS NOT NULL) STORED,
    lasteditedby integer NOT NULL,
    lasteditedwhen timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT pk_purchasing_suppliertransactions PRIMARY KEY (suppliertransactionid)
);
