-- PostgreSQL equivalent of [DataLoadSimulation].GetRandomPaymentDays
-- Converted from T-SQL to PL/pgSQL

CREATE OR REPLACE PROCEDURE dataload_simulation.get_random_payment_days(
    INOUT p_random_payment_days INTEGER
)
LANGUAGE plpgsql
AS $$
BEGIN
    -- Generate random payment days (7, 14, 30, or 60 days)
    SELECT (ARRAY[7, 14, 30, 60])[FLOOR(RANDOM() * 4 + 1)::INTEGER]
    INTO p_random_payment_days;
END;
$$;

COMMENT ON PROCEDURE dataload_simulation.get_random_payment_days IS 'Selects a random payment days value';
