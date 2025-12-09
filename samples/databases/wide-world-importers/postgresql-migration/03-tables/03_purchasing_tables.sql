-- Wide World Importers PostgreSQL Migration
-- Purchasing Schema Tables
-- This script creates all tables in the Purchasing schema

-- SupplierCategories Table (with temporal support)
CREATE TABLE IF NOT EXISTS purchasing.suppliercategories (
    suppliercategoryid integer NOT NULL DEFAULT nextval('sequences.suppliercategoryid'),
    suppliercategoryname varchar(50) NOT NULL,
    lasteditedby integer NOT NULL,
    validfrom timestamp NOT NULL DEFAULT NOW(),
    validto timestamp NOT NULL DEFAULT '9999-12-31 23:59:59.999999',
    CONSTRAINT pk_purchasing_suppliercategories PRIMARY KEY (suppliercategoryid),
    CONSTRAINT uq_purchasing_suppliercategories_suppliercategoryname UNIQUE (suppliercategoryname),
    CONSTRAINT fk_purchasing_suppliercategories_application_people FOREIGN KEY (lasteditedby) REFERENCES application.people(personid)
);
COMMENT ON TABLE purchasing.suppliercategories IS 'Categories for suppliers (e.g., novelty goods, clothing, packaging)';

-- SupplierCategories Archive Table
CREATE TABLE IF NOT EXISTS purchasing.suppliercategories_archive (
    suppliercategoryid integer NOT NULL,
    suppliercategoryname varchar(50) NOT NULL,
    lasteditedby integer NOT NULL,
    validfrom timestamp NOT NULL,
    validto timestamp NOT NULL
);
COMMENT ON TABLE purchasing.suppliercategories_archive IS 'Historical records for SupplierCategories table';

-- Suppliers Table (with temporal support)
CREATE TABLE IF NOT EXISTS purchasing.suppliers (
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
    validfrom timestamp NOT NULL DEFAULT NOW(),
    validto timestamp NOT NULL DEFAULT '9999-12-31 23:59:59.999999',
    CONSTRAINT pk_purchasing_suppliers PRIMARY KEY (supplierid),
    CONSTRAINT uq_purchasing_suppliers_suppliername UNIQUE (suppliername),
    CONSTRAINT fk_purchasing_suppliers_suppliercategoryid FOREIGN KEY (suppliercategoryid) REFERENCES purchasing.suppliercategories(suppliercategoryid),
    CONSTRAINT fk_purchasing_suppliers_primarycontactpersonid FOREIGN KEY (primarycontactpersonid) REFERENCES application.people(personid),
    CONSTRAINT fk_purchasing_suppliers_alternatecontactpersonid FOREIGN KEY (alternatecontactpersonid) REFERENCES application.people(personid),
    CONSTRAINT fk_purchasing_suppliers_deliverymethodid FOREIGN KEY (deliverymethodid) REFERENCES application.deliverymethods(deliverymethodid),
    CONSTRAINT fk_purchasing_suppliers_deliverycityid FOREIGN KEY (deliverycityid) REFERENCES application.cities(cityid),
    CONSTRAINT fk_purchasing_suppliers_postalcityid FOREIGN KEY (postalcityid) REFERENCES application.cities(cityid),
    CONSTRAINT fk_purchasing_suppliers_application_people FOREIGN KEY (lasteditedby) REFERENCES application.people(personid)
);
COMMENT ON TABLE purchasing.suppliers IS 'Main entity table for suppliers (organizations)';
CREATE INDEX IF NOT EXISTS fk_purchasing_suppliers_suppliercategoryid ON purchasing.suppliers(suppliercategoryid);
CREATE INDEX IF NOT EXISTS fk_purchasing_suppliers_primarycontactpersonid ON purchasing.suppliers(primarycontactpersonid);
CREATE INDEX IF NOT EXISTS fk_purchasing_suppliers_alternatecontactpersonid ON purchasing.suppliers(alternatecontactpersonid);
CREATE INDEX IF NOT EXISTS fk_purchasing_suppliers_deliverymethodid ON purchasing.suppliers(deliverymethodid);
CREATE INDEX IF NOT EXISTS fk_purchasing_suppliers_deliverycityid ON purchasing.suppliers(deliverycityid);
CREATE INDEX IF NOT EXISTS fk_purchasing_suppliers_postalcityid ON purchasing.suppliers(postalcityid);

-- Suppliers Archive Table
CREATE TABLE IF NOT EXISTS purchasing.suppliers_archive (
    supplierid integer NOT NULL,
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
    validfrom timestamp NOT NULL,
    validto timestamp NOT NULL
);
COMMENT ON TABLE purchasing.suppliers_archive IS 'Historical records for Suppliers table';
CREATE INDEX IF NOT EXISTS ix_suppliers_archive_validfrom ON purchasing.suppliers_archive(validfrom);
CREATE INDEX IF NOT EXISTS ix_suppliers_archive_validto ON purchasing.suppliers_archive(validto);

-- PurchaseOrders Table
CREATE TABLE IF NOT EXISTS purchasing.purchaseorders (
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
    lasteditedwhen timestamp NOT NULL DEFAULT NOW(),
    CONSTRAINT pk_purchasing_purchaseorders PRIMARY KEY (purchaseorderid),
    CONSTRAINT fk_purchasing_purchaseorders_supplierid FOREIGN KEY (supplierid) REFERENCES purchasing.suppliers(supplierid),
    CONSTRAINT fk_purchasing_purchaseorders_deliverymethodid FOREIGN KEY (deliverymethodid) REFERENCES application.deliverymethods(deliverymethodid),
    CONSTRAINT fk_purchasing_purchaseorders_contactpersonid FOREIGN KEY (contactpersonid) REFERENCES application.people(personid),
    CONSTRAINT fk_purchasing_purchaseorders_application_people FOREIGN KEY (lasteditedby) REFERENCES application.people(personid)
);
COMMENT ON TABLE purchasing.purchaseorders IS 'Details of supplier purchase orders';
CREATE INDEX IF NOT EXISTS fk_purchasing_purchaseorders_supplierid ON purchasing.purchaseorders(supplierid);
CREATE INDEX IF NOT EXISTS fk_purchasing_purchaseorders_deliverymethodid ON purchasing.purchaseorders(deliverymethodid);
CREATE INDEX IF NOT EXISTS fk_purchasing_purchaseorders_contactpersonid ON purchasing.purchaseorders(contactpersonid);

-- PurchaseOrderLines Table
CREATE TABLE IF NOT EXISTS purchasing.purchaseorderlines (
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
    lasteditedwhen timestamp NOT NULL DEFAULT NOW(),
    CONSTRAINT pk_purchasing_purchaseorderlines PRIMARY KEY (purchaseorderlineid),
    CONSTRAINT fk_purchasing_purchaseorderlines_purchaseorderid FOREIGN KEY (purchaseorderid) REFERENCES purchasing.purchaseorders(purchaseorderid),
    CONSTRAINT fk_purchasing_purchaseorderlines_application_people FOREIGN KEY (lasteditedby) REFERENCES application.people(personid)
);
COMMENT ON TABLE purchasing.purchaseorderlines IS 'Detail lines from supplier purchase orders';
CREATE INDEX IF NOT EXISTS fk_purchasing_purchaseorderlines_purchaseorderid ON purchasing.purchaseorderlines(purchaseorderid);
CREATE INDEX IF NOT EXISTS fk_purchasing_purchaseorderlines_stockitemid ON purchasing.purchaseorderlines(stockitemid);
CREATE INDEX IF NOT EXISTS fk_purchasing_purchaseorderlines_packagetypeid ON purchasing.purchaseorderlines(packagetypeid);
CREATE INDEX IF NOT EXISTS ix_purchasing_purchaseorderlines_perf_20160301_04 ON purchasing.purchaseorderlines(isorderlinefinalized, stockitemid) INCLUDE (orderedouters, receivedouters);

-- SupplierTransactions Table
CREATE TABLE IF NOT EXISTS purchasing.suppliertransactions (
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
    lasteditedwhen timestamp NOT NULL DEFAULT NOW(),
    CONSTRAINT pk_purchasing_suppliertransactions PRIMARY KEY (suppliertransactionid),
    CONSTRAINT fk_purchasing_suppliertransactions_supplierid FOREIGN KEY (supplierid) REFERENCES purchasing.suppliers(supplierid),
    CONSTRAINT fk_purchasing_suppliertransactions_transactiontypeid FOREIGN KEY (transactiontypeid) REFERENCES application.transactiontypes(transactiontypeid),
    CONSTRAINT fk_purchasing_suppliertransactions_purchaseorderid FOREIGN KEY (purchaseorderid) REFERENCES purchasing.purchaseorders(purchaseorderid),
    CONSTRAINT fk_purchasing_suppliertransactions_paymentmethodid FOREIGN KEY (paymentmethodid) REFERENCES application.paymentmethods(paymentmethodid),
    CONSTRAINT fk_purchasing_suppliertransactions_application_people FOREIGN KEY (lasteditedby) REFERENCES application.people(personid)
);
COMMENT ON TABLE purchasing.suppliertransactions IS 'All financial transactions that are supplier-related';
CREATE INDEX IF NOT EXISTS fk_purchasing_suppliertransactions_supplierid ON purchasing.suppliertransactions(supplierid);
CREATE INDEX IF NOT EXISTS fk_purchasing_suppliertransactions_transactiontypeid ON purchasing.suppliertransactions(transactiontypeid);
CREATE INDEX IF NOT EXISTS fk_purchasing_suppliertransactions_purchaseorderid ON purchasing.suppliertransactions(purchaseorderid);
CREATE INDEX IF NOT EXISTS fk_purchasing_suppliertransactions_paymentmethodid ON purchasing.suppliertransactions(paymentmethodid);
CREATE INDEX IF NOT EXISTS ix_purchasing_suppliertransactions_isfinalized ON purchasing.suppliertransactions(isfinalized);
