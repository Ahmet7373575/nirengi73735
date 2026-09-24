-- The mobile sync layer uses upsert(..., onConflict: 'local_id').
-- Add the required unique indexes after removing any duplicate preview rows.
DELETE FROM public.incidents a
USING public.incidents b
WHERE a.local_id = b.local_id AND a.ctid > b.ctid;

DELETE FROM public.bilgi_notu_drafts a
USING public.bilgi_notu_drafts b
WHERE a.local_id = b.local_id AND a.ctid > b.ctid;

DELETE FROM public.submitted_notes a
USING public.submitted_notes b
WHERE a.local_id = b.local_id AND a.ctid > b.ctid;

DELETE FROM public.pdf_records a
USING public.pdf_records b
WHERE a.local_id = b.local_id AND a.ctid > b.ctid;

CREATE UNIQUE INDEX IF NOT EXISTS uq_incidents_local_id
  ON public.incidents(local_id);
CREATE UNIQUE INDEX IF NOT EXISTS uq_bilgi_notu_drafts_local_id
  ON public.bilgi_notu_drafts(local_id);
CREATE UNIQUE INDEX IF NOT EXISTS uq_submitted_notes_local_id
  ON public.submitted_notes(local_id);
CREATE UNIQUE INDEX IF NOT EXISTS uq_pdf_records_local_id
  ON public.pdf_records(local_id);
