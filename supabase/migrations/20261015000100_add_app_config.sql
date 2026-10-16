create table public.app_config (
  id boolean primary key default true check (id),
  maintenance_enabled boolean not null default false,
  maintenance_message text not null default 'Veil is undergoing maintenance. Please try again shortly.',
  android_min_build integer not null default 0 check (android_min_build >= 0),
  ios_min_build integer not null default 0 check (ios_min_build >= 0),
  android_store_url text not null default 'https://play.google.com/store/apps/details?id=com.vexellab.veil',
  ios_store_url text not null default '',
  constraint android_update_destination check (android_min_build = 0 or android_store_url ~ '^https://play\.google\.com/store/apps/details\?id='),
  constraint ios_update_destination check (ios_min_build = 0 or ios_store_url ~ '^https://apps\.apple\.com/([a-z]{2}/)?app/')
);

alter table public.app_config enable row level security;
revoke all on public.app_config from anon, authenticated;
grant select on public.app_config to anon, authenticated;
grant all on public.app_config to service_role;
create policy "App configuration is publicly readable"
  on public.app_config for select to anon, authenticated using (true);

insert into public.app_config (id) values (true);
comment on table public.app_config is 'Edit the singleton row in Table Editor. Clients can read only. Maintenance takes priority over minimum build requirements.';
