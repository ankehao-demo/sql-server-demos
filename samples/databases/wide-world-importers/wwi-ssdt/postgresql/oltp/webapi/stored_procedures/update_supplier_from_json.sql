-- PostgreSQL equivalent of [WebApi].UpdateSupplierFromJson
-- Converted from T-SQL to PL/pgSQL

CREATE OR REPLACE PROCEDURE webapi.update_supplier_from_json(
    p_supplier JSONB,
    p_supplier_id INTEGER,
    p_user_id INTEGER
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    UPDATE purchasing.suppliers SET
        supplier_name = COALESCE((p_supplier->>'SupplierName')::VARCHAR(100), supplier_name),
        supplier_category_id = COALESCE((p_supplier->>'SupplierCategoryID')::INTEGER, supplier_category_id),
        primary_contact_person_id = COALESCE((p_supplier->>'PrimaryContactPersonID')::INTEGER, primary_contact_person_id),
        alternate_contact_person_id = (p_supplier->>'AlternateContactPersonID')::INTEGER,
        delivery_method_id = (p_supplier->>'DeliveryMethodID')::INTEGER,
        delivery_city_id = COALESCE((p_supplier->>'DeliveryCityID')::INTEGER, delivery_city_id),
        postal_city_id = COALESCE((p_supplier->>'PostalCityID')::INTEGER, postal_city_id),
        supplier_reference = (p_supplier->>'SupplierReference')::VARCHAR(20),
        bank_account_name = (p_supplier->>'BankAccountName')::VARCHAR(50),
        bank_account_branch = (p_supplier->>'BankAccountBranch')::VARCHAR(50),
        bank_account_code = (p_supplier->>'BankAccountCode')::VARCHAR(20),
        bank_account_number = (p_supplier->>'BankAccountNumber')::VARCHAR(20),
        bank_international_code = (p_supplier->>'BankInternationalCode')::VARCHAR(20),
        payment_days = COALESCE((p_supplier->>'PaymentDays')::INTEGER, payment_days),
        internal_comments = (p_supplier->>'InternalComments')::TEXT,
        phone_number = COALESCE((p_supplier->>'PhoneNumber')::VARCHAR(20), phone_number),
        fax_number = COALESCE((p_supplier->>'FaxNumber')::VARCHAR(20), fax_number),
        website_url = COALESCE((p_supplier->>'WebsiteURL')::VARCHAR(256), website_url),
        delivery_address_line_1 = COALESCE((p_supplier->>'DeliveryAddressLine1')::VARCHAR(60), delivery_address_line_1),
        delivery_address_line_2 = (p_supplier->>'DeliveryAddressLine2')::VARCHAR(60),
        delivery_postal_code = COALESCE((p_supplier->>'DeliveryPostalCode')::VARCHAR(10), delivery_postal_code),
        postal_address_line_1 = COALESCE((p_supplier->>'PostalAddressLine1')::VARCHAR(60), postal_address_line_1),
        postal_address_line_2 = (p_supplier->>'PostalAddressLine2')::VARCHAR(60),
        postal_postal_code = COALESCE((p_supplier->>'PostalPostalCode')::VARCHAR(10), postal_postal_code),
        last_edited_by = p_user_id
    WHERE supplier_id = p_supplier_id;
END;
$$;

COMMENT ON PROCEDURE webapi.update_supplier_from_json IS 'Updates a supplier from JSON';
