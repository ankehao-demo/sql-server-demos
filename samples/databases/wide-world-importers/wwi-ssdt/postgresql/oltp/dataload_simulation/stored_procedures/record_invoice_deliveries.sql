-- PostgreSQL equivalent of [DataLoadSimulation].RecordInvoiceDeliveries
-- Converted from T-SQL to PL/pgSQL

CREATE OR REPLACE PROCEDURE dataload_simulation.record_invoice_deliveries(
    p_current_date_time TIMESTAMP,
    p_starting_when TIMESTAMP,
    p_end_of_time TIMESTAMP,
    p_is_silent_mode BOOLEAN
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_staff_member_person_id INTEGER;
    v_invoice_id INTEGER;
    v_delivery_data JSONB;
BEGIN
    -- Get a random staff member (driver)
    SELECT person_id INTO v_staff_member_person_id
    FROM application.people
    WHERE is_employee = true
    ORDER BY RANDOM()
    LIMIT 1;
    
    -- Update invoices that are ready for delivery
    FOR v_invoice_id IN
        SELECT invoice_id
        FROM sales.invoices
        WHERE confirmed_delivery_time IS NULL
        AND invoice_date < p_current_date_time::DATE
        ORDER BY invoice_id
        LIMIT FLOOR(RANDOM() * 20 + 10)::INTEGER
    LOOP
        -- Build delivery data JSON
        v_delivery_data := jsonb_build_object(
            'Events', jsonb_build_array(
                jsonb_build_object(
                    'Event', 'DeliveryAttempt',
                    'EventTime', to_char(p_starting_when, 'YYYY-MM-DD"T"HH24:MI:SS'),
                    'Status', 'Delivered',
                    'DeliveredTo', 'Reception'
                )
            ),
            'DeliveredWhen', to_char(p_starting_when, 'YYYY-MM-DD"T"HH24:MI:SS'),
            'ReceivedBy', 'Customer Representative'
        );
        
        -- Update the invoice with delivery information
        UPDATE sales.invoices
        SET confirmed_delivery_time = p_starting_when,
            confirmed_received_by = 'Customer Representative',
            returned_delivery_data = returned_delivery_data || v_delivery_data,
            last_edited_by = v_staff_member_person_id,
            last_edited_when = p_starting_when
        WHERE invoice_id = v_invoice_id;
    END LOOP;
END;
$$;

COMMENT ON PROCEDURE dataload_simulation.record_invoice_deliveries IS 'Simulates recording of invoice deliveries';
