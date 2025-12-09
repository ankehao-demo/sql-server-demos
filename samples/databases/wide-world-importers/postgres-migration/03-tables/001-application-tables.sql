-- Wide World Importers PostgreSQL Migration
-- Phase 2: OLTP Schema Migration
-- File: 001-application-tables.sql
-- Description: Create Application schema tables

-- Note: Tables are created without foreign keys first to avoid dependency issues
-- Foreign keys are added in a separate file after all tables are created

-- Application.People table (temporal)
-- Note: People table is created first as many other tables reference it
CREATE TABLE application.people (
    personid integer NOT NULL DEFAULT nextval('sequences.personid'),
    fullname varchar(50) NOT NULL,
    preferredname varchar(50) NOT NULL,
    searchname varchar(101) GENERATED ALWAYS AS (preferredname || ' ' || fullname) STORED,
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
    validfrom timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
    validto timestamp NOT NULL DEFAULT '9999-12-31 23:59:59.999999',
    CONSTRAINT pk_application_people PRIMARY KEY (personid)
);

-- Application.Countries table (temporal)
CREATE TABLE application.countries (
    countryid integer NOT NULL DEFAULT nextval('sequences.countryid'),
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
    validfrom timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
    validto timestamp NOT NULL DEFAULT '9999-12-31 23:59:59.999999',
    CONSTRAINT pk_application_countries PRIMARY KEY (countryid),
    CONSTRAINT uq_application_countries_countryname UNIQUE (countryname),
    CONSTRAINT uq_application_countries_formalname UNIQUE (formalname)
);

-- Application.StateProvinces table (temporal)
CREATE TABLE application.stateprovinces (
    stateprovinceid integer NOT NULL DEFAULT nextval('sequences.stateprovinceid'),
    stateprovincecode varchar(5) NOT NULL,
    stateprovincename varchar(50) NOT NULL,
    countryid integer NOT NULL,
    salesterritory varchar(50) NOT NULL,
    border geography NULL,
    latestrecordedpopulation bigint NULL,
    lasteditedby integer NOT NULL,
    validfrom timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
    validto timestamp NOT NULL DEFAULT '9999-12-31 23:59:59.999999',
    CONSTRAINT pk_application_stateprovinces PRIMARY KEY (stateprovinceid),
    CONSTRAINT uq_application_stateprovinces_stateprovincename UNIQUE (stateprovincename)
);

-- Application.Cities table (temporal)
CREATE TABLE application.cities (
    cityid integer NOT NULL DEFAULT nextval('sequences.cityid'),
    cityname varchar(50) NOT NULL,
    stateprovinceid integer NOT NULL,
    location geography NULL,
    latestrecordedpopulation bigint NULL,
    lasteditedby integer NOT NULL,
    validfrom timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
    validto timestamp NOT NULL DEFAULT '9999-12-31 23:59:59.999999',
    CONSTRAINT pk_application_cities PRIMARY KEY (cityid)
);

-- Application.DeliveryMethods table (temporal)
CREATE TABLE application.deliverymethods (
    deliverymethodid integer NOT NULL DEFAULT nextval('sequences.deliverymethodid'),
    deliverymethodname varchar(50) NOT NULL,
    lasteditedby integer NOT NULL,
    validfrom timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
    validto timestamp NOT NULL DEFAULT '9999-12-31 23:59:59.999999',
    CONSTRAINT pk_application_deliverymethods PRIMARY KEY (deliverymethodid),
    CONSTRAINT uq_application_deliverymethods_deliverymethodname UNIQUE (deliverymethodname)
);

-- Application.PaymentMethods table (temporal)
CREATE TABLE application.paymentmethods (
    paymentmethodid integer NOT NULL DEFAULT nextval('sequences.paymentmethodid'),
    paymentmethodname varchar(50) NOT NULL,
    lasteditedby integer NOT NULL,
    validfrom timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
    validto timestamp NOT NULL DEFAULT '9999-12-31 23:59:59.999999',
    CONSTRAINT pk_application_paymentmethods PRIMARY KEY (paymentmethodid),
    CONSTRAINT uq_application_paymentmethods_paymentmethodname UNIQUE (paymentmethodname)
);

-- Application.TransactionTypes table (temporal)
CREATE TABLE application.transactiontypes (
    transactiontypeid integer NOT NULL DEFAULT nextval('sequences.transactiontypeid'),
    transactiontypename varchar(50) NOT NULL,
    lasteditedby integer NOT NULL,
    validfrom timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
    validto timestamp NOT NULL DEFAULT '9999-12-31 23:59:59.999999',
    CONSTRAINT pk_application_transactiontypes PRIMARY KEY (transactiontypeid),
    CONSTRAINT uq_application_transactiontypes_transactiontypename UNIQUE (transactiontypename)
);

-- Application.SystemParameters table (non-temporal)
CREATE TABLE application.systemparameters (
    systemparameterid integer NOT NULL DEFAULT nextval('sequences.systemparameterid'),
    deliveryaddressline1 varchar(60) NOT NULL,
    deliveryaddressline2 varchar(60) NULL,
    deliverycityid integer NOT NULL,
    deliverypostalcode varchar(10) NOT NULL,
    deliverylocation geography NOT NULL,
    postaladdressline1 varchar(60) NOT NULL,
    postaladdressline2 varchar(60) NULL,
    postalcityid integer NOT NULL,
    postalpostalcode varchar(10) NOT NULL,
    applicationsettings text NOT NULL,
    lasteditedby integer NOT NULL,
    lasteditedwhen timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT pk_application_systemparameters PRIMARY KEY (systemparameterid)
);

-- Application.Logs table (non-temporal)
-- Note: SQL Server uses clustered columnstore index, PostgreSQL uses regular table
CREATE TABLE application.logs (
    message varchar(4000) NOT NULL,
    level varchar(16) NOT NULL,
    eventtime timestamp NOT NULL,
    logevent text NULL
);
