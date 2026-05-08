# TrendHunter AI — Estrutura Completa do Projeto

## 📁 Estrutura de Pastas

```
trendhunter-ai/
├── app/                          # Next.js 14 App Router
│   ├── (auth)/
│   │   ├── login/page.tsx
│   │   └── signup/page.tsx
│   ├── (dashboard)/
│   │   ├── layout.tsx            # Dashboard shell
│   │   ├── dashboard/page.tsx    # Home do dashboard
│   │   ├── search/page.tsx       # Pesquisa de produtos
│   │   ├── product/[id]/page.tsx # Detalhe do produto
│   │   ├── history/page.tsx      # Histórico de buscas
│   │   ├── favorites/page.tsx    # Produtos favoritos
│   │   └── settings/page.tsx     # Configurações
│   ├── (admin)/
│   │   ├── layout.tsx
│   │   └── admin/
│   │       ├── page.tsx          # Painel admin
│   │       ├── users/page.tsx    # Gestão de usuários
│   │       └── analytics/page.tsx
│   ├── api/
│   │   ├── products/
│   │   │   ├── search/route.ts   # POST — busca produtos
│   │   │   ├── viral-score/route.ts
│   │   │   └── [id]/route.ts
│   │   ├── ai/
│   │   │   ├── copy/route.ts     # Geração de copy
│   │   │   ├── headlines/route.ts
│   │   │   └── audiences/route.ts
│   │   ├── trends/
│   │   │   └── route.ts          # Dados de tendências
│   │   ├── stripe/
│   │   │   ├── checkout/route.ts
│   │   │   ├── portal/route.ts
│   │   │   └── webhook/route.ts
│   │   └── auth/
│   │       └── [...nextauth]/route.ts
│   ├── layout.tsx
│   └── page.tsx                  # Landing page
├── components/
│   ├── ui/                       # Componentes base (shadcn/ui)
│   │   ├── button.tsx
│   │   ├── card.tsx
│   │   ├── input.tsx
│   │   ├── badge.tsx
│   │   ├── dialog.tsx
│   │   └── ...
│   ├── dashboard/
│   │   ├── Sidebar.tsx
│   │   ├── Header.tsx
│   │   ├── ProductCard.tsx
│   │   ├── ViralScoreChart.tsx
│   │   ├── TrendChart.tsx
│   │   ├── CopyGenerator.tsx
│   │   ├── AudienceSuggestor.tsx
│   │   └── SearchBar.tsx
│   └── landing/
│       ├── Hero.tsx
│       ├── Features.tsx
│       ├── Pricing.tsx
│       └── Testimonials.tsx
├── lib/
│   ├── supabase/
│   │   ├── client.ts             # Browser client
│   │   ├── server.ts             # Server client
│   │   └── middleware.ts
│   ├── stripe.ts
│   ├── openai.ts
│   ├── viral-score.ts            # Algoritmo de score
│   └── utils.ts
├── hooks/
│   ├── useProducts.ts
│   ├── useSubscription.ts
│   └── useSearchHistory.ts
├── types/
│   ├── product.ts
│   ├── subscription.ts
│   └── database.ts
├── middleware.ts                  # Auth + subscription gate
├── supabase/
│   └── migrations/
│       ├── 001_users.sql
│       ├── 002_products.sql
│       ├── 003_searches.sql
│       └── 004_subscriptions.sql
├── .env.local
├── next.config.js
└── tailwind.config.ts
```
