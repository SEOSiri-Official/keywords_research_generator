## 1.0.0

**Initial release — published by [seosiri.com](https://www.seosiri.com)**

### Features
- 🔍 **Keyword Generation** — Expand any seed keyword into 100+ short, medium, and long-tail phrases
- 🎯 **Search Intent Classification** — Automatic tagging as Informational, Navigational, Commercial, or Transactional
- 📊 **SEO Metrics** — Estimated monthly search volume, SEO difficulty, opportunity score, CPC, CTR potential
- 🎙 **Voice Search Optimisation** — Generate conversational and question-based variants for voice queries
- ⚡ **AEO (Answer Engine Optimisation)** — Featured snippet and People Also Ask targeting hints
- 💰 **SEM Hints** — Match type, bid strategy, ad copy, and landing page alignment recommendations
- 🌍 **Region Filtering** — Target specific geographic markets (US, UK, BD, IN, Global, and more)
- 🏢 **Business Segment Filtering** — SaaS, E-commerce, Healthcare, Finance, and 15+ segments
- 📂 **Category Filtering** — Custom content/product category tagging
- 📤 **Export** — Download keyword lists as CSV or JSON with seosiri.com backlinks
- 🔗 **Share** — Native share sheet support (CSV, plain text)
- 📱 **Flutter Widgets** — Drop-in `KeywordListWidget`, `KeywordFilterPanel`, `KeywordMetricsCard`

## 2.0.0

**Zero-cost real API upgrade — no more simulated data**

### New Services
- `GoogleAutocompleteService` — alphabetical + question + preposition + qualifier + YouTube expansion (500–1,000 phrases per seed)
- `DatamuseService` — semantic/LSI keyword expansion, synonyms, co-occurring terms, topic vocabulary (no API key)
- `GoogleTrendsService` — real trend direction, interest score, rising related queries (no API key)
- `WikipediaService` — entity relationships, semantic category clusters, page summaries (no API key)
- `GoogleSearchConsoleService` — real clicks/impressions/CTR/position from user's own verified properties (free OAuth)
- `RealMetricsService` — derives volume, difficulty, CPC from actual API signals (no randomness)
- `KeywordClusterBuilder` — semantic topic clustering of all keywords into pillar + supporting groups

### New Widgets
- `ProgressOverlay` — animated real-time pipeline progress (shows each API stage)
- `KeywordClusterWidget` — visual topic cluster display with expandable groups
- `GscConnectWidget` — Google Search Console OAuth flow + striking distance / top keyword / cannibalization views
- `TrendChip` — real-time trend direction badge

### Infrastructure
- `RateLimiter` — token-bucket per-API rate limiting to stay inside free quotas
- `KeywordCacheService` — two-layer cache (L1 memory + L2 SharedPreferences) with 24hr TTL

### Breaking Changes
- `KeywordListResult` now includes `clusterSummaries`, `trendDirection`, `trendInterestScore`, `risingRelatedQueries`
- `KeywordGeneratorService.generate()` now accepts `onProgress` callback and `fetchTrends/fetchWikipedia/fetchDatamuse` flags
