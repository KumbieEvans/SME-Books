-- 1. TENANTS TABLE
CREATE TABLE tenants (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_name VARCHAR(255) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- Enable RLS for Tenants
ALTER TABLE tenants ENABLE ROW LEVEL SECURITY;

CREATE POLICY tenant_isolation_policy ON tenants
    FOR ALL
    USING (id = (auth.jwt() -> 'app_metadata' ->> 'tenant_id')::uuid);

-- 2. ACCOUNTS TABLE (Chart of Accounts)
CREATE TABLE accounts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID REFERENCES tenants(id) ON DELETE CASCADE NOT NULL,
    account_number VARCHAR(50) NOT NULL,
    name VARCHAR(100) NOT NULL,
    type VARCHAR(50) NOT NULL, -- Asset, Liability, Equity, Revenue, Expense
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    UNIQUE(tenant_id, account_number)
);
ALTER TABLE accounts ENABLE ROW LEVEL SECURITY;

CREATE POLICY accounts_tenant_isolation_policy ON accounts
    FOR ALL
    USING (tenant_id = (auth.jwt() -> 'app_metadata' ->> 'tenant_id')::uuid);

-- 3. JOURNAL ENTRIES TABLE (The Header)
CREATE TABLE journal_entries (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID REFERENCES tenants(id) ON DELETE CASCADE NOT NULL,
    entry_date DATE NOT NULL,
    description TEXT,
    currency_code VARCHAR(3) DEFAULT 'USD' NOT NULL,
    exchange_rate NUMERIC(15, 6) DEFAULT 1.000000 NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);
ALTER TABLE journal_entries ENABLE ROW LEVEL SECURITY;

CREATE POLICY journal_entries_tenant_isolation_policy ON journal_entries
    FOR ALL
    USING (tenant_id = (auth.jwt() -> 'app_metadata' ->> 'tenant_id')::uuid);

-- 4. JOURNAL LINES TABLE (The Double-Entry Items)
CREATE TABLE journal_lines (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID REFERENCES tenants(id) ON DELETE CASCADE NOT NULL,
    journal_entry_id UUID REFERENCES journal_entries(id) ON DELETE CASCADE NOT NULL,
    account_id UUID REFERENCES accounts(id) NOT NULL,
    debit NUMERIC(15, 4) DEFAULT 0.0000 NOT NULL,
    credit NUMERIC(15, 4) DEFAULT 0.0000 NOT NULL,
    CONSTRAINT check_debit_credit CHECK (
        (debit > 0 AND credit = 0) OR (credit > 0 AND debit = 0)
    )
);
ALTER TABLE journal_lines ENABLE ROW LEVEL SECURITY;

CREATE POLICY journal_lines_tenant_isolation_policy ON journal_lines
    FOR ALL
    USING (tenant_id = (auth.jwt() -> 'app_metadata' ->> 'tenant_id')::uuid);

-- 5. RPC Function for Double-Entry Journal Creation
CREATE OR REPLACE FUNCTION create_journal_entry(
    p_tenant_id UUID,
    p_entry_date DATE,
    p_description TEXT,
    p_currency_code VARCHAR(3),
    p_exchange_rate NUMERIC(15, 6),
    p_lines JSONB -- Array of { "account_id": UUID, "debit": NUMERIC, "credit": NUMERIC }
) RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_journal_entry_id UUID;
    v_total_debit NUMERIC := 0;
    v_total_credit NUMERIC := 0;
    v_line JSONB;
BEGIN
    -- Validate that total debit equals total credit
    FOR v_line IN SELECT * FROM jsonb_array_elements(p_lines)
    LOOP
        v_total_debit := v_total_debit + COALESCE((v_line->>'debit')::NUMERIC, 0);
        v_total_credit := v_total_credit + COALESCE((v_line->>'credit')::NUMERIC, 0);
    END LOOP;

    IF v_total_debit <> v_total_credit THEN
        RAISE EXCEPTION 'Journal entry unbalanced: Debits (%) must equal Credits (%)', v_total_debit, v_total_credit;
    END IF;

    -- Insert the journal entry
    INSERT INTO journal_entries (tenant_id, entry_date, description, currency_code, exchange_rate)
    VALUES (p_tenant_id, p_entry_date, p_description, p_currency_code, p_exchange_rate)
    RETURNING id INTO v_journal_entry_id;

    -- Insert the journal lines
    FOR v_line IN SELECT * FROM jsonb_array_elements(p_lines)
    LOOP
        INSERT INTO journal_lines (tenant_id, journal_entry_id, account_id, debit, credit)
        VALUES (
            p_tenant_id,
            v_journal_entry_id,
            (v_line->>'account_id')::UUID,
            COALESCE((v_line->>'debit')::NUMERIC, 0),
            COALESCE((v_line->>'credit')::NUMERIC, 0)
        );
    END LOOP;

    RETURN v_journal_entry_id;
END;
$$;

-- 6. Trigger to create default Chart of Accounts for new tenants
CREATE OR REPLACE FUNCTION create_default_accounts()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    -- Asset Accounts
    INSERT INTO accounts (tenant_id, account_number, name, type) VALUES
    (NEW.id, '1000', 'Cash', 'Asset'),
    (NEW.id, '1200', 'Accounts Receivable', 'Asset'),
    (NEW.id, '1500', 'Inventory', 'Asset');

    -- Liability Accounts
    INSERT INTO accounts (tenant_id, account_number, name, type) VALUES
    (NEW.id, '2000', 'Accounts Payable', 'Liability'),
    (NEW.id, '2100', 'Short-term Loans', 'Liability');

    -- Equity Accounts
    INSERT INTO accounts (tenant_id, account_number, name, type) VALUES
    (NEW.id, '3000', 'Owner Equity', 'Equity'),
    (NEW.id, '3100', 'Retained Earnings', 'Equity');

    -- Revenue Accounts
    INSERT INTO accounts (tenant_id, account_number, name, type) VALUES
    (NEW.id, '4000', 'Sales Revenue', 'Revenue'),
    (NEW.id, '4100', 'Service Revenue', 'Revenue');

    -- Expense Accounts
    INSERT INTO accounts (tenant_id, account_number, name, type) VALUES
    (NEW.id, '5000', 'Cost of Goods Sold', 'Expense'),
    (NEW.id, '5100', 'Rent Expense', 'Expense'),
    (NEW.id, '5200', 'Utilities Expense', 'Expense'),
    (NEW.id, '5300', 'Payroll Expense', 'Expense');

    RETURN NEW;
END;
$$;

CREATE TRIGGER on_tenant_created
AFTER INSERT ON tenants
FOR EACH ROW EXECUTE FUNCTION create_default_accounts();

-- Note on JWT claims:
-- We'll store tenant_id in user's app_metadata when they sign up.
