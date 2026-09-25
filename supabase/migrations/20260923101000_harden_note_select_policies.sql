-- The realtime migration created broad SELECT policies for preview mode.
-- Remove them after authentication is enabled so the per-user policies apply.
DROP POLICY IF EXISTS "officers_view_all_submitted_notes" ON public.submitted_notes;
DROP POLICY IF EXISTS "officers_view_all_drafts" ON public.bilgi_notu_drafts;
DROP POLICY IF EXISTS "officers_view_all_pdf_records" ON public.pdf_records;

-- Recreate explicit authenticated ownership policies for SELECT in case a
-- previous deployment removed or renamed the policies.
DROP POLICY IF EXISTS "users_read_own_bilgi_notu_drafts" ON public.bilgi_notu_drafts;
CREATE POLICY "users_read_own_bilgi_notu_drafts"
  ON public.bilgi_notu_drafts FOR SELECT TO authenticated
  USING (user_id = auth.uid());

DROP POLICY IF EXISTS "users_read_own_submitted_notes" ON public.submitted_notes;
CREATE POLICY "users_read_own_submitted_notes"
  ON public.submitted_notes FOR SELECT TO authenticated
  USING (user_id = auth.uid());

DROP POLICY IF EXISTS "users_read_own_pdf_records" ON public.pdf_records;
CREATE POLICY "users_read_own_pdf_records"
  ON public.pdf_records FOR SELECT TO authenticated
  USING (user_id = auth.uid());
