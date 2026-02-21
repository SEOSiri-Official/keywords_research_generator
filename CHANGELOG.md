## 2.0.4

- Fix: remove google_sign_in dependency — GSC now accepts OAuth token directly
- Fix: compatible with any Google auth library (no version conflicts)

## 2.0.4

- Stability: pin google_sign_in to ^6.2.1 (v7 has breaking OAuth changes)
- Keep intl ^0.19.0 for stability

## 2.0.3

- Fix: bump google_sign_in to ^7.0.0 and intl to ^0.20.0 for 160/160 pub points

## 2.0.3

- Fix: bump google_sign_in to ^7.0.0 and intl to ^0.20.0 for 160/160 pub points

## 2.0.3

- Fix: bump google_sign_in to ^7.0.0 and intl to ^0.20.0 for 160/160 pub points

## 2.0.3

- Fix: bump google_sign_in to ^7.0.0 and intl to ^0.20.0 for 160/160 pub points

## 2.0.3

- Fix: bump google_sign_in to ^7.0.0 and intl to ^0.20.0 for 160/160 pub points

## 2.0.2

- Fix: bump csv to ^7.0.0 and connectivity_plus to ^7.0.0 for full pub points

## 2.0.1

- Fix: shorten pubspec description to meet pub.dev 180-char limit
- Fix: update all dependencies to latest versions

## 2.0.1

- Fix: shorten pubspec description to meet pub.dev 180-char limit
- Fix: update dependencies to latest versions for full pub points

## 1.0.0

**Initial release â€” published by [seosiri.com](https://www.seosiri.com)**

### Features
- ðŸ” **Keyword Generation** â€” Expand any seed keyword into 100+ short, medium, and long-tail phrases
- ðŸŽ¯ **Search Intent Classification** â€” Automatic tagging as Informational, Navigational, Commercial, or Transactional
- ðŸ“Š **SEO Metrics** â€” Estimated monthly search volume, SEO difficulty, opportunity score, CPC, CTR potential
- ðŸŽ™ **Voice Search Optimisation** â€” Generate conversational and question-based variants for voice queries
- âš¡ **AEO (Answer Engine Optimisation)** â€” Featured snippet and People Also Ask targeting hints
- ðŸ’° **SEM Hints** â€” Match type, bid strategy, ad copy, and landing page alignment recommendations
- ðŸŒ **Region Filtering** â€” Target specific geographic markets (US, UK, BD, IN, Global, and more)
- ðŸ¢ **Business Segment Filtering** â€” SaaS, E-commerce, Healthcare, Finance, and 15+ segments
- ðŸ“‚ **Category Filtering** â€” Custom content/product category tagging
- ðŸ“¤ **Export** â€” Download keyword lists as CSV or JSON with seosiri.com backlinks
- ðŸ”— **Share** â€” Native share sheet support (CSV, plain text)
- ðŸ“± **Flutter Widgets** â€” Drop-in `KeywordListWidget`, `KeywordFilterPanel`, `KeywordMetricsCard`

## 2.0.0

**Zero-cost real API upgrade â€” no more simulated data**

### New Services
- `GoogleAutocompleteService` â€” alphabetical + question + preposition + qualifier + YouTube expansion (500â€“1,000 phrases per seed)
- `DatamuseService` â€” semantic/LSI keyword expansion, synonyms, co-occurring terms, topic vocabulary (no API key)
- `GoogleTrendsService` â€” real trend direction, interest score, rising related queries (no API key)
- `WikipediaService` â€” entity relationships, semantic category clusters, page summaries (no API key)
- `GoogleSearchConsoleService` â€” real clicks/impressions/CTR/position from user's own verified properties (free OAuth)
- `RealMetricsService` â€” derives volume, difficulty, CPC from actual API signals (no randomness)
- `KeywordClusterBuilder` â€” semantic topic clustering of all keywords into pillar + supporting groups

### New Widgets
- `ProgressOverlay` â€” animated real-time pipeline progress (shows each API stage)
- `KeywordClusterWidget` â€” visual topic cluster display with expandable groups
- `GscConnectWidget` â€” Google Search Console OAuth flow + striking distance / top keyword / cannibalization views
- `TrendChip` â€” real-time trend direction badge

### Infrastructure
- `RateLimiter` â€” token-bucket per-API rate limiting to stay inside free quotas
- `KeywordCacheService` â€” two-layer cache (L1 memory + L2 SharedPreferences) with 24hr TTL

### Breaking Changes
- `KeywordListResult` now includes `clusterSummaries`, `trendDirection`, `trendInterestScore`, `risingRelatedQueries`
- `KeywordGeneratorService.generate()` now accepts `onProgress` callback and `fetchTrends/fetchWikipedia/fetchDatamuse` flags
