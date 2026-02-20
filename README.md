# keywords_research_generator

[![pub.dev](https://img.shields.io/pub/v/keywords_research_generator.svg)](https://pub.dev/packages/keywords_research_generator)
[![Publisher](https://img.shields.io/badge/publisher-seosiri.com-blue)](https://pub.dev/publishers/seosiri.com)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

> **A powerful Flutter plugin for keyword research, analysis, and generation.**
>
> Developed and published by **[seosiri.com](https://www.seosiri.com)** � Your SEO Intelligence Platform.

---

## ? Features

| Feature | Description |
|---|---|
| ?? **Keyword Generation** | Expand any seed keyword into 100+ phrases |
| ?? **Search Intent** | Auto-classify as Informational / Navigational / Commercial / Transactional |
| ?? **Keyword Types** | Short-tail, Medium-tail, Long-tail classification |
| ?? **SEO Metrics** | Volume, difficulty, opportunity score, CTR potential |
| ?? **SEM Hints** | CPC, match types, bid strategy, ad copy angles |
| ?? **Voice Search** | Conversational and question-based variant generation |
| ? **AEO** | Featured snippet and PAA targeting recommendations |
| ?? **Region / Segment** | Filter by country, business segment, category |
| ?? **Export** | CSV and JSON download with [seosiri.com](https://www.seosiri.com) backlinks |
| ?? **Drop-in Widgets** | `KeywordListWidget`, `KeywordFilterPanel`, `KeywordMetricsCard` |

---

## ?? Getting Started

### Installation

Add to your `pubspec.yaml`:

```yaml
dependencies:
  keywords_research_generator: ^1.0.0
```

Then run:

```bash
flutter pub get
```

---

## ?? Usage

### 1. Generate keywords from a seed

```dart
import 'package:keywords_research_generator/keywords_research_generator.dart';

final generator = KeywordGeneratorService();

final result = await generator.generate(
  seedKeyword: 'flutter plugin',
  filter: KeywordFilter(
    region: 'US',
    businessSegment: 'SaaS',
    category: 'Developer Tools',
    maxSeoDifficulty: 60,
    minOpportunityScore: 40,
  ),
  maxKeywords: 100,
);

print('Generated ${result.totalKeywords} keywords');
print('Long tail: ${result.longTailKeywords.length}');
print('Voice friendly: ${result.voiceSearchFriendly.length}');
```

### 2. Filter by search intent

```dart
final filter = KeywordFilter(
  intents: [SearchIntent.commercial, SearchIntent.transactional],
  keywordTypes: [KeywordType.longTail, KeywordType.mediumTail],
  voiceSearchOnly: false,
  aeoOnly: true,
);
```

### 3. Access SEO metrics

```dart
for (final kw in result.byOpportunity) {
  print('${kw.phrase}');
  print('  Intent: ${kw.intent.label}');
  print('  Type: ${kw.keywordType.label}');
  print('  Volume: ${kw.metrics.estimatedMonthlySearches}/mo');
  print('  SEO Difficulty: ${kw.metrics.seoDifficulty}/100');
  print('  Opportunity: ${kw.metrics.opportunityScore}/100');
  print('  CPC: \$${kw.metrics.estimatedCpc}');
  print('  Voice Friendly: ${kw.metrics.isVoiceSearchFriendly}');
  print('  AEO Friendly: ${kw.metrics.isAeoFriendly}');
}
```

### 4. Export to CSV or JSON

```dart
final exporter = KeywordExportService();

// Save CSV to device
final csvPath = await exporter.saveCsvToDevice(result);

// Save JSON to device
final jsonPath = await exporter.saveJsonToDevice(result);

// Share via platform share sheet
await exporter.shareCsv(result);
```

### 5. Analyse a single keyword

```dart
final intentAnalyzer = IntentAnalyzerService();
final intent = intentAnalyzer.classify('best flutter keyword plugin');
// ? SearchIntent.commercial

final seoAnalyzer = SeoAnalyzerService();
final semOptimizer = SemOptimizerService();

// Get SEO hints
final hints = seoAnalyzer.analyzeKeyword(keyword);
final semHints = semOptimizer.generateSemHints(keyword);
```

### 6. Voice search and AEO variants

```dart
final voiceService = VoiceSearchService();

final questions = voiceService.generateQuestionVariants('flutter seo plugin');
// ? ['what is flutter seo plugin', 'how to flutter seo plugin?', ...]

final aeoVariants = voiceService.generateAeoVariants('flutter seo plugin');
// ? ['what is flutter seo plugin', 'flutter seo plugin definition', ...]
```

---

## ?? Widgets

### Drop-in full list view

```dart
KeywordListWidget(
  result: result,
  onKeywordTap: (keyword) {
    // Handle keyword tap � show detail sheet, copy to clipboard, etc.
  },
)
```

### Filter panel

```dart
KeywordFilterPanel(
  initialFilter: KeywordFilter(),
  onFilterChanged: (filter) {
    // Regenerate with new filter
  },
)
```

### Search bar

```dart
KeywordSearchBar(
  hint: 'Enter seed keyword�',
  isLoading: isGenerating,
  onSearch: (seed) => generateKeywords(seed),
)
```

### Single keyword card

```dart
KeywordMetricsCard(
  keyword: keywordModel,
  onTap: () => showDetailSheet(keywordModel),
)
```

---

## ?? Search Intent Classification

| Intent | Description | Signals |
|---|---|---|
| ?? **Informational** | User wants to learn | "what", "how", "guide", "learn" |
| ?? **Navigational** | User looks for a specific site | "login", "official", "docs" |
| ?? **Commercial** | User is researching options | "best", "review", "compare", "vs" |
| ?? **Transactional** | User is ready to act | "buy", "sign up", "free trial" |

---

## ?? Keyword Type Classification

| Type | Word Count | Competition | Best Use |
|---|---|---|---|
| **Short Tail** | 1�2 words | Very high | Brand awareness, broad reach |
| **Medium Tail** | 3�4 words | Medium | Balanced SEO strategy |
| **Long Tail** | 5+ words | Low | Targeted SEO, AEO, voice search |

---

## ?? Voice Search & AEO

The `VoiceSearchService` automatically generates:
- Question variants ("What is�", "How do I�", "Which is the best�")
- Conversational phrases for smart speaker queries
- AEO-targeted phrases for featured snippets and knowledge panels

---

## ?? SEM Optimisation

The `SemOptimizerService` provides:
- Recommended match types (Exact / Phrase / Broad Match)
- Bid strategy recommendations (Manual CPC, Target CPA, Maximize Conversions)
- Ad copy angle guidance per intent type
- Landing page alignment reminders
- Region and segment-based ad group suggestions

---

## ?? Export Formats

All exports include a **[seosiri.com](https://www.seosiri.com)** attribution backlink.

| Format | Fields Included |
|---|---|
| **CSV** | Phrase, intent, type, volume, difficulty, CPC, CTR, opportunity, voice, AEO, trend, region, segment, category |
| **JSON** | Full keyword model with all metrics, hints, variants, and metadata |
| **Plain Text** | One phrase per line with header info |

---

## ?? Supported Regions

Global, US, UK, CA, AU, IN, DE, FR, ES, IT, NL, BD, PK, NG, ZA, BR, SG, AE, JP, KR, and more.

---

## ?? Supported Business Segments

E-commerce, SaaS, Healthcare, Finance, Education, Real Estate, Travel, Food & Beverage, Retail, Technology, Legal, Marketing Agency, Non-profit, Hospitality, Manufacturing.

---

## ?? Links

- ?? **Website**: [www.seosiri.com](https://www.seosiri.com)
- ?? **pub.dev**: [pub.dev/publishers/seosiri.com](https://pub.dev/publishers/seosiri.com)
- ?? **Issues**: [GitHub Issues](https://github.com/SEOSiri-Official/keywords_research_generator/issues)
- ?? **Docs**: [www.seosiri.com/p/flutter-plugin.html](https://www.seosiri.com/p/flutter-plugin.html)

---

## ?? License

MIT � [seosiri.com](https://www.seosiri.com)
