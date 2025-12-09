-- Wide World Importers PostgreSQL Migration
-- Warehouse Schema Tables
-- This script creates all tables in the Warehouse schema

-- Colors Table (with temporal support)
CREATE TABLE IF NOT EXISTS warehouse.colors (
    colorid integer NOT NULL DEFAULT nextval('sequences.colorid'),
    colorname varchar(20) NOT NULL,
    lasteditedby integer NOT NULL,
    validfrom timestamp NOT NULL DEFAULT NOW(),
    validto timestamp NOT NULL DEFAULT '9999-12-31 23:59:59.999999',
    CONSTRAINT pk_warehouse_colors PRIMARY KEY (colorid),
    CONSTRAINT uq_warehouse_colors_colorname UNIQUE (colorname),
    CONSTRAINT fk_warehouse_colors_application_people FOREIGN KEY (lasteditedby) REFERENCES application.people(personid)
);
COMMENT ON TABLE warehouse.colors IS 'Stock items can (optionally) have colors';

-- Colors Archive Table
CREATE TABLE IF NOT EXISTS warehouse.colors_archive (
    colorid integer NOT NULL,
    colorname varchar(20) NOT NULL,
    lasteditedby integer NOT NULL,
    validfrom timestamp NOT NULL,
    validto timestamp NOT NULL
);
COMMENT ON TABLE warehouse.colors_archive IS 'Historical records for Colors table';

-- PackageTypes Table (with temporal support)
CREATE TABLE IF NOT EXISTS warehouse.packagetypes (
    packagetypeid integer NOT NULL DEFAULT nextval('sequences.packagetypeid'),
    packagetypename varchar(50) NOT NULL,
    lasteditedby integer NOT NULL,
    validfrom timestamp NOT NULL DEFAULT NOW(),
    validto timestamp NOT NULL DEFAULT '9999-12-31 23:59:59.999999',
    CONSTRAINT pk_warehouse_packagetypes PRIMARY KEY (packagetypeid),
    CONSTRAINT uq_warehouse_packagetypes_packagetypename UNIQUE (packagetypename),
    CONSTRAINT fk_warehouse_packagetypes_application_people FOREIGN KEY (lasteditedby) REFERENCES application.people(personid)
);
COMMENT ON TABLE warehouse.packagetypes IS 'Ways that stock items can be packaged (e.g., box, carton, pallet, kg)';

-- PackageTypes Archive Table
CREATE TABLE IF NOT EXISTS warehouse.packagetypes_archive (
    packagetypeid integer NOT NULL,
    packagetypename varchar(50) NOT NULL,
    lasteditedby integer NOT NULL,
    validfrom timestamp NOT NULL,
    validto timestamp NOT NULL
);
COMMENT ON TABLE warehouse.packagetypes_archive IS 'Historical records for PackageTypes table';

-- StockGroups Table (with temporal support)
CREATE TABLE IF NOT EXISTS warehouse.stockgroups (
    stockgroupid integer NOT NULL DEFAULT nextval('sequences.stockgroupid'),
    stockgroupname varchar(50) NOT NULL,
    lasteditedby integer NOT NULL,
    validfrom timestamp NOT NULL DEFAULT NOW(),
    validto timestamp NOT NULL DEFAULT '9999-12-31 23:59:59.999999',
    CONSTRAINT pk_warehouse_stockgroups PRIMARY KEY (stockgroupid),
    CONSTRAINT uq_warehouse_stockgroups_stockgroupname UNIQUE (stockgroupname),
    CONSTRAINT fk_warehouse_stockgroups_application_people FOREIGN KEY (lasteditedby) REFERENCES application.people(personid)
);
COMMENT ON TABLE warehouse.stockgroups IS 'Groups for categorizing stock items (e.g., novelties, clothing, packaging materials)';

-- StockGroups Archive Table
CREATE TABLE IF NOT EXISTS warehouse.stockgroups_archive (
    stockgroupid integer NOT NULL,
    stockgroupname varchar(50) NOT NULL,
    lasteditedby integer NOT NULL,
    validfrom timestamp NOT NULL,
    validto timestamp NOT NULL
);
COMMENT ON TABLE warehouse.stockgroups_archive IS 'Historical records for StockGroups table';

-- StockItems Table (with temporal support)
CREATE TABLE IF NOT EXISTS warehouse.stockitems (
    stockitemid integer NOT NULL DEFAULT nextval('sequences.stockitemid'),
    stockitemname varchar(100) NOT NULL,
    supplierid integer NOT NULL,
    colorid integer NULL,
    unitpackageid integer NOT NULL,
    outerpackageid integer NOT NULL,
    brand varchar(50) NULL,
    size varchar(20) NULL,
    leadtimedays integer NOT NULL,
    quantityperouter integer NOT NULL,
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
    tags text GENERATED ALWAYS AS (
        CASE 
            WHEN customfields IS NOT NULL AND customfields::jsonb ? 'Tags' 
            THEN (customfields::jsonb)->>'Tags' 
            ELSE NULL 
        END
    ) STORED,
    searchdetails text GENERATED ALWAYS AS (
        COALESCE(stockitemname, '') || ' ' || COALESCE(marketingcomments, '')
    ) STORED,
    lasteditedby integer NOT NULL,
    validfrom timestamp NOT NULL DEFAULT NOW(),
    validto timestamp NOT NULL DEFAULT '9999-12-31 23:59:59.999999',
    CONSTRAINT pk_warehouse_stockitems PRIMARY KEY (stockitemid),
    CONSTRAINT uq_warehouse_stockitems_stockitemname UNIQUE (stockitemname),
    CONSTRAINT fk_warehouse_stockitems_supplierid FOREIGN KEY (supplierid) REFERENCES purchasing.suppliers(supplierid),
    CONSTRAINT fk_warehouse_stockitems_colorid FOREIGN KEY (colorid) REFERENCES warehouse.colors(colorid),
    CONSTRAINT fk_warehouse_stockitems_unitpackageid FOREIGN KEY (unitpackageid) REFERENCES warehouse.packagetypes(packagetypeid),
    CONSTRAINT fk_warehouse_stockitems_outerpackageid FOREIGN KEY (outerpackageid) REFERENCES warehouse.packagetypes(packagetypeid),
    CONSTRAINT fk_warehouse_stockitems_application_people FOREIGN KEY (lasteditedby) REFERENCES application.people(personid)
);
COMMENT ON TABLE warehouse.stockitems IS 'Main entity table for stock items';
CREATE INDEX IF NOT EXISTS fk_warehouse_stockitems_supplierid ON warehouse.stockitems(supplierid);
CREATE INDEX IF NOT EXISTS fk_warehouse_stockitems_colorid ON warehouse.stockitems(colorid);
CREATE INDEX IF NOT EXISTS fk_warehouse_stockitems_unitpackageid ON warehouse.stockitems(unitpackageid);
CREATE INDEX IF NOT EXISTS fk_warehouse_stockitems_outerpackageid ON warehouse.stockitems(outerpackageid);

-- StockItems Archive Table
CREATE TABLE IF NOT EXISTS warehouse.stockitems_archive (
    stockitemid integer NOT NULL,
    stockitemname varchar(100) NOT NULL,
    supplierid integer NOT NULL,
    colorid integer NULL,
    unitpackageid integer NOT NULL,
    outerpackageid integer NOT NULL,
    brand varchar(50) NULL,
    size varchar(20) NULL,
    leadtimedays integer NOT NULL,
    quantityperouter integer NOT NULL,
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
    tags text NULL,
    searchdetails text NULL,
    lasteditedby integer NOT NULL,
    validfrom timestamp NOT NULL,
    validto timestamp NOT NULL
);
COMMENT ON TABLE warehouse.stockitems_archive IS 'Historical records for StockItems table';
CREATE INDEX IF NOT EXISTS ix_stockitems_archive_validfrom ON warehouse.stockitems_archive(validfrom);
CREATE INDEX IF NOT EXISTS ix_stockitems_archive_validto ON warehouse.stockitems_archive(validto);

-- StockItemHoldings Table
CREATE TABLE IF NOT EXISTS warehouse.stockitemholdings (
    stockitemid integer NOT NULL,
    quantityonhand integer NOT NULL,
    binlocation varchar(20) NOT NULL,
    laststocktakequantity integer NOT NULL,
    lastcostprice numeric(18,2) NOT NULL,
    reorderlevel integer NOT NULL,
    targetstocklevel integer NOT NULL,
    lasteditedby integer NOT NULL,
    lasteditedwhen timestamp NOT NULL DEFAULT NOW(),
    CONSTRAINT pk_warehouse_stockitemholdings PRIMARY KEY (stockitemid),
    CONSTRAINT fk_warehouse_stockitemholdings_stockitemid FOREIGN KEY (stockitemid) REFERENCES warehouse.stockitems(stockitemid),
    CONSTRAINT fk_warehouse_stockitemholdings_application_people FOREIGN KEY (lasteditedby) REFERENCES application.people(personid)
);
COMMENT ON TABLE warehouse.stockitemholdings IS 'Non-temporal attributes for stock items';

-- StockItemStockGroups Table (many-to-many relationship)
CREATE TABLE IF NOT EXISTS warehouse.stockitemstockgroups (
    stockitemstockgroupid integer NOT NULL DEFAULT nextval('sequences.stockitemstockgroupid'),
    stockitemid integer NOT NULL,
    stockgroupid integer NOT NULL,
    lasteditedby integer NOT NULL,
    lasteditedwhen timestamp NOT NULL DEFAULT NOW(),
    CONSTRAINT pk_warehouse_stockitemstockgroups PRIMARY KEY (stockitemstockgroupid),
    CONSTRAINT uq_stockitemstockgroups_stockitemid_stockgroupid UNIQUE (stockitemid, stockgroupid),
    CONSTRAINT fk_warehouse_stockitemstockgroups_stockitemid FOREIGN KEY (stockitemid) REFERENCES warehouse.stockitems(stockitemid),
    CONSTRAINT fk_warehouse_stockitemstockgroups_stockgroupid FOREIGN KEY (stockgroupid) REFERENCES warehouse.stockgroups(stockgroupid),
    CONSTRAINT fk_warehouse_stockitemstockgroups_application_people FOREIGN KEY (lasteditedby) REFERENCES application.people(personid)
);
COMMENT ON TABLE warehouse.stockitemstockgroups IS 'Which stock items are in which stock groups';
CREATE INDEX IF NOT EXISTS fk_warehouse_stockitemstockgroups_stockitemid ON warehouse.stockitemstockgroups(stockitemid);
CREATE INDEX IF NOT EXISTS fk_warehouse_stockitemstockgroups_stockgroupid ON warehouse.stockitemstockgroups(stockgroupid);

-- StockItemTransactions Table
CREATE TABLE IF NOT EXISTS warehouse.stockitemtransactions (
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
    lasteditedwhen timestamp NOT NULL DEFAULT NOW(),
    CONSTRAINT pk_warehouse_stockitemtransactions PRIMARY KEY (stockitemtransactionid),
    CONSTRAINT fk_warehouse_stockitemtransactions_stockitemid FOREIGN KEY (stockitemid) REFERENCES warehouse.stockitems(stockitemid),
    CONSTRAINT fk_warehouse_stockitemtransactions_transactiontypeid FOREIGN KEY (transactiontypeid) REFERENCES application.transactiontypes(transactiontypeid),
    CONSTRAINT fk_warehouse_stockitemtransactions_customerid FOREIGN KEY (customerid) REFERENCES sales.customers(customerid),
    CONSTRAINT fk_warehouse_stockitemtransactions_invoiceid FOREIGN KEY (invoiceid) REFERENCES sales.invoices(invoiceid),
    CONSTRAINT fk_warehouse_stockitemtransactions_supplierid FOREIGN KEY (supplierid) REFERENCES purchasing.suppliers(supplierid),
    CONSTRAINT fk_warehouse_stockitemtransactions_purchaseorderid FOREIGN KEY (purchaseorderid) REFERENCES purchasing.purchaseorders(purchaseorderid),
    CONSTRAINT fk_warehouse_stockitemtransactions_application_people FOREIGN KEY (lasteditedby) REFERENCES application.people(personid)
);
COMMENT ON TABLE warehouse.stockitemtransactions IS 'Transactions covering all movements of all stock items';
CREATE INDEX IF NOT EXISTS fk_warehouse_stockitemtransactions_stockitemid ON warehouse.stockitemtransactions(stockitemid);
CREATE INDEX IF NOT EXISTS fk_warehouse_stockitemtransactions_transactiontypeid ON warehouse.stockitemtransactions(transactiontypeid);
CREATE INDEX IF NOT EXISTS fk_warehouse_stockitemtransactions_customerid ON warehouse.stockitemtransactions(customerid);
CREATE INDEX IF NOT EXISTS fk_warehouse_stockitemtransactions_invoiceid ON warehouse.stockitemtransactions(invoiceid);
CREATE INDEX IF NOT EXISTS fk_warehouse_stockitemtransactions_supplierid ON warehouse.stockitemtransactions(supplierid);
CREATE INDEX IF NOT EXISTS fk_warehouse_stockitemtransactions_purchaseorderid ON warehouse.stockitemtransactions(purchaseorderid);

-- ColdRoomTemperatures Table (originally memory-optimized with temporal support)
-- Note: PostgreSQL doesn't have memory-optimized tables, using standard table with proper indexing
CREATE TABLE IF NOT EXISTS warehouse.coldroomtemperatures (
    coldroomtemperatureid bigint GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    coldroomsensornumber integer NOT NULL,
    recordedwhen timestamp NOT NULL,
    temperature numeric(10,2) NOT NULL,
    validfrom timestamp NOT NULL DEFAULT NOW(),
    validto timestamp NOT NULL DEFAULT '9999-12-31 23:59:59.999999'
);
COMMENT ON TABLE warehouse.coldroomtemperatures IS 'Regularly recorded temperatures of cold room refrigerators';
CREATE INDEX IF NOT EXISTS ix_warehouse_coldroomtemperatures_coldroomsensornumber ON warehouse.coldroomtemperatures(coldroomsensornumber);

-- ColdRoomTemperatures Archive Table
CREATE TABLE IF NOT EXISTS warehouse.coldroomtemperatures_archive (
    coldroomtemperatureid bigint NOT NULL,
    coldroomsensornumber integer NOT NULL,
    recordedwhen timestamp NOT NULL,
    temperature numeric(10,2) NOT NULL,
    validfrom timestamp NOT NULL,
    validto timestamp NOT NULL
);
COMMENT ON TABLE warehouse.coldroomtemperatures_archive IS 'Historical records for ColdRoomTemperatures table';
CREATE INDEX IF NOT EXISTS ix_coldroomtemperatures_archive_validfrom ON warehouse.coldroomtemperatures_archive(validfrom);
CREATE INDEX IF NOT EXISTS ix_coldroomtemperatures_archive_validto ON warehouse.coldroomtemperatures_archive(validto);

-- VehicleTemperatures Table (originally memory-optimized)
-- Note: PostgreSQL doesn't have memory-optimized tables, using standard table with proper indexing
CREATE TABLE IF NOT EXISTS warehouse.vehicletemperatures (
    vehicletemperatureid bigint GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    vehicleregistration varchar(20) NOT NULL,
    chillersensornumber integer NOT NULL,
    recordedwhen timestamp NOT NULL,
    temperature numeric(10,2) NOT NULL,
    fullsensordata varchar(1000) NULL,
    iscompressed boolean NOT NULL DEFAULT false,
    compressedsensordata bytea NULL
);
COMMENT ON TABLE warehouse.vehicletemperatures IS 'Regularly recorded temperatures of vehicle chillers';
CREATE INDEX IF NOT EXISTS ix_warehouse_vehicletemperatures_vehicleregistration ON warehouse.vehicletemperatures(vehicleregistration);

-- Add foreign key constraints for OrderLines and InvoiceLines that reference StockItems and PackageTypes
ALTER TABLE sales.orderlines ADD CONSTRAINT fk_sales_orderlines_stockitemid 
    FOREIGN KEY (stockitemid) REFERENCES warehouse.stockitems(stockitemid);
ALTER TABLE sales.orderlines ADD CONSTRAINT fk_sales_orderlines_packagetypeid 
    FOREIGN KEY (packagetypeid) REFERENCES warehouse.packagetypes(packagetypeid);

ALTER TABLE sales.invoicelines ADD CONSTRAINT fk_sales_invoicelines_stockitemid 
    FOREIGN KEY (stockitemid) REFERENCES warehouse.stockitems(stockitemid);
ALTER TABLE sales.invoicelines ADD CONSTRAINT fk_sales_invoicelines_packagetypeid 
    FOREIGN KEY (packagetypeid) REFERENCES warehouse.packagetypes(packagetypeid);

ALTER TABLE purchasing.purchaseorderlines ADD CONSTRAINT fk_purchasing_purchaseorderlines_stockitemid 
    FOREIGN KEY (stockitemid) REFERENCES warehouse.stockitems(stockitemid);
ALTER TABLE purchasing.purchaseorderlines ADD CONSTRAINT fk_purchasing_purchaseorderlines_packagetypeid 
    FOREIGN KEY (packagetypeid) REFERENCES warehouse.packagetypes(packagetypeid);

ALTER TABLE sales.specialdeals ADD CONSTRAINT fk_sales_specialdeals_stockitemid 
    FOREIGN KEY (stockitemid) REFERENCES warehouse.stockitems(stockitemid);
ALTER TABLE sales.specialdeals ADD CONSTRAINT fk_sales_specialdeals_stockgroupid 
    FOREIGN KEY (stockgroupid) REFERENCES warehouse.stockgroups(stockgroupid);
