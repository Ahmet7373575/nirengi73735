-- Olay dosyası medya ekleri için özel storage alanı.
INSERT INTO storage.buckets (id, name, public)
VALUES ('case-media', 'case-media', true)
ON CONFLICT (id) DO NOTHING;

DROP POLICY IF EXISTS case_media_storage_read ON storage.objects;
CREATE POLICY case_media_storage_read
ON storage.objects FOR SELECT TO authenticated
USING (bucket_id = 'case-media');

DROP POLICY IF EXISTS case_media_storage_insert ON storage.objects;
CREATE POLICY case_media_storage_insert
ON storage.objects FOR INSERT TO authenticated
WITH CHECK (bucket_id = 'case-media' AND (storage.foldername(name))[1] = auth.uid()::text);

DROP POLICY IF EXISTS case_media_storage_update ON storage.objects;
CREATE POLICY case_media_storage_update
ON storage.objects FOR UPDATE TO authenticated
USING (bucket_id = 'case-media' AND owner_id = auth.uid()::text)
WITH CHECK (bucket_id = 'case-media' AND owner_id = auth.uid()::text);

DROP POLICY IF EXISTS case_media_storage_delete ON storage.objects;
CREATE POLICY case_media_storage_delete
ON storage.objects FOR DELETE TO authenticated
USING (bucket_id = 'case-media' AND owner_id = auth.uid()::text);
