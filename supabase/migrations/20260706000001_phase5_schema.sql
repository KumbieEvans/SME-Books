-- Phase 5 Additions: RBAC, Invoices, Expenses, Reporting Views

-- 1. TENANT USERS TABLE (RBAC)
CREATE TABLE tenant_users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID REFERENCES tenants(id) ON DELETE CASCADE NOT NULL,
    user_id UUID NOT NULL, -- references auth.users(id)
    role VARCHAR(50) NOT NULL CHECK (role IN ('Owner', 'Accountant', 'Manager')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    UNIQUE(tenant_id, user_id)
);
ALTER TABLE tenant_users ENABLE ROW LEVEL SECURITY;

CREATE POLICY tenant_users_isolation_policy ON tenant_users
    FOR ALL
    USING (tenant_id = (auth.jwt() -> 'app_metadata' ->> 'tenant_id')::uuid);

-- Note: In a full system, you would update the RLS on journal_entries to check the user's role.
-- e.g., to prevent Managers from modifying past entries:
-- CREATE POLICY journal_entries_update_policy ON journal_entries
--     FOR UPDATE
--     USING (
--       EXISTS (
--         SELECT 1 FROM tenant_users 
--         WHERE user_id = auth.uid() 
--         AND tenant_id = journal_entries.tenant_id 
--         AND role IN ('Owner', 'Accountant')
--       )
--     );

-- 2. INVOICES TABLE
CREATE TABLE invoices (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID REFERENCES tenants(id) ON DELETE CASCADE NOT NULL,
    invoice_number VARCHAR(100) NOT NULL,
    client_name VARCHAR(255) NOT NULL,
    status VARCHAR(50) NOT NULL CHECK (status IN ('Draft', 'Sent', 'Partially Paid', 'Paid', 'Overdue', 'Voided')),
    issue_date DATE NOT NULL,
    due_date DATE,
    total_amount NUMERIC(15, 4) DEFAULT 0.0000 NOT NULL,
    currency_code VARCHAR(3) DEFAULT 'USD' NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    UNIQUE(tenant_id, invoice_number)
);
ALTER TABLE invoices ENABLE ROW LEVEL SECURITY;

CREATE POLICY invoices_isolation_policy ON invoices
    FOR ALL
    USING (tenant_id = (auth.jwt() -> 'app_metadata' ->> 'tenant_id')::uuid);

-- 3. INVOICE LINES TABLE
CREATE TABLE invoice_lines (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID REFERENCES tenants(id) ON DELETE CASCADE NOT NULL,
    invoice_id UUID REFERENCES invoices(id) ON DELETE CASCADE NOT NULL,
    description TEXT NOT NULL,
    quantity NUMERIC(15, 4) DEFAULT 1.0000 NOT NULL,
    unit_price NUMERIC(15, 4) DEFAULT 0.0000 NOT NULL,
    line_total NUMERIC(15, 4) GENERATED ALWAYS AS (quantity * unit_price) STORED
);
ALTER TABLE invoice_lines ENABLE ROW LEVEL SECURITY;

CREATE POLICY invoice_lines_isolation_policy ON invoice_lines
    FOR ALL
    USING (tenant_id = (auth.jwt() -> 'app_metadata' ->> 'tenant_id')::uuid);

-- 4. EXPENSES TABLE (Receipt Capture)
CREATE TABLE expenses (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID REFERENCES tenants(id) ON DELETE CASCADE NOT NULL,
    vendor_name VARCHAR(255) NOT NULL,
    amount NUMERIC(15, 4) NOT NULL,
    currency_code VARCHAR(3) DEFAULT 'USD' NOT NULL,
    receipt_url TEXT, -- Path in Supabase storage
    expense_date DATE NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);
ALTER TABLE expenses ENABLE ROW LEVEL SECURITY;

CREATE POLICY expenses_isolation_policy ON expenses
    FOR ALL
    USING (tenant_id = (auth.jwt() -> 'app_metadata' ->> 'tenant_id')::uuid);

-- 5. REPORTING VIEWS / FUNCTIONS
-- Simple function to get Account Balances for a specific date
CREATE OR REPLACE FUNCTION get_account_balances(p_tenant_id UUID, p_as_of_date DATE)
RETURNS TABLE (
    account_id UUID,
    account_number VARCHAR,
    account_name VARCHAR,
    account_type VARCHAR,
    balance NUMERIC
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    RETURN QUERY
    SELECT 
        a.id,
        a.account_number,
        a.name,
        a.type,
        SUM(
            CASE 
                WHEN a.type IN ('Asset', 'Expense') THEN jl.debit - jl.credit
                ELSE jl.credit - jl.debit
            END
        ) as balance
    FROM accounts a
    LEFT JOIN journal_lines jl ON a.id = jl.account_id
    LEFT JOIN journal_entries je ON jl.journal_entry_id = je.id
    WHERE a.tenant_id = p_tenant_id
      AND je.entry_date <= p_as_of_date
    GROUP BY a.id, a.account_number, a.name, a.type
    ORDER BY a.type, a.account_number;
END;
$$;

-- Function to get Income Statement (Revenue - Expenses) for a date range
CREATE OR REPLACE FUNCTION get_income_statement(p_tenant_id UUID, p_start_date DATE, p_end_date DATE)
RETURNS TABLE (
    account_id UUID,
    account_number VARCHAR,
    account_name VARCHAR,
    account_type VARCHAR,
    balance NUMERIC
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    RETURN QUERY
    SELECT 
        a.id,
        a.account_number,
        a.name,
        a.type,
        SUM(
            CASE 
                WHEN a.type = 'Expense' THEN jl.debit - jl.credit
                WHEN a.type = 'Revenue' THEN jl.credit - jl.debit
                ELSE 0
            END
        ) as balance
    FROM accounts a
    JOIN journal_lines jl ON a.id = jl.account_id
    JOIN journal_entries je ON jl.journal_entry_id = je.id
    WHERE a.tenant_id = p_tenant_id
      AND a.type IN ('Revenue', 'Expense')
      AND je.entry_date >= p_start_date
      AND je.entry_date <= p_end_date
    GROUP BY a.id, a.account_number, a.name, a.type
    ORDER BY a.type DESC, a.account_number;
END;
$$;
