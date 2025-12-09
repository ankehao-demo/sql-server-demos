-- PostgreSQL equivalent of [WebApi].InsertSuppliersFromJson
-- Converted from T-SQL to PL/pgSQL

CREATE OR REPLACE FUNCTION webapi.insert_suppliers_from_json(
    p_suppliers JSONB,
    p_user_id INTEGER
)
RETURNS TABLE (supplier_id INTEGER)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    RETURN QUERY
    INSERT INTO purchasing.suppliers(
        supplier_name, supplier_category_id, primary_contact_person_id,
        alternate_contact_person_id, delivery_method_id, delivery_city_id,
        postal_city_id, supplier_reference, bank_account_name, bank_account_branch,
        bank_account_code, bank_account_number, bank_international_code,
        payment_days, internal_comments, phone_number, fax_number, website_url,
        delivery_address_line_1, delivery_address_line_2, delivery_postal_code,
        postal_address_line_1, postal_address_line_2, postal_postal_code, last_edited_by
    )
    SELECT 
        (item->>'SupplierName')::VARCHAR(100),
        (item->>'SupplierCategoryID')::INTEGER,
        (item->>'PrimaryContactPersonID')::INTEGER,
        (item->>'AlternateContactPersonID')::INTEGER,
        (item->>'DeliveryMethodID')::INTEGER,
        (item->>'DeliveryCityID')::INTEGER,
        (item->>'PostalCityID')::INTEGER,
        (item->>'SupplierReference')::VARCHAR(20),
        (item->>'BankAccountName')::VARCHAR(50),
        (item->>'BankAccountBranch')::VARCHAR(50),
        (item->>'BankAccountCode')::VARCHAR(20),
        (item->>'BankAccountNumber')::VARCHAR(20),
        (item->>'BankInternationalCode')::VARCHAR(20),
        (item->>'PaymentDays')::INTEGER,
        (item->>'InternalComments')::TEXT,
        (item->>'PhoneNumber')::VARCHAR(20),
        (item->>'FaxNumber')::VARCHAR(20),
        (item->>'WebsiteURL')::VARCHAR(256),
        (item->>'DeliveryAddressLine1')::VARCHAR(60),
        (item->>'DeliveryAddressLine2')::VARCHAR(60),
        (item->>'DeliveryPostalCode')::VARCHAR(10),
        (item->>'PostalAddressLine1')::VARCHAR(60),
        (item->>'PostalAddressLine2')::VARCHAR(60),
        (item->>'PostalPostalCode')::VARCHAR(10),
        p_user_id
    FROM jsonb_array_elements(p_suppliers) AS item
    RETURNING purchasing.suppliers.supplier_id;
END;
$$;

COMMENT ON FUNCTION webapi.insert_suppliers_from_json IS 'Inserts suppliers from JSON array and returns inserted IDs';
