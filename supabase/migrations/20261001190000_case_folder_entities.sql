-- Nirengi olay dosyası omurgası: şahıs, araç, evrak, medya ve işlem geçmişi.
CREATE TABLE IF NOT EXISTS public.case_persons (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  incident_id UUID NOT NULL REFERENCES public.incidents(id) ON DELETE CASCADE,
  role TEXT NOT NULL DEFAULT 'bilgi_sahibi',
  full_name TEXT NOT NULL,
  national_id TEXT,
  phone TEXT,
  address TEXT,
  notes TEXT,
  user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.case_vehicles (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  incident_id UUID NOT NULL REFERENCES public.incidents(id) ON DELETE CASCADE,
  plate TEXT,
  make_model TEXT,
  color TEXT,
  owner_name TEXT,
  notes TEXT,
  user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.case_documents (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  incident_id UUID NOT NULL REFERENCES public.incidents(id) ON DELETE CASCADE,
  document_type TEXT NOT NULL,
  title TEXT NOT NULL,
  file_name TEXT,
  file_path TEXT,
  status TEXT NOT NULL DEFAULT 'draft',
  created_by UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.case_media (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  incident_id UUID NOT NULL REFERENCES public.incidents(id) ON DELETE CASCADE,
  media_type TEXT NOT NULL DEFAULT 'photo',
  file_name TEXT NOT NULL,
  file_path TEXT NOT NULL,
  latitude DOUBLE PRECISION,
  longitude DOUBLE PRECISION,
  captured_at TIMESTAMPTZ,
  created_by UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.case_activity_log (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  incident_id UUID NOT NULL REFERENCES public.incidents(id) ON DELETE CASCADE,
  action TEXT NOT NULL,
  description TEXT NOT NULL,
  actor_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_case_persons_incident_id ON public.case_persons(incident_id);
CREATE INDEX IF NOT EXISTS idx_case_vehicles_incident_id ON public.case_vehicles(incident_id);
CREATE INDEX IF NOT EXISTS idx_case_documents_incident_id ON public.case_documents(incident_id);
CREATE INDEX IF NOT EXISTS idx_case_media_incident_id ON public.case_media(incident_id);
CREATE INDEX IF NOT EXISTS idx_case_activity_incident_id ON public.case_activity_log(incident_id);

ALTER TABLE public.case_persons ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.case_vehicles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.case_documents ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.case_media ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.case_activity_log ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS case_persons_read ON public.case_persons;
CREATE POLICY case_persons_read ON public.case_persons FOR SELECT TO authenticated USING (true);
DROP POLICY IF EXISTS case_persons_write ON public.case_persons;
CREATE POLICY case_persons_write ON public.case_persons FOR ALL TO authenticated USING (user_id = auth.uid()) WITH CHECK (user_id = auth.uid());

DROP POLICY IF EXISTS case_vehicles_read ON public.case_vehicles;
CREATE POLICY case_vehicles_read ON public.case_vehicles FOR SELECT TO authenticated USING (true);
DROP POLICY IF EXISTS case_vehicles_write ON public.case_vehicles;
CREATE POLICY case_vehicles_write ON public.case_vehicles FOR ALL TO authenticated USING (user_id = auth.uid()) WITH CHECK (user_id = auth.uid());

DROP POLICY IF EXISTS case_documents_read ON public.case_documents;
CREATE POLICY case_documents_read ON public.case_documents FOR SELECT TO authenticated USING (true);
DROP POLICY IF EXISTS case_documents_write ON public.case_documents;
CREATE POLICY case_documents_write ON public.case_documents FOR ALL TO authenticated USING (created_by = auth.uid()) WITH CHECK (created_by = auth.uid());

DROP POLICY IF EXISTS case_media_read ON public.case_media;
CREATE POLICY case_media_read ON public.case_media FOR SELECT TO authenticated USING (true);
DROP POLICY IF EXISTS case_media_write ON public.case_media;
CREATE POLICY case_media_write ON public.case_media FOR ALL TO authenticated USING (created_by = auth.uid()) WITH CHECK (created_by = auth.uid());

DROP POLICY IF EXISTS case_activity_read ON public.case_activity_log;
CREATE POLICY case_activity_read ON public.case_activity_log FOR SELECT TO authenticated USING (true);
DROP POLICY IF EXISTS case_activity_write ON public.case_activity_log;
CREATE POLICY case_activity_write ON public.case_activity_log FOR INSERT TO authenticated WITH CHECK (actor_id = auth.uid());
