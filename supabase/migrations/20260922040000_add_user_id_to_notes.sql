-- Migration: Add user_id to bilgi_notu_drafts, submitted_notes, pdf_records
-- and update RLS policies to enforce per-user row-level security.

-- ── 1. Add user_id columns ────────────────────────────────────────────────

ALTER TABLE public.bilgi_notu_drafts
  ADD COLUMN IF NOT EXISTS user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE;

ALTER TABLE public.submitted_notes
  ADD COLUMN IF NOT EXISTS user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE;

ALTER TABLE public.pdf_records
  ADD COLUMN IF NOT EXISTS user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE;

-- ── 2. Indexes on user_id ─────────────────────────────────────────────────

CREATE INDEX IF NOT EXISTS idx_bilgi_notu_drafts_user_id ON public.bilgi_notu_drafts(user_id);
CREATE INDEX IF NOT EXISTS idx_submitted_notes_user_id ON public.submitted_notes(user_id);
CREATE INDEX IF NOT EXISTS idx_pdf_records_user_id ON public.pdf_records(user_id);

-- ── 3. Drop old open-access policies ─────────────────────────────────────

DROP POLICY IF EXISTS "open_access_drafts" ON public.bilgi_notu_drafts;
DROP POLICY IF EXISTS "open_access_submitted" ON public.submitted_notes;
DROP POLICY IF EXISTS "open_access_pdf" ON public.pdf_records;

-- Also drop any previously created policies by name variants
DROP POLICY IF EXISTS "Allow all operations on bilgi_notu_drafts" ON public.bilgi_notu_drafts;
DROP POLICY IF EXISTS "Allow all operations on submitted_notes" ON public.submitted_notes;
DROP POLICY IF EXISTS "Allow all operations on pdf_records" ON public.pdf_records;
DROP POLICY IF EXISTS "bilgi_notu_drafts_open_access" ON public.bilgi_notu_drafts;
DROP POLICY IF EXISTS "submitted_notes_open_access" ON public.submitted_notes;
DROP POLICY IF EXISTS "pdf_records_open_access" ON public.pdf_records;

-- ── 4. Create per-user RLS policies ──────────────────────────────────────

-- bilgi_notu_drafts
DROP POLICY IF EXISTS "users_manage_own_bilgi_notu_drafts" ON public.bilgi_notu_drafts;
CREATE POLICY "users_manage_own_bilgi_notu_drafts"
ON public.bilgi_notu_drafts
FOR ALL
TO authenticated
USING (user_id = auth.uid())
WITH CHECK (user_id = auth.uid());

-- submitted_notes
DROP POLICY IF EXISTS "users_manage_own_submitted_notes" ON public.submitted_notes;
CREATE POLICY "users_manage_own_submitted_notes"
ON public.submitted_notes
FOR ALL
TO authenticated
USING (user_id = auth.uid())
WITH CHECK (user_id = auth.uid());

-- pdf_records
DROP POLICY IF EXISTS "users_manage_own_pdf_records" ON public.pdf_records;
CREATE POLICY "users_manage_own_pdf_records"
ON public.pdf_records
FOR ALL
TO authenticated
USING (user_id = auth.uid())
WITH CHECK (user_id = auth.uid());
