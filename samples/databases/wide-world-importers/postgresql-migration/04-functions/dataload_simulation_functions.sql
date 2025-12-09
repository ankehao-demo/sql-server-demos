-- Wide World Importers PostgreSQL Migration
-- DataLoadSimulation Functions
-- This script creates all functions in the DataLoadSimulation schema

-- GetRandomCity function
CREATE OR REPLACE FUNCTION dataloadSimulation.get_random_city()
RETURNS integer AS $$
DECLARE
    v_cityid integer;
BEGIN
    SELECT cityid INTO v_cityid
    FROM application.cities
    ORDER BY RANDOM()
    LIMIT 1;
    
    RETURN v_cityid;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION dataloadSimulation.get_random_city() IS 'Returns a random city ID';

-- GetRandomCustomer function
CREATE OR REPLACE FUNCTION dataloadSimulation.get_random_customer()
RETURNS integer AS $$
DECLARE
    v_customerid integer;
BEGIN
    SELECT customerid INTO v_customerid
    FROM sales.customers
    WHERE isoncredithold = false
    ORDER BY RANDOM()
    LIMIT 1;
    
    RETURN v_customerid;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION dataloadSimulation.get_random_customer() IS 'Returns a random customer ID (not on credit hold)';

-- GetRandomEmployeePerson function
CREATE OR REPLACE FUNCTION dataloadSimulation.get_random_employee_person()
RETURNS integer AS $$
DECLARE
    v_personid integer;
BEGIN
    SELECT personid INTO v_personid
    FROM application.people
    WHERE isemployee = true
    ORDER BY RANDOM()
    LIMIT 1;
    
    RETURN v_personid;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION dataloadSimulation.get_random_employee_person() IS 'Returns a random employee person ID';

-- GetRandomSalesPersonID function
CREATE OR REPLACE FUNCTION dataloadSimulation.get_random_salesperson_id()
RETURNS integer AS $$
DECLARE
    v_personid integer;
BEGIN
    SELECT personid INTO v_personid
    FROM application.people
    WHERE issalesperson = true
    ORDER BY RANDOM()
    LIMIT 1;
    
    RETURN v_personid;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION dataloadSimulation.get_random_salesperson_id() IS 'Returns a random salesperson ID';

-- GetRandomBuyingGroup function
CREATE OR REPLACE FUNCTION dataloadSimulation.get_random_buying_group()
RETURNS integer AS $$
DECLARE
    v_buyinggroupid integer;
BEGIN
    SELECT buyinggroupid INTO v_buyinggroupid
    FROM sales.buyinggroups
    ORDER BY RANDOM()
    LIMIT 1;
    
    RETURN v_buyinggroupid;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION dataloadSimulation.get_random_buying_group() IS 'Returns a random buying group ID';

-- GetRandomCustomerCategory function
CREATE OR REPLACE FUNCTION dataloadSimulation.get_random_customer_category()
RETURNS integer AS $$
DECLARE
    v_customercategoryid integer;
BEGIN
    SELECT customercategoryid INTO v_customercategoryid
    FROM sales.customercategories
    ORDER BY RANDOM()
    LIMIT 1;
    
    RETURN v_customercategoryid;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION dataloadSimulation.get_random_customer_category() IS 'Returns a random customer category ID';

-- GetRandomDeliveryMethod function
CREATE OR REPLACE FUNCTION dataloadSimulation.get_random_delivery_method()
RETURNS integer AS $$
DECLARE
    v_deliverymethodid integer;
BEGIN
    SELECT deliverymethodid INTO v_deliverymethodid
    FROM application.deliverymethods
    ORDER BY RANDOM()
    LIMIT 1;
    
    RETURN v_deliverymethodid;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION dataloadSimulation.get_random_delivery_method() IS 'Returns a random delivery method ID';

-- GetRandomPaymentDays function
CREATE OR REPLACE FUNCTION dataloadSimulation.get_random_payment_days()
RETURNS integer AS $$
BEGIN
    -- Returns 7, 14, or 30 days randomly
    RETURN (ARRAY[7, 14, 30])[floor(random() * 3 + 1)::int];
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION dataloadSimulation.get_random_payment_days() IS 'Returns a random payment days value (7, 14, or 30)';

-- GetFicticiousName function
CREATE OR REPLACE FUNCTION dataloadSimulation.get_ficticious_name()
RETURNS TABLE (firstname varchar, lastname varchar, fullname varchar) AS $$
BEGIN
    RETURN QUERY
    SELECT f.firstname, f.lastname, f.fullname
    FROM dataloadSimulation.ficticiousnamepool f
    ORDER BY RANDOM()
    LIMIT 1;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION dataloadSimulation.get_ficticious_name() IS 'Returns a random fictitious name';

-- GetRandomStreet function
CREATE OR REPLACE FUNCTION dataloadSimulation.get_random_street()
RETURNS varchar AS $$
DECLARE
    v_street_number integer;
    v_street_name varchar;
    v_street_suffix varchar;
BEGIN
    v_street_number := floor(random() * 9999 + 1)::int;
    v_street_name := (ARRAY['Main', 'Oak', 'Maple', 'Cedar', 'Pine', 'Elm', 'Washington', 'Lake', 'Hill', 'Park', 
                           'River', 'Spring', 'Valley', 'Forest', 'Sunset', 'Highland', 'Meadow', 'Church', 'Mill', 'School'])[floor(random() * 20 + 1)::int];
    v_street_suffix := (ARRAY['Street', 'Avenue', 'Road', 'Boulevard', 'Drive', 'Lane', 'Way', 'Court', 'Place', 'Circle'])[floor(random() * 10 + 1)::int];
    
    RETURN v_street_number || ' ' || v_street_name || ' ' || v_street_suffix;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION dataloadSimulation.get_random_street() IS 'Returns a random street address';

-- GetRandomSecondaryAddress function
CREATE OR REPLACE FUNCTION dataloadSimulation.get_random_secondary_address()
RETURNS varchar AS $$
DECLARE
    v_type varchar;
    v_number integer;
BEGIN
    -- 70% chance of no secondary address
    IF random() < 0.7 THEN
        RETURN NULL;
    END IF;
    
    v_type := (ARRAY['Apt', 'Suite', 'Unit', 'Floor', 'Building'])[floor(random() * 5 + 1)::int];
    v_number := floor(random() * 999 + 1)::int;
    
    RETURN v_type || ' ' || v_number;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION dataloadSimulation.get_random_secondary_address() IS 'Returns a random secondary address (apartment, suite, etc.)';

-- GetBogativePostalCode function
CREATE OR REPLACE FUNCTION dataloadSimulation.get_bogative_postal_code(p_stateprovinceid integer)
RETURNS varchar AS $$
DECLARE
    v_postal_code varchar;
BEGIN
    -- Generate a random 5-digit postal code
    v_postal_code := lpad(floor(random() * 99999 + 1)::text, 5, '0');
    RETURN v_postal_code;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION dataloadSimulation.get_bogative_postal_code(integer) IS 'Returns a random postal code for a state/province';

-- GetRandomStockItemToAdjust function
CREATE OR REPLACE FUNCTION dataloadSimulation.get_random_stock_item_to_adjust()
RETURNS integer AS $$
DECLARE
    v_stockitemid integer;
BEGIN
    SELECT stockitemid INTO v_stockitemid
    FROM warehouse.stockitems
    ORDER BY RANDOM()
    LIMIT 1;
    
    RETURN v_stockitemid;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION dataloadSimulation.get_random_stock_item_to_adjust() IS 'Returns a random stock item ID for adjustment';

-- GetBuyingGroupDomain function
CREATE OR REPLACE FUNCTION dataloadSimulation.get_buying_group_domain(p_buyinggroupid integer)
RETURNS varchar AS $$
DECLARE
    v_domain varchar;
BEGIN
    SELECT lower(replace(buyinggroupname, ' ', '')) || '.com' INTO v_domain
    FROM sales.buyinggroups
    WHERE buyinggroupid = p_buyinggroupid;
    
    RETURN COALESCE(v_domain, 'example.com');
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION dataloadSimulation.get_buying_group_domain(integer) IS 'Returns a domain name based on buying group name';
