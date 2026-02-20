# 🚀 Publishing Guide — keywords_research_generator
## Publisher: seosiri.com → pub.dev/publishers/seosiri.com

---

## Prerequisites

1. **Flutter SDK** ≥ 3.10 — [flutter.dev](https://flutter.dev/docs/get-started/install)
2. **Dart SDK** ≥ 3.0 (bundled with Flutter)
3. **pub.dev account** linked to seosiri.com domain
4. **Domain verification** at pub.dev for seosiri.com publisher

---

## Step 1 — Open in VS Code

```bash
# Open the workspace file (launches both plugin + example in one window)
code keywords_research_generator.code-workspace
```

---

## Step 2 — Install dependencies

```bash
# Plugin dependencies
flutter pub get

# Example app dependencies
cd example && flutter pub get && cd ..
```

---

## Step 3 — Run tests

```bash
flutter test
```

All tests should pass before publishing.

---

## Step 4 — Run the example app

```bash
cd example
flutter run
```

Verify all features work:
- [ ] Keyword generation from seed
- [ ] Filter panel (intent, type, region, segment)
- [ ] Keyword list with tabs (All / Info / Nav / Comm / Trans / Long Tail)
- [ ] Keyword detail sheet with hints
- [ ] Export bottom sheet (CSV, JSON, Share)
- [ ] seosiri.com attribution footer

---

## Step 5 — Dry run (no upload, full validation)

```bash
flutter pub publish --dry-run
```

Fix any warnings before proceeding.

---

## Step 6 — Score check (aim for 140+ pub.dev score)

pub.dev scoring checklist:

- [x] README.md with examples and badges
- [x] CHANGELOG.md
- [x] LICENSE (MIT)
- [x] analysis_options.yaml with flutter_lints
- [x] Dartdoc comments on public APIs
- [x] example/ app
- [x] test/ with unit tests
- [x] pubspec.yaml homepage and repository fields

Run score locally:
```bash
dart pub global activate pana
pana .
```

Target: **140+ / 160 points**

---

## Step 7 — Publish

```bash
flutter pub publish
```

You will be prompted to confirm. The package will appear at:
```
https://pub.dev/packages/keywords_research_generator
https://pub.dev/publishers/seosiri.com/packages
```

---

## Step 8 — Post-publish checklist

- [ ] Verify listing at pub.dev/packages/keywords_research_generator
- [ ] Add package link to www.seosiri.com website
- [ ] Add backlink from seosiri.com homepage to pub.dev page
- [ ] Add pub.dev badge to seosiri.com developer docs page
- [ ] Tweet / announce on seosiri.com social channels

---

## Updating the package

1. Update code
2. Bump version in `pubspec.yaml` (e.g. `1.0.0` → `1.0.1`)
3. Add entry to `CHANGELOG.md` under new version heading
4. Run tests: `flutter test`
5. Dry run: `flutter pub publish --dry-run`
6. Publish: `flutter pub publish`

---

## Folder Structure Reference

```
keywords_research_generator/
├── lib/
│   ├── keywords_research_generator.dart   ← main export barrel
│   └── src/
│       ├── models/
│       │   ├── keyword_model.dart          ← core KeywordModel
│       │   ├── search_intent.dart          ← 4 intent types
│       │   ├── keyword_type.dart           ← short/medium/long tail
│       │   ├── keyword_metrics.dart        ← SEO/SEM metrics
│       │   ├── seo_hint.dart               ← hint/recommendation model
│       │   ├── keyword_filter.dart         ← filter parameters
│       │   └── keyword_list_result.dart    ← session result aggregate
│       ├── services/
│       │   ├── keyword_generator_service.dart  ← main generation engine
│       │   ├── intent_analyzer_service.dart    ← intent classification
│       │   ├── seo_analyzer_service.dart       ← SEO/AEO hints
│       │   ├── voice_search_service.dart       ← voice/AEO variants
│       │   ├── sem_optimizer_service.dart      ← SEM hints
│       │   └── keyword_export_service.dart     ← CSV/JSON export
│       ├── widgets/
│       │   ├── keyword_list_widget.dart        ← main list UI
│       │   ├── keyword_search_bar.dart         ← seed input
│       │   ├── keyword_filter_panel.dart       ← filter UI
│       │   ├── keyword_metrics_card.dart       ← single keyword card
│       │   ├── intent_badge.dart               ← intent color badge
│       │   └── export_bottom_sheet.dart        ← export/download UI
│       └── utils/
│           ├── keyword_constants.dart          ← word lists
│           └── seosiri_backlink_helper.dart    ← attribution strings
├── example/
│   ├── lib/main.dart                       ← full demo app
│   └── pubspec.yaml
├── test/
│   └── keywords_research_generator_test.dart
├── pubspec.yaml
├── README.md
├── CHANGELOG.md
├── LICENSE
├── analysis_options.yaml
└── keywords_research_generator.code-workspace
```

---

_Questions? Visit [www.seosiri.com](https://www.seosiri.com) or open an issue on GitHub._
