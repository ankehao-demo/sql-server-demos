-- Wide World Importers PostgreSQL Migration
-- Phase 2: OLTP Schema Migration
-- File: 002-warehouse-tables.sql
-- Description: Create Warehouse schema tables

-- Note: Tables are created without foreign keys first to avoid dependency issues
-- Foreign keys are added in a separate file after all tables are created

-- Warehouse.Colors table (temporal)
CREATE TABLE warehouse.colors (
    colorid integer NOT NULL DEFAULT nextval('sequences.colorid'),
    colorname varchar(20) NOT NULL,
    lasteditedby integer NOT NULL,
    validfrom timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
    validto timestamp NOT NULL DEFAULT '9999-12-31 23:59:59.999999',
    CONSTRAINT pk_warehouse_colors PRIMARY KEY (colorid),
    CONSTRAINT uq_warehouse_colors_colorname UNIQUE (colorname)
);

-- Warehouse.PackageTypes table (temporal)
CREATE TABLE warehouse.packagetypes (
    packagetypeid integer NOT NULL DEFAULT nextval('sequences.packagetypeid'),
    packagetypename varchar(50) NOT NULL,
    lasteditedby integer NOT NULL,
    validfrom timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
    validto timestamp NOT NULL DEFAULT '9999-12-31 23:59:59.999999',
    CONSTRAINT pk_warehouse_packagetypes PRIMARY KEY (packagetypeid),
    CONSTRAINT uq_warehouse_packagetypes_packagetypename UNIQUE (packagetypename)
);

-- Warehouse.StockGroups table (temporal)
CREATE TABLE warehouse.stockgroups (
    stockgroupid integer NOT NULL DEFAULT nextval('sequences.stockgroupid'),
    stockgroupname varchar(50) NOT NULL,
    lasteditedby integer NOT NULL,
    validfrom timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
    validto timestamp NOT NULL DEFAULT '9999-12-31 23:59:59.999999',
    CONSTRAINT pk_warehouse_stockgroups PRIMARY KEY (stockgroupid),
    CONSTRAINT uq_warehouse_stockgroups_stockgroupname UNIQUE (stockgroupname)
);

-- Warehouse.StockItems table (temporal)
-- Note: Tags and SearchDetails are computed columns in SQL Server
-- Tags uses json_query which we'll handle via a JSONB column
-- SearchDetails is a generated column (concatenation of stockitemname and marketingcomments)
CREATE TABLE warehouse.stockitems (
    stockitemid integer NOT NULL DEFAULT nextval('sequences.stockitemid'),
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
    tags jsonb NULL,
    searchdetails text GENERATED ALWAYS AS (stockitemname || ' ' || COALESCE(marketingcomments, '')) STORED,
    lasteditedby integer NOT NULL,
    validfrom timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
    validto timestamp NOT NULL DEFAULT '9999-12-31 23:59:59.999999',
    CONSTRAINT pk_warehouse_stockitems PRIMARY KEY (stockitemid),
    CONSTRAINT uq_warehouse_stockitems_stockitemname UNIQUE (stockitemname)
);

-- Warehouse.StockItemHoldings table (non-temporal)
-- Note: lastreceiptdate added for Integration ETL procedures
CREATE TABLE warehouse.stockitemholdings (
    stockitemid integer NOT NULL,
    quantityonhand integer NOT NULL,
    binlocation varchar(20) NOT NULL,
    laststocktakequantity integer NOT NULL,
    lastcostprice numeric(18,2) NOT NULL,
    reorderlevel integer NOT NULL,
    targetstocklevel integer NOT NULL,
    lastreceiptdate date NULL,
    lasteditedby integer NOT NULL,
    lasteditedwhen timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT pk_warehouse_stockitemholdings PRIMARY KEY (stockitemid)
);

-- Warehouse.StockItemStockGroups table (non-temporal, junction table)
CREATE TABLE warehouse.stockitemstockgroups (
    stockitemstockgroupid integer NOT NULL DEFAULT nextval('sequences.stockitemstockgroupid'),
    stockitemid integer NOT NULL,
    stockgroupid integer NOT NULL,
    lasteditedby integer NOT NULL,
    lasteditedwhen timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT pk_warehouse_stockitemstockgroups PRIMARY KEY (stockitemstockgroupid),
    CONSTRAINT uq_stockitemstockgroups_stockgroupid_lookup UNIQUE (stockgroupid, stockitemid),
    CONSTRAINT uq_stockitemstockgroups_stockitemid_lookup UNIQUE (stockitemid, stockgroupid)
);

-- Warehouse.StockItemTransactions table (non-temporal)
-- Note: SQL Server uses clustered columnstore index, PostgreSQL uses regular table
CREATE TABLE warehouse.stockitemtransactions (
    stockitemtransactionid integer NOT NULL DEFAULT nextval('sequences.transactionid'),
    stockitemid integer NOT NULL,
    transactiontypeid integer NOT NULL,
    customerid integer NULL,
    invoiceid integer NULL,
    supplierid integer NULL,
    purchaseorderid integer NULL,
    transactionoccurredwhen timestamp NOT NULL,
    quantity numeric(18,3) NOT NULL,
    lasteditedby integer NOT NULL,
    lasteditedwhen timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT pk_warehouse_stockitemtransactions PRIMARY KEY (stockitemtransactionid)
);

-- Warehouse.ColdRoomTemperatures table (temporal, was memory-optimized in SQL Server)
-- Note: SQL Server uses IDENTITY, PostgreSQL uses BIGSERIAL
CREATE TABLE warehouse.coldroomtemperatures (
    coldroomtemperatureid bigserial NOT NULL,
    coldroomsensornumber integer NOT NULL,
    recordedwhen timestamp NOT NULL,
    temperature numeric(10,2) NOT NULL,
    validfrom timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
    validto timestamp NOT NULL DEFAULT '9999-12-31 23:59:59.999999',
    CONSTRAINT pk_warehouse_coldroomtemperatures PRIMARY KEY (coldroomtemperatureid)
);

-- Warehouse.VehicleTemperatures table (non-temporal, was memory-optimized in SQL Server)
-- Note: SQL Server uses IDENTITY, PostgreSQL uses BIGSERIAL
CREATE TABLE warehouse.vehicletemperatures (
    vehicletemperatureid bigserial NOT NULL,
    vehicleregistration varchar(20) NOT NULL,
    chillersensornumber integer NOT NULL,
    recordedwhen timestamp NOT NULL,
    temperature numeric(10,2) NOT NULL,
    fullsensordata varchar(1000) NULL,
    iscompressed boolean NOT NULL,
    compressedsensordata bytea NULL,
    CONSTRAINT pk_warehouse_vehicletemperatures PRIMARY KEY (vehicletemperatureid)
);
