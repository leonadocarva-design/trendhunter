-- ============================================================
-- TrendHunter AI — Supabase Database Schema
-- Execute na ordem: 001 → 002 → 003 → 004
-- ============================================================

-- ============================================================
-- 001_users.sql — Perfis de usuários e planos
-- ============================================================
create extension if not exists "uuid-ossp";

-- Tabela de perfis (estende auth.users do Supabase)
create table public.profiles (
  id uuid references auth.users(id) on delete cascade primary key,
  email text not null,
  full_name text,
  avatar_url text,
  plan text not null default 'free' check (plan in ('free', 'pro', 'scale')),
  plan_status text not null default 'active' check (plan_status in ('active', 'canceled', 'past_due', 'trialing')),
  stripe_customer_id text unique,
  stripe_subscription_id text unique,
  trial_ends_at timestamptz,
  searches_today int not null default 0,
  searches_reset_at date not null default current_date,
  is_admin boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- RLS (Row Level Security)
alter table public.profiles enable row level security;

create policy "Users can view own profile"
  on public.profiles for select
  using (auth.uid() = id);

create policy "Users can update own profile"
  on public.profiles for update
  using (auth.uid() = id);

create policy "Admins can view all profiles"
  on public.profiles for all
  using (
    exists (
      select 1 from public.profiles
      where id = auth.uid() and is_admin = true
    )
  );

-- Trigger: criar perfil ao registrar usuário
create or replace function public.handle_new_user()
returns trigger as $$
begin
  insert into public.profiles (id, email, full_name)
  values (
    new.id,
    new.email,
    coalesce(new.raw_user_meta_data->>'full_name', split_part(new.email, '@', 1))
  );
  return new;
end;
$$ language plpgsql security definer;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user();

-- Trigger: updated_at automático
create or replace function public.set_updated_at()
returns trigger as $$
begin
  new.updated_at = now();
  return new;
end;
$$ language plpgsql;

create trigger profiles_updated_at
  before update on public.profiles
  for each row execute procedure public.set_updated_at();


-- ============================================================
-- 002_products.sql — Produtos e análises
-- ============================================================

-- Tabela de produtos analisados (cache)
create table public.products (
  id uuid default uuid_generate_v4() primary key,
  slug text unique not null,
  name text not null,
  description text,
  category text,
  image_url text,
  source_url text,
  price_usd numeric(10,2),
  -- Scores
  viral_score numeric(3,1) check (viral_score >= 0 and viral_score <= 10),
  engagement_score numeric(5,2),
  trend_score numeric(5,2),
  competition_score numeric(5,2),
  -- Meta
  trend_status text check (trend_status in ('rising', 'peak', 'declining', 'stable', 'new')),
  competition_level text check (competition_level in ('very_low', 'low', 'medium', 'high', 'very_high')),
  -- Dados extras (JSONB para flexibilidade)
  trend_data jsonb default '{}',    -- {labels:[], values:[]}
  ad_data jsonb default '{}',       -- dados de anúncios ativos
  keywords jsonb default '[]',      -- palavras-chave relacionadas
  platforms jsonb default '[]',     -- plataformas onde foi visto
  -- Controle
  last_analyzed_at timestamptz default now(),
  analysis_count int default 1,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index products_viral_score_idx on public.products(viral_score desc);
create index products_category_idx on public.products(category);
create index products_trend_status_idx on public.products(trend_status);
create index products_created_at_idx on public.products(created_at desc);

-- RLS: produtos são públicos para leitura
alter table public.products enable row level security;
create policy "Products are viewable by authenticated users"
  on public.products for select
  using (auth.role() = 'authenticated');

-- Trigger updated_at
create trigger products_updated_at
  before update on public.products
  for each row execute procedure public.set_updated_at();


-- Tabela de copies geradas por IA
create table public.ai_copies (
  id uuid default uuid_generate_v4() primary key,
  product_id uuid references public.products(id) on delete cascade,
  user_id uuid references public.profiles(id) on delete cascade,
  type text not null check (type in ('headline', 'ad_copy', 'cta', 'audience_meta', 'audience_google')),
  content text not null,
  platform text check (platform in ('meta', 'google', 'tiktok', 'email', 'generic')),
  tone text check (tone in ('urgency', 'curiosity', 'social_proof', 'benefit', 'pain')),
  metadata jsonb default '{}',
  is_favorite boolean default false,
  created_at timestamptz not null default now()
);

create index ai_copies_user_idx on public.ai_copies(user_id, created_at desc);
create index ai_copies_product_idx on public.ai_copies(product_id);

alter table public.ai_copies enable row level security;
create policy "Users can manage own copies"
  on public.ai_copies for all
  using (auth.uid() = user_id);


-- ============================================================
-- 003_searches.sql — Histórico de buscas
-- ============================================================

create table public.search_history (
  id uuid default uuid_generate_v4() primary key,
  user_id uuid references public.profiles(id) on delete cascade not null,
  query text not null,
  filters jsonb default '{}',          -- {category, min_score, trend_status}
  results_count int default 0,
  top_product_id uuid references public.products(id),
  top_score numeric(3,1),
  created_at timestamptz not null default now()
);

create index search_history_user_idx on public.search_history(user_id, created_at desc);

alter table public.search_history enable row level security;
create policy "Users can view own search history"
  on public.search_history for all
  using (auth.uid() = user_id);


-- Tabela de produtos favoritos
create table public.favorites (
  id uuid default uuid_generate_v4() primary key,
  user_id uuid references public.profiles(id) on delete cascade not null,
  product_id uuid references public.products(id) on delete cascade not null,
  notes text,
  created_at timestamptz not null default now(),
  unique(user_id, product_id)
);

alter table public.favorites enable row level security;
create policy "Users can manage own favorites"
  on public.favorites for all
  using (auth.uid() = user_id);


-- Nichos monitorados pelo usuário
create table public.monitored_niches (
  id uuid default uuid_generate_v4() primary key,
  user_id uuid references public.profiles(id) on delete cascade not null,
  name text not null,
  keywords jsonb default '[]',
  alert_threshold numeric(3,1) default 7.5,
  alert_enabled boolean default true,
  last_alert_at timestamptz,
  created_at timestamptz not null default now()
);

alter table public.monitored_niches enable row level security;
create policy "Users can manage own niches"
  on public.monitored_niches for all
  using (auth.uid() = user_id);


-- ============================================================
-- 004_subscriptions.sql — Eventos de assinatura Stripe
-- ============================================================

create table public.subscription_events (
  id uuid default uuid_generate_v4() primary key,
  user_id uuid references public.profiles(id) on delete set null,
  stripe_event_id text unique not null,
  event_type text not null,
  payload jsonb not null,
  processed_at timestamptz,
  created_at timestamptz not null default now()
);

create index sub_events_user_idx on public.subscription_events(user_id);
create index sub_events_type_idx on public.subscription_events(event_type);

-- Limites por plano (tabela de referência)
create table public.plan_limits (
  plan text primary key,
  daily_searches int not null,
  monitored_niches int not null,
  history_days int not null,
  ai_copies_per_day int not null,  -- -1 = ilimitado
  team_members int not null,
  api_access boolean not null,
  white_label boolean not null
);

insert into public.plan_limits values
  ('free',  5,  1,   7,   0,  1, false, false),
  ('pro',  -1, 10,  90,  -1,  1, false, false),
  ('scale',-1, -1, 365,  -1,  5, true,  true);


-- ============================================================
-- Views úteis para o dashboard admin
-- ============================================================

create or replace view public.admin_stats as
select
  (select count(*) from public.profiles) as total_users,
  (select count(*) from public.profiles where plan = 'pro') as pro_users,
  (select count(*) from public.profiles where plan = 'scale') as scale_users,
  (select count(*) from public.profiles where created_at > now() - interval '7 days') as new_users_7d,
  (select count(*) from public.search_history where created_at > now() - interval '24 hours') as searches_24h,
  (select count(*) from public.products) as total_products,
  (select round(avg(viral_score)::numeric, 2) from public.products) as avg_viral_score;
