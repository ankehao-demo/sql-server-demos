-- PostgreSQL equivalent of [DataLoadSimulation].PerformStocktake
-- Converted from T-SQL to PL/pgSQL

CREATE OR REPLACE PROCEDURE dataload_simulation.perform_stocktake(
    p_current_date_time TIMESTAMP,
    p_starting_when TIMESTAMP,
    p_end_of_time TIMESTAMP,
    p_is_silent_mode BOOLEAN
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_staff_member_person_id INTEGER;
    v_stock_adjustment_type_id INTEGER;
    v_stock_item_id INTEGER;
    v_quantity_on_hand INTEGER;
    v_adjustment INTEGER;
BEGIN
    -- Get a random staff member
    SELECT person_id INTO v_staff_member_person_id
    FROM application.people
    WHERE is_employee = true
    ORDER BY RANDOM()
    LIMIT 1;
    
    -- Get transaction type ID for stock adjustment
    SELECT transaction_type_id INTO v_stock_adjustment_type_id
    FROM application.transaction_types
    WHERE transaction_type_name = 'Stock Adjustment at Stocktake';
    
    -- Perform stocktake adjustments for random items
    FOR v_stock_item_id, v_quantity_on_hand IN
        SELECT sih.stock_item_id, sih.quantity_on_hand
        FROM warehouse.stock_item_holdings sih
        ORDER BY RANDOM()
        LIMIT FLOOR(RANDOM() * 10 + 5)::INTEGER
    LOOP
        -- Calculate a small random adjustment (-5 to +5)
        v_adjustment := FLOOR(RANDOM() * 11 - 5)::INTEGER;
        
        IF v_adjustment <> 0 THEN
            -- Update stock holding
            UPDATE warehouse.stock_item_holdings
            SET quantity_on_hand = quantity_on_hand + v_adjustment,
                last_stocktake_quantity = quantity_on_hand + v_adjustment,
                last_edited_by = v_staff_member_person_id,
                last_edited_when = p_starting_when
            WHERE stock_item_id = v_stock_item_id;
            
            -- Record the transaction
            INSERT INTO warehouse.stock_item_transactions (
                stock_item_id, transaction_type_id, customer_id, invoice_id,
                supplier_id, purchase_order_id, transaction_occurred_when,
                quantity, last_edited_by, last_edited_when
            )
            VALUES (
                v_stock_item_id, v_stock_adjustment_type_id, NULL, NULL,
                NULL, NULL, p_starting_when,
                v_adjustment, v_staff_member_person_id, p_starting_when
            );
        END IF;
    END LOOP;
END;
$$;

COMMENT ON PROCEDURE dataload_simulation.perform_stocktake IS 'Simulates quarterly stocktake with random adjustments';
