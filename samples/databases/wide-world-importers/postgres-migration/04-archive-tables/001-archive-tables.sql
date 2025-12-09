-- Wide World Importers PostgreSQL Migration
-- Phase 2: OLTP Schema Migration
-- File: 001-archive-tables.sql
-- Description: Create archive/history tables for temporal table support

-- Application schema archive tables

CREATE TABLE application.people_archive (
    personid integer NOT NULL,
    fullname varchar(50) NOT NULL,
    preferredname varchar(50) NOT NULL,
    searchname varchar(101),
    ispermittedtologon boolean NOT NULL,
    logonname varchar(256) NULL,
    isexternallogonprovider boolean NOT NULL,
    hashedpassword bytea NULL,
    issystemuser boolean NOT NULL,
    isemployee boolean NOT NULL,
    issalesperson boolean NOT NULL,
    userpreferences text NULL,
    phonenumber varchar(20) NULL,
    faxnumber varchar(20) NULL,
    emailaddress varchar(256) NULL,
    photo bytea NULL,
    customfields text NULL,
    lasteditedby integer NOT NULL,
    validfrom timestamp NOT NULL,
    validto timestamp NOT NULL
);

CREATE INDEX ix_people_archive ON application.people_archive (validto, validfrom);

CREATE TABLE application.countries_archive (
    countryid integer NOT NULL,
    countryname varchar(60) NOT NULL,
    formalname varchar(60) NOT NULL,
    isoalpha3code varchar(3) NULL,
    isonumericcode integer NULL,
    countrytype varchar(20) NULL,
    latestrecordedpopulation bigint NULL,
    continent varchar(30) NOT NULL,
    region varchar(30) NOT NULL,
    subregion varchar(30) NOT NULL,
    border geography NULL,
    lasteditedby integer NOT NULL,
    validfrom timestamp NOT NULL,
    validto timestamp NOT NULL
);

CREATE INDEX ix_countries_archive ON application.countries_archive (validto, validfrom);

CREATE TABLE application.stateprovinces_archive (
    stateprovinceid integer NOT NULL,
    stateprovincecode varchar(5) NOT NULL,
    stateprovincename varchar(50) NOT NULL,
    countryid integer NOT NULL,
    salesterritory varchar(50) NOT NULL,
    border geography NULL,
    latestrecordedpopulation bigint NULL,
    lasteditedby integer NOT NULL,
    validfrom timestamp NOT NULL,
    validto timestamp NOT NULL
);

CREATE INDEX ix_stateprovinces_archive ON application.stateprovinces_archive (validto, validfrom);

CREATE TABLE application.cities_archive (
    cityid integer NOT NULL,
    cityname varchar(50) NOT NULL,
    stateprovinceid integer NOT NULL,
    location geography NULL,
    latestrecordedpopulation bigint NULL,
    lasteditedby integer NOT NULL,
    validfrom timestamp NOT NULL,
    validto timestamp NOT NULL
);

CREATE INDEX ix_cities_archive ON application.cities_archive (validto, validfrom);

CREATE TABLE application.deliverymethods_archive (
    deliverymethodid integer NOT NULL,
    deliverymethodname varchar(50) NOT NULL,
    lasteditedby integer NOT NULL,
    validfrom timestamp NOT NULL,
    validto timestamp NOT NULL
);

CREATE INDEX ix_deliverymethods_archive ON application.deliverymethods_archive (validto, validfrom);

CREATE TABLE application.paymentmethods_archive (
    paymentmethodid integer NOT NULL,
    paymentmethodname varchar(50) NOT NULL,
    lasteditedby integer NOT NULL,
    validfrom timestamp NOT NULL,
    validto timestamp NOT NULL
);

CREATE INDEX ix_paymentmethods_archive ON application.paymentmethods_archive (validto, validfrom);

CREATE TABLE application.transactiontypes_archive (
    transactiontypeid integer NOT NULL,
    transactiontypename varchar(50) NOT NULL,
    lasteditedby integer NOT NULL,
    validfrom timestamp NOT NULL,
    validto timestamp NOT NULL
);

CREATE INDEX ix_transactiontypes_archive ON application.transactiontypes_archive (validto, validfrom);

-- Warehouse schema archive tables

CREATE TABLE warehouse.colors_archive (
    colorid integer NOT NULL,
    colorname varchar(20) NOT NULL,
    lasteditedby integer NOT NULL,
    validfrom timestamp NOT NULL,
    validto timestamp NOT NULL
);

CREATE INDEX ix_colors_archive ON warehouse.colors_archive (validto, validfrom);

CREATE TABLE warehouse.packagetypes_archive (
    packagetypeid integer NOT NULL,
    packagetypename varchar(50) NOT NULL,
    lasteditedby integer NOT NULL,
    validfrom timestamp NOT NULL,
    validto timestamp NOT NULL
);

CREATE INDEX ix_packagetypes_archive ON warehouse.packagetypes_archive (validto, validfrom);

CREATE TABLE warehouse.stockgroups_archive (
    stockgroupid integer NOT NULL,
    stockgroupname varchar(50) NOT NULL,
    lasteditedby integer NOT NULL,
    validfrom timestamp NOT NULL,
    validto timestamp NOT NULL
);

CREATE INDEX ix_stockgroups_archive ON warehouse.stockgroups_archive (validto, validfrom);

CREATE TABLE warehouse.stockitems_archive (
    stockitemid integer NOT NULL,
    stockitemname varchar(100) NOT NULL,
    supplierid integer NOT NULL,
    colorid integer NULL,
    unitpackageid integer NOT NULL,
    outerpackageid integer NOT NULL,
    brand varchar(50) NULL,
    size varchar(20) NULL,
    leadtimedays integer NOT NULL,
    quantityperOuter integer NOT NULL,
    ischillerstock boolean NOT NULL,
    barcode varchar(50) NULL,
    taxrate numeric(18,3) NOT NULL,
    unitprice numeric(18,2) NOT NULL,
    recommendedretailprice numeric(18,2) NULL,
    typicalweightperunit numeric(18,3) NOT NULL,
    marketingcomments text NULL,
    internalcomments text NULL,
    photo bytea NULL,
    customfields text NULL,
    lasteditedby integer NOT NULL,
    validfrom timestamp NOT NULL,
    validto timestamp NOT NULL
);

CREATE INDEX ix_stockitems_archive ON warehouse.stockitems_archive (validto, validfrom);

CREATE TABLE warehouse.coldroomtemperatures_archive (
    coldroomtemperatureid bigint NOT NULL,
    coldroomsensornumber integer NOT NULL,
    recordedwhen timestamp NOT NULL,
    temperature numeric(10,2) NOT NULL,
    validfrom timestamp NOT NULL,
    validto timestamp NOT NULL
);

CREATE INDEX ix_coldroomtemperatures_archive ON warehouse.coldroomtemperatures_archive (validto, validfrom);

-- Sales schema archive tables

CREATE TABLE sales.buyinggroups_archive (
    buyinggroupid integer NOT NULL,
    buyinggroupname varchar(50) NOT NULL,
    lasteditedby integer NOT NULL,
    validfrom timestamp NOT NULL,
    validto timestamp NOT NULL
);

CREATE INDEX ix_buyinggroups_archive ON sales.buyinggroups_archive (validto, validfrom);

CREATE TABLE sales.customercategories_archive (
    customercategoryid integer NOT NULL,
    customercategoryname varchar(50) NOT NULL,
    lasteditedby integer NOT NULL,
    validfrom timestamp NOT NULL,
    validto timestamp NOT NULL
);

CREATE INDEX ix_customercategories_archive ON sales.customercategories_archive (validto, validfrom);

CREATE TABLE sales.customers_archive (
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

CREATE INDEX ix_customers_archive ON sales.customers_archive (validto, validfrom);

-- Purchasing schema archive tables

CREATE TABLE purchasing.suppliercategories_archive (
    suppliercategoryid integer NOT NULL,
    suppliercategoryname varchar(50) NOT NULL,
    lasteditedby integer NOT NULL,
    validfrom timestamp NOT NULL,
    validto timestamp NOT NULL
);

CREATE INDEX ix_suppliercategories_archive ON purchasing.suppliercategories_archive (validto, validfrom);

CREATE TABLE purchasing.suppliers_archive (
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

CREATE INDEX ix_suppliers_archive ON purchasing.suppliers_archive (validto, validfrom);
