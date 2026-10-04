ALTER TABLE public.incidents
  ADD COLUMN IF NOT EXISTS incident_type TEXT,
  ADD COLUMN IF NOT EXISTS crime_name TEXT,
  ADD COLUMN IF NOT EXISTS investigation_number TEXT,
  ADD COLUMN IF NOT EXISTS neighborhood TEXT;
