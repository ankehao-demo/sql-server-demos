-- Wide World Importers PostgreSQL Migration
-- Sales Schema Tables
-- This script creates all tables in the Sales schema

-- BuyingGroups Table (with temporal support)
CREATE TABLE IF NOT EXISTS sales.buyinggroups (
    buyinggroupid integer NOT NULL DEFAULT nextval('sequences.buyinggroupid'),
    buyinggroupname varchar(50) NOT NULL,
    lasteditedby integer NOT NULL,
    validfrom timestamp NOT NULL DEFAULT NOW(),
    validto timestamp NOT NULL DEFAULT '9999-12-31 23:59:59.999999',
    CONSTRAINT pk_sales_buyinggroups PRIMARY KEY (buyinggroupid),
    CONSTRAINT uq_sales_buyinggroups_buyinggroupname UNIQUE (buyinggroupname),
    CONSTRAINT fk_sales_buyinggroups_application_people FOREIGN KEY (lasteditedby) REFERENCES application.people(personid)
);
COMMENT ON TABLE sales.buyinggroups IS 'Customer organizations can be part of groups that exert greater buying power';

-- BuyingGroups Archive Table
CREATE TABLE IF NOT EXISTS sales.buyinggroups_archive (
    buyinggroupid integer NOT NULL,
    buyinggroupname varchar(50) NOT NULL,
    lasteditedby integer NOT NULL,
    validfrom timestamp NOT NULL,
    validto timestamp NOT NULL
);
COMMENT ON TABLE sales.buyinggroups_archive IS 'Historical records for BuyingGroups table';

-- CustomerCategories Table (with temporal support)
CREATE TABLE IF NOT EXISTS sales.customercategories (
    customercategoryid integer NOT NULL DEFAULT nextval('sequences.customercategoryid'),
    customercategoryname varchar(50) NOT NULL,
    lasteditedby integer NOT NULL,
    validfrom timestamp NOT NULL DEFAULT NOW(),
    validto timestamp NOT NULL DEFAULT '9999-12-31 23:59:59.999999',
    CONSTRAINT pk_sales_customercategories PRIMARY KEY (customercategoryid),
    CONSTRAINT uq_sales_customercategories_customercategoryname UNIQUE (customercategoryname),
    CONSTRAINT fk_sales_customercategories_application_people FOREIGN KEY (lasteditedby) REFERENCES application.people(personid)
);
COMMENT ON TABLE sales.customercategories IS 'Categories for customers (e.g., novelty store, supermarket)';

-- CustomerCategories Archive Table
CREATE TABLE IF NOT EXISTS sales.customercategories_archive (
    customercategoryid integer NOT NULL,
    customercategoryname varchar(50) NOT NULL,
    lasteditedby integer NOT NULL,
    validfrom timestamp NOT NULL,
    validto timestamp NOT NULL
);
COMMENT ON TABLE sales.customercategories_archive IS 'Historical records for CustomerCategories table';

-- Customers Table (with temporal support)
CREATE TABLE IF NOT EXISTS sales.customers (
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
    validfrom timestamp NOT NULL DEFAULT NOW(),
    validto timestamp NOT NULL DEFAULT '9999-12-31 23:59:59.999999',
    CONSTRAINT pk_sales_customers PRIMARY KEY (customerid),
    CONSTRAINT uq_sales_customers_customername UNIQUE (customername),
    CONSTRAINT fk_sales_customers_billtocustomerid FOREIGN KEY (billtocustomerid) REFERENCES sales.customers(customerid),
    CONSTRAINT fk_sales_customers_customercategoryid FOREIGN KEY (customercategoryid) REFERENCES sales.customercategories(customercategoryid),
    CONSTRAINT fk_sales_customers_buyinggroupid FOREIGN KEY (buyinggroupid) REFERENCES sales.buyinggroups(buyinggroupid),
    CONSTRAINT fk_sales_customers_primarycontactpersonid FOREIGN KEY (primarycontactpersonid) REFERENCES application.people(personid),
    CONSTRAINT fk_sales_customers_alternatecontactpersonid FOREIGN KEY (alternatecontactpersonid) REFERENCES application.people(personid),
    CONSTRAINT fk_sales_customers_deliverymethodid FOREIGN KEY (deliverymethodid) REFERENCES application.deliverymethods(deliverymethodid),
    CONSTRAINT fk_sales_customers_deliverycityid FOREIGN KEY (deliverycityid) REFERENCES application.cities(cityid),
    CONSTRAINT fk_sales_customers_postalcityid FOREIGN KEY (postalcityid) REFERENCES application.cities(cityid),
    CONSTRAINT fk_sales_customers_application_people FOREIGN KEY (lasteditedby) REFERENCES application.people(personid)
);
COMMENT ON TABLE sales.customers IS 'Main entity tables for customers (organizations or individuals)';
CREATE INDEX IF NOT EXISTS fk_sales_customers_customercategoryid ON sales.customers(customercategoryid);
CREATE INDEX IF NOT EXISTS fk_sales_customers_buyinggroupid ON sales.customers(buyinggroupid);
CREATE INDEX IF NOT EXISTS fk_sales_customers_primarycontactpersonid ON sales.customers(primarycontactpersonid);
CREATE INDEX IF NOT EXISTS fk_sales_customers_alternatecontactpersonid ON sales.customers(alternatecontactpersonid);
CREATE INDEX IF NOT EXISTS fk_sales_customers_deliverymethodid ON sales.customers(deliverymethodid);
CREATE INDEX IF NOT EXISTS fk_sales_customers_deliverycityid ON sales.customers(deliverycityid);
CREATE INDEX IF NOT EXISTS fk_sales_customers_postalcityid ON sales.customers(postalcityid);
CREATE INDEX IF NOT EXISTS ix_sales_customers_perf_20160301_06 ON sales.customers(isoncredithold, customerid, billtocustomerid) INCLUDE (primarycontactpersonid);

-- Customers Archive Table
CREATE TABLE IF NOT EXISTS sales.customers_archive (
    customerid integer NOT NULL,
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
    validfrom timestamp NOT NULL,
    validto timestamp NOT NULL
);
COMMENT ON TABLE sales.customers_archive IS 'Historical records for Customers table';
CREATE INDEX IF NOT EXISTS ix_customers_archive_validfrom ON sales.customers_archive(validfrom);
CREATE INDEX IF NOT EXISTS ix_customers_archive_validto ON sales.customers_archive(validto);

-- Orders Table
CREATE TABLE IF NOT EXISTS sales.orders (
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
    lasteditedwhen timestamp NOT NULL DEFAULT NOW(),
    CONSTRAINT pk_sales_orders PRIMARY KEY (orderid),
    CONSTRAINT fk_sales_orders_customerid FOREIGN KEY (customerid) REFERENCES sales.customers(customerid),
    CONSTRAINT fk_sales_orders_salespersonpersonid FOREIGN KEY (salespersonpersonid) REFERENCES application.people(personid),
    CONSTRAINT fk_sales_orders_pickedbypersonid FOREIGN KEY (pickedbypersonid) REFERENCES application.people(personid),
    CONSTRAINT fk_sales_orders_contactpersonid FOREIGN KEY (contactpersonid) REFERENCES application.people(personid),
    CONSTRAINT fk_sales_orders_backorderorderid FOREIGN KEY (backorderorderid) REFERENCES sales.orders(orderid),
    CONSTRAINT fk_sales_orders_application_people FOREIGN KEY (lasteditedby) REFERENCES application.people(personid)
);
COMMENT ON TABLE sales.orders IS 'Detail of customer orders';
CREATE INDEX IF NOT EXISTS fk_sales_orders_customerid ON sales.orders(customerid);
CREATE INDEX IF NOT EXISTS fk_sales_orders_salespersonpersonid ON sales.orders(salespersonpersonid);
CREATE INDEX IF NOT EXISTS fk_sales_orders_contactpersonid ON sales.orders(contactpersonid);
CREATE INDEX IF NOT EXISTS ix_sales_orders_orderdate ON sales.orders(orderdate);

-- OrderLines Table
CREATE TABLE IF NOT EXISTS sales.orderlines (
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
    lasteditedwhen timestamp NOT NULL DEFAULT NOW(),
    CONSTRAINT pk_sales_orderlines PRIMARY KEY (orderlineid),
    CONSTRAINT fk_sales_orderlines_orderid FOREIGN KEY (orderid) REFERENCES sales.orders(orderid),
    CONSTRAINT fk_sales_orderlines_application_people FOREIGN KEY (lasteditedby) REFERENCES application.people(personid)
);
COMMENT ON TABLE sales.orderlines IS 'Detail lines from customer orders';
CREATE INDEX IF NOT EXISTS fk_sales_orderlines_orderid ON sales.orderlines(orderid);
CREATE INDEX IF NOT EXISTS fk_sales_orderlines_stockitemid ON sales.orderlines(stockitemid);
CREATE INDEX IF NOT EXISTS fk_sales_orderlines_packagetypeid ON sales.orderlines(packagetypeid);
CREATE INDEX IF NOT EXISTS ix_sales_orderlines_perf_20160301_01 ON sales.orderlines(pickingcompletedwhen, orderid, orderlineid) INCLUDE (quantity, stockitemid);
CREATE INDEX IF NOT EXISTS ix_sales_orderlines_perf_20160301_02 ON sales.orderlines(stockitemid, pickingcompletedwhen) INCLUDE (orderid, pickedquantity);

-- Invoices Table
CREATE TABLE IF NOT EXISTS sales.invoices (
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
    confirmeddeliverytime timestamp NULL,
    confirmedreceivedby varchar(4000) NULL,
    lasteditedby integer NOT NULL,
    lasteditedwhen timestamp NOT NULL DEFAULT NOW(),
    CONSTRAINT pk_sales_invoices PRIMARY KEY (invoiceid),
    CONSTRAINT fk_sales_invoices_customerid FOREIGN KEY (customerid) REFERENCES sales.customers(customerid),
    CONSTRAINT fk_sales_invoices_billtocustomerid FOREIGN KEY (billtocustomerid) REFERENCES sales.customers(customerid),
    CONSTRAINT fk_sales_invoices_orderid FOREIGN KEY (orderid) REFERENCES sales.orders(orderid),
    CONSTRAINT fk_sales_invoices_deliverymethodid FOREIGN KEY (deliverymethodid) REFERENCES application.deliverymethods(deliverymethodid),
    CONSTRAINT fk_sales_invoices_contactpersonid FOREIGN KEY (contactpersonid) REFERENCES application.people(personid),
    CONSTRAINT fk_sales_invoices_accountspersonid FOREIGN KEY (accountspersonid) REFERENCES application.people(personid),
    CONSTRAINT fk_sales_invoices_salespersonpersonid FOREIGN KEY (salespersonpersonid) REFERENCES application.people(personid),
    CONSTRAINT fk_sales_invoices_packedbypersonid FOREIGN KEY (packedbypersonid) REFERENCES application.people(personid),
    CONSTRAINT fk_sales_invoices_application_people FOREIGN KEY (lasteditedby) REFERENCES application.people(personid)
);
COMMENT ON TABLE sales.invoices IS 'Details of customer invoices';
CREATE INDEX IF NOT EXISTS fk_sales_invoices_customerid ON sales.invoices(customerid);
CREATE INDEX IF NOT EXISTS fk_sales_invoices_billtocustomerid ON sales.invoices(billtocustomerid);
CREATE INDEX IF NOT EXISTS fk_sales_invoices_orderid ON sales.invoices(orderid);
CREATE INDEX IF NOT EXISTS fk_sales_invoices_deliverymethodid ON sales.invoices(deliverymethodid);
CREATE INDEX IF NOT EXISTS fk_sales_invoices_contactpersonid ON sales.invoices(contactpersonid);
CREATE INDEX IF NOT EXISTS fk_sales_invoices_accountspersonid ON sales.invoices(accountspersonid);
CREATE INDEX IF NOT EXISTS fk_sales_invoices_salespersonpersonid ON sales.invoices(salespersonpersonid);
CREATE INDEX IF NOT EXISTS fk_sales_invoices_packedbypersonid ON sales.invoices(packedbypersonid);
CREATE INDEX IF NOT EXISTS ix_sales_invoices_confirmeddeliverytime ON sales.invoices(confirmeddeliverytime) INCLUDE (confirmedreceivedby);

-- InvoiceLines Table
CREATE TABLE IF NOT EXISTS sales.invoicelines (
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
    lasteditedwhen timestamp NOT NULL DEFAULT NOW(),
    CONSTRAINT pk_sales_invoicelines PRIMARY KEY (invoicelineid),
    CONSTRAINT fk_sales_invoicelines_invoiceid FOREIGN KEY (invoiceid) REFERENCES sales.invoices(invoiceid),
    CONSTRAINT fk_sales_invoicelines_application_people FOREIGN KEY (lasteditedby) REFERENCES application.people(personid)
);
COMMENT ON TABLE sales.invoicelines IS 'Detail lines from customer invoices';
CREATE INDEX IF NOT EXISTS fk_sales_invoicelines_invoiceid ON sales.invoicelines(invoiceid);
CREATE INDEX IF NOT EXISTS fk_sales_invoicelines_stockitemid ON sales.invoicelines(stockitemid);
CREATE INDEX IF NOT EXISTS fk_sales_invoicelines_packagetypeid ON sales.invoicelines(packagetypeid);

-- CustomerTransactions Table
CREATE TABLE IF NOT EXISTS sales.customertransactions (
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
    lasteditedwhen timestamp NOT NULL DEFAULT NOW(),
    CONSTRAINT pk_sales_customertransactions PRIMARY KEY (customertransactionid),
    CONSTRAINT fk_sales_customertransactions_customerid FOREIGN KEY (customerid) REFERENCES sales.customers(customerid),
    CONSTRAINT fk_sales_customertransactions_transactiontypeid FOREIGN KEY (transactiontypeid) REFERENCES application.transactiontypes(transactiontypeid),
    CONSTRAINT fk_sales_customertransactions_invoiceid FOREIGN KEY (invoiceid) REFERENCES sales.invoices(invoiceid),
    CONSTRAINT fk_sales_customertransactions_paymentmethodid FOREIGN KEY (paymentmethodid) REFERENCES application.paymentmethods(paymentmethodid),
    CONSTRAINT fk_sales_customertransactions_application_people FOREIGN KEY (lasteditedby) REFERENCES application.people(personid)
);
COMMENT ON TABLE sales.customertransactions IS 'All financial transactions that are customer-related';
CREATE INDEX IF NOT EXISTS fk_sales_customertransactions_customerid ON sales.customertransactions(customerid);
CREATE INDEX IF NOT EXISTS fk_sales_customertransactions_transactiontypeid ON sales.customertransactions(transactiontypeid);
CREATE INDEX IF NOT EXISTS fk_sales_customertransactions_invoiceid ON sales.customertransactions(invoiceid);
CREATE INDEX IF NOT EXISTS fk_sales_customertransactions_paymentmethodid ON sales.customertransactions(paymentmethodid);
CREATE INDEX IF NOT EXISTS ix_sales_customertransactions_isfinalized ON sales.customertransactions(isfinalized);

-- SpecialDeals Table
CREATE TABLE IF NOT EXISTS sales.specialdeals (
    specialdealid integer NOT NULL DEFAULT nextval('sequences.specialdealid'),
    stockitemid integer NULL,
    customerid integer NULL,
    buyinggroupid integer NULL,
    customercategoryid integer NULL,
    stockgroupid integer NULL,
    dealDescription varchar(30) NOT NULL,
    startdate date NOT NULL,
    enddate date NOT NULL,
    discountamount numeric(18,2) NULL,
    discountpercentage numeric(18,3) NULL,
    unitprice numeric(18,2) NULL,
    lasteditedby integer NOT NULL,
    lasteditedwhen timestamp NOT NULL DEFAULT NOW(),
    CONSTRAINT pk_sales_specialdeals PRIMARY KEY (specialdealid),
    CONSTRAINT fk_sales_specialdeals_customerid FOREIGN KEY (customerid) REFERENCES sales.customers(customerid),
    CONSTRAINT fk_sales_specialdeals_buyinggroupid FOREIGN KEY (buyinggroupid) REFERENCES sales.buyinggroups(buyinggroupid),
    CONSTRAINT fk_sales_specialdeals_customercategoryid FOREIGN KEY (customercategoryid) REFERENCES sales.customercategories(customercategoryid),
    CONSTRAINT fk_sales_specialdeals_application_people FOREIGN KEY (lasteditedby) REFERENCES application.people(personid),
    CONSTRAINT ck_sales_specialdeals_unit_price_deal_type CHECK (
        (discountamount IS NULL AND discountpercentage IS NULL AND unitprice IS NOT NULL)
        OR (discountamount IS NOT NULL AND discountpercentage IS NULL AND unitprice IS NULL)
        OR (discountamount IS NULL AND discountpercentage IS NOT NULL AND unitprice IS NULL)
    ),
    CONSTRAINT ck_sales_specialdeals_buying_group_or_customer_or_category CHECK (
        (buyinggroupid IS NULL AND customerid IS NULL AND customercategoryid IS NULL)
        OR (buyinggroupid IS NOT NULL AND customerid IS NULL AND customercategoryid IS NULL)
        OR (buyinggroupid IS NULL AND customerid IS NOT NULL AND customercategoryid IS NULL)
        OR (buyinggroupid IS NULL AND customerid IS NULL AND customercategoryid IS NOT NULL)
    )
);
COMMENT ON TABLE sales.specialdeals IS 'Special pricing (can include fixed prices, discount percentages, or discount amounts)';
CREATE INDEX IF NOT EXISTS fk_sales_specialdeals_stockitemid ON sales.specialdeals(stockitemid);
CREATE INDEX IF NOT EXISTS fk_sales_specialdeals_customerid ON sales.specialdeals(customerid);
CREATE INDEX IF NOT EXISTS fk_sales_specialdeals_buyinggroupid ON sales.specialdeals(buyinggroupid);
CREATE INDEX IF NOT EXISTS fk_sales_specialdeals_customercategoryid ON sales.specialdeals(customercategoryid);
CREATE INDEX IF NOT EXISTS fk_sales_specialdeals_stockgroupid ON sales.specialdeals(stockgroupid);
