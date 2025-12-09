-- PostgreSQL equivalent of [WebApi].InsertCustomersFromJson
-- Converted from T-SQL to PL/pgSQL

CREATE OR REPLACE FUNCTION webapi.insert_customers_from_json(
    p_customers JSONB,
    p_user_id INTEGER
)
RETURNS TABLE (customer_id INTEGER)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    RETURN QUERY
    INSERT INTO sales.customers(
        customer_name, bill_to_customer_id, customer_category_id, buying_group_id,
        primary_contact_person_id, alternate_contact_person_id, delivery_method_id,
        delivery_city_id, postal_city_id, credit_limit, account_opened_date,
        standard_discount_percentage, is_statement_sent, is_on_credit_hold,
        payment_days, phone_number, fax_number, delivery_run, run_position,
        website_url, delivery_address_line_1, delivery_address_line_2,
        delivery_postal_code, postal_address_line_1, postal_address_line_2,
        postal_postal_code, last_edited_by
    )
    SELECT 
        (item->>'CustomerName')::VARCHAR(100),
        (item->>'BillToCustomerID')::INTEGER,
        (item->>'CustomerCategoryID')::INTEGER,
        (item->>'BuyingGroupID')::INTEGER,
        (item->>'PrimaryContactPersonID')::INTEGER,
        (item->>'AlternateContactPersonID')::INTEGER,
        (item->>'DeliveryMethodID')::INTEGER,
        (item->>'DeliveryCityID')::INTEGER,
        (item->>'PostalCityID')::INTEGER,
        (item->>'CreditLimit')::DECIMAL(18,2),
        (item->>'AccountOpenedDate')::DATE,
        (item->>'StandardDiscountPercentage')::DECIMAL(18,3),
        (item->>'IsStatementSent')::BOOLEAN,
        (item->>'IsOnCreditHold')::BOOLEAN,
        (item->>'PaymentDays')::INTEGER,
        (item->>'PhoneNumber')::VARCHAR(20),
        (item->>'FaxNumber')::VARCHAR(20),
        (item->>'DeliveryRun')::VARCHAR(5),
        (item->>'RunPosition')::VARCHAR(5),
        (item->>'WebsiteURL')::VARCHAR(256),
        (item->>'DeliveryAddressLine1')::VARCHAR(60),
        (item->>'DeliveryAddressLine2')::VARCHAR(60),
        (item->>'DeliveryPostalCode')::VARCHAR(10),
        (item->>'PostalAddressLine1')::VARCHAR(60),
        (item->>'PostalAddressLine2')::VARCHAR(60),
        (item->>'PostalPostalCode')::VARCHAR(10),
        p_user_id
    FROM jsonb_array_elements(p_customers) AS item
    RETURNING sales.customers.customer_id;
END;
$$;

COMMENT ON FUNCTION webapi.insert_customers_from_json IS 'Inserts customers from JSON array and returns inserted IDs';
