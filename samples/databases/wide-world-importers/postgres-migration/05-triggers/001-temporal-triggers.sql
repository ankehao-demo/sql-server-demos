-- Wide World Importers PostgreSQL Migration
-- Phase 2: OLTP Schema Migration
-- File: 001-temporal-triggers.sql
-- Description: Create triggers for temporal table history tracking

-- Generic temporal table trigger function
-- This function handles INSERT, UPDATE, and DELETE operations for temporal tables
-- On INSERT: Sets ValidFrom to current timestamp, ValidTo to infinity
-- On UPDATE: Copies old row to archive with ValidTo = current timestamp, updates ValidFrom in main table
-- On DELETE: Copies row to archive with ValidTo = current timestamp

-- Application.People temporal trigger
CREATE OR REPLACE FUNCTION application.people_temporal_trigger()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        NEW.validfrom := CURRENT_TIMESTAMP;
        NEW.validto := '9999-12-31 23:59:59.999999'::timestamp;
        RETURN NEW;
    ELSIF TG_OP = 'UPDATE' THEN
        INSERT INTO application.people_archive (
            personid, fullname, preferredname, searchname, ispermittedtologon, logonname,
            isexternallogonprovider, hashedpassword, issystemuser, isemployee, issalesperson,
            userpreferences, phonenumber, faxnumber, emailaddress, photo, customfields,
            lasteditedby, validfrom, validto
        ) VALUES (
            OLD.personid, OLD.fullname, OLD.preferredname, OLD.searchname, OLD.ispermittedtologon, OLD.logonname,
            OLD.isexternallogonprovider, OLD.hashedpassword, OLD.issystemuser, OLD.isemployee, OLD.issalesperson,
            OLD.userpreferences, OLD.phonenumber, OLD.faxnumber, OLD.emailaddress, OLD.photo, OLD.customfields,
            OLD.lasteditedby, OLD.validfrom, CURRENT_TIMESTAMP
        );
        NEW.validfrom := CURRENT_TIMESTAMP;
        NEW.validto := '9999-12-31 23:59:59.999999'::timestamp;
        RETURN NEW;
    ELSIF TG_OP = 'DELETE' THEN
        INSERT INTO application.people_archive (
            personid, fullname, preferredname, searchname, ispermittedtologon, logonname,
            isexternallogonprovider, hashedpassword, issystemuser, isemployee, issalesperson,
            userpreferences, phonenumber, faxnumber, emailaddress, photo, customfields,
            lasteditedby, validfrom, validto
        ) VALUES (
            OLD.personid, OLD.fullname, OLD.preferredname, OLD.searchname, OLD.ispermittedtologon, OLD.logonname,
            OLD.isexternallogonprovider, OLD.hashedpassword, OLD.issystemuser, OLD.isemployee, OLD.issalesperson,
            OLD.userpreferences, OLD.phonenumber, OLD.faxnumber, OLD.emailaddress, OLD.photo, OLD.customfields,
            OLD.lasteditedby, OLD.validfrom, CURRENT_TIMESTAMP
        );
        RETURN OLD;
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER tr_people_temporal
    BEFORE INSERT OR UPDATE OR DELETE ON application.people
    FOR EACH ROW EXECUTE FUNCTION application.people_temporal_trigger();

-- Application.Countries temporal trigger
CREATE OR REPLACE FUNCTION application.countries_temporal_trigger()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        NEW.validfrom := CURRENT_TIMESTAMP;
        NEW.validto := '9999-12-31 23:59:59.999999'::timestamp;
        RETURN NEW;
    ELSIF TG_OP = 'UPDATE' THEN
        INSERT INTO application.countries_archive (
            countryid, countryname, formalname, isoalpha3code, isonumericcode, countrytype,
            latestrecordedpopulation, continent, region, subregion, border, lasteditedby, validfrom, validto
        ) VALUES (
            OLD.countryid, OLD.countryname, OLD.formalname, OLD.isoalpha3code, OLD.isonumericcode, OLD.countrytype,
            OLD.latestrecordedpopulation, OLD.continent, OLD.region, OLD.subregion, OLD.border, OLD.lasteditedby, OLD.validfrom, CURRENT_TIMESTAMP
        );
        NEW.validfrom := CURRENT_TIMESTAMP;
        NEW.validto := '9999-12-31 23:59:59.999999'::timestamp;
        RETURN NEW;
    ELSIF TG_OP = 'DELETE' THEN
        INSERT INTO application.countries_archive (
            countryid, countryname, formalname, isoalpha3code, isonumericcode, countrytype,
            latestrecordedpopulation, continent, region, subregion, border, lasteditedby, validfrom, validto
        ) VALUES (
            OLD.countryid, OLD.countryname, OLD.formalname, OLD.isoalpha3code, OLD.isonumericcode, OLD.countrytype,
            OLD.latestrecordedpopulation, OLD.continent, OLD.region, OLD.subregion, OLD.border, OLD.lasteditedby, OLD.validfrom, CURRENT_TIMESTAMP
        );
        RETURN OLD;
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER tr_countries_temporal
    BEFORE INSERT OR UPDATE OR DELETE ON application.countries
    FOR EACH ROW EXECUTE FUNCTION application.countries_temporal_trigger();

-- Application.StateProvinces temporal trigger
CREATE OR REPLACE FUNCTION application.stateprovinces_temporal_trigger()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        NEW.validfrom := CURRENT_TIMESTAMP;
        NEW.validto := '9999-12-31 23:59:59.999999'::timestamp;
        RETURN NEW;
    ELSIF TG_OP = 'UPDATE' THEN
        INSERT INTO application.stateprovinces_archive (
            stateprovinceid, stateprovincecode, stateprovincename, countryid, salesterritory,
            border, latestrecordedpopulation, lasteditedby, validfrom, validto
        ) VALUES (
            OLD.stateprovinceid, OLD.stateprovincecode, OLD.stateprovincename, OLD.countryid, OLD.salesterritory,
            OLD.border, OLD.latestrecordedpopulation, OLD.lasteditedby, OLD.validfrom, CURRENT_TIMESTAMP
        );
        NEW.validfrom := CURRENT_TIMESTAMP;
        NEW.validto := '9999-12-31 23:59:59.999999'::timestamp;
        RETURN NEW;
    ELSIF TG_OP = 'DELETE' THEN
        INSERT INTO application.stateprovinces_archive (
            stateprovinceid, stateprovincecode, stateprovincename, countryid, salesterritory,
            border, latestrecordedpopulation, lasteditedby, validfrom, validto
        ) VALUES (
            OLD.stateprovinceid, OLD.stateprovincecode, OLD.stateprovincename, OLD.countryid, OLD.salesterritory,
            OLD.border, OLD.latestrecordedpopulation, OLD.lasteditedby, OLD.validfrom, CURRENT_TIMESTAMP
        );
        RETURN OLD;
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER tr_stateprovinces_temporal
    BEFORE INSERT OR UPDATE OR DELETE ON application.stateprovinces
    FOR EACH ROW EXECUTE FUNCTION application.stateprovinces_temporal_trigger();

-- Application.Cities temporal trigger
CREATE OR REPLACE FUNCTION application.cities_temporal_trigger()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        NEW.validfrom := CURRENT_TIMESTAMP;
        NEW.validto := '9999-12-31 23:59:59.999999'::timestamp;
        RETURN NEW;
    ELSIF TG_OP = 'UPDATE' THEN
        INSERT INTO application.cities_archive (
            cityid, cityname, stateprovinceid, location, latestrecordedpopulation, lasteditedby, validfrom, validto
        ) VALUES (
            OLD.cityid, OLD.cityname, OLD.stateprovinceid, OLD.location, OLD.latestrecordedpopulation, OLD.lasteditedby, OLD.validfrom, CURRENT_TIMESTAMP
        );
        NEW.validfrom := CURRENT_TIMESTAMP;
        NEW.validto := '9999-12-31 23:59:59.999999'::timestamp;
        RETURN NEW;
    ELSIF TG_OP = 'DELETE' THEN
        INSERT INTO application.cities_archive (
            cityid, cityname, stateprovinceid, location, latestrecordedpopulation, lasteditedby, validfrom, validto
        ) VALUES (
            OLD.cityid, OLD.cityname, OLD.stateprovinceid, OLD.location, OLD.latestrecordedpopulation, OLD.lasteditedby, OLD.validfrom, CURRENT_TIMESTAMP
        );
        RETURN OLD;
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER tr_cities_temporal
    BEFORE INSERT OR UPDATE OR DELETE ON application.cities
    FOR EACH ROW EXECUTE FUNCTION application.cities_temporal_trigger();

-- Application.DeliveryMethods temporal trigger
CREATE OR REPLACE FUNCTION application.deliverymethods_temporal_trigger()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        NEW.validfrom := CURRENT_TIMESTAMP;
        NEW.validto := '9999-12-31 23:59:59.999999'::timestamp;
        RETURN NEW;
    ELSIF TG_OP = 'UPDATE' THEN
        INSERT INTO application.deliverymethods_archive (
            deliverymethodid, deliverymethodname, lasteditedby, validfrom, validto
        ) VALUES (
            OLD.deliverymethodid, OLD.deliverymethodname, OLD.lasteditedby, OLD.validfrom, CURRENT_TIMESTAMP
        );
        NEW.validfrom := CURRENT_TIMESTAMP;
        NEW.validto := '9999-12-31 23:59:59.999999'::timestamp;
        RETURN NEW;
    ELSIF TG_OP = 'DELETE' THEN
        INSERT INTO application.deliverymethods_archive (
            deliverymethodid, deliverymethodname, lasteditedby, validfrom, validto
        ) VALUES (
            OLD.deliverymethodid, OLD.deliverymethodname, OLD.lasteditedby, OLD.validfrom, CURRENT_TIMESTAMP
        );
        RETURN OLD;
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER tr_deliverymethods_temporal
    BEFORE INSERT OR UPDATE OR DELETE ON application.deliverymethods
    FOR EACH ROW EXECUTE FUNCTION application.deliverymethods_temporal_trigger();

-- Application.PaymentMethods temporal trigger
CREATE OR REPLACE FUNCTION application.paymentmethods_temporal_trigger()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        NEW.validfrom := CURRENT_TIMESTAMP;
        NEW.validto := '9999-12-31 23:59:59.999999'::timestamp;
        RETURN NEW;
    ELSIF TG_OP = 'UPDATE' THEN
        INSERT INTO application.paymentmethods_archive (
            paymentmethodid, paymentmethodname, lasteditedby, validfrom, validto
        ) VALUES (
            OLD.paymentmethodid, OLD.paymentmethodname, OLD.lasteditedby, OLD.validfrom, CURRENT_TIMESTAMP
        );
        NEW.validfrom := CURRENT_TIMESTAMP;
        NEW.validto := '9999-12-31 23:59:59.999999'::timestamp;
        RETURN NEW;
    ELSIF TG_OP = 'DELETE' THEN
        INSERT INTO application.paymentmethods_archive (
            paymentmethodid, paymentmethodname, lasteditedby, validfrom, validto
        ) VALUES (
            OLD.paymentmethodid, OLD.paymentmethodname, OLD.lasteditedby, OLD.validfrom, CURRENT_TIMESTAMP
        );
        RETURN OLD;
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER tr_paymentmethods_temporal
    BEFORE INSERT OR UPDATE OR DELETE ON application.paymentmethods
    FOR EACH ROW EXECUTE FUNCTION application.paymentmethods_temporal_trigger();

-- Application.TransactionTypes temporal trigger
CREATE OR REPLACE FUNCTION application.transactiontypes_temporal_trigger()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        NEW.validfrom := CURRENT_TIMESTAMP;
        NEW.validto := '9999-12-31 23:59:59.999999'::timestamp;
        RETURN NEW;
    ELSIF TG_OP = 'UPDATE' THEN
        INSERT INTO application.transactiontypes_archive (
            transactiontypeid, transactiontypename, lasteditedby, validfrom, validto
        ) VALUES (
            OLD.transactiontypeid, OLD.transactiontypename, OLD.lasteditedby, OLD.validfrom, CURRENT_TIMESTAMP
        );
        NEW.validfrom := CURRENT_TIMESTAMP;
        NEW.validto := '9999-12-31 23:59:59.999999'::timestamp;
        RETURN NEW;
    ELSIF TG_OP = 'DELETE' THEN
        INSERT INTO application.transactiontypes_archive (
            transactiontypeid, transactiontypename, lasteditedby, validfrom, validto
        ) VALUES (
            OLD.transactiontypeid, OLD.transactiontypename, OLD.lasteditedby, OLD.validfrom, CURRENT_TIMESTAMP
        );
        RETURN OLD;
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER tr_transactiontypes_temporal
    BEFORE INSERT OR UPDATE OR DELETE ON application.transactiontypes
    FOR EACH ROW EXECUTE FUNCTION application.transactiontypes_temporal_trigger();

-- Warehouse.Colors temporal trigger
CREATE OR REPLACE FUNCTION warehouse.colors_temporal_trigger()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        NEW.validfrom := CURRENT_TIMESTAMP;
        NEW.validto := '9999-12-31 23:59:59.999999'::timestamp;
        RETURN NEW;
    ELSIF TG_OP = 'UPDATE' THEN
        INSERT INTO warehouse.colors_archive (
            colorid, colorname, lasteditedby, validfrom, validto
        ) VALUES (
            OLD.colorid, OLD.colorname, OLD.lasteditedby, OLD.validfrom, CURRENT_TIMESTAMP
        );
        NEW.validfrom := CURRENT_TIMESTAMP;
        NEW.validto := '9999-12-31 23:59:59.999999'::timestamp;
        RETURN NEW;
    ELSIF TG_OP = 'DELETE' THEN
        INSERT INTO warehouse.colors_archive (
            colorid, colorname, lasteditedby, validfrom, validto
        ) VALUES (
            OLD.colorid, OLD.colorname, OLD.lasteditedby, OLD.validfrom, CURRENT_TIMESTAMP
        );
        RETURN OLD;
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER tr_colors_temporal
    BEFORE INSERT OR UPDATE OR DELETE ON warehouse.colors
    FOR EACH ROW EXECUTE FUNCTION warehouse.colors_temporal_trigger();

-- Warehouse.PackageTypes temporal trigger
CREATE OR REPLACE FUNCTION warehouse.packagetypes_temporal_trigger()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        NEW.validfrom := CURRENT_TIMESTAMP;
        NEW.validto := '9999-12-31 23:59:59.999999'::timestamp;
        RETURN NEW;
    ELSIF TG_OP = 'UPDATE' THEN
        INSERT INTO warehouse.packagetypes_archive (
            packagetypeid, packagetypename, lasteditedby, validfrom, validto
        ) VALUES (
            OLD.packagetypeid, OLD.packagetypename, OLD.lasteditedby, OLD.validfrom, CURRENT_TIMESTAMP
        );
        NEW.validfrom := CURRENT_TIMESTAMP;
        NEW.validto := '9999-12-31 23:59:59.999999'::timestamp;
        RETURN NEW;
    ELSIF TG_OP = 'DELETE' THEN
        INSERT INTO warehouse.packagetypes_archive (
            packagetypeid, packagetypename, lasteditedby, validfrom, validto
        ) VALUES (
            OLD.packagetypeid, OLD.packagetypename, OLD.lasteditedby, OLD.validfrom, CURRENT_TIMESTAMP
        );
        RETURN OLD;
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER tr_packagetypes_temporal
    BEFORE INSERT OR UPDATE OR DELETE ON warehouse.packagetypes
    FOR EACH ROW EXECUTE FUNCTION warehouse.packagetypes_temporal_trigger();

-- Warehouse.StockGroups temporal trigger
CREATE OR REPLACE FUNCTION warehouse.stockgroups_temporal_trigger()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        NEW.validfrom := CURRENT_TIMESTAMP;
        NEW.validto := '9999-12-31 23:59:59.999999'::timestamp;
        RETURN NEW;
    ELSIF TG_OP = 'UPDATE' THEN
        INSERT INTO warehouse.stockgroups_archive (
            stockgroupid, stockgroupname, lasteditedby, validfrom, validto
        ) VALUES (
            OLD.stockgroupid, OLD.stockgroupname, OLD.lasteditedby, OLD.validfrom, CURRENT_TIMESTAMP
        );
        NEW.validfrom := CURRENT_TIMESTAMP;
        NEW.validto := '9999-12-31 23:59:59.999999'::timestamp;
        RETURN NEW;
    ELSIF TG_OP = 'DELETE' THEN
        INSERT INTO warehouse.stockgroups_archive (
            stockgroupid, stockgroupname, lasteditedby, validfrom, validto
        ) VALUES (
            OLD.stockgroupid, OLD.stockgroupname, OLD.lasteditedby, OLD.validfrom, CURRENT_TIMESTAMP
        );
        RETURN OLD;
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER tr_stockgroups_temporal
    BEFORE INSERT OR UPDATE OR DELETE ON warehouse.stockgroups
    FOR EACH ROW EXECUTE FUNCTION warehouse.stockgroups_temporal_trigger();

-- Warehouse.StockItems temporal trigger
CREATE OR REPLACE FUNCTION warehouse.stockitems_temporal_trigger()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        NEW.validfrom := CURRENT_TIMESTAMP;
        NEW.validto := '9999-12-31 23:59:59.999999'::timestamp;
        RETURN NEW;
    ELSIF TG_OP = 'UPDATE' THEN
        INSERT INTO warehouse.stockitems_archive (
            stockitemid, stockitemname, supplierid, colorid, unitpackageid, outerpackageid,
            brand, size, leadtimedays, quantityperOuter, ischillerstock, barcode,
            taxrate, unitprice, recommendedretailprice, typicalweightperunit,
            marketingcomments, internalcomments, photo, customfields, lasteditedby, validfrom, validto
        ) VALUES (
            OLD.stockitemid, OLD.stockitemname, OLD.supplierid, OLD.colorid, OLD.unitpackageid, OLD.outerpackageid,
            OLD.brand, OLD.size, OLD.leadtimedays, OLD.quantityperOuter, OLD.ischillerstock, OLD.barcode,
            OLD.taxrate, OLD.unitprice, OLD.recommendedretailprice, OLD.typicalweightperunit,
            OLD.marketingcomments, OLD.internalcomments, OLD.photo, OLD.customfields, OLD.lasteditedby, OLD.validfrom, CURRENT_TIMESTAMP
        );
        NEW.validfrom := CURRENT_TIMESTAMP;
        NEW.validto := '9999-12-31 23:59:59.999999'::timestamp;
        RETURN NEW;
    ELSIF TG_OP = 'DELETE' THEN
        INSERT INTO warehouse.stockitems_archive (
            stockitemid, stockitemname, supplierid, colorid, unitpackageid, outerpackageid,
            brand, size, leadtimedays, quantityperOuter, ischillerstock, barcode,
            taxrate, unitprice, recommendedretailprice, typicalweightperunit,
            marketingcomments, internalcomments, photo, customfields, lasteditedby, validfrom, validto
        ) VALUES (
            OLD.stockitemid, OLD.stockitemname, OLD.supplierid, OLD.colorid, OLD.unitpackageid, OLD.outerpackageid,
            OLD.brand, OLD.size, OLD.leadtimedays, OLD.quantityperOuter, OLD.ischillerstock, OLD.barcode,
            OLD.taxrate, OLD.unitprice, OLD.recommendedretailprice, OLD.typicalweightperunit,
            OLD.marketingcomments, OLD.internalcomments, OLD.photo, OLD.customfields, OLD.lasteditedby, OLD.validfrom, CURRENT_TIMESTAMP
        );
        RETURN OLD;
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER tr_stockitems_temporal
    BEFORE INSERT OR UPDATE OR DELETE ON warehouse.stockitems
    FOR EACH ROW EXECUTE FUNCTION warehouse.stockitems_temporal_trigger();

-- Warehouse.ColdRoomTemperatures temporal trigger
CREATE OR REPLACE FUNCTION warehouse.coldroomtemperatures_temporal_trigger()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        NEW.validfrom := CURRENT_TIMESTAMP;
        NEW.validto := '9999-12-31 23:59:59.999999'::timestamp;
        RETURN NEW;
    ELSIF TG_OP = 'UPDATE' THEN
        INSERT INTO warehouse.coldroomtemperatures_archive (
            coldroomtemperatureid, coldroomsensornumber, recordedwhen, temperature, validfrom, validto
        ) VALUES (
            OLD.coldroomtemperatureid, OLD.coldroomsensornumber, OLD.recordedwhen, OLD.temperature, OLD.validfrom, CURRENT_TIMESTAMP
        );
        NEW.validfrom := CURRENT_TIMESTAMP;
        NEW.validto := '9999-12-31 23:59:59.999999'::timestamp;
        RETURN NEW;
    ELSIF TG_OP = 'DELETE' THEN
        INSERT INTO warehouse.coldroomtemperatures_archive (
            coldroomtemperatureid, coldroomsensornumber, recordedwhen, temperature, validfrom, validto
        ) VALUES (
            OLD.coldroomtemperatureid, OLD.coldroomsensornumber, OLD.recordedwhen, OLD.temperature, OLD.validfrom, CURRENT_TIMESTAMP
        );
        RETURN OLD;
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER tr_coldroomtemperatures_temporal
    BEFORE INSERT OR UPDATE OR DELETE ON warehouse.coldroomtemperatures
    FOR EACH ROW EXECUTE FUNCTION warehouse.coldroomtemperatures_temporal_trigger();

-- Sales.BuyingGroups temporal trigger
CREATE OR REPLACE FUNCTION sales.buyinggroups_temporal_trigger()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        NEW.validfrom := CURRENT_TIMESTAMP;
        NEW.validto := '9999-12-31 23:59:59.999999'::timestamp;
        RETURN NEW;
    ELSIF TG_OP = 'UPDATE' THEN
        INSERT INTO sales.buyinggroups_archive (
            buyinggroupid, buyinggroupname, lasteditedby, validfrom, validto
        ) VALUES (
            OLD.buyinggroupid, OLD.buyinggroupname, OLD.lasteditedby, OLD.validfrom, CURRENT_TIMESTAMP
        );
        NEW.validfrom := CURRENT_TIMESTAMP;
        NEW.validto := '9999-12-31 23:59:59.999999'::timestamp;
        RETURN NEW;
    ELSIF TG_OP = 'DELETE' THEN
        INSERT INTO sales.buyinggroups_archive (
            buyinggroupid, buyinggroupname, lasteditedby, validfrom, validto
        ) VALUES (
            OLD.buyinggroupid, OLD.buyinggroupname, OLD.lasteditedby, OLD.validfrom, CURRENT_TIMESTAMP
        );
        RETURN OLD;
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER tr_buyinggroups_temporal
    BEFORE INSERT OR UPDATE OR DELETE ON sales.buyinggroups
    FOR EACH ROW EXECUTE FUNCTION sales.buyinggroups_temporal_trigger();

-- Sales.CustomerCategories temporal trigger
CREATE OR REPLACE FUNCTION sales.customercategories_temporal_trigger()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        NEW.validfrom := CURRENT_TIMESTAMP;
        NEW.validto := '9999-12-31 23:59:59.999999'::timestamp;
        RETURN NEW;
    ELSIF TG_OP = 'UPDATE' THEN
        INSERT INTO sales.customercategories_archive (
            customercategoryid, customercategoryname, lasteditedby, validfrom, validto
        ) VALUES (
            OLD.customercategoryid, OLD.customercategoryname, OLD.lasteditedby, OLD.validfrom, CURRENT_TIMESTAMP
        );
        NEW.validfrom := CURRENT_TIMESTAMP;
        NEW.validto := '9999-12-31 23:59:59.999999'::timestamp;
        RETURN NEW;
    ELSIF TG_OP = 'DELETE' THEN
        INSERT INTO sales.customercategories_archive (
            customercategoryid, customercategoryname, lasteditedby, validfrom, validto
        ) VALUES (
            OLD.customercategoryid, OLD.customercategoryname, OLD.lasteditedby, OLD.validfrom, CURRENT_TIMESTAMP
        );
        RETURN OLD;
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER tr_customercategories_temporal
    BEFORE INSERT OR UPDATE OR DELETE ON sales.customercategories
    FOR EACH ROW EXECUTE FUNCTION sales.customercategories_temporal_trigger();

-- Sales.Customers temporal trigger
CREATE OR REPLACE FUNCTION sales.customers_temporal_trigger()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        NEW.validfrom := CURRENT_TIMESTAMP;
        NEW.validto := '9999-12-31 23:59:59.999999'::timestamp;
        RETURN NEW;
    ELSIF TG_OP = 'UPDATE' THEN
        INSERT INTO sales.customers_archive (
            customerid, customername, billtocustomerid, customercategoryid, buyinggroupid,
            primarycontactpersonid, alternatecontactpersonid, deliverymethodid, deliverycityid, postalcityid,
            creditlimit, accountopeneddate, standarddiscountpercentage, isstatementsent, isoncredithold,
            paymentdays, phonenumber, faxnumber, deliveryrun, runposition, websiteurl,
            deliveryaddressline1, deliveryaddressline2, deliverypostalcode, deliverylocation,
            postaladdressline1, postaladdressline2, postalpostalcode, lasteditedby, validfrom, validto
        ) VALUES (
            OLD.customerid, OLD.customername, OLD.billtocustomerid, OLD.customercategoryid, OLD.buyinggroupid,
            OLD.primarycontactpersonid, OLD.alternatecontactpersonid, OLD.deliverymethodid, OLD.deliverycityid, OLD.postalcityid,
            OLD.creditlimit, OLD.accountopeneddate, OLD.standarddiscountpercentage, OLD.isstatementsent, OLD.isoncredithold,
            OLD.paymentdays, OLD.phonenumber, OLD.faxnumber, OLD.deliveryrun, OLD.runposition, OLD.websiteurl,
            OLD.deliveryaddressline1, OLD.deliveryaddressline2, OLD.deliverypostalcode, OLD.deliverylocation,
            OLD.postaladdressline1, OLD.postaladdressline2, OLD.postalpostalcode, OLD.lasteditedby, OLD.validfrom, CURRENT_TIMESTAMP
        );
        NEW.validfrom := CURRENT_TIMESTAMP;
        NEW.validto := '9999-12-31 23:59:59.999999'::timestamp;
        RETURN NEW;
    ELSIF TG_OP = 'DELETE' THEN
        INSERT INTO sales.customers_archive (
            customerid, customername, billtocustomerid, customercategoryid, buyinggroupid,
            primarycontactpersonid, alternatecontactpersonid, deliverymethodid, deliverycityid, postalcityid,
            creditlimit, accountopeneddate, standarddiscountpercentage, isstatementsent, isoncredithold,
            paymentdays, phonenumber, faxnumber, deliveryrun, runposition, websiteurl,
            deliveryaddressline1, deliveryaddressline2, deliverypostalcode, deliverylocation,
            postaladdressline1, postaladdressline2, postalpostalcode, lasteditedby, validfrom, validto
        ) VALUES (
            OLD.customerid, OLD.customername, OLD.billtocustomerid, OLD.customercategoryid, OLD.buyinggroupid,
            OLD.primarycontactpersonid, OLD.alternatecontactpersonid, OLD.deliverymethodid, OLD.deliverycityid, OLD.postalcityid,
            OLD.creditlimit, OLD.accountopeneddate, OLD.standarddiscountpercentage, OLD.isstatementsent, OLD.isoncredithold,
            OLD.paymentdays, OLD.phonenumber, OLD.faxnumber, OLD.deliveryrun, OLD.runposition, OLD.websiteurl,
            OLD.deliveryaddressline1, OLD.deliveryaddressline2, OLD.deliverypostalcode, OLD.deliverylocation,
            OLD.postaladdressline1, OLD.postaladdressline2, OLD.postalpostalcode, OLD.lasteditedby, OLD.validfrom, CURRENT_TIMESTAMP
        );
        RETURN OLD;
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER tr_customers_temporal
    BEFORE INSERT OR UPDATE OR DELETE ON sales.customers
    FOR EACH ROW EXECUTE FUNCTION sales.customers_temporal_trigger();

-- Purchasing.SupplierCategories temporal trigger
CREATE OR REPLACE FUNCTION purchasing.suppliercategories_temporal_trigger()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        NEW.validfrom := CURRENT_TIMESTAMP;
        NEW.validto := '9999-12-31 23:59:59.999999'::timestamp;
        RETURN NEW;
    ELSIF TG_OP = 'UPDATE' THEN
        INSERT INTO purchasing.suppliercategories_archive (
            suppliercategoryid, suppliercategoryname, lasteditedby, validfrom, validto
        ) VALUES (
            OLD.suppliercategoryid, OLD.suppliercategoryname, OLD.lasteditedby, OLD.validfrom, CURRENT_TIMESTAMP
        );
        NEW.validfrom := CURRENT_TIMESTAMP;
        NEW.validto := '9999-12-31 23:59:59.999999'::timestamp;
        RETURN NEW;
    ELSIF TG_OP = 'DELETE' THEN
        INSERT INTO purchasing.suppliercategories_archive (
            suppliercategoryid, suppliercategoryname, lasteditedby, validfrom, validto
        ) VALUES (
            OLD.suppliercategoryid, OLD.suppliercategoryname, OLD.lasteditedby, OLD.validfrom, CURRENT_TIMESTAMP
        );
        RETURN OLD;
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER tr_suppliercategories_temporal
    BEFORE INSERT OR UPDATE OR DELETE ON purchasing.suppliercategories
    FOR EACH ROW EXECUTE FUNCTION purchasing.suppliercategories_temporal_trigger();

-- Purchasing.Suppliers temporal trigger
CREATE OR REPLACE FUNCTION purchasing.suppliers_temporal_trigger()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        NEW.validfrom := CURRENT_TIMESTAMP;
        NEW.validto := '9999-12-31 23:59:59.999999'::timestamp;
        RETURN NEW;
    ELSIF TG_OP = 'UPDATE' THEN
        INSERT INTO purchasing.suppliers_archive (
            supplierid, suppliername, suppliercategoryid, primarycontactpersonid, alternatecontactpersonid,
            deliverymethodid, deliverycityid, postalcityid, supplierreference,
            bankaccountname, bankaccountbranch, bankaccountcode, bankaccountnumber, bankinternationalcode,
            paymentdays, internalcomments, phonenumber, faxnumber, websiteurl,
            deliveryaddressline1, deliveryaddressline2, deliverypostalcode, deliverylocation,
            postaladdressline1, postaladdressline2, postalpostalcode, lasteditedby, validfrom, validto
        ) VALUES (
            OLD.supplierid, OLD.suppliername, OLD.suppliercategoryid, OLD.primarycontactpersonid, OLD.alternatecontactpersonid,
            OLD.deliverymethodid, OLD.deliverycityid, OLD.postalcityid, OLD.supplierreference,
            OLD.bankaccountname, OLD.bankaccountbranch, OLD.bankaccountcode, OLD.bankaccountnumber, OLD.bankinternationalcode,
            OLD.paymentdays, OLD.internalcomments, OLD.phonenumber, OLD.faxnumber, OLD.websiteurl,
            OLD.deliveryaddressline1, OLD.deliveryaddressline2, OLD.deliverypostalcode, OLD.deliverylocation,
            OLD.postaladdressline1, OLD.postaladdressline2, OLD.postalpostalcode, OLD.lasteditedby, OLD.validfrom, CURRENT_TIMESTAMP
        );
        NEW.validfrom := CURRENT_TIMESTAMP;
        NEW.validto := '9999-12-31 23:59:59.999999'::timestamp;
        RETURN NEW;
    ELSIF TG_OP = 'DELETE' THEN
        INSERT INTO purchasing.suppliers_archive (
            supplierid, suppliername, suppliercategoryid, primarycontactpersonid, alternatecontactpersonid,
            deliverymethodid, deliverycityid, postalcityid, supplierreference,
            bankaccountname, bankaccountbranch, bankaccountcode, bankaccountnumber, bankinternationalcode,
            paymentdays, internalcomments, phonenumber, faxnumber, websiteurl,
            deliveryaddressline1, deliveryaddressline2, deliverypostalcode, deliverylocation,
            postaladdressline1, postaladdressline2, postalpostalcode, lasteditedby, validfrom, validto
        ) VALUES (
            OLD.supplierid, OLD.suppliername, OLD.suppliercategoryid, OLD.primarycontactpersonid, OLD.alternatecontactpersonid,
            OLD.deliverymethodid, OLD.deliverycityid, OLD.postalcityid, OLD.supplierreference,
            OLD.bankaccountname, OLD.bankaccountbranch, OLD.bankaccountcode, OLD.bankaccountnumber, OLD.bankinternationalcode,
            OLD.paymentdays, OLD.internalcomments, OLD.phonenumber, OLD.faxnumber, OLD.websiteurl,
            OLD.deliveryaddressline1, OLD.deliveryaddressline2, OLD.deliverypostalcode, OLD.deliverylocation,
            OLD.postaladdressline1, OLD.postaladdressline2, OLD.postalpostalcode, OLD.lasteditedby, OLD.validfrom, CURRENT_TIMESTAMP
        );
        RETURN OLD;
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER tr_suppliers_temporal
    BEFORE INSERT OR UPDATE OR DELETE ON purchasing.suppliers
    FOR EACH ROW EXECUTE FUNCTION purchasing.suppliers_temporal_trigger();
