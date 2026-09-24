-- Dynamic template-specific fields for official information notes.
ALTER TABLE public.bilgi_notu_drafts
  ADD COLUMN IF NOT EXISTS template_data JSONB NOT NULL DEFAULT '{}'::jsonb;

ALTER TABLE public.submitted_notes
  ADD COLUMN IF NOT EXISTS template_data JSONB NOT NULL DEFAULT '{}'::jsonb;

CREATE INDEX IF NOT EXISTS idx_bilgi_notu_drafts_template_data
  ON public.bilgi_notu_drafts USING GIN (template_data);

CREATE INDEX IF NOT EXISTS idx_submitted_notes_template_data
  ON public.submitted_notes USING GIN (template_data);
