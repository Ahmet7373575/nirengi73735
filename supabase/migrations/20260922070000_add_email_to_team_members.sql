-- Migration: Add email column to team_members for badge-based login
-- Timestamp: 20260922070000

ALTER TABLE public.team_members
  ADD COLUMN IF NOT EXISTS email text;

-- Index for fast email lookup
CREATE INDEX IF NOT EXISTS idx_team_members_email ON public.team_members(email);

-- Update RLS: allow users to read their own team_members row by user_id
-- (existing policies remain; this is additive)
