-- Wide World Importers PostgreSQL Migration
-- Phase 2: OLTP Schema Migration
-- File: 003-sales-tables.sql
-- Description: Create Sales schema tables

-- Note: Tables are created without foreign keys first to avoid dependency issues
-- Foreign keys are added in a separate file after all tables are created

-- Sales.BuyingGroups table (temporal)
CREATE TABLE sales.buyinggroups (
    buyinggroupid integer NOT NULL DEFAULT nextval('sequences.buyinggroupid'),
    buyinggroupname varchar(50) NOT NULL,
    lasteditedby integer NOT NULL,
    validfrom timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
    validto timestamp NOT NULL DEFAULT '9999-12-31 23:59:59.999999',
    CONSTRAINT pk_sales_buyinggroups PRIMARY KEY (buyinggroupid),
    CONSTRAINT uq_sales_buyinggroups_buyinggroupname UNIQUE (buyinggroupname)
);

-- Sales.CustomerCategories table (temporal)
CREATE TABLE sales.customercategories (
    customercategoryid integer NOT NULL DEFAULT nextval('sequences.customercategoryid'),
    customercategoryname varchar(50) NOT NULL,
    lasteditedby integer NOT NULL,
    validfrom timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
    validto timestamp NOT NULL DEFAULT '9999-12-31 23:59:59.999999',
    CONSTRAINT pk_sales_customercategories PRIMARY KEY (customercategoryid),
    CONSTRAINT uq_sales_customercategories_customercategoryname UNIQUE (customercategoryname)
);

-- Sales.Customers table (temporal)
CREATE TABLE sales.customers (
    customerid integer NOT NULL DEFAULT nextval('sequences.customerid'),
    customername varchar(100) NOT NULL,
    billtocustomerid integer NOT NULL,
    customercategoryid integer NOT NULL,
    buyinggroupid integer NULL,
    primarycontactpersonid integer NOT NULL,
    alternatecontactpersonid integer NULL,
    deliverymethodid integer NOT NULL,
    deliverycityid integer NOT NULL,
    postalcityid integer NOT NULL,
    creditlimit numeric(18,2) NULL,
    accountopeneddate date NOT NULL,
    standarddiscountpercentage numeric(18,3) NOT NULL,
    isstatementsent boolean NOT NULL,
    isoncredithold boolean NOT NULL,
    paymentdays integer NOT NULL,
    phonenumber varchar(20) NOT NULL,
    faxnumber varchar(20) NOT NULL,
    deliveryrun varchar(5) NULL,
    runposition varchar(5) NULL,
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
    CONSTRAINT pk_sales_customers PRIMARY KEY (customerid),
    CONSTRAINT uq_sales_customers_customername UNIQUE (customername)
);

-- Sales.Orders table (non-temporal)
CREATE TABLE sales.orders (
    orderid integer NOT NULL DEFAULT nextval('sequences.orderid'),
    customerid integer NOT NULL,
    salespersonpersonid integer NOT NULL,
    pickedbypersonid integer NULL,
    contactpersonid integer NOT NULL,
    backorderorderid integer NULL,
    orderdate date NOT NULL,
    expecteddeliverydate date NOT NULL,
    customerpurchaseordernumber varchar(20) NULL,
    isundersupplybackordered boolean NOT NULL,
    comments text NULL,
    deliveryinstructions text NULL,
    internalcomments text NULL,
    pickingcompletedwhen timestamp NULL,
    lasteditedby integer NOT NULL,
    lasteditedwhen timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT pk_sales_orders PRIMARY KEY (orderid)
);

-- Sales.OrderLines table (non-temporal)
-- Note: SQL Server uses columnstore index, PostgreSQL uses regular table
CREATE TABLE sales.orderlines (
    orderlineid integer NOT NULL DEFAULT nextval('sequences.orderlineid'),
    orderid integer NOT NULL,
    stockitemid integer NOT NULL,
    description varchar(100) NOT NULL,
    packagetypeid integer NOT NULL,
    quantity integer NOT NULL,
    unitprice numeric(18,2) NULL,
    taxrate numeric(18,3) NOT NULL,
    pickedquantity integer NOT NULL,
    pickingcompletedwhen timestamp NULL,
    lasteditedby integer NOT NULL,
    lasteditedwhen timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT pk_sales_orderlines PRIMARY KEY (orderlineid)
);

-- Sales.Invoices table (non-temporal)
-- Note: ConfirmedDeliveryTime and ConfirmedReceivedBy are computed columns from JSON
-- These will be handled via a view or trigger
CREATE TABLE sales.invoices (
    invoiceid integer NOT NULL DEFAULT nextval('sequences.invoiceid'),
    customerid integer NOT NULL,
    billtocustomerid integer NOT NULL,
    orderid integer NULL,
    deliverymethodid integer NOT NULL,
    contactpersonid integer NOT NULL,
    accountspersonid integer NOT NULL,
    salespersonpersonid integer NOT NULL,
    packedbypersonid integer NOT NULL,
    invoicedate date NOT NULL,
    customerpurchaseordernumber varchar(20) NULL,
    iscreditnote boolean NOT NULL,
    creditnotereason text NULL,
    comments text NULL,
    deliveryinstructions text NULL,
    internalcomments text NULL,
    totaldryitems integer NOT NULL,
    totalchilleritems integer NOT NULL,
    deliveryrun varchar(5) NULL,
    runposition varchar(5) NULL,
    returneddeliverydata text NULL,
    lasteditedby integer NOT NULL,
    lasteditedwhen timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT pk_sales_invoices PRIMARY KEY (invoiceid),
    CONSTRAINT ck_sales_invoices_returneddeliverydata_must_be_valid_json 
        CHECK (returneddeliverydata IS NULL OR returneddeliverydata::jsonb IS NOT NULL)
);

-- Sales.InvoiceLines table (non-temporal)
-- Note: SQL Server uses columnstore index, PostgreSQL uses regular table
CREATE TABLE sales.invoicelines (
    invoicelineid integer NOT NULL DEFAULT nextval('sequences.invoicelineid'),
    invoiceid integer NOT NULL,
    stockitemid integer NOT NULL,
    description varchar(100) NOT NULL,
    packagetypeid integer NOT NULL,
    quantity integer NOT NULL,
    unitprice numeric(18,2) NULL,
    taxrate numeric(18,3) NOT NULL,
    taxamount numeric(18,2) NOT NULL,
    lineprofit numeric(18,2) NOT NULL,
    extendedprice numeric(18,2) NOT NULL,
    lasteditedby integer NOT NULL,
    lasteditedwhen timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT pk_sales_invoicelines PRIMARY KEY (invoicelineid)
);

-- Sales.SpecialDeals table (non-temporal)
CREATE TABLE sales.specialdeals (
    specialdealid integer NOT NULL DEFAULT nextval('sequences.specialdealid'),
    stockitemid integer NULL,
    customerid integer NULL,
    buyinggroupid integer NULL,
    customercategoryid integer NULL,
    stockgroupid integer NULL,
    dealdescription varchar(30) NOT NULL,
    startdate date NOT NULL,
    enddate date NOT NULL,
    discountamount numeric(18,2) NULL,
    discountpercentage numeric(18,3) NULL,
    unitprice numeric(18,2) NULL,
    lasteditedby integer NOT NULL,
    lasteditedwhen timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT pk_sales_specialdeals PRIMARY KEY (specialdealid),
    CONSTRAINT ck_sales_specialdeals_exactly_one_not_null_pricing_option_is_required 
        CHECK (((CASE WHEN discountamount IS NULL THEN 0 ELSE 1 END + 
                 CASE WHEN discountpercentage IS NULL THEN 0 ELSE 1 END) + 
                 CASE WHEN unitprice IS NULL THEN 0 ELSE 1 END) = 1),
    CONSTRAINT ck_sales_specialdeals_unit_price_deal_requires_special_stockitem 
        CHECK ((stockitemid IS NOT NULL AND unitprice IS NOT NULL) OR unitprice IS NULL)
);

-- Sales.CustomerTransactions table (non-temporal)
-- Note: IsFinalized is a computed column
CREATE TABLE sales.customertransactions (
    customertransactionid integer NOT NULL DEFAULT nextval('sequences.transactionid'),
    customerid integer NOT NULL,
    transactiontypeid integer NOT NULL,
    invoiceid integer NULL,
    paymentmethodid integer NULL,
    transactiondate date NOT NULL,
    amountexcludingtax numeric(18,2) NOT NULL,
    taxamount numeric(18,2) NOT NULL,
    transactionamount numeric(18,2) NOT NULL,
    outstandingbalance numeric(18,2) NOT NULL,
    finalizationdate date NULL,
    isfinalized boolean GENERATED ALWAYS AS (finalizationdate IS NOT NULL) STORED,
    lasteditedby integer NOT NULL,
    lasteditedwhen timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT pk_sales_customertransactions PRIMARY KEY (customertransactionid)
);
