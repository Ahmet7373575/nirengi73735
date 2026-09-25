-- ============================================================
-- Migration: incidents, team_members, user_preferences
-- Timestamp: 20260922060000
-- ============================================================

-- ── 1. ENUM TYPES ────────────────────────────────────────────

DROP TYPE IF EXISTS public.incident_priority CASCADE;
CREATE TYPE public.incident_priority AS ENUM ('low', 'medium', 'high', 'critical');

DROP TYPE IF EXISTS public.incident_status CASCADE;
CREATE TYPE public.incident_status AS ENUM ('open', 'in_progress', 'resolved', 'closed');

DROP TYPE IF EXISTS public.shift_status CASCADE;
CREATE TYPE public.shift_status AS ENUM ('on_duty', 'on_break', 'off_duty', 'responding');

-- ── 2. TABLES ────────────────────────────────────────────────

-- Incidents table: stores rapid incident submissions
CREATE TABLE IF NOT EXISTS public.incidents (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    local_id TEXT NOT NULL,
    title TEXT NOT NULL,
    description TEXT NOT NULL,
    location TEXT,
    reporter_name TEXT,
    priority public.incident_priority NOT NULL DEFAULT 'medium'::public.incident_priority,
    incident_status public.incident_status NOT NULL DEFAULT 'open'::public.incident_status,
    assigned_team_id TEXT,
    assigned_team_name TEXT,
    ai_suggested_priority public.incident_priority,
    ai_suggested_category TEXT,
    -- GPS ping fields
    gps_latitude DOUBLE PRECISION,
    gps_longitude DOUBLE PRECISION,
    gps_accuracy DOUBLE PRECISION,
    gps_pinged_at TIMESTAMPTZ,
    submitted_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL
);

-- Team members table: stores officer/team member records
CREATE TABLE IF NOT EXISTS public.team_members (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    badge_number TEXT NOT NULL UNIQUE,
    rank TEXT,
    team_name TEXT,
    shift_status public.shift_status NOT NULL DEFAULT 'off_duty'::public.shift_status,
    -- GPS tracking
    last_gps_latitude DOUBLE PRECISION,
    last_gps_longitude DOUBLE PRECISION,
    last_gps_ping_at TIMESTAMPTZ,
    last_known_location TEXT,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL
);

-- GPS pings table: time-series GPS location records
CREATE TABLE IF NOT EXISTS public.gps_pings (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    team_member_id UUID REFERENCES public.team_members(id) ON DELETE CASCADE,
    incident_id UUID REFERENCES public.incidents(id) ON DELETE SET NULL,
    latitude DOUBLE PRECISION NOT NULL,
    longitude DOUBLE PRECISION NOT NULL,
    accuracy DOUBLE PRECISION,
    location_label TEXT,
    pinged_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL
);

-- User preferences table: stores notification settings per user
CREATE TABLE IF NOT EXISTS public.user_preferences (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    -- Notification toggles
    notif_critical_incidents BOOLEAN NOT NULL DEFAULT true,
    notif_team_updates BOOLEAN NOT NULL DEFAULT true,
    notif_assignments BOOLEAN NOT NULL DEFAULT true,
    -- Quiet hours
    quiet_hours_enabled BOOLEAN NOT NULL DEFAULT false,
    quiet_hours_start INTEGER NOT NULL DEFAULT 22,
    quiet_hours_end INTEGER NOT NULL DEFAULT 7,
    -- Priority threshold: 0=all, 1=medium+, 2=high+, 3=critical only
    priority_threshold INTEGER NOT NULL DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT user_preferences_user_id_unique UNIQUE (user_id)
);

-- ── 3. INDEXES ───────────────────────────────────────────────

CREATE INDEX IF NOT EXISTS idx_incidents_user_id ON public.incidents(user_id);
CREATE INDEX IF NOT EXISTS idx_incidents_priority ON public.incidents(priority);
CREATE INDEX IF NOT EXISTS idx_incidents_incident_status ON public.incidents(incident_status);
CREATE INDEX IF NOT EXISTS idx_incidents_submitted_at ON public.incidents(submitted_at DESC);
CREATE INDEX IF NOT EXISTS idx_incidents_local_id ON public.incidents(local_id);

CREATE INDEX IF NOT EXISTS idx_team_members_user_id ON public.team_members(user_id);
CREATE INDEX IF NOT EXISTS idx_team_members_badge_number ON public.team_members(badge_number);
CREATE INDEX IF NOT EXISTS idx_team_members_shift_status ON public.team_members(shift_status);

CREATE INDEX IF NOT EXISTS idx_gps_pings_team_member_id ON public.gps_pings(team_member_id);
CREATE INDEX IF NOT EXISTS idx_gps_pings_incident_id ON public.gps_pings(incident_id);
CREATE INDEX IF NOT EXISTS idx_gps_pings_pinged_at ON public.gps_pings(pinged_at DESC);

CREATE INDEX IF NOT EXISTS idx_user_preferences_user_id ON public.user_preferences(user_id);

-- ── 4. UPDATED_AT TRIGGER FUNCTION ───────────────────────────

CREATE OR REPLACE FUNCTION public.set_updated_at()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$;

-- ── 5. ENABLE RLS ────────────────────────────────────────────

ALTER TABLE public.incidents ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.team_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.gps_pings ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_preferences ENABLE ROW LEVEL SECURITY;

-- ── 6. RLS POLICIES ──────────────────────────────────────────

-- Incidents: users manage their own
DROP POLICY IF EXISTS "users_manage_own_incidents" ON public.incidents;
CREATE POLICY "users_manage_own_incidents"
ON public.incidents
FOR ALL
TO authenticated
USING (user_id = auth.uid())
WITH CHECK (user_id = auth.uid());

-- Incidents: all authenticated users can read (team visibility)
DROP POLICY IF EXISTS "authenticated_read_incidents" ON public.incidents;
CREATE POLICY "authenticated_read_incidents"
ON public.incidents
FOR SELECT
TO authenticated
USING (true);

-- Team members: all authenticated users can read
DROP POLICY IF EXISTS "authenticated_read_team_members" ON public.team_members;
CREATE POLICY "authenticated_read_team_members"
ON public.team_members
FOR SELECT
TO authenticated
USING (true);

-- Team members: users manage their own record
DROP POLICY IF EXISTS "users_manage_own_team_member" ON public.team_members;
CREATE POLICY "users_manage_own_team_member"
ON public.team_members
FOR ALL
TO authenticated
USING (user_id = auth.uid())
WITH CHECK (user_id = auth.uid());

-- GPS pings: users manage their own
DROP POLICY IF EXISTS "users_manage_own_gps_pings" ON public.gps_pings;
CREATE POLICY "users_manage_own_gps_pings"
ON public.gps_pings
FOR ALL
TO authenticated
USING (user_id = auth.uid())
WITH CHECK (user_id = auth.uid());

-- GPS pings: all authenticated users can read
DROP POLICY IF EXISTS "authenticated_read_gps_pings" ON public.gps_pings;
CREATE POLICY "authenticated_read_gps_pings"
ON public.gps_pings
FOR SELECT
TO authenticated
USING (true);

-- User preferences: users manage only their own
DROP POLICY IF EXISTS "users_manage_own_preferences" ON public.user_preferences;
CREATE POLICY "users_manage_own_preferences"
ON public.user_preferences
FOR ALL
TO authenticated
USING (user_id = auth.uid())
WITH CHECK (user_id = auth.uid());

-- ── 7. TRIGGERS ──────────────────────────────────────────────

DROP TRIGGER IF EXISTS set_incidents_updated_at ON public.incidents;
CREATE TRIGGER set_incidents_updated_at
    BEFORE UPDATE ON public.incidents
    FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

DROP TRIGGER IF EXISTS set_team_members_updated_at ON public.team_members;
CREATE TRIGGER set_team_members_updated_at
    BEFORE UPDATE ON public.team_members
    FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

DROP TRIGGER IF EXISTS set_user_preferences_updated_at ON public.user_preferences;
CREATE TRIGGER set_user_preferences_updated_at
    BEFORE UPDATE ON public.user_preferences
    FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

-- ── 8. MOCK DATA ─────────────────────────────────────────────

DO $$
DECLARE
    existing_user_id UUID;
    member1_id UUID := gen_random_uuid();
    member2_id UUID := gen_random_uuid();
    member3_id UUID := gen_random_uuid();
    incident1_id UUID := gen_random_uuid();
    incident2_id UUID := gen_random_uuid();
BEGIN
    -- Try to get an existing auth user
    SELECT id INTO existing_user_id FROM auth.users LIMIT 1;

    -- Insert sample team members (no user_id required for demo data)
    INSERT INTO public.team_members (id, name, badge_number, rank, team_name, shift_status, last_known_location, last_gps_ping_at)
    VALUES
        (member1_id, 'Ahmet Kaya', 'P-1042', 'Komiser', 'Alfa', 'on_duty'::public.shift_status, 'Kadıköy, İstanbul', now() - interval '2 minutes'),
        (member2_id, 'Fatma Demir', 'P-2187', 'Memur', 'Bravo', 'responding'::public.shift_status, 'Üsküdar, İstanbul', now() - interval '1 minute'),
        (member3_id, 'Hasan Çelik', 'P-0934', 'Başkomiser', 'Alfa', 'on_duty'::public.shift_status, 'Beşiktaş, İstanbul', now() - interval '5 minutes')
    ON CONFLICT (badge_number) DO NOTHING;

    -- Insert sample incidents
    INSERT INTO public.incidents (id, local_id, title, description, location, reporter_name, priority, incident_status, assigned_team_name, submitted_at, user_id)
    VALUES
        (incident1_id, 'OLY-DEMO001', 'Trafik Kazası', 'Kadıköy köprüsünde çift taraflı araç çarpışması, yaralı var.', 'Kadıköy Köprüsü, İstanbul', 'Ahmet Kaya', 'high'::public.incident_priority, 'in_progress'::public.incident_status, 'Trafik Timi', now() - interval '30 minutes', existing_user_id),
        (incident2_id, 'OLY-DEMO002', 'Hırsızlık İhbarı', 'Mağazadan hırsızlık şüphelisi tespit edildi, kaçıyor.', 'Bağcılar Alışveriş Merkezi', 'Fatma Demir', 'medium'::public.incident_priority, 'open'::public.incident_status, 'Asayiş Timi', now() - interval '10 minutes', existing_user_id)
    ON CONFLICT (id) DO NOTHING;

    -- Insert sample GPS pings for team members
    INSERT INTO public.gps_pings (team_member_id, incident_id, latitude, longitude, accuracy, location_label, user_id)
    VALUES
        (member1_id, incident1_id, 40.9906, 29.0233, 5.0, 'Kadıköy, İstanbul', existing_user_id),
        (member2_id, NULL, 41.0231, 29.0150, 8.0, 'Üsküdar, İstanbul', existing_user_id)
    ON CONFLICT (id) DO NOTHING;

EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'Mock data insertion skipped: %', SQLERRM;
END $$;
