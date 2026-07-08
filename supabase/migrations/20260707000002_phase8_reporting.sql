-- Phase 8 Additions: Cash Flow Forecast

CREATE OR REPLACE FUNCTION get_cash_flow_forecast(p_tenant_id UUID, p_days_ahead INT DEFAULT 30)
RETURNS TABLE (
    expected_date DATE,
    expected_inflow NUMERIC,
    expected_outflow NUMERIC
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    RETURN QUERY
    WITH inflows AS (
        SELECT 
            due_date as d_date,
            SUM(total_amount) as amount
        FROM invoices
        WHERE tenant_id = p_tenant_id
          AND status IN ('Sent', 'Partially Paid', 'Overdue', 'Draft') -- including draft for forecasting
          AND due_date IS NOT NULL
          AND due_date >= CURRENT_DATE
          AND due_date <= CURRENT_DATE + p_days_ahead
        GROUP BY due_date
    ),
    outflows AS (
        -- Placeholder for future Accounts Payable/Bills
        SELECT 
            CURRENT_DATE as d_date,
            0::NUMERIC as amount
        WHERE FALSE
    ),
    all_dates AS (
        SELECT d_date FROM inflows
        UNION
        SELECT d_date FROM outflows
    )
    SELECT 
        ad.d_date,
        COALESCE(i.amount, 0),
        COALESCE(o.amount, 0)
    FROM all_dates ad
    LEFT JOIN inflows i ON ad.d_date = i.d_date
    LEFT JOIN outflows o ON ad.d_date = o.d_date
    ORDER BY ad.d_date;
END;
$$;
