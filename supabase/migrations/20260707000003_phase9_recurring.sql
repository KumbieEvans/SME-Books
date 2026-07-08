-- Phase 9 Additions: Recurring Invoices

CREATE TABLE recurring_invoices (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID REFERENCES tenants(id) ON DELETE CASCADE NOT NULL,
    base_invoice_id UUID REFERENCES invoices(id) ON DELETE CASCADE NOT NULL,
    frequency VARCHAR(50) NOT NULL CHECK (frequency IN ('Weekly', 'Monthly', 'Yearly')),
    next_run_date DATE NOT NULL,
    is_active BOOLEAN DEFAULT true NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    UNIQUE(tenant_id, base_invoice_id)
);

ALTER TABLE recurring_invoices ENABLE ROW LEVEL SECURITY;

CREATE POLICY recurring_invoices_isolation_policy ON recurring_invoices
    FOR ALL
    USING (tenant_id = (auth.jwt() -> 'app_metadata' ->> 'tenant_id')::uuid);
