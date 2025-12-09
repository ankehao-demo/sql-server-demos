-- Wide World Importers PostgreSQL Migration
-- Application Schema Tables
-- This script creates all tables in the Application schema

-- Enable required extensions
CREATE EXTENSION IF NOT EXISTS postgis;  -- For geography type
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";  -- For UUID generation

-- Countries Table (with temporal support)
CREATE TABLE IF NOT EXISTS application.countries (
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
    validfrom timestamp NOT NULL DEFAULT NOW(),
    validto timestamp NOT NULL DEFAULT '9999-12-31 23:59:59.999999',
    CONSTRAINT pk_application_countries PRIMARY KEY (countryid),
    CONSTRAINT uq_application_countries_countryname UNIQUE (countryname),
    CONSTRAINT uq_application_countries_formalname UNIQUE (formalname)
);
COMMENT ON TABLE application.countries IS 'Countries that contain the states or provinces (including geographic boundaries)';

-- Countries Archive Table (for temporal history)
CREATE TABLE IF NOT EXISTS application.countries_archive (
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
COMMENT ON TABLE application.countries_archive IS 'Historical records for Countries table';
CREATE INDEX IF NOT EXISTS ix_countries_archive_validfrom ON application.countries_archive(validfrom);
CREATE INDEX IF NOT EXISTS ix_countries_archive_validto ON application.countries_archive(validto);

-- StateProvinces Table (with temporal support)
CREATE TABLE IF NOT EXISTS application.stateprovinces (
    stateprovinceid integer NOT NULL DEFAULT nextval('sequences.stateprovinceid'),
    stateprovincecode varchar(5) NOT NULL,
    stateprovincename varchar(50) NOT NULL,
    countryid integer NOT NULL,
    salesterritory varchar(50) NOT NULL,
    border geography NULL,
    latestrecordedpopulation bigint NULL,
    lasteditedby integer NOT NULL,
    validfrom timestamp NOT NULL DEFAULT NOW(),
    validto timestamp NOT NULL DEFAULT '9999-12-31 23:59:59.999999',
    CONSTRAINT pk_application_stateprovinces PRIMARY KEY (stateprovinceid),
    CONSTRAINT uq_application_stateprovinces_stateprovincename UNIQUE (stateprovincename),
    CONSTRAINT fk_application_stateprovinces_countryid FOREIGN KEY (countryid) REFERENCES application.countries(countryid)
);
COMMENT ON TABLE application.stateprovinces IS 'States or provinces that contain cities (including geographic boundaries)';
CREATE INDEX IF NOT EXISTS fk_application_stateprovinces_countryid ON application.stateprovinces(countryid);

-- StateProvinces Archive Table
CREATE TABLE IF NOT EXISTS application.stateprovinces_archive (
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
COMMENT ON TABLE application.stateprovinces_archive IS 'Historical records for StateProvinces table';
CREATE INDEX IF NOT EXISTS ix_stateprovinces_archive_validfrom ON application.stateprovinces_archive(validfrom);
CREATE INDEX IF NOT EXISTS ix_stateprovinces_archive_validto ON application.stateprovinces_archive(validto);

-- Cities Table (with temporal support)
CREATE TABLE IF NOT EXISTS application.cities (
    cityid integer NOT NULL DEFAULT nextval('sequences.cityid'),
    cityname varchar(50) NOT NULL,
    stateprovinceid integer NOT NULL,
    location geography NULL,
    latestrecordedpopulation bigint NULL,
    lasteditedby integer NOT NULL,
    validfrom timestamp NOT NULL DEFAULT NOW(),
    validto timestamp NOT NULL DEFAULT '9999-12-31 23:59:59.999999',
    CONSTRAINT pk_application_cities PRIMARY KEY (cityid),
    CONSTRAINT fk_application_cities_stateprovinceid FOREIGN KEY (stateprovinceid) REFERENCES application.stateprovinces(stateprovinceid)
);
COMMENT ON TABLE application.cities IS 'Cities that are part of any address (including geographic location)';
CREATE INDEX IF NOT EXISTS fk_application_cities_stateprovinceid ON application.cities(stateprovinceid);

-- Cities Archive Table
CREATE TABLE IF NOT EXISTS application.cities_archive (
    cityid integer NOT NULL,
    cityname varchar(50) NOT NULL,
    stateprovinceid integer NOT NULL,
    location geography NULL,
    latestrecordedpopulation bigint NULL,
    lasteditedby integer NOT NULL,
    validfrom timestamp NOT NULL,
    validto timestamp NOT NULL
);
COMMENT ON TABLE application.cities_archive IS 'Historical records for Cities table';
CREATE INDEX IF NOT EXISTS ix_cities_archive_validfrom ON application.cities_archive(validfrom);
CREATE INDEX IF NOT EXISTS ix_cities_archive_validto ON application.cities_archive(validto);

-- People Table (with temporal support)
CREATE TABLE IF NOT EXISTS application.people (
    personid integer NOT NULL DEFAULT nextval('sequences.personid'),
    fullname varchar(50) NOT NULL,
    preferredname varchar(50) NOT NULL,
    searchname varchar(101) GENERATED ALWAYS AS (preferredname || ' ' || fullname) STORED NOT NULL,
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
    otherlanguages jsonb GENERATED ALWAYS AS (
        CASE 
            WHEN customfields IS NOT NULL AND customfields::jsonb ? 'OtherLanguages' 
            THEN (customfields::jsonb)->'OtherLanguages' 
            ELSE NULL 
        END
    ) STORED,
    lasteditedby integer NOT NULL,
    validfrom timestamp NOT NULL DEFAULT NOW(),
    validto timestamp NOT NULL DEFAULT '9999-12-31 23:59:59.999999',
    CONSTRAINT pk_application_people PRIMARY KEY (personid)
);
COMMENT ON TABLE application.people IS 'People known to the application (staff, customer contacts, supplier contacts)';
CREATE INDEX IF NOT EXISTS ix_application_people_isemployee ON application.people(isemployee);
CREATE INDEX IF NOT EXISTS ix_application_people_issalesperson ON application.people(issalesperson);
CREATE INDEX IF NOT EXISTS ix_application_people_fullname ON application.people(fullname);
CREATE INDEX IF NOT EXISTS ix_application_people_perf_20160301_05 ON application.people(ispermittedtologon, personid) INCLUDE (fullname, emailaddress);

-- Add self-referencing foreign key after table creation
ALTER TABLE application.people ADD CONSTRAINT fk_application_people_application_people 
    FOREIGN KEY (lasteditedby) REFERENCES application.people(personid);

-- People Archive Table
CREATE TABLE IF NOT EXISTS application.people_archive (
    personid integer NOT NULL,
    fullname varchar(50) NOT NULL,
    preferredname varchar(50) NOT NULL,
    searchname varchar(101) NOT NULL,
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
    otherlanguages jsonb NULL,
    lasteditedby integer NOT NULL,
    validfrom timestamp NOT NULL,
    validto timestamp NOT NULL
);
COMMENT ON TABLE application.people_archive IS 'Historical records for People table';
CREATE INDEX IF NOT EXISTS ix_people_archive_validfrom ON application.people_archive(validfrom);
CREATE INDEX IF NOT EXISTS ix_people_archive_validto ON application.people_archive(validto);

-- DeliveryMethods Table (with temporal support)
CREATE TABLE IF NOT EXISTS application.deliverymethods (
    deliverymethodid integer NOT NULL DEFAULT nextval('sequences.deliverymethodid'),
    deliverymethodname varchar(50) NOT NULL,
    lasteditedby integer NOT NULL,
    validfrom timestamp NOT NULL DEFAULT NOW(),
    validto timestamp NOT NULL DEFAULT '9999-12-31 23:59:59.999999',
    CONSTRAINT pk_application_deliverymethods PRIMARY KEY (deliverymethodid),
    CONSTRAINT uq_application_deliverymethods_deliverymethodname UNIQUE (deliverymethodname),
    CONSTRAINT fk_application_deliverymethods_application_people FOREIGN KEY (lasteditedby) REFERENCES application.people(personid)
);
COMMENT ON TABLE application.deliverymethods IS 'Ways that stock items can be delivered (e.g., post, courier)';

-- DeliveryMethods Archive Table
CREATE TABLE IF NOT EXISTS application.deliverymethods_archive (
    deliverymethodid integer NOT NULL,
    deliverymethodname varchar(50) NOT NULL,
    lasteditedby integer NOT NULL,
    validfrom timestamp NOT NULL,
    validto timestamp NOT NULL
);
COMMENT ON TABLE application.deliverymethods_archive IS 'Historical records for DeliveryMethods table';

-- PaymentMethods Table (with temporal support)
CREATE TABLE IF NOT EXISTS application.paymentmethods (
    paymentmethodid integer NOT NULL DEFAULT nextval('sequences.paymentmethodid'),
    paymentmethodname varchar(50) NOT NULL,
    lasteditedby integer NOT NULL,
    validfrom timestamp NOT NULL DEFAULT NOW(),
    validto timestamp NOT NULL DEFAULT '9999-12-31 23:59:59.999999',
    CONSTRAINT pk_application_paymentmethods PRIMARY KEY (paymentmethodid),
    CONSTRAINT uq_application_paymentmethods_paymentmethodname UNIQUE (paymentmethodname),
    CONSTRAINT fk_application_paymentmethods_application_people FOREIGN KEY (lasteditedby) REFERENCES application.people(personid)
);
COMMENT ON TABLE application.paymentmethods IS 'Ways that payments can be made (e.g., cash, check, EFT)';

-- PaymentMethods Archive Table
CREATE TABLE IF NOT EXISTS application.paymentmethods_archive (
    paymentmethodid integer NOT NULL,
    paymentmethodname varchar(50) NOT NULL,
    lasteditedby integer NOT NULL,
    validfrom timestamp NOT NULL,
    validto timestamp NOT NULL
);
COMMENT ON TABLE application.paymentmethods_archive IS 'Historical records for PaymentMethods table';

-- TransactionTypes Table (with temporal support)
CREATE TABLE IF NOT EXISTS application.transactiontypes (
    transactiontypeid integer NOT NULL DEFAULT nextval('sequences.transactiontypeid'),
    transactiontypename varchar(50) NOT NULL,
    lasteditedby integer NOT NULL,
    validfrom timestamp NOT NULL DEFAULT NOW(),
    validto timestamp NOT NULL DEFAULT '9999-12-31 23:59:59.999999',
    CONSTRAINT pk_application_transactiontypes PRIMARY KEY (transactiontypeid),
    CONSTRAINT uq_application_transactiontypes_transactiontypename UNIQUE (transactiontypename),
    CONSTRAINT fk_application_transactiontypes_application_people FOREIGN KEY (lasteditedby) REFERENCES application.people(personid)
);
COMMENT ON TABLE application.transactiontypes IS 'Types of customer, supplier, or stock transactions (e.g., invoice, credit note)';

-- TransactionTypes Archive Table
CREATE TABLE IF NOT EXISTS application.transactiontypes_archive (
    transactiontypeid integer NOT NULL,
    transactiontypename varchar(50) NOT NULL,
    lasteditedby integer NOT NULL,
    validfrom timestamp NOT NULL,
    validto timestamp NOT NULL
);
COMMENT ON TABLE application.transactiontypes_archive IS 'Historical records for TransactionTypes table';

-- SystemParameters Table
CREATE TABLE IF NOT EXISTS application.systemparameters (
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
    applicationSettings text NOT NULL,
    lasteditedby integer NOT NULL,
    lasteditedwhen timestamp NOT NULL DEFAULT NOW(),
    CONSTRAINT pk_application_systemparameters PRIMARY KEY (systemparameterid),
    CONSTRAINT fk_application_systemparameters_deliverycityid FOREIGN KEY (deliverycityid) REFERENCES application.cities(cityid),
    CONSTRAINT fk_application_systemparameters_postalcityid FOREIGN KEY (postalcityid) REFERENCES application.cities(cityid),
    CONSTRAINT fk_application_systemparameters_application_people FOREIGN KEY (lasteditedby) REFERENCES application.people(personid)
);
COMMENT ON TABLE application.systemparameters IS 'Any configurable parameters for the whole system';

-- Logs Table (for application logging)
CREATE TABLE IF NOT EXISTS application.logs (
    logid bigint GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    loggedat timestamp NOT NULL DEFAULT NOW(),
    loggedby varchar(256) NULL,
    loglevel varchar(20) NOT NULL,
    logmessage text NOT NULL,
    logdetails text NULL
);
COMMENT ON TABLE application.logs IS 'Application logging table';
CREATE INDEX IF NOT EXISTS ix_application_logs_loggedat ON application.logs(loggedat);

-- Add foreign key constraints that reference People table
ALTER TABLE application.countries ADD CONSTRAINT fk_application_countries_application_people 
    FOREIGN KEY (lasteditedby) REFERENCES application.people(personid);
ALTER TABLE application.stateprovinces ADD CONSTRAINT fk_application_stateprovinces_application_people 
    FOREIGN KEY (lasteditedby) REFERENCES application.people(personid);
ALTER TABLE application.cities ADD CONSTRAINT fk_application_cities_application_people 
    FOREIGN KEY (lasteditedby) REFERENCES application.people(personid);
