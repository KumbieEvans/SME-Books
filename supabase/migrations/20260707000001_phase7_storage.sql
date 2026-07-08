-- Phase 7 Additions: Storage Bucket for Receipts

INSERT INTO storage.buckets (id, name, public)
VALUES ('receipts', 'receipts', false)
ON CONFLICT (id) DO NOTHING;

-- Allow authenticated users to upload, read, and delete receipts within their tenant folder.
-- The object name must be formatted as: tenant_id/filename.ext
CREATE POLICY "Allow tenant access to own receipts" ON storage.objects
    FOR ALL
    USING (
        bucket_id = 'receipts' 
        AND (storage.foldername(name))[1] = (auth.jwt() -> 'app_metadata' ->> 'tenant_id')
    );
