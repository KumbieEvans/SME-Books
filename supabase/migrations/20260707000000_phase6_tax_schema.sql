-- Phase 6 Additions: Taxes and Advanced Invoicing

-- 1. TAXES TABLE
CREATE TABLE taxes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID REFERENCES tenants(id) ON DELETE CASCADE NOT NULL,
    name VARCHAR(50) NOT NULL, -- e.g., 'VAT', 'GST'
    rate NUMERIC(5, 4) NOT NULL, -- e.g., 0.1500 for 15%
    is_active BOOLEAN DEFAULT true NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    UNIQUE(tenant_id, name)
);
ALTER TABLE taxes ENABLE ROW LEVEL SECURITY;

CREATE POLICY taxes_isolation_policy ON taxes
    FOR ALL
    USING (tenant_id = (auth.jwt() -> 'app_metadata' ->> 'tenant_id')::uuid);

-- 2. UPDATE INVOICES AND INVOICE_LINES
ALTER TABLE invoices ADD COLUMN subtotal_amount NUMERIC(15, 4) DEFAULT 0.0000 NOT NULL;
ALTER TABLE invoices ADD COLUMN tax_amount NUMERIC(15, 4) DEFAULT 0.0000 NOT NULL;
ALTER TABLE invoices ADD COLUMN terms TEXT;

-- We add tax_id and tax_amount to invoice lines
ALTER TABLE invoice_lines ADD COLUMN tax_id UUID REFERENCES taxes(id) ON DELETE SET NULL;
ALTER TABLE invoice_lines ADD COLUMN tax_amount NUMERIC(15, 4) DEFAULT 0.0000 NOT NULL;

-- 3. REPORTING RPC FOR TAX LIABILITY
CREATE OR REPLACE FUNCTION get_tax_liability(p_tenant_id UUID, p_start_date DATE, p_end_date DATE)
RETURNS TABLE (
    tax_name VARCHAR,
    total_taxable_amount NUMERIC,
    total_tax_collected NUMERIC
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    RETURN QUERY
    SELECT 
        t.name as tax_name,
        SUM(il.line_total) as total_taxable_amount,
        SUM(il.tax_amount) as total_tax_collected
    FROM invoices i
    JOIN invoice_lines il ON i.id = il.invoice_id
    JOIN taxes t ON il.tax_id = t.id
    WHERE i.tenant_id = p_tenant_id
      AND i.issue_date >= p_start_date
      AND i.issue_date <= p_end_date
      AND i.status NOT IN ('Draft', 'Voided')
    GROUP BY t.name
    ORDER BY t.name;
END;
$$;
