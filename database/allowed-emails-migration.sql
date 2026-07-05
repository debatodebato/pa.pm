-- New table: allowed_emails (manual email allowlist, managed by Admins)
create table allowed_emails (
  id uuid primary key default gen_random_uuid(),
  email text unique not null,
  added_by uuid references profiles(id),
  created_at timestamptz not null default now(),
  notes text
);

-- Enable RLS on allowed_emails
alter table allowed_emails enable row level security;

-- Policy: Admins and Leaders can manage the allowlist
create policy "admins_leaders_manage_allowlist" on allowed_emails for all using (
  (select is_admin from profiles where id = auth.uid())
  or
  (select role from profiles where id = auth.uid()) = 'leader'
);

-- Policy: All authenticated users can view (for reference)
create policy "users_view_allowlist" on allowed_emails for select using (
  auth.role() = 'authenticated'
);

-- Helper function: check if email is in allowlist
create or replace function is_email_allowed(p_email text)
returns boolean as $$
  select exists (
    select 1 from allowed_emails where email = p_email
  );
$$ language sql security definer stable;

-- Add column to profiles table for tracking allowlist acceptance
alter table profiles add column role text default 'contributor' 
  check (role in ('admin', 'leader', 'contributor', 'viewer'));
