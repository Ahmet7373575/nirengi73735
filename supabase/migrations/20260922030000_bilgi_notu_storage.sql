-- Migration: bilgi_notu_storage
-- Tables: bilgi_notu_drafts, submitted_notes, pdf_records
-- Preview mode (no auth required) with open access policies

-- ── 1. ENUM TYPES ────────────────────────────────────────────────────────────
DROP TYPE IF EXISTS public.note_status CASCADE;
CREATE TYPE public.note_status AS ENUM ('draft', 'submitted', 'archived');

DROP TYPE IF EXISTS public.pdf_status CASCADE;
CREATE TYPE public.pdf_status AS ENUM ('pending', 'generated', 'failed');

-- ── 2. TABLES ────────────────────────────────────────────────────────────────

-- Bilgi notu drafts (local-first, auto-saved)
CREATE TABLE IF NOT EXISTS public.bilgi_notu_drafts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    local_id TEXT NOT NULL,
    template_index INTEGER DEFAULT 0,
    template_name TEXT,
    date_text TEXT,
    time_text TEXT,
    personnel_name TEXT,
    badge_number TEXT,
    team_name TEXT,
    duty_location TEXT,
    gps_coordinates TEXT,
    subject TEXT,
    description TEXT,
    status public.note_status DEFAULT 'draft'::public.note_status,
    is_synced BOOLEAN DEFAULT false,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- Submitted notes (finalized records)
CREATE TABLE IF NOT EXISTS public.submitted_notes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    draft_id UUID REFERENCES public.bilgi_notu_drafts(id) ON DELETE SET NULL,
    local_id TEXT NOT NULL,
    template_index INTEGER DEFAULT 0,
    template_name TEXT,
    date_text TEXT,
    time_text TEXT,
    personnel_name TEXT,
    badge_number TEXT,
    team_name TEXT,
    duty_location TEXT,
    gps_coordinates TEXT,
    subject TEXT NOT NULL,
    description TEXT NOT NULL,
    submitted_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- PDF records (generated PDF metadata)
CREATE TABLE IF NOT EXISTS public.pdf_records (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    submitted_note_id UUID REFERENCES public.submitted_notes(id) ON DELETE CASCADE,
    draft_id UUID REFERENCES public.bilgi_notu_drafts(id) ON DELETE SET NULL,
    local_id TEXT NOT NULL,
    file_name TEXT NOT NULL,
    file_path TEXT,
    file_size_bytes BIGINT,
    pdf_status public.pdf_status DEFAULT 'pending'::public.pdf_status,
    generated_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- ── 3. INDEXES ───────────────────────────────────────────────────────────────
CREATE INDEX IF NOT EXISTS idx_bilgi_notu_drafts_local_id ON public.bilgi_notu_drafts(local_id);
CREATE INDEX IF NOT EXISTS idx_bilgi_notu_drafts_status ON public.bilgi_notu_drafts(status);
CREATE INDEX IF NOT EXISTS idx_bilgi_notu_drafts_is_synced ON public.bilgi_notu_drafts(is_synced);
CREATE INDEX IF NOT EXISTS idx_submitted_notes_local_id ON public.submitted_notes(local_id);
CREATE INDEX IF NOT EXISTS idx_submitted_notes_draft_id ON public.submitted_notes(draft_id);
CREATE INDEX IF NOT EXISTS idx_pdf_records_local_id ON public.pdf_records(local_id);
CREATE INDEX IF NOT EXISTS idx_pdf_records_submitted_note_id ON public.pdf_records(submitted_note_id);

-- ── 4. FUNCTIONS ─────────────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION public.update_updated_at_column()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$;

-- ── 5. ENABLE RLS ────────────────────────────────────────────────────────────
ALTER TABLE public.bilgi_notu_drafts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.submitted_notes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.pdf_records ENABLE ROW LEVEL SECURITY;

-- ── 6. RLS POLICIES (open access — preview mode, no auth) ────────────────────
DROP POLICY IF EXISTS "open_access_bilgi_notu_drafts" ON public.bilgi_notu_drafts;
CREATE POLICY "open_access_bilgi_notu_drafts"
ON public.bilgi_notu_drafts FOR ALL TO public USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "open_access_submitted_notes" ON public.submitted_notes;
CREATE POLICY "open_access_submitted_notes"
ON public.submitted_notes FOR ALL TO public USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "open_access_pdf_records" ON public.pdf_records;
CREATE POLICY "open_access_pdf_records"
ON public.pdf_records FOR ALL TO public USING (true) WITH CHECK (true);

-- ── 7. TRIGGERS ──────────────────────────────────────────────────────────────
DROP TRIGGER IF EXISTS set_updated_at_bilgi_notu_drafts ON public.bilgi_notu_drafts;
CREATE TRIGGER set_updated_at_bilgi_notu_drafts
    BEFORE UPDATE ON public.bilgi_notu_drafts
    FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();
