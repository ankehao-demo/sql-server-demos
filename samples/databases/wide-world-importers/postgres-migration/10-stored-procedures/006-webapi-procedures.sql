-- Phase 3: OLTP Code Migration - WebApi Schema Stored Procedures
-- Converted from SQL Server T-SQL to PostgreSQL PL/pgSQL

-- Create WebApi schema if it doesn't exist
CREATE SCHEMA IF NOT EXISTS webapi;

-- =============================================
-- Procedure: WebApi.Login
-- Description: Validates user login credentials
-- =============================================
CREATE OR REPLACE PROCEDURE webapi.login(
    p_logon_name varchar(50),
    p_password varchar(40),
    INOUT p_person_id integer DEFAULT NULL,
    INOUT p_is_valid boolean DEFAULT false
)
LANGUAGE plpgsql
AS $$
BEGIN
    SELECT personid INTO p_person_id
    FROM application.people
    WHERE logonname = p_logon_name
    AND hashedpassword = encode(sha256(p_password::bytea), 'hex')
    AND ispermittedtologon = true;
    
    p_is_valid := (p_person_id IS NOT NULL);
END;
$$;

-- =============================================
-- Procedure: WebApi.SearchForStockItems
-- Description: Searches for stock items with pagination
-- =============================================
CREATE OR REPLACE PROCEDURE webapi.search_for_stock_items(
    p_search_text varchar(1000) DEFAULT NULL,
    p_page_number integer DEFAULT 1,
    p_page_size integer DEFAULT 20,
    INOUT p_results refcursor DEFAULT NULL
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_offset integer;
BEGIN
    v_offset := (p_page_number - 1) * p_page_size;
    
    OPEN p_results FOR
    SELECT si.stockitemid, si.stockitemname, si.unitprice, si.recommendedretailprice,
           si.taxrate, c.colorname AS color, si.size, si.brand,
           si.quantityperouter, si.leadtimedays, si.ischillerstock,
           si.barcode, si.searchdetails
    FROM warehouse.stockitems si
    LEFT JOIN warehouse.colors c ON si.colorid = c.colorid
    WHERE p_search_text IS NULL
       OR si.stockitemname ILIKE '%' || p_search_text || '%'
       OR si.searchdetails ILIKE '%' || p_search_text || '%'
    ORDER BY si.stockitemname
    LIMIT p_page_size OFFSET v_offset;
END;
$$;

-- =============================================
-- DELETE Procedures
-- =============================================

CREATE OR REPLACE PROCEDURE webapi.delete_buying_group(p_buying_group_id integer)
LANGUAGE plpgsql AS $$
BEGIN
    DELETE FROM sales.buyinggroups WHERE buyinggroupid = p_buying_group_id;
END;
$$;

CREATE OR REPLACE PROCEDURE webapi.delete_city(p_city_id integer)
LANGUAGE plpgsql AS $$
BEGIN
    DELETE FROM application.cities WHERE cityid = p_city_id;
END;
$$;

CREATE OR REPLACE PROCEDURE webapi.delete_color(p_color_id integer)
LANGUAGE plpgsql AS $$
BEGIN
    DELETE FROM warehouse.colors WHERE colorid = p_color_id;
END;
$$;

CREATE OR REPLACE PROCEDURE webapi.delete_country(p_country_id integer)
LANGUAGE plpgsql AS $$
BEGIN
    DELETE FROM application.countries WHERE countryid = p_country_id;
END;
$$;

CREATE OR REPLACE PROCEDURE webapi.delete_customer(p_customer_id integer)
LANGUAGE plpgsql AS $$
BEGIN
    DELETE FROM sales.customers WHERE customerid = p_customer_id;
END;
$$;

CREATE OR REPLACE PROCEDURE webapi.delete_customer_category(p_customer_category_id integer)
LANGUAGE plpgsql AS $$
BEGIN
    DELETE FROM sales.customercategories WHERE customercategoryid = p_customer_category_id;
END;
$$;

CREATE OR REPLACE PROCEDURE webapi.delete_delivery_method(p_delivery_method_id integer)
LANGUAGE plpgsql AS $$
BEGIN
    DELETE FROM application.deliverymethods WHERE deliverymethodid = p_delivery_method_id;
END;
$$;

CREATE OR REPLACE PROCEDURE webapi.delete_package_type(p_package_type_id integer)
LANGUAGE plpgsql AS $$
BEGIN
    DELETE FROM warehouse.packagetypes WHERE packagetypeid = p_package_type_id;
END;
$$;

CREATE OR REPLACE PROCEDURE webapi.delete_payment_method(p_payment_method_id integer)
LANGUAGE plpgsql AS $$
BEGIN
    DELETE FROM application.paymentmethods WHERE paymentmethodid = p_payment_method_id;
END;
$$;

CREATE OR REPLACE PROCEDURE webapi.delete_state_province(p_state_province_id integer)
LANGUAGE plpgsql AS $$
BEGIN
    DELETE FROM application.stateprovinces WHERE stateprovinceid = p_state_province_id;
END;
$$;

CREATE OR REPLACE PROCEDURE webapi.delete_stock_group(p_stock_group_id integer)
LANGUAGE plpgsql AS $$
BEGIN
    DELETE FROM warehouse.stockgroups WHERE stockgroupid = p_stock_group_id;
END;
$$;

CREATE OR REPLACE PROCEDURE webapi.delete_stock_item(p_stock_item_id integer)
LANGUAGE plpgsql AS $$
BEGIN
    DELETE FROM warehouse.stockitems WHERE stockitemid = p_stock_item_id;
END;
$$;

CREATE OR REPLACE PROCEDURE webapi.delete_supplier(p_supplier_id integer)
LANGUAGE plpgsql AS $$
BEGIN
    DELETE FROM purchasing.suppliers WHERE supplierid = p_supplier_id;
END;
$$;

CREATE OR REPLACE PROCEDURE webapi.delete_supplier_category(p_supplier_category_id integer)
LANGUAGE plpgsql AS $$
BEGIN
    DELETE FROM purchasing.suppliercategories WHERE suppliercategoryid = p_supplier_category_id;
END;
$$;

CREATE OR REPLACE PROCEDURE webapi.delete_transaction_type(p_transaction_type_id integer)
LANGUAGE plpgsql AS $$
BEGIN
    DELETE FROM application.transactiontypes WHERE transactiontypeid = p_transaction_type_id;
END;
$$;

-- =============================================
-- INSERT FROM JSON Procedures
-- =============================================

CREATE OR REPLACE PROCEDURE webapi.insert_buying_groups_from_json(
    p_json jsonb,
    p_last_edited_by integer
)
LANGUAGE plpgsql AS $$
BEGIN
    INSERT INTO sales.buyinggroups (buyinggroupname, lasteditedby)
    SELECT j->>'BuyingGroupName', p_last_edited_by
    FROM jsonb_array_elements(p_json) AS j;
END;
$$;

CREATE OR REPLACE PROCEDURE webapi.insert_cities_from_json(
    p_json jsonb,
    p_last_edited_by integer
)
LANGUAGE plpgsql AS $$
BEGIN
    INSERT INTO application.cities (cityname, stateprovinceid, location, latestrecordedpopulation, lasteditedby)
    SELECT j->>'CityName', (j->>'StateProvinceID')::integer, 
           ST_GeogFromText(j->>'Location'), (j->>'LatestRecordedPopulation')::bigint,
           p_last_edited_by
    FROM jsonb_array_elements(p_json) AS j;
END;
$$;

CREATE OR REPLACE PROCEDURE webapi.insert_colors_from_json(
    p_json jsonb,
    p_last_edited_by integer
)
LANGUAGE plpgsql AS $$
BEGIN
    INSERT INTO warehouse.colors (colorname, lasteditedby)
    SELECT j->>'ColorName', p_last_edited_by
    FROM jsonb_array_elements(p_json) AS j;
END;
$$;

CREATE OR REPLACE PROCEDURE webapi.insert_countries_from_json(
    p_json jsonb,
    p_last_edited_by integer
)
LANGUAGE plpgsql AS $$
BEGIN
    INSERT INTO application.countries (countryname, formalname, isoalpha3code, isonumericcode,
                                       countrytype, latestrecordedpopulation, continent, region, subregion, lasteditedby)
    SELECT j->>'CountryName', j->>'FormalName', j->>'IsoAlpha3Code', (j->>'IsoNumericCode')::integer,
           j->>'CountryType', (j->>'LatestRecordedPopulation')::bigint, j->>'Continent', j->>'Region', j->>'Subregion',
           p_last_edited_by
    FROM jsonb_array_elements(p_json) AS j;
END;
$$;

CREATE OR REPLACE PROCEDURE webapi.insert_customer_categories_from_json(
    p_json jsonb,
    p_last_edited_by integer
)
LANGUAGE plpgsql AS $$
BEGIN
    INSERT INTO sales.customercategories (customercategoryname, lasteditedby)
    SELECT j->>'CustomerCategoryName', p_last_edited_by
    FROM jsonb_array_elements(p_json) AS j;
END;
$$;

CREATE OR REPLACE PROCEDURE webapi.insert_customers_from_json(
    p_json jsonb,
    p_last_edited_by integer
)
LANGUAGE plpgsql AS $$
BEGIN
    INSERT INTO sales.customers (customername, billtocustomerid, customercategoryid, buyinggroupid,
                                 primarycontactpersonid, alternatecontactpersonid, deliverymethodid,
                                 deliverycityid, postalcityid, creditlimit, accountopeneddate,
                                 standarddiscountpercentage, isstatementsenttoday, isoncredithold,
                                 paymentdays, phonenumber, faxnumber, websiteurl,
                                 deliveryaddressline1, deliveryaddressline2, deliverypostalcode,
                                 deliverylocation, postaladdressline1, postaladdressline2, postalpostalcode,
                                 lasteditedby)
    SELECT j->>'CustomerName', (j->>'BillToCustomerID')::integer, (j->>'CustomerCategoryID')::integer,
           (j->>'BuyingGroupID')::integer, (j->>'PrimaryContactPersonID')::integer,
           (j->>'AlternateContactPersonID')::integer, (j->>'DeliveryMethodID')::integer,
           (j->>'DeliveryCityID')::integer, (j->>'PostalCityID')::integer,
           (j->>'CreditLimit')::numeric, (j->>'AccountOpenedDate')::date,
           (j->>'StandardDiscountPercentage')::numeric, (j->>'IsStatementSentToday')::boolean,
           (j->>'IsOnCreditHold')::boolean, (j->>'PaymentDays')::integer,
           j->>'PhoneNumber', j->>'FaxNumber', j->>'WebsiteURL',
           j->>'DeliveryAddressLine1', j->>'DeliveryAddressLine2', j->>'DeliveryPostalCode',
           ST_GeogFromText(j->>'DeliveryLocation'), j->>'PostalAddressLine1', j->>'PostalAddressLine2',
           j->>'PostalPostalCode', p_last_edited_by
    FROM jsonb_array_elements(p_json) AS j;
END;
$$;

CREATE OR REPLACE PROCEDURE webapi.insert_delivery_methods_from_json(
    p_json jsonb,
    p_last_edited_by integer
)
LANGUAGE plpgsql AS $$
BEGIN
    INSERT INTO application.deliverymethods (deliverymethodname, lasteditedby)
    SELECT j->>'DeliveryMethodName', p_last_edited_by
    FROM jsonb_array_elements(p_json) AS j;
END;
$$;

CREATE OR REPLACE PROCEDURE webapi.insert_package_types_from_json(
    p_json jsonb,
    p_last_edited_by integer
)
LANGUAGE plpgsql AS $$
BEGIN
    INSERT INTO warehouse.packagetypes (packagetypename, lasteditedby)
    SELECT j->>'PackageTypeName', p_last_edited_by
    FROM jsonb_array_elements(p_json) AS j;
END;
$$;

CREATE OR REPLACE PROCEDURE webapi.insert_payment_methods_from_json(
    p_json jsonb,
    p_last_edited_by integer
)
LANGUAGE plpgsql AS $$
BEGIN
    INSERT INTO application.paymentmethods (paymentmethodname, lasteditedby)
    SELECT j->>'PaymentMethodName', p_last_edited_by
    FROM jsonb_array_elements(p_json) AS j;
END;
$$;

CREATE OR REPLACE PROCEDURE webapi.insert_state_provinces_from_json(
    p_json jsonb,
    p_last_edited_by integer
)
LANGUAGE plpgsql AS $$
BEGIN
    INSERT INTO application.stateprovinces (stateprovincecode, stateprovincename, countryid,
                                            salesterritory, latestrecordedpopulation, lasteditedby)
    SELECT j->>'StateProvinceCode', j->>'StateProvinceName', (j->>'CountryID')::integer,
           j->>'SalesTerritory', (j->>'LatestRecordedPopulation')::bigint, p_last_edited_by
    FROM jsonb_array_elements(p_json) AS j;
END;
$$;

CREATE OR REPLACE PROCEDURE webapi.insert_stock_groups_from_json(
    p_json jsonb,
    p_last_edited_by integer
)
LANGUAGE plpgsql AS $$
BEGIN
    INSERT INTO warehouse.stockgroups (stockgroupname, lasteditedby)
    SELECT j->>'StockGroupName', p_last_edited_by
    FROM jsonb_array_elements(p_json) AS j;
END;
$$;

CREATE OR REPLACE PROCEDURE webapi.insert_stock_items_from_json(
    p_json jsonb,
    p_last_edited_by integer
)
LANGUAGE plpgsql AS $$
BEGIN
    INSERT INTO warehouse.stockitems (stockitemname, supplierid, colorid, unitpackageid, outerpackageid,
                                      brand, size, leadtimedays, quantityperouter, ischillerstock,
                                      barcode, taxrate, unitprice, recommendedretailprice,
                                      typicalweightperunit, marketingcomments, internalcomments,
                                      customfields, tags, searchdetails, lasteditedby)
    SELECT j->>'StockItemName', (j->>'SupplierID')::integer, (j->>'ColorID')::integer,
           (j->>'UnitPackageID')::integer, (j->>'OuterPackageID')::integer,
           j->>'Brand', j->>'Size', (j->>'LeadTimeDays')::integer, (j->>'QuantityPerOuter')::integer,
           (j->>'IsChillerStock')::boolean, j->>'Barcode', (j->>'TaxRate')::numeric,
           (j->>'UnitPrice')::numeric, (j->>'RecommendedRetailPrice')::numeric,
           (j->>'TypicalWeightPerUnit')::numeric, j->>'MarketingComments', j->>'InternalComments',
           (j->'CustomFields')::jsonb, (j->'Tags')::jsonb, j->>'SearchDetails', p_last_edited_by
    FROM jsonb_array_elements(p_json) AS j;
END;
$$;

CREATE OR REPLACE PROCEDURE webapi.insert_supplier_categories_from_json(
    p_json jsonb,
    p_last_edited_by integer
)
LANGUAGE plpgsql AS $$
BEGIN
    INSERT INTO purchasing.suppliercategories (suppliercategoryname, lasteditedby)
    SELECT j->>'SupplierCategoryName', p_last_edited_by
    FROM jsonb_array_elements(p_json) AS j;
END;
$$;

CREATE OR REPLACE PROCEDURE webapi.insert_suppliers_from_json(
    p_json jsonb,
    p_last_edited_by integer
)
LANGUAGE plpgsql AS $$
BEGIN
    INSERT INTO purchasing.suppliers (suppliername, suppliercategoryid, primarycontactpersonid,
                                      alternatecontactpersonid, deliverymethodid, deliverycityid,
                                      postalcityid, supplierreference, bankaccountname, bankaccountbranch,
                                      bankaccountcode, bankaccountnumber, bankinternationalcode,
                                      paymentdays, internalcomments, phonenumber, faxnumber, websiteurl,
                                      deliveryaddressline1, deliveryaddressline2, deliverypostalcode,
                                      deliverylocation, postaladdressline1, postaladdressline2,
                                      postalpostalcode, lasteditedby)
    SELECT j->>'SupplierName', (j->>'SupplierCategoryID')::integer, (j->>'PrimaryContactPersonID')::integer,
           (j->>'AlternateContactPersonID')::integer, (j->>'DeliveryMethodID')::integer,
           (j->>'DeliveryCityID')::integer, (j->>'PostalCityID')::integer,
           j->>'SupplierReference', j->>'BankAccountName', j->>'BankAccountBranch',
           j->>'BankAccountCode', j->>'BankAccountNumber', j->>'BankInternationalCode',
           (j->>'PaymentDays')::integer, j->>'InternalComments', j->>'PhoneNumber', j->>'FaxNumber',
           j->>'WebsiteURL', j->>'DeliveryAddressLine1', j->>'DeliveryAddressLine2',
           j->>'DeliveryPostalCode', ST_GeogFromText(j->>'DeliveryLocation'),
           j->>'PostalAddressLine1', j->>'PostalAddressLine2', j->>'PostalPostalCode',
           p_last_edited_by
    FROM jsonb_array_elements(p_json) AS j;
END;
$$;

CREATE OR REPLACE PROCEDURE webapi.insert_transaction_types_from_json(
    p_json jsonb,
    p_last_edited_by integer
)
LANGUAGE plpgsql AS $$
BEGIN
    INSERT INTO application.transactiontypes (transactiontypename, lasteditedby)
    SELECT j->>'TransactionTypeName', p_last_edited_by
    FROM jsonb_array_elements(p_json) AS j;
END;
$$;

-- =============================================
-- UPDATE FROM JSON Procedures
-- =============================================

CREATE OR REPLACE PROCEDURE webapi.update_buying_group_from_json(
    p_buying_group_id integer,
    p_json jsonb,
    p_last_edited_by integer
)
LANGUAGE plpgsql AS $$
BEGIN
    UPDATE sales.buyinggroups
    SET buyinggroupname = COALESCE(p_json->>'BuyingGroupName', buyinggroupname),
        lasteditedby = p_last_edited_by,
        lasteditedwhen = NOW()
    WHERE buyinggroupid = p_buying_group_id;
END;
$$;

CREATE OR REPLACE PROCEDURE webapi.update_city_from_json(
    p_city_id integer,
    p_json jsonb,
    p_last_edited_by integer
)
LANGUAGE plpgsql AS $$
BEGIN
    UPDATE application.cities
    SET cityname = COALESCE(p_json->>'CityName', cityname),
        stateprovinceid = COALESCE((p_json->>'StateProvinceID')::integer, stateprovinceid),
        latestrecordedpopulation = COALESCE((p_json->>'LatestRecordedPopulation')::bigint, latestrecordedpopulation),
        lasteditedby = p_last_edited_by,
        lasteditedwhen = NOW()
    WHERE cityid = p_city_id;
END;
$$;

CREATE OR REPLACE PROCEDURE webapi.update_color_from_json(
    p_color_id integer,
    p_json jsonb,
    p_last_edited_by integer
)
LANGUAGE plpgsql AS $$
BEGIN
    UPDATE warehouse.colors
    SET colorname = COALESCE(p_json->>'ColorName', colorname),
        lasteditedby = p_last_edited_by,
        lasteditedwhen = NOW()
    WHERE colorid = p_color_id;
END;
$$;

CREATE OR REPLACE PROCEDURE webapi.update_country_from_json(
    p_country_id integer,
    p_json jsonb,
    p_last_edited_by integer
)
LANGUAGE plpgsql AS $$
BEGIN
    UPDATE application.countries
    SET countryname = COALESCE(p_json->>'CountryName', countryname),
        formalname = COALESCE(p_json->>'FormalName', formalname),
        isoalpha3code = COALESCE(p_json->>'IsoAlpha3Code', isoalpha3code),
        isonumericcode = COALESCE((p_json->>'IsoNumericCode')::integer, isonumericcode),
        countrytype = COALESCE(p_json->>'CountryType', countrytype),
        latestrecordedpopulation = COALESCE((p_json->>'LatestRecordedPopulation')::bigint, latestrecordedpopulation),
        continent = COALESCE(p_json->>'Continent', continent),
        region = COALESCE(p_json->>'Region', region),
        subregion = COALESCE(p_json->>'Subregion', subregion),
        lasteditedby = p_last_edited_by,
        lasteditedwhen = NOW()
    WHERE countryid = p_country_id;
END;
$$;

CREATE OR REPLACE PROCEDURE webapi.update_customer_category_from_json(
    p_customer_category_id integer,
    p_json jsonb,
    p_last_edited_by integer
)
LANGUAGE plpgsql AS $$
BEGIN
    UPDATE sales.customercategories
    SET customercategoryname = COALESCE(p_json->>'CustomerCategoryName', customercategoryname),
        lasteditedby = p_last_edited_by,
        lasteditedwhen = NOW()
    WHERE customercategoryid = p_customer_category_id;
END;
$$;

CREATE OR REPLACE PROCEDURE webapi.update_customer_from_json(
    p_customer_id integer,
    p_json jsonb,
    p_last_edited_by integer
)
LANGUAGE plpgsql AS $$
BEGIN
    UPDATE sales.customers
    SET customername = COALESCE(p_json->>'CustomerName', customername),
        billtocustomerid = COALESCE((p_json->>'BillToCustomerID')::integer, billtocustomerid),
        customercategoryid = COALESCE((p_json->>'CustomerCategoryID')::integer, customercategoryid),
        buyinggroupid = COALESCE((p_json->>'BuyingGroupID')::integer, buyinggroupid),
        primarycontactpersonid = COALESCE((p_json->>'PrimaryContactPersonID')::integer, primarycontactpersonid),
        deliverymethodid = COALESCE((p_json->>'DeliveryMethodID')::integer, deliverymethodid),
        deliverycityid = COALESCE((p_json->>'DeliveryCityID')::integer, deliverycityid),
        creditlimit = COALESCE((p_json->>'CreditLimit')::numeric, creditlimit),
        paymentdays = COALESCE((p_json->>'PaymentDays')::integer, paymentdays),
        phonenumber = COALESCE(p_json->>'PhoneNumber', phonenumber),
        websiteurl = COALESCE(p_json->>'WebsiteURL', websiteurl),
        deliveryaddressline1 = COALESCE(p_json->>'DeliveryAddressLine1', deliveryaddressline1),
        deliveryaddressline2 = COALESCE(p_json->>'DeliveryAddressLine2', deliveryaddressline2),
        deliverypostalcode = COALESCE(p_json->>'DeliveryPostalCode', deliverypostalcode),
        lasteditedby = p_last_edited_by,
        lasteditedwhen = NOW()
    WHERE customerid = p_customer_id;
END;
$$;

CREATE OR REPLACE PROCEDURE webapi.update_delivery_method_from_json(
    p_delivery_method_id integer,
    p_json jsonb,
    p_last_edited_by integer
)
LANGUAGE plpgsql AS $$
BEGIN
    UPDATE application.deliverymethods
    SET deliverymethodname = COALESCE(p_json->>'DeliveryMethodName', deliverymethodname),
        lasteditedby = p_last_edited_by,
        lasteditedwhen = NOW()
    WHERE deliverymethodid = p_delivery_method_id;
END;
$$;

CREATE OR REPLACE PROCEDURE webapi.update_package_type_from_json(
    p_package_type_id integer,
    p_json jsonb,
    p_last_edited_by integer
)
LANGUAGE plpgsql AS $$
BEGIN
    UPDATE warehouse.packagetypes
    SET packagetypename = COALESCE(p_json->>'PackageTypeName', packagetypename),
        lasteditedby = p_last_edited_by,
        lasteditedwhen = NOW()
    WHERE packagetypeid = p_package_type_id;
END;
$$;

CREATE OR REPLACE PROCEDURE webapi.update_payment_method_from_json(
    p_payment_method_id integer,
    p_json jsonb,
    p_last_edited_by integer
)
LANGUAGE plpgsql AS $$
BEGIN
    UPDATE application.paymentmethods
    SET paymentmethodname = COALESCE(p_json->>'PaymentMethodName', paymentmethodname),
        lasteditedby = p_last_edited_by,
        lasteditedwhen = NOW()
    WHERE paymentmethodid = p_payment_method_id;
END;
$$;

CREATE OR REPLACE PROCEDURE webapi.update_state_province_from_json(
    p_state_province_id integer,
    p_json jsonb,
    p_last_edited_by integer
)
LANGUAGE plpgsql AS $$
BEGIN
    UPDATE application.stateprovinces
    SET stateprovincecode = COALESCE(p_json->>'StateProvinceCode', stateprovincecode),
        stateprovincename = COALESCE(p_json->>'StateProvinceName', stateprovincename),
        countryid = COALESCE((p_json->>'CountryID')::integer, countryid),
        salesterritory = COALESCE(p_json->>'SalesTerritory', salesterritory),
        latestrecordedpopulation = COALESCE((p_json->>'LatestRecordedPopulation')::bigint, latestrecordedpopulation),
        lasteditedby = p_last_edited_by,
        lasteditedwhen = NOW()
    WHERE stateprovinceid = p_state_province_id;
END;
$$;

CREATE OR REPLACE PROCEDURE webapi.update_stock_group_from_json(
    p_stock_group_id integer,
    p_json jsonb,
    p_last_edited_by integer
)
LANGUAGE plpgsql AS $$
BEGIN
    UPDATE warehouse.stockgroups
    SET stockgroupname = COALESCE(p_json->>'StockGroupName', stockgroupname),
        lasteditedby = p_last_edited_by,
        lasteditedwhen = NOW()
    WHERE stockgroupid = p_stock_group_id;
END;
$$;

CREATE OR REPLACE PROCEDURE webapi.update_stock_item_from_json(
    p_stock_item_id integer,
    p_json jsonb,
    p_last_edited_by integer
)
LANGUAGE plpgsql AS $$
BEGIN
    UPDATE warehouse.stockitems
    SET stockitemname = COALESCE(p_json->>'StockItemName', stockitemname),
        supplierid = COALESCE((p_json->>'SupplierID')::integer, supplierid),
        colorid = COALESCE((p_json->>'ColorID')::integer, colorid),
        unitpackageid = COALESCE((p_json->>'UnitPackageID')::integer, unitpackageid),
        outerpackageid = COALESCE((p_json->>'OuterPackageID')::integer, outerpackageid),
        brand = COALESCE(p_json->>'Brand', brand),
        size = COALESCE(p_json->>'Size', size),
        leadtimedays = COALESCE((p_json->>'LeadTimeDays')::integer, leadtimedays),
        quantityperouter = COALESCE((p_json->>'QuantityPerOuter')::integer, quantityperouter),
        ischillerstock = COALESCE((p_json->>'IsChillerStock')::boolean, ischillerstock),
        barcode = COALESCE(p_json->>'Barcode', barcode),
        taxrate = COALESCE((p_json->>'TaxRate')::numeric, taxrate),
        unitprice = COALESCE((p_json->>'UnitPrice')::numeric, unitprice),
        recommendedretailprice = COALESCE((p_json->>'RecommendedRetailPrice')::numeric, recommendedretailprice),
        typicalweightperunit = COALESCE((p_json->>'TypicalWeightPerUnit')::numeric, typicalweightperunit),
        marketingcomments = COALESCE(p_json->>'MarketingComments', marketingcomments),
        internalcomments = COALESCE(p_json->>'InternalComments', internalcomments),
        lasteditedby = p_last_edited_by,
        lasteditedwhen = NOW()
    WHERE stockitemid = p_stock_item_id;
END;
$$;

CREATE OR REPLACE PROCEDURE webapi.update_supplier_category_from_json(
    p_supplier_category_id integer,
    p_json jsonb,
    p_last_edited_by integer
)
LANGUAGE plpgsql AS $$
BEGIN
    UPDATE purchasing.suppliercategories
    SET suppliercategoryname = COALESCE(p_json->>'SupplierCategoryName', suppliercategoryname),
        lasteditedby = p_last_edited_by,
        lasteditedwhen = NOW()
    WHERE suppliercategoryid = p_supplier_category_id;
END;
$$;

CREATE OR REPLACE PROCEDURE webapi.update_supplier_from_json(
    p_supplier_id integer,
    p_json jsonb,
    p_last_edited_by integer
)
LANGUAGE plpgsql AS $$
BEGIN
    UPDATE purchasing.suppliers
    SET suppliername = COALESCE(p_json->>'SupplierName', suppliername),
        suppliercategoryid = COALESCE((p_json->>'SupplierCategoryID')::integer, suppliercategoryid),
        primarycontactpersonid = COALESCE((p_json->>'PrimaryContactPersonID')::integer, primarycontactpersonid),
        deliverymethodid = COALESCE((p_json->>'DeliveryMethodID')::integer, deliverymethodid),
        deliverycityid = COALESCE((p_json->>'DeliveryCityID')::integer, deliverycityid),
        supplierreference = COALESCE(p_json->>'SupplierReference', supplierreference),
        paymentdays = COALESCE((p_json->>'PaymentDays')::integer, paymentdays),
        phonenumber = COALESCE(p_json->>'PhoneNumber', phonenumber),
        websiteurl = COALESCE(p_json->>'WebsiteURL', websiteurl),
        deliveryaddressline1 = COALESCE(p_json->>'DeliveryAddressLine1', deliveryaddressline1),
        deliveryaddressline2 = COALESCE(p_json->>'DeliveryAddressLine2', deliveryaddressline2),
        deliverypostalcode = COALESCE(p_json->>'DeliveryPostalCode', deliverypostalcode),
        lasteditedby = p_last_edited_by,
        lasteditedwhen = NOW()
    WHERE supplierid = p_supplier_id;
END;
$$;

CREATE OR REPLACE PROCEDURE webapi.update_transaction_type_from_json(
    p_transaction_type_id integer,
    p_json jsonb,
    p_last_edited_by integer
)
LANGUAGE plpgsql AS $$
BEGIN
    UPDATE application.transactiontypes
    SET transactiontypename = COALESCE(p_json->>'TransactionTypeName', transactiontypename),
        lasteditedby = p_last_edited_by,
        lasteditedwhen = NOW()
    WHERE transactiontypeid = p_transaction_type_id;
END;
$$;

-- Additional update procedures for transactions

CREATE OR REPLACE PROCEDURE webapi.update_customer_transaction_from_json(
    p_customer_transaction_id integer,
    p_json jsonb,
    p_last_edited_by integer
)
LANGUAGE plpgsql AS $$
BEGIN
    UPDATE sales.customertransactions
    SET transactiontypeid = COALESCE((p_json->>'TransactionTypeID')::integer, transactiontypeid),
        paymentmethodid = COALESCE((p_json->>'PaymentMethodID')::integer, paymentmethodid),
        transactiondate = COALESCE((p_json->>'TransactionDate')::date, transactiondate),
        amountexcludingtax = COALESCE((p_json->>'AmountExcludingTax')::numeric, amountexcludingtax),
        taxamount = COALESCE((p_json->>'TaxAmount')::numeric, taxamount),
        transactionamount = COALESCE((p_json->>'TransactionAmount')::numeric, transactionamount),
        outstandingbalance = COALESCE((p_json->>'OutstandingBalance')::numeric, outstandingbalance),
        finalizationdate = COALESCE((p_json->>'FinalizationDate')::date, finalizationdate),
        lasteditedby = p_last_edited_by,
        lasteditedwhen = NOW()
    WHERE customertransactionid = p_customer_transaction_id;
END;
$$;

CREATE OR REPLACE PROCEDURE webapi.update_supplier_transaction_from_json(
    p_supplier_transaction_id integer,
    p_json jsonb,
    p_last_edited_by integer
)
LANGUAGE plpgsql AS $$
BEGIN
    UPDATE purchasing.suppliertransactions
    SET transactiontypeid = COALESCE((p_json->>'TransactionTypeID')::integer, transactiontypeid),
        paymentmethodid = COALESCE((p_json->>'PaymentMethodID')::integer, paymentmethodid),
        transactiondate = COALESCE((p_json->>'TransactionDate')::date, transactiondate),
        amountexcludingtax = COALESCE((p_json->>'AmountExcludingTax')::numeric, amountexcludingtax),
        taxamount = COALESCE((p_json->>'TaxAmount')::numeric, taxamount),
        transactionamount = COALESCE((p_json->>'TransactionAmount')::numeric, transactionamount),
        outstandingbalance = COALESCE((p_json->>'OutstandingBalance')::numeric, outstandingbalance),
        finalizationdate = COALESCE((p_json->>'FinalizationDate')::date, finalizationdate),
        lasteditedby = p_last_edited_by,
        lasteditedwhen = NOW()
    WHERE suppliertransactionid = p_supplier_transaction_id;
END;
$$;

CREATE OR REPLACE PROCEDURE webapi.update_invoice_from_json(
    p_invoice_id integer,
    p_json jsonb,
    p_last_edited_by integer
)
LANGUAGE plpgsql AS $$
BEGIN
    UPDATE sales.invoices
    SET deliverymethodid = COALESCE((p_json->>'DeliveryMethodID')::integer, deliverymethodid),
        contactpersonid = COALESCE((p_json->>'ContactPersonID')::integer, contactpersonid),
        deliveryinstructions = COALESCE(p_json->>'DeliveryInstructions', deliveryinstructions),
        internalcomments = COALESCE(p_json->>'InternalComments', internalcomments),
        deliveryrun = COALESCE(p_json->>'DeliveryRun', deliveryrun),
        runposition = COALESCE(p_json->>'RunPosition', runposition),
        lasteditedby = p_last_edited_by,
        lasteditedwhen = NOW()
    WHERE invoiceid = p_invoice_id;
END;
$$;

CREATE OR REPLACE PROCEDURE webapi.update_purchase_order_from_json(
    p_purchase_order_id integer,
    p_json jsonb,
    p_last_edited_by integer
)
LANGUAGE plpgsql AS $$
BEGIN
    UPDATE purchasing.purchaseorders
    SET deliverymethodid = COALESCE((p_json->>'DeliveryMethodID')::integer, deliverymethodid),
        contactpersonid = COALESCE((p_json->>'ContactPersonID')::integer, contactpersonid),
        expecteddeliverydate = COALESCE((p_json->>'ExpectedDeliveryDate')::date, expecteddeliverydate),
        supplierreference = COALESCE(p_json->>'SupplierReference', supplierreference),
        internalcomments = COALESCE(p_json->>'InternalComments', internalcomments),
        lasteditedby = p_last_edited_by,
        lasteditedwhen = NOW()
    WHERE purchaseorderid = p_purchase_order_id;
END;
$$;

CREATE OR REPLACE PROCEDURE webapi.update_sales_order_from_json(
    p_order_id integer,
    p_json jsonb,
    p_last_edited_by integer
)
LANGUAGE plpgsql AS $$
BEGIN
    UPDATE sales.orders
    SET salespersonpersonid = COALESCE((p_json->>'SalespersonPersonID')::integer, salespersonpersonid),
        contactpersonid = COALESCE((p_json->>'ContactPersonID')::integer, contactpersonid),
        expecteddeliverydate = COALESCE((p_json->>'ExpectedDeliveryDate')::date, expecteddeliverydate),
        customerpurchaseordernumber = COALESCE(p_json->>'CustomerPurchaseOrderNumber', customerpurchaseordernumber),
        isundersupplybackordered = COALESCE((p_json->>'IsUndersupplyBackordered')::boolean, isundersupplybackordered),
        comments = COALESCE(p_json->>'Comments', comments),
        deliveryinstructions = COALESCE(p_json->>'DeliveryInstructions', deliveryinstructions),
        internalcomments = COALESCE(p_json->>'InternalComments', internalcomments),
        lasteditedby = p_last_edited_by,
        lasteditedwhen = NOW()
    WHERE orderid = p_order_id;
END;
$$;

CREATE OR REPLACE PROCEDURE webapi.update_special_deal_from_json(
    p_special_deal_id integer,
    p_json jsonb,
    p_last_edited_by integer
)
LANGUAGE plpgsql AS $$
BEGIN
    UPDATE sales.specialdeals
    SET stockitemid = COALESCE((p_json->>'StockItemID')::integer, stockitemid),
        customerid = COALESCE((p_json->>'CustomerID')::integer, customerid),
        buyinggroupid = COALESCE((p_json->>'BuyingGroupID')::integer, buyinggroupid),
        customercategoryid = COALESCE((p_json->>'CustomerCategoryID')::integer, customercategoryid),
        stockgroupid = COALESCE((p_json->>'StockGroupID')::integer, stockgroupid),
        dealname = COALESCE(p_json->>'DealName', dealname),
        startdate = COALESCE((p_json->>'StartDate')::date, startdate),
        enddate = COALESCE((p_json->>'EndDate')::date, enddate),
        discountamount = COALESCE((p_json->>'DiscountAmount')::numeric, discountamount),
        discountpercentage = COALESCE((p_json->>'DiscountPercentage')::numeric, discountpercentage),
        unitprice = COALESCE((p_json->>'UnitPrice')::numeric, unitprice),
        lasteditedby = p_last_edited_by,
        lasteditedwhen = NOW()
    WHERE specialdealid = p_special_deal_id;
END;
$$;

COMMENT ON PROCEDURE webapi.login(varchar, varchar, integer, boolean) IS 
'Validates user login credentials';

COMMENT ON PROCEDURE webapi.search_for_stock_items(varchar, integer, integer, refcursor) IS 
'Searches for stock items with pagination';
