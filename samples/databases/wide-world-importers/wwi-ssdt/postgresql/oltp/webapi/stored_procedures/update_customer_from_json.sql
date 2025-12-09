-- PostgreSQL equivalent of [WebApi].UpdateCustomerFromJson
-- Converted from T-SQL to PL/pgSQL

CREATE OR REPLACE PROCEDURE webapi.update_customer_from_json(
    p_customer JSONB,
    p_customer_id INTEGER,
    p_user_id INTEGER
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    UPDATE sales.customers SET
        customer_name = COALESCE((p_customer->>'CustomerName')::VARCHAR(100), customer_name),
        bill_to_customer_id = COALESCE((p_customer->>'BillToCustomerID')::INTEGER, bill_to_customer_id),
        customer_category_id = COALESCE((p_customer->>'CustomerCategoryID')::INTEGER, customer_category_id),
        buying_group_id = (p_customer->>'BuyingGroupID')::INTEGER,
        primary_contact_person_id = COALESCE((p_customer->>'PrimaryContactPersonID')::INTEGER, primary_contact_person_id),
        alternate_contact_person_id = COALESCE((p_customer->>'AlternateContactPersonID')::INTEGER, alternate_contact_person_id),
        delivery_method_id = COALESCE((p_customer->>'DeliveryMethodID')::INTEGER, delivery_method_id),
        delivery_city_id = COALESCE((p_customer->>'DeliveryCityID')::INTEGER, delivery_city_id),
        postal_city_id = COALESCE((p_customer->>'PostalCityID')::INTEGER, postal_city_id),
        credit_limit = (p_customer->>'CreditLimit')::DECIMAL(18,2),
        account_opened_date = COALESCE((p_customer->>'AccountOpenedDate')::DATE, account_opened_date),
        standard_discount_percentage = COALESCE((p_customer->>'StandardDiscountPercentage')::DECIMAL(18,3), standard_discount_percentage),
        is_statement_sent = COALESCE((p_customer->>'IsStatementSent')::BOOLEAN, is_statement_sent),
        is_on_credit_hold = COALESCE((p_customer->>'IsOnCreditHold')::BOOLEAN, is_on_credit_hold),
        payment_days = COALESCE((p_customer->>'PaymentDays')::INTEGER, payment_days),
        phone_number = COALESCE((p_customer->>'PhoneNumber')::VARCHAR(20), phone_number),
        fax_number = COALESCE((p_customer->>'FaxNumber')::VARCHAR(20), fax_number),
        delivery_run = (p_customer->>'DeliveryRun')::VARCHAR(5),
        run_position = (p_customer->>'RunPosition')::VARCHAR(5),
        website_url = COALESCE((p_customer->>'WebsiteURL')::VARCHAR(256), website_url),
        delivery_address_line_1 = COALESCE((p_customer->>'DeliveryAddressLine1')::VARCHAR(60), delivery_address_line_1),
        delivery_address_line_2 = (p_customer->>'DeliveryAddressLine2')::VARCHAR(60),
        delivery_postal_code = COALESCE((p_customer->>'DeliveryPostalCode')::VARCHAR(10), delivery_postal_code),
        postal_address_line_1 = COALESCE((p_customer->>'PostalAddressLine1')::VARCHAR(60), postal_address_line_1),
        postal_address_line_2 = (p_customer->>'PostalAddressLine2')::VARCHAR(60),
        postal_postal_code = COALESCE((p_customer->>'PostalPostalCode')::VARCHAR(10), postal_postal_code),
        last_edited_by = p_user_id
    WHERE customer_id = p_customer_id;
END;
$$;

COMMENT ON PROCEDURE webapi.update_customer_from_json IS 'Updates a customer from JSON';
