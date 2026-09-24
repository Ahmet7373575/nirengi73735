-- Migration: Enable Supabase Realtime publication for live activity feed
-- Tables: bilgi_notu_drafts, submitted_notes, pdf_records
-- This allows the ActivityFeedService to receive INSERT/UPDATE events in real-time.

-- Add tables to the supabase_realtime publication (idempotent via DO block)
DO $$
BEGIN
  -- bilgi_notu_drafts
  IF NOT EXISTS (
    SELECT 1 FROM pg_publication_tables
    WHERE pubname = 'supabase_realtime'
      AND schemaname = 'public'
      AND tablename = 'bilgi_notu_drafts'
  ) THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.bilgi_notu_drafts;
  END IF;

  -- submitted_notes
  IF NOT EXISTS (
    SELECT 1 FROM pg_publication_tables
    WHERE pubname = 'supabase_realtime'
      AND schemaname = 'public'
      AND tablename = 'submitted_notes'
  ) THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.submitted_notes;
  END IF;

  -- pdf_records
  IF NOT EXISTS (
    SELECT 1 FROM pg_publication_tables
    WHERE pubname = 'supabase_realtime'
      AND schemaname = 'public'
      AND tablename = 'pdf_records'
  ) THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.pdf_records;
  END IF;
END $$;

-- Add a SELECT policy so authenticated users can see ALL team members' submitted notes
-- (needed for realtime broadcast of peer submissions)
DROP POLICY IF EXISTS "officers_view_all_submitted_notes" ON public.submitted_notes;
CREATE POLICY "officers_view_all_submitted_notes"
  ON public.submitted_notes
  FOR SELECT
  TO authenticated
  USING (true);

-- Add a SELECT policy so authenticated users can see ALL team members' drafts
DROP POLICY IF EXISTS "officers_view_all_drafts" ON public.bilgi_notu_drafts;
CREATE POLICY "officers_view_all_drafts"
  ON public.bilgi_notu_drafts
  FOR SELECT
  TO authenticated
  USING (true);

-- Add a SELECT policy so authenticated users can see ALL team members' PDF records
DROP POLICY IF EXISTS "officers_view_all_pdf_records" ON public.pdf_records;
CREATE POLICY "officers_view_all_pdf_records"
  ON public.pdf_records
  FOR SELECT
  TO authenticated
  USING (true);
