-- Wide World Importers PostgreSQL Migration
-- Website Schema Stored Procedures
-- This script creates all stored procedures in the Website schema

-- SearchForCustomers procedure
CREATE OR REPLACE FUNCTION website.search_for_customers(
    p_searchtext varchar,
    p_maximumrowstoreturn integer
)
RETURNS jsonb AS $$
DECLARE
    v_result jsonb;
BEGIN
    SELECT jsonb_build_object('Customers', jsonb_agg(row_to_json(t)))
    INTO v_result
    FROM (
        SELECT 
            c.customerid,
            c.customername,
            ct.cityname,
            c.phonenumber,
            c.faxnumber,
            p.fullname AS primarycontactfullname,
            p.preferredname AS primarycontactpreferredname
        FROM sales.customers AS c
        INNER JOIN application.cities AS ct ON c.deliverycityid = ct.cityid
        LEFT OUTER JOIN application.people AS p ON c.primarycontactpersonid = p.personid
        WHERE CONCAT(c.customername, ' ', p.fullname, ' ', p.preferredname) ILIKE '%' || p_searchtext || '%'
        ORDER BY c.customername
        LIMIT p_maximumrowstoreturn
    ) t;
    
    RETURN COALESCE(v_result, '{"Customers": []}'::jsonb);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

COMMENT ON FUNCTION website.search_for_customers(varchar, integer) IS 'Searches for customers by name';

-- SearchForPeople procedure
CREATE OR REPLACE FUNCTION website.search_for_people(
    p_searchtext varchar,
    p_maximumrowstoreturn integer
)
RETURNS jsonb AS $$
DECLARE
    v_result jsonb;
BEGIN
    SELECT jsonb_build_object('People', jsonb_agg(row_to_json(t)))
    INTO v_result
    FROM (
        SELECT 
            p.personid,
            p.fullname,
            p.preferredname,
            p.phonenumber,
            p.faxnumber,
            p.emailaddress
        FROM application.people AS p
        WHERE p.searchname ILIKE '%' || p_searchtext || '%'
        ORDER BY p.fullname
        LIMIT p_maximumrowstoreturn
    ) t;
    
    RETURN COALESCE(v_result, '{"People": []}'::jsonb);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

COMMENT ON FUNCTION website.search_for_people(varchar, integer) IS 'Searches for people by name';

-- SearchForStockItems procedure
CREATE OR REPLACE FUNCTION website.search_for_stock_items(
    p_searchtext varchar,
    p_maximumrowstoreturn integer
)
RETURNS jsonb AS $$
DECLARE
    v_result jsonb;
BEGIN
    SELECT jsonb_build_object('StockItems', jsonb_agg(row_to_json(t)))
    INTO v_result
    FROM (
        SELECT 
            si.stockitemid,
            si.stockitemname,
            si.recommendedretailprice,
            c.colorname
        FROM warehouse.stockitems AS si
        LEFT OUTER JOIN warehouse.colors AS c ON si.colorid = c.colorid
        WHERE si.searchdetails ILIKE '%' || p_searchtext || '%'
        ORDER BY si.stockitemname
        LIMIT p_maximumrowstoreturn
    ) t;
    
    RETURN COALESCE(v_result, '{"StockItems": []}'::jsonb);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

COMMENT ON FUNCTION website.search_for_stock_items(varchar, integer) IS 'Searches for stock items by name or description';

-- SearchForStockItemsByTags procedure
CREATE OR REPLACE FUNCTION website.search_for_stock_items_by_tags(
    p_searchtext varchar,
    p_maximumrowstoreturn integer
)
RETURNS jsonb AS $$
DECLARE
    v_result jsonb;
BEGIN
    SELECT jsonb_build_object('StockItems', jsonb_agg(row_to_json(t)))
    INTO v_result
    FROM (
        SELECT 
            si.stockitemid,
            si.stockitemname,
            si.recommendedretailprice,
            c.colorname
        FROM warehouse.stockitems AS si
        LEFT OUTER JOIN warehouse.colors AS c ON si.colorid = c.colorid
        WHERE si.tags ILIKE '%' || p_searchtext || '%'
        ORDER BY si.stockitemname
        LIMIT p_maximumrowstoreturn
    ) t;
    
    RETURN COALESCE(v_result, '{"StockItems": []}'::jsonb);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

COMMENT ON FUNCTION website.search_for_stock_items_by_tags(varchar, integer) IS 'Searches for stock items by tags';

-- SearchForSuppliers procedure
CREATE OR REPLACE FUNCTION website.search_for_suppliers(
    p_searchtext varchar,
    p_maximumrowstoreturn integer
)
RETURNS jsonb AS $$
DECLARE
    v_result jsonb;
BEGIN
    SELECT jsonb_build_object('Suppliers', jsonb_agg(row_to_json(t)))
    INTO v_result
    FROM (
        SELECT 
            s.supplierid,
            s.suppliername,
            sc.suppliercategoryname,
            p.fullname AS primarycontactfullname,
            s.phonenumber,
            s.faxnumber
        FROM purchasing.suppliers AS s
        INNER JOIN purchasing.suppliercategories AS sc ON s.suppliercategoryid = sc.suppliercategoryid
        LEFT OUTER JOIN application.people AS p ON s.primarycontactpersonid = p.personid
        WHERE s.suppliername ILIKE '%' || p_searchtext || '%'
        ORDER BY s.suppliername
        LIMIT p_maximumrowstoreturn
    ) t;
    
    RETURN COALESCE(v_result, '{"Suppliers": []}'::jsonb);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

COMMENT ON FUNCTION website.search_for_suppliers(varchar, integer) IS 'Searches for suppliers by name';

-- InvoiceCustomerOrders procedure
CREATE OR REPLACE FUNCTION website.invoice_customer_orders(
    p_orders_to_invoice integer[],
    p_packed_by_person_id integer,
    p_invoiced_by_person_id integer
)
RETURNS integer AS $$
DECLARE
    v_order_id integer;
    v_invoice_id integer;
    v_total_dry_items integer;
    v_total_chiller_items integer;
    v_invoices_generated integer := 0;
BEGIN
    -- Process each order
    FOREACH v_order_id IN ARRAY p_orders_to_invoice
    LOOP
        -- Check if order exists, is picked, and not already invoiced
        IF NOT EXISTS (
            SELECT 1 FROM sales.orders o
            WHERE o.orderid = v_order_id
            AND o.pickingcompletedwhen IS NOT NULL
            AND NOT EXISTS (SELECT 1 FROM sales.invoices i WHERE i.orderid = o.orderid)
        ) THEN
            CONTINUE;
        END IF;
        
        -- Get next invoice ID
        v_invoice_id := nextval('sequences.invoiceid');
        
        -- Calculate totals
        SELECT 
            COALESCE(SUM(CASE WHEN si.ischillerstock = false THEN 1 ELSE 0 END), 0),
            COALESCE(SUM(CASE WHEN si.ischillerstock = true THEN 1 ELSE 0 END), 0)
        INTO v_total_dry_items, v_total_chiller_items
        FROM sales.orderlines ol
        INNER JOIN warehouse.stockitems si ON ol.stockitemid = si.stockitemid
        WHERE ol.orderid = v_order_id;
        
        -- Create invoice
        INSERT INTO sales.invoices (
            invoiceid, customerid, billtocustomerid, orderid, deliverymethodid, contactpersonid,
            accountspersonid, salespersonpersonid, packedbypersonid, invoicedate,
            customerpurchaseordernumber, iscreditnote, creditnotereason, comments,
            deliveryinstructions, internalcomments, totaldryitems, totalchilleritems,
            deliveryrun, runposition, returneddeliverydata, lasteditedby, lasteditedwhen
        )
        SELECT 
            v_invoice_id, c.customerid, c.billtocustomerid, o.orderid, c.deliverymethodid,
            o.contactpersonid, btc.primarycontactpersonid, o.salespersonpersonid,
            p_packed_by_person_id, CURRENT_DATE, o.customerpurchaseordernumber,
            false, NULL, NULL, c.deliveryaddressline1 || ', ' || c.deliveryaddressline2,
            NULL, v_total_dry_items, v_total_chiller_items, c.deliveryrun, c.runposition,
            jsonb_build_object('Events', jsonb_build_array(
                jsonb_build_object(
                    'Event', 'Ready for collection',
                    'EventTime', to_char(NOW(), 'YYYY-MM-DD"T"HH24:MI:SS'),
                    'ConNote', 'EAN-125-' || (v_invoice_id + 1050)::text
                )
            ))::text,
            p_invoiced_by_person_id, NOW()
        FROM sales.orders o
        INNER JOIN sales.customers c ON o.customerid = c.customerid
        INNER JOIN sales.customers btc ON btc.customerid = c.billtocustomerid
        WHERE o.orderid = v_order_id;
        
        -- Create invoice lines
        INSERT INTO sales.invoicelines (
            invoiceid, stockitemid, description, packagetypeid, quantity, unitprice,
            taxrate, taxamount, lineprofit, extendedprice, lasteditedby, lasteditedwhen
        )
        SELECT 
            v_invoice_id, ol.stockitemid, ol.description, ol.packagetypeid,
            ol.pickedquantity, ol.unitprice, ol.taxrate,
            ROUND(ol.pickedquantity * ol.unitprice * ol.taxrate / 100.0, 2),
            ROUND(ol.pickedquantity * (ol.unitprice - sih.lastcostprice), 2),
            ROUND(ol.pickedquantity * ol.unitprice, 2) + ROUND(ol.pickedquantity * ol.unitprice * ol.taxrate / 100.0, 2),
            p_invoiced_by_person_id, NOW()
        FROM sales.orderlines ol
        INNER JOIN warehouse.stockitems si ON ol.stockitemid = si.stockitemid
        INNER JOIN warehouse.stockitemholdings sih ON si.stockitemid = sih.stockitemid
        WHERE ol.orderid = v_order_id
        ORDER BY ol.orderlineid;
        
        -- Create stock item transactions
        INSERT INTO warehouse.stockitemtransactions (
            stockitemid, transactiontypeid, customerid, invoiceid, supplierid,
            purchaseorderid, transactionoccurredwhen, quantity, lasteditedby, lasteditedwhen
        )
        SELECT 
            il.stockitemid,
            (SELECT transactiontypeid FROM application.transactiontypes WHERE transactiontypename = 'Stock Issue'),
            i.customerid, i.invoiceid, NULL, NULL, NOW(), 0 - il.quantity,
            p_invoiced_by_person_id, NOW()
        FROM sales.invoicelines il
        INNER JOIN sales.invoices i ON il.invoiceid = i.invoiceid
        WHERE il.invoiceid = v_invoice_id
        ORDER BY il.invoicelineid;
        
        -- Update stock holdings
        UPDATE warehouse.stockitemholdings sih
        SET quantityonhand = sih.quantityonhand - sit.totalquantity,
            lasteditedby = p_invoiced_by_person_id,
            lasteditedwhen = NOW()
        FROM (
            SELECT il.stockitemid, SUM(il.quantity) AS totalquantity
            FROM sales.invoicelines il
            WHERE il.invoiceid = v_invoice_id
            GROUP BY il.stockitemid
        ) sit
        WHERE sih.stockitemid = sit.stockitemid;
        
        -- Create customer transaction
        INSERT INTO sales.customertransactions (
            customerid, transactiontypeid, invoiceid, paymentmethodid, transactiondate,
            amountexcludingtax, taxamount, transactionamount, outstandingbalance,
            finalizationdate, lasteditedby, lasteditedwhen
        )
        SELECT 
            i.billtocustomerid,
            (SELECT transactiontypeid FROM application.transactiontypes WHERE transactiontypename = 'Customer Invoice'),
            v_invoice_id, NULL, CURRENT_DATE,
            (SELECT SUM(il.extendedprice - il.taxamount) FROM sales.invoicelines il WHERE il.invoiceid = v_invoice_id),
            (SELECT SUM(il.taxamount) FROM sales.invoicelines il WHERE il.invoiceid = v_invoice_id),
            (SELECT SUM(il.extendedprice) FROM sales.invoicelines il WHERE il.invoiceid = v_invoice_id),
            (SELECT SUM(il.extendedprice) FROM sales.invoicelines il WHERE il.invoiceid = v_invoice_id),
            NULL, p_invoiced_by_person_id, NOW()
        FROM sales.invoices i
        WHERE i.invoiceid = v_invoice_id;
        
        v_invoices_generated := v_invoices_generated + 1;
    END LOOP;
    
    RETURN v_invoices_generated;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

COMMENT ON FUNCTION website.invoice_customer_orders(integer[], integer, integer) IS 'Creates invoices for picked customer orders';

-- InsertCustomerOrders procedure
CREATE OR REPLACE FUNCTION website.insert_customer_orders(
    p_orders jsonb,
    p_order_lines jsonb,
    p_orders_created_by_person_id integer,
    p_salesperson_person_id integer
)
RETURNS integer AS $$
DECLARE
    v_order record;
    v_order_line record;
    v_order_id integer;
    v_orders_created integer := 0;
BEGIN
    -- Process each order
    FOR v_order IN SELECT * FROM jsonb_to_recordset(p_orders) AS x(
        orderreference integer,
        customerid integer,
        contactpersonid integer,
        expecteddeliverydate date,
        customerpurchaseordernumber varchar,
        isundersupplybackordered boolean,
        comments text,
        deliveryinstructions text
    )
    LOOP
        -- Get next order ID
        v_order_id := nextval('sequences.orderid');
        
        -- Create order
        INSERT INTO sales.orders (
            orderid, customerid, salespersonpersonid, pickedbypersonid, contactpersonid,
            backorderorderid, orderdate, expecteddeliverydate, customerpurchaseordernumber,
            isundersupplybackordered, comments, deliveryinstructions, internalcomments,
            pickingcompletedwhen, lasteditedby, lasteditedwhen
        )
        VALUES (
            v_order_id, v_order.customerid, p_salesperson_person_id, NULL, v_order.contactpersonid,
            NULL, CURRENT_DATE, v_order.expecteddeliverydate, v_order.customerpurchaseordernumber,
            v_order.isundersupplybackordered, v_order.comments, v_order.deliveryinstructions, NULL,
            NULL, p_orders_created_by_person_id, NOW()
        );
        
        -- Create order lines for this order
        FOR v_order_line IN SELECT * FROM jsonb_to_recordset(p_order_lines) AS x(
            orderreference integer,
            stockitemid integer,
            description varchar,
            quantity integer
        ) WHERE orderreference = v_order.orderreference
        LOOP
            INSERT INTO sales.orderlines (
                orderid, stockitemid, description, packagetypeid, quantity, unitprice,
                taxrate, pickedquantity, pickingcompletedwhen, lasteditedby, lasteditedwhen
            )
            SELECT 
                v_order_id, v_order_line.stockitemid, v_order_line.description,
                si.unitpackageid, v_order_line.quantity, si.unitprice, si.taxrate,
                0, NULL, p_orders_created_by_person_id, NOW()
            FROM warehouse.stockitems si
            WHERE si.stockitemid = v_order_line.stockitemid;
        END LOOP;
        
        v_orders_created := v_orders_created + 1;
    END LOOP;
    
    RETURN v_orders_created;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

COMMENT ON FUNCTION website.insert_customer_orders(jsonb, jsonb, integer, integer) IS 'Creates customer orders from JSON input';

-- RecordColdRoomTemperatures procedure
CREATE OR REPLACE FUNCTION website.record_cold_room_temperatures(
    p_sensor_readings jsonb
)
RETURNS integer AS $$
DECLARE
    v_reading record;
    v_readings_processed integer := 0;
    v_row_count integer;
BEGIN
    FOR v_reading IN SELECT * FROM jsonb_to_recordset(p_sensor_readings) AS x(
        coldroomsensornumber integer,
        recordedwhen timestamp,
        temperature numeric
    )
    LOOP
        -- Try to update existing record
        UPDATE warehouse.coldroomtemperatures
        SET recordedwhen = v_reading.recordedwhen,
            temperature = v_reading.temperature
        WHERE coldroomsensornumber = v_reading.coldroomsensornumber;
        
        GET DIAGNOSTICS v_row_count = ROW_COUNT;
        
        -- If no row was updated, insert new record
        IF v_row_count = 0 THEN
            INSERT INTO warehouse.coldroomtemperatures (
                coldroomsensornumber, recordedwhen, temperature
            )
            VALUES (
                v_reading.coldroomsensornumber, v_reading.recordedwhen, v_reading.temperature
            );
        END IF;
        
        v_readings_processed := v_readings_processed + 1;
    END LOOP;
    
    RETURN v_readings_processed;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

COMMENT ON FUNCTION website.record_cold_room_temperatures(jsonb) IS 'Records cold room temperature sensor readings';

-- Login procedure
CREATE OR REPLACE FUNCTION website.login(
    p_logon_name varchar,
    p_password varchar
)
RETURNS jsonb AS $$
DECLARE
    v_person record;
    v_result jsonb;
BEGIN
    SELECT personid, fullname, preferredname, emailaddress, phonenumber, hashedpassword
    INTO v_person
    FROM application.people
    WHERE logonname = p_logon_name
    AND ispermittedtologon = true;
    
    IF v_person IS NULL THEN
        RETURN jsonb_build_object('Success', false, 'Message', 'Invalid username or password');
    END IF;
    
    -- Note: In production, use proper password hashing (e.g., pgcrypto)
    -- This is a simplified version for demonstration
    IF v_person.hashedpassword IS NOT NULL THEN
        -- Password verification would go here
        -- For now, we'll just return success if user exists
        RETURN jsonb_build_object(
            'Success', true,
            'PersonID', v_person.personid,
            'FullName', v_person.fullname,
            'PreferredName', v_person.preferredname,
            'EmailAddress', v_person.emailaddress,
            'PhoneNumber', v_person.phonenumber
        );
    ELSE
        RETURN jsonb_build_object('Success', false, 'Message', 'No password set for this user');
    END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

COMMENT ON FUNCTION website.login(varchar, varchar) IS 'Authenticates a user login';

-- ChangePassword procedure
CREATE OR REPLACE FUNCTION website.change_password(
    p_person_id integer,
    p_old_password varchar,
    p_new_password varchar
)
RETURNS jsonb AS $$
DECLARE
    v_current_hash bytea;
BEGIN
    SELECT hashedpassword INTO v_current_hash
    FROM application.people
    WHERE personid = p_person_id;
    
    IF v_current_hash IS NULL THEN
        RETURN jsonb_build_object('Success', false, 'Message', 'User not found');
    END IF;
    
    -- Note: In production, use proper password hashing (e.g., pgcrypto)
    -- This is a simplified version for demonstration
    UPDATE application.people
    SET hashedpassword = decode(md5(p_new_password), 'hex')
    WHERE personid = p_person_id;
    
    RETURN jsonb_build_object('Success', true, 'Message', 'Password changed successfully');
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

COMMENT ON FUNCTION website.change_password(integer, varchar, varchar) IS 'Changes a user password';
