-- Phase 3: OLTP Code Migration - Website Schema Stored Procedures
-- Converted from SQL Server T-SQL to PostgreSQL PL/pgSQL

-- =============================================
-- Procedure: Website.ActivateWebsiteLogon
-- Description: Activates a website logon for a person
-- =============================================
CREATE OR REPLACE PROCEDURE website.activate_website_logon(
    p_person_id integer,
    p_logon_name varchar(50),
    p_initial_password varchar(40)
)
LANGUAGE plpgsql
AS $$
BEGIN
    UPDATE application.people
    SET ispermittedtologon = true,
        logonname = p_logon_name,
        hashedpassword = encode(sha256(p_initial_password::bytea), 'hex'),
        lasteditedwhen = NOW()
    WHERE personid = p_person_id;
    
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Person with ID % not found', p_person_id;
    END IF;
END;
$$;

-- =============================================
-- Procedure: Website.ChangePassword
-- Description: Changes a user's password
-- =============================================
CREATE OR REPLACE PROCEDURE website.change_password(
    p_person_id integer,
    p_old_password varchar(40),
    p_new_password varchar(40)
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_current_hash varchar(128);
BEGIN
    SELECT hashedpassword INTO v_current_hash
    FROM application.people
    WHERE personid = p_person_id;
    
    IF v_current_hash IS NULL THEN
        RAISE EXCEPTION 'Person with ID % not found', p_person_id;
    END IF;
    
    IF v_current_hash != encode(sha256(p_old_password::bytea), 'hex') THEN
        RAISE EXCEPTION 'Old password is incorrect';
    END IF;
    
    UPDATE application.people
    SET hashedpassword = encode(sha256(p_new_password::bytea), 'hex'),
        lasteditedwhen = NOW()
    WHERE personid = p_person_id;
END;
$$;

-- =============================================
-- Procedure: Website.InsertCustomerOrders
-- Description: Inserts customer orders from arrays
-- Note: PostgreSQL doesn't have table-valued parameters, so we use arrays or temp tables
-- =============================================
CREATE OR REPLACE PROCEDURE website.insert_customer_orders(
    p_orders_created_by_person_id integer,
    p_salesperson_person_id integer,
    INOUT p_order_ids integer[] DEFAULT NULL
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_order_id integer;
    v_order_ref integer;
    v_customer_id integer;
    v_contact_person_id integer;
    v_expected_delivery_date date;
    v_customer_purchase_order_number varchar(20);
    v_is_undersupply_backordered boolean;
    v_comments text;
    v_delivery_instructions text;
    rec RECORD;
BEGIN
    -- This procedure expects data to be in temp tables:
    -- temp_orders (order_reference, customer_id, contact_person_id, expected_delivery_date, 
    --              customer_purchase_order_number, is_undersupply_backordered, comments, delivery_instructions)
    -- temp_order_lines (order_reference, stock_item_id, description, quantity)
    
    p_order_ids := ARRAY[]::integer[];
    
    -- Process each order from temp_orders
    FOR rec IN SELECT * FROM temp_orders
    LOOP
        -- Get next order ID
        v_order_id := nextval('sequences.orderid');
        p_order_ids := array_append(p_order_ids, v_order_id);
        
        -- Insert the order
        INSERT INTO sales.orders (
            orderid, customerid, salespersonpersonid, pickedbypersonid, contactpersonid,
            backorderorderid, orderdate, expecteddeliverydate, customerpurchaseordernumber,
            isundersupplybackordered, comments, deliveryinstructions, internalcomments,
            pickingcompletedwhen, lasteditedby, lasteditedwhen
        )
        VALUES (
            v_order_id, rec.customer_id, p_salesperson_person_id, NULL, rec.contact_person_id,
            NULL, NOW(), rec.expected_delivery_date, rec.customer_purchase_order_number,
            rec.is_undersupply_backordered, rec.comments, rec.delivery_instructions, NULL,
            NULL, p_orders_created_by_person_id, NOW()
        );
        
        -- Insert order lines
        INSERT INTO sales.orderlines (
            orderid, stockitemid, description, packagetypeid, quantity, unitprice,
            taxrate, pickedquantity, pickingcompletedwhen, lasteditedby, lasteditedwhen
        )
        SELECT 
            v_order_id, ol.stock_item_id, ol.description, si.unitpackageid, ol.quantity,
            website.calculate_customer_price(rec.customer_id, ol.stock_item_id, NOW()::date),
            si.taxrate, 0, NULL, p_orders_created_by_person_id, NOW()
        FROM temp_order_lines ol
        INNER JOIN warehouse.stockitems si ON ol.stock_item_id = si.stockitemid
        WHERE ol.order_reference = rec.order_reference;
    END LOOP;
    
EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'Unable to create the customer orders: %', SQLERRM;
        RAISE;
END;
$$;

-- =============================================
-- Procedure: Website.InvoiceCustomerOrders
-- Description: Creates invoices for picked orders
-- =============================================
CREATE OR REPLACE PROCEDURE website.invoice_customer_orders(
    p_order_ids integer[],
    p_packed_by_person_id integer,
    p_invoiced_by_person_id integer
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_invoice_id integer;
    v_order_id integer;
    v_total_dry_items integer;
    v_total_chiller_items integer;
    v_stock_issue_type_id integer;
    v_customer_invoice_type_id integer;
    rec RECORD;
BEGIN
    -- Get transaction type IDs
    SELECT transactiontypeid INTO v_stock_issue_type_id
    FROM application.transactiontypes WHERE transactiontypename = 'Stock Issue';
    
    SELECT transactiontypeid INTO v_customer_invoice_type_id
    FROM application.transactiontypes WHERE transactiontypename = 'Customer Invoice';
    
    -- Process each order
    FOREACH v_order_id IN ARRAY p_order_ids
    LOOP
        -- Check if order exists, is picked, and not already invoiced
        IF NOT EXISTS (
            SELECT 1 FROM sales.orders o
            WHERE o.orderid = v_order_id
            AND o.pickingcompletedwhen IS NOT NULL
            AND NOT EXISTS (SELECT 1 FROM sales.invoices i WHERE i.orderid = v_order_id)
        ) THEN
            RAISE EXCEPTION 'Order % either does not exist, is not picked, or is already invoiced', v_order_id;
        END IF;
        
        -- Calculate totals
        SELECT 
            COALESCE(SUM(CASE WHEN si.ischillerstock THEN 0 ELSE 1 END), 0),
            COALESCE(SUM(CASE WHEN si.ischillerstock THEN 1 ELSE 0 END), 0)
        INTO v_total_dry_items, v_total_chiller_items
        FROM sales.orderlines ol
        INNER JOIN warehouse.stockitems si ON ol.stockitemid = si.stockitemid
        WHERE ol.orderid = v_order_id;
        
        -- Get next invoice ID
        v_invoice_id := nextval('sequences.invoiceid');
        
        -- Insert invoice
        INSERT INTO sales.invoices (
            invoiceid, customerid, billtocustomerid, orderid, deliverymethodid,
            contactpersonid, accountspersonid, salespersonpersonid, packedbypersonid,
            invoicedate, customerpurchaseordernumber, iscreditnote, creditnotereason,
            comments, deliveryinstructions, internalcomments, totaldryitems, totalchilleritems,
            deliveryrun, runposition, returneddeliverydata, lasteditedby, lasteditedwhen
        )
        SELECT 
            v_invoice_id, c.customerid, c.billtocustomerid, v_order_id, c.deliverymethodid,
            o.contactpersonid, btc.primarycontactpersonid, o.salespersonpersonid, p_packed_by_person_id,
            NOW(), o.customerpurchaseordernumber, false, NULL,
            NULL, c.deliveryaddressline1 || ', ' || c.deliveryaddressline2, NULL,
            v_total_dry_items, v_total_chiller_items, c.deliveryrun, c.runposition,
            jsonb_build_object('Events', jsonb_build_array(
                jsonb_build_object(
                    'Event', 'Ready for collection',
                    'EventTime', to_char(NOW(), 'YYYY-MM-DD"T"HH24:MI:SS'),
                    'ConNote', 'EAN-125-' || (v_invoice_id + 1050)::text
                )
            )),
            p_invoiced_by_person_id, NOW()
        FROM sales.orders o
        INNER JOIN sales.customers c ON o.customerid = c.customerid
        INNER JOIN sales.customers btc ON btc.customerid = c.billtocustomerid
        WHERE o.orderid = v_order_id;
        
        -- Insert invoice lines
        INSERT INTO sales.invoicelines (
            invoiceid, stockitemid, description, packagetypeid, quantity, unitprice,
            taxrate, taxamount, lineprofit, extendedprice, lasteditedby, lasteditedwhen
        )
        SELECT 
            v_invoice_id, ol.stockitemid, ol.description, ol.packagetypeid,
            ol.pickedquantity, ol.unitprice, ol.taxrate,
            ROUND(ol.pickedquantity * ol.unitprice * ol.taxrate / 100.0, 2),
            ROUND(ol.pickedquantity * (ol.unitprice - sih.lastcostprice), 2),
            ROUND(ol.pickedquantity * ol.unitprice, 2) + 
                ROUND(ol.pickedquantity * ol.unitprice * ol.taxrate / 100.0, 2),
            p_invoiced_by_person_id, NOW()
        FROM sales.orderlines ol
        INNER JOIN warehouse.stockitems si ON ol.stockitemid = si.stockitemid
        INNER JOIN warehouse.stockitemholdings sih ON si.stockitemid = sih.stockitemid
        WHERE ol.orderid = v_order_id
        ORDER BY ol.orderlineid;
        
        -- Insert stock item transactions
        INSERT INTO warehouse.stockitemtransactions (
            stockitemid, transactiontypeid, customerid, invoiceid, supplierid,
            purchaseorderid, transactionoccurredwhen, quantity, lasteditedby, lasteditedwhen
        )
        SELECT 
            il.stockitemid, v_stock_issue_type_id, i.customerid, i.invoiceid, NULL, NULL,
            NOW(), 0 - il.quantity, p_invoiced_by_person_id, NOW()
        FROM sales.invoicelines il
        INNER JOIN sales.invoices i ON il.invoiceid = i.invoiceid
        WHERE il.invoiceid = v_invoice_id
        ORDER BY il.invoicelineid;
        
        -- Update stock holdings
        UPDATE warehouse.stockitemholdings sih
        SET quantityonhand = sih.quantityonhand - totals.total_quantity,
            lasteditedby = p_invoiced_by_person_id,
            lasteditedwhen = NOW()
        FROM (
            SELECT il.stockitemid, SUM(il.quantity) AS total_quantity
            FROM sales.invoicelines il
            WHERE il.invoiceid = v_invoice_id
            GROUP BY il.stockitemid
        ) totals
        WHERE sih.stockitemid = totals.stockitemid;
        
        -- Insert customer transaction
        INSERT INTO sales.customertransactions (
            customerid, transactiontypeid, invoiceid, paymentmethodid,
            transactiondate, amountexcludingtax, taxamount, transactionamount,
            outstandingbalance, finalizationdate, lasteditedby, lasteditedwhen
        )
        SELECT 
            i.billtocustomerid, v_customer_invoice_type_id, v_invoice_id, NULL,
            NOW(),
            (SELECT SUM(il.extendedprice - il.taxamount) FROM sales.invoicelines il WHERE il.invoiceid = v_invoice_id),
            (SELECT SUM(il.taxamount) FROM sales.invoicelines il WHERE il.invoiceid = v_invoice_id),
            (SELECT SUM(il.extendedprice) FROM sales.invoicelines il WHERE il.invoiceid = v_invoice_id),
            (SELECT SUM(il.extendedprice) FROM sales.invoicelines il WHERE il.invoiceid = v_invoice_id),
            NULL, p_invoiced_by_person_id, NOW()
        FROM sales.invoices i
        WHERE i.invoiceid = v_invoice_id;
    END LOOP;
    
EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'Unable to invoice these orders: %', SQLERRM;
        RAISE;
END;
$$;

-- =============================================
-- Procedure: Website.RecordColdRoomTemperatures
-- Description: Records cold room temperature readings
-- =============================================
CREATE OR REPLACE PROCEDURE website.record_cold_room_temperatures(
    p_sensor_readings jsonb
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_sensor_number integer;
    v_recorded_when timestamp;
    v_temperature numeric(18,2);
    v_row_count integer;
    rec RECORD;
BEGIN
    -- Process each sensor reading from the JSONB array
    FOR rec IN SELECT * FROM jsonb_to_recordset(p_sensor_readings) AS x(
        cold_room_sensor_number integer,
        recorded_when timestamp,
        temperature numeric(18,2)
    )
    LOOP
        -- Try to update existing record
        UPDATE warehouse.coldroomtemperatures
        SET recordedwhen = rec.recorded_when,
            temperature = rec.temperature
        WHERE coldroomsensornumber = rec.cold_room_sensor_number;
        
        GET DIAGNOSTICS v_row_count = ROW_COUNT;
        
        -- If no row was updated, insert a new one
        IF v_row_count = 0 THEN
            INSERT INTO warehouse.coldroomtemperatures (
                coldroomsensornumber, recordedwhen, temperature
            )
            VALUES (rec.cold_room_sensor_number, rec.recorded_when, rec.temperature);
        END IF;
    END LOOP;
    
EXCEPTION
    WHEN OTHERS THEN
        RAISE EXCEPTION 'Unable to apply the sensor data: %', SQLERRM
            USING ERRCODE = '51000';
END;
$$;

-- =============================================
-- Procedure: Website.RecordVehicleTemperature
-- Description: Records vehicle temperature readings
-- =============================================
CREATE OR REPLACE PROCEDURE website.record_vehicle_temperature(
    p_vehicle_registration varchar(20),
    p_chiller_sensor_number integer,
    p_recorded_when timestamp,
    p_temperature numeric(10,2),
    p_full_sensor_data varchar(1000) DEFAULT NULL,
    p_is_compressed boolean DEFAULT false,
    p_compressed_sensor_data bytea DEFAULT NULL
)
LANGUAGE plpgsql
AS $$
BEGIN
    INSERT INTO warehouse.vehicletemperatures (
        vehicleregistration, chillersensornumber, recordedwhen, temperature,
        fullsensordata, iscompressed, compressedsensordata
    )
    VALUES (
        p_vehicle_registration, p_chiller_sensor_number, p_recorded_when, p_temperature,
        p_full_sensor_data, p_is_compressed, p_compressed_sensor_data
    );
    
EXCEPTION
    WHEN OTHERS THEN
        RAISE EXCEPTION 'Unable to record vehicle temperature: %', SQLERRM;
END;
$$;

-- =============================================
-- Procedure: Website.SearchForCustomers
-- Description: Searches for customers by name
-- =============================================
CREATE OR REPLACE PROCEDURE website.search_for_customers(
    p_search_text varchar(1000),
    p_max_rows_to_return integer DEFAULT 10,
    INOUT p_results refcursor DEFAULT NULL
)
LANGUAGE plpgsql
AS $$
BEGIN
    OPEN p_results FOR
    SELECT c.customerid, c.customername, c.deliveryaddressline1, c.deliveryaddressline2,
           c.deliverycityid, ct.cityname AS deliverycity
    FROM sales.customers c
    INNER JOIN application.cities ct ON c.deliverycityid = ct.cityid
    WHERE c.customername ILIKE '%' || p_search_text || '%'
       OR c.deliveryaddressline1 ILIKE '%' || p_search_text || '%'
       OR c.deliveryaddressline2 ILIKE '%' || p_search_text || '%'
    ORDER BY c.customername
    LIMIT p_max_rows_to_return;
END;
$$;

-- =============================================
-- Procedure: Website.SearchForPeople
-- Description: Searches for people by name
-- =============================================
CREATE OR REPLACE PROCEDURE website.search_for_people(
    p_search_text varchar(1000),
    p_max_rows_to_return integer DEFAULT 10,
    INOUT p_results refcursor DEFAULT NULL
)
LANGUAGE plpgsql
AS $$
BEGIN
    OPEN p_results FOR
    SELECT p.personid, p.fullname, p.preferredname, p.emailaddress, p.phonenumber
    FROM application.people p
    WHERE p.searchname ILIKE '%' || p_search_text || '%'
       OR p.fullname ILIKE '%' || p_search_text || '%'
       OR p.preferredname ILIKE '%' || p_search_text || '%'
    ORDER BY p.fullname
    LIMIT p_max_rows_to_return;
END;
$$;

-- =============================================
-- Procedure: Website.SearchForStockItems
-- Description: Searches for stock items by name or tags
-- =============================================
CREATE OR REPLACE PROCEDURE website.search_for_stock_items(
    p_search_text varchar(1000),
    p_max_rows_to_return integer DEFAULT 10,
    INOUT p_results refcursor DEFAULT NULL
)
LANGUAGE plpgsql
AS $$
BEGIN
    OPEN p_results FOR
    SELECT si.stockitemid, si.stockitemname, si.unitprice, si.recommendedretailprice,
           si.taxrate, si.searchdetails
    FROM warehouse.stockitems si
    WHERE si.stockitemname ILIKE '%' || p_search_text || '%'
       OR si.searchdetails ILIKE '%' || p_search_text || '%'
       OR si.marketingcomments ILIKE '%' || p_search_text || '%'
    ORDER BY si.stockitemname
    LIMIT p_max_rows_to_return;
END;
$$;

-- =============================================
-- Procedure: Website.SearchForStockItemsByTags
-- Description: Searches for stock items by tags (JSONB)
-- =============================================
CREATE OR REPLACE PROCEDURE website.search_for_stock_items_by_tags(
    p_search_tag varchar(100),
    p_max_rows_to_return integer DEFAULT 10,
    INOUT p_results refcursor DEFAULT NULL
)
LANGUAGE plpgsql
AS $$
BEGIN
    OPEN p_results FOR
    SELECT si.stockitemid, si.stockitemname, si.unitprice, si.recommendedretailprice,
           si.taxrate, si.tags
    FROM warehouse.stockitems si
    WHERE si.tags ? p_search_tag
       OR si.tags @> jsonb_build_array(p_search_tag)
    ORDER BY si.stockitemname
    LIMIT p_max_rows_to_return;
END;
$$;

-- =============================================
-- Procedure: Website.SearchForSuppliers
-- Description: Searches for suppliers by name
-- =============================================
CREATE OR REPLACE PROCEDURE website.search_for_suppliers(
    p_search_text varchar(1000),
    p_max_rows_to_return integer DEFAULT 10,
    INOUT p_results refcursor DEFAULT NULL
)
LANGUAGE plpgsql
AS $$
BEGIN
    OPEN p_results FOR
    SELECT s.supplierid, s.suppliername, s.deliveryaddressline1, s.deliveryaddressline2,
           s.deliverycityid, ct.cityname AS deliverycity
    FROM purchasing.suppliers s
    INNER JOIN application.cities ct ON s.deliverycityid = ct.cityid
    WHERE s.suppliername ILIKE '%' || p_search_text || '%'
       OR s.deliveryaddressline1 ILIKE '%' || p_search_text || '%'
       OR s.deliveryaddressline2 ILIKE '%' || p_search_text || '%'
    ORDER BY s.suppliername
    LIMIT p_max_rows_to_return;
END;
$$;

COMMENT ON PROCEDURE website.activate_website_logon(integer, varchar, varchar) IS 
'Activates a website logon for a person';

COMMENT ON PROCEDURE website.change_password(integer, varchar, varchar) IS 
'Changes a user password after verifying the old password';

COMMENT ON PROCEDURE website.insert_customer_orders(integer, integer, integer[]) IS 
'Inserts customer orders from temp tables (temp_orders and temp_order_lines)';

COMMENT ON PROCEDURE website.invoice_customer_orders(integer[], integer, integer) IS 
'Creates invoices for picked orders';

COMMENT ON PROCEDURE website.record_cold_room_temperatures(jsonb) IS 
'Records cold room temperature readings from JSONB array';

COMMENT ON PROCEDURE website.record_vehicle_temperature(varchar, integer, timestamp, numeric, varchar, boolean, bytea) IS 
'Records a vehicle temperature reading';
