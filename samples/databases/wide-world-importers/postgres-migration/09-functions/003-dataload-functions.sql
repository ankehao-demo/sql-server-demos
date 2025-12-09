-- Phase 3: OLTP Code Migration - DataLoadSimulation Schema Functions
-- Converted from SQL Server T-SQL to PostgreSQL PL/pgSQL

-- =============================================
-- Function: DataLoadSimulation.GetAreaCode
-- Description: Returns the area code for a state province
-- =============================================
CREATE OR REPLACE FUNCTION dataload.get_area_code(p_state_province_id integer)
RETURNS varchar(3)
LANGUAGE plpgsql
AS $$
DECLARE
    v_area_code varchar(3);
BEGIN
    -- Simple mapping based on state province ID
    v_area_code := CASE 
        WHEN p_state_province_id BETWEEN 1 AND 10 THEN '212'
        WHEN p_state_province_id BETWEEN 11 AND 20 THEN '312'
        WHEN p_state_province_id BETWEEN 21 AND 30 THEN '415'
        WHEN p_state_province_id BETWEEN 31 AND 40 THEN '713'
        WHEN p_state_province_id BETWEEN 41 AND 50 THEN '305'
        ELSE '800'
    END;
    
    RETURN v_area_code;
END;
$$;

-- =============================================
-- Function: DataLoadSimulation.GetBogativePhoneNumber
-- Description: Generates a fake phone number
-- =============================================
CREATE OR REPLACE FUNCTION dataload.get_bogative_phone_number(p_state_province_id integer)
RETURNS varchar(20)
LANGUAGE plpgsql
AS $$
DECLARE
    v_area_code varchar(3);
    v_exchange varchar(3);
    v_subscriber varchar(4);
BEGIN
    v_area_code := dataload.get_area_code(p_state_province_id);
    v_exchange := lpad((floor(random() * 900) + 100)::text, 3, '0');
    v_subscriber := lpad((floor(random() * 9000) + 1000)::text, 4, '0');
    
    RETURN '(' || v_area_code || ') ' || v_exchange || '-' || v_subscriber;
END;
$$;

-- =============================================
-- Function: DataLoadSimulation.GetCityLocation
-- Description: Returns the geographic location for a city
-- =============================================
CREATE OR REPLACE FUNCTION dataload.get_city_location(p_city_id integer)
RETURNS geography
LANGUAGE plpgsql
AS $$
DECLARE
    v_location geography;
BEGIN
    SELECT location INTO v_location
    FROM application.cities
    WHERE cityid = p_city_id;
    
    RETURN v_location;
END;
$$;

-- =============================================
-- Function: DataLoadSimulation.GetCustomerCount
-- Description: Returns the count of customers
-- =============================================
CREATE OR REPLACE FUNCTION dataload.get_customer_count()
RETURNS integer
LANGUAGE plpgsql
AS $$
DECLARE
    v_count integer;
BEGIN
    SELECT COUNT(*) INTO v_count FROM sales.customers;
    RETURN v_count;
END;
$$;

-- =============================================
-- Function: DataLoadSimulation.GetDeliveryMethodID
-- Description: Returns the delivery method ID for a given name
-- =============================================
CREATE OR REPLACE FUNCTION dataload.get_delivery_method_id(p_delivery_method_name varchar(50))
RETURNS integer
LANGUAGE plpgsql
AS $$
DECLARE
    v_id integer;
BEGIN
    SELECT deliverymethodid INTO v_id
    FROM application.deliverymethods
    WHERE deliverymethodname = p_delivery_method_name;
    
    RETURN v_id;
END;
$$;

-- =============================================
-- Function: DataLoadSimulation.GetPaymentMethodID
-- Description: Returns the payment method ID for a given name
-- =============================================
CREATE OR REPLACE FUNCTION dataload.get_payment_method_id(p_payment_method_name varchar(50))
RETURNS integer
LANGUAGE plpgsql
AS $$
DECLARE
    v_id integer;
BEGIN
    SELECT paymentmethodid INTO v_id
    FROM application.paymentmethods
    WHERE paymentmethodname = p_payment_method_name;
    
    RETURN v_id;
END;
$$;

-- =============================================
-- Function: DataLoadSimulation.GetPersonID
-- Description: Returns the person ID for a given full name
-- =============================================
CREATE OR REPLACE FUNCTION dataload.get_person_id(p_full_name varchar(50))
RETURNS integer
LANGUAGE plpgsql
AS $$
DECLARE
    v_id integer;
BEGIN
    SELECT personid INTO v_id
    FROM application.people
    WHERE fullname = p_full_name;
    
    RETURN v_id;
END;
$$;

-- =============================================
-- Function: DataLoadSimulation.GetStateProvinceID
-- Description: Returns the state province ID for a given name
-- =============================================
CREATE OR REPLACE FUNCTION dataload.get_state_province_id(p_state_province_name varchar(50))
RETURNS integer
LANGUAGE plpgsql
AS $$
DECLARE
    v_id integer;
BEGIN
    SELECT stateprovinceid INTO v_id
    FROM application.stateprovinces
    WHERE stateprovincename = p_state_province_name;
    
    RETURN v_id;
END;
$$;

-- =============================================
-- Function: DataLoadSimulation.GetSupplierCategoryID
-- Description: Returns the supplier category ID for a given name
-- =============================================
CREATE OR REPLACE FUNCTION dataload.get_supplier_category_id(p_supplier_category_name varchar(50))
RETURNS integer
LANGUAGE plpgsql
AS $$
DECLARE
    v_id integer;
BEGIN
    SELECT suppliercategoryid INTO v_id
    FROM purchasing.suppliercategories
    WHERE suppliercategoryname = p_supplier_category_name;
    
    RETURN v_id;
END;
$$;

-- =============================================
-- Function: DataLoadSimulation.GetTransactionTypeID
-- Description: Returns the transaction type ID for a given name
-- =============================================
CREATE OR REPLACE FUNCTION dataload.get_transaction_type_id(p_transaction_type_name varchar(50))
RETURNS integer
LANGUAGE plpgsql
AS $$
DECLARE
    v_id integer;
BEGIN
    SELECT transactiontypeid INTO v_id
    FROM application.transactiontypes
    WHERE transactiontypename = p_transaction_type_name;
    
    RETURN v_id;
END;
$$;

COMMENT ON FUNCTION dataload.get_area_code(integer) IS 
'Returns the area code for a state province';

COMMENT ON FUNCTION dataload.get_bogative_phone_number(integer) IS 
'Generates a fake phone number for a state province';

COMMENT ON FUNCTION dataload.get_city_location(integer) IS 
'Returns the geographic location for a city';

COMMENT ON FUNCTION dataload.get_customer_count() IS 
'Returns the count of customers';

COMMENT ON FUNCTION dataload.get_delivery_method_id(varchar) IS 
'Returns the delivery method ID for a given name';

COMMENT ON FUNCTION dataload.get_payment_method_id(varchar) IS 
'Returns the payment method ID for a given name';

COMMENT ON FUNCTION dataload.get_person_id(varchar) IS 
'Returns the person ID for a given full name';

COMMENT ON FUNCTION dataload.get_state_province_id(varchar) IS 
'Returns the state province ID for a given name';

COMMENT ON FUNCTION dataload.get_supplier_category_id(varchar) IS 
'Returns the supplier category ID for a given name';

COMMENT ON FUNCTION dataload.get_transaction_type_id(varchar) IS 
'Returns the transaction type ID for a given name';
