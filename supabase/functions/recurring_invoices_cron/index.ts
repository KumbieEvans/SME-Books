import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from "https://esm.sh/@supabase/supabase-js@2"

// This function is meant to be invoked by pg_cron or Supabase scheduled functions.
// It queries the `recurring_invoices` table for any active schedules where `next_run_date` <= CURRENT_DATE.
// For each match, it creates a new draft invoice based on the `base_invoice_id` and updates the `next_run_date`.

serve(async (req: Request) => {
  try {
    const supabaseClient = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    );

    // 1. Fetch active recurring invoices that are due
    const { data: recurringInvoices, error: fetchError } = await supabaseClient
      .from('recurring_invoices')
      .select('*, base_invoice:invoices(*, lines:invoice_lines(*))')
      .eq('is_active', true)
      .lte('next_run_date', new Date().toISOString().split('T')[0]);

    if (fetchError) throw fetchError;

    const results = [];

    // 2. Process each due invoice
    for (const recurring of (recurringInvoices || [])) {
      const baseInvoice = recurring.base_invoice;
      if (!baseInvoice) continue;

      // Create new draft invoice
      const newInvoiceData = {
        tenant_id: baseInvoice.tenant_id,
        invoice_number: `INV-REC-${Date.now()}`,
        client_name: baseInvoice.client_name,
        status: 'Draft',
        issue_date: new Date().toISOString().split('T')[0], // Today
        due_date: null, // Depending on terms, might calculate this
        subtotal_amount: baseInvoice.subtotal_amount,
        tax_amount: baseInvoice.tax_amount,
        total_amount: baseInvoice.total_amount,
        currency_code: baseInvoice.currency_code,
        terms: baseInvoice.terms,
      };

      const { data: newInvoice, error: insertError } = await supabaseClient
        .from('invoices')
        .insert(newInvoiceData)
        .select()
        .single();

      if (insertError) throw insertError;

      // Copy lines
      if (baseInvoice.lines && baseInvoice.lines.length > 0) {
        const newLines = baseInvoice.lines.map((line: any) => ({
          tenant_id: newInvoice.tenant_id,
          invoice_id: newInvoice.id,
          description: line.description,
          quantity: line.quantity,
          unit_price: line.unit_price,
          tax_id: line.tax_id,
          tax_amount: line.tax_amount
        }));

        const { error: linesError } = await supabaseClient
          .from('invoice_lines')
          .insert(newLines);

        if (linesError) throw linesError;
      }

      // Calculate next run date
      const currentNextRun = new Date(recurring.next_run_date);
      if (recurring.frequency === 'Weekly') {
        currentNextRun.setDate(currentNextRun.getDate() + 7);
      } else if (recurring.frequency === 'Monthly') {
        currentNextRun.setMonth(currentNextRun.getMonth() + 1);
      } else if (recurring.frequency === 'Yearly') {
        currentNextRun.setFullYear(currentNextRun.getFullYear() + 1);
      }

      // Update the next run date
      const { error: updateError } = await supabaseClient
        .from('recurring_invoices')
        .update({ next_run_date: currentNextRun.toISOString().split('T')[0] })
        .eq('id', recurring.id);

      if (updateError) throw updateError;

      results.push({
        recurring_id: recurring.id,
        new_invoice_id: newInvoice.id,
        next_run_date: currentNextRun.toISOString().split('T')[0],
      });
    }

    return new Response(JSON.stringify({ success: true, processed: results }), {
      headers: { "Content-Type": "application/json" },
      status: 200,
    });
  } catch (error: any) {
    return new Response(JSON.stringify({ error: error.message }), {
      headers: { "Content-Type": "application/json" },
      status: 500,
    });
  }
});
