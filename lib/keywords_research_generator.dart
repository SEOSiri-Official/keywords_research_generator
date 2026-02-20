/// Keywords Research Generator — World-class Flutter plugin
/// powered entirely by free APIs.
///
/// Free API stack:
/// - Google Autocomplete (no key, alphabetical + question expansion)
/// - Datamuse (no key, semantic/LSI expansion)
/// - Google Trends unofficial (no key, real trend signals)
/// - Wikipedia/Wikidata (no key, entity clusters)
/// - Google Search Console (free OAuth, real user site data)
///
/// Publisher: seosiri.com | https://pub.dev/publishers/seosiri.com
library keywords_research_generator;

// ─── Models ───────────────────────────────────────────────────────────────────
export 'src/models/keyword_model.dart';
export 'src/models/search_intent.dart';
export 'src/models/keyword_type.dart';
export 'src/models/keyword_metrics.dart';
export 'src/models/seo_hint.dart';
export 'src/models/keyword_filter.dart';
export 'src/models/keyword_list_result.dart';

// ─── Core Services ────────────────────────────────────────────────────────────
export 'src/services/keyword_generator_service.dart';
export 'src/services/intent_analyzer_service.dart';
export 'src/services/seo_analyzer_service.dart';
export 'src/services/voice_search_service.dart';
export 'src/services/sem_optimizer_service.dart';
export 'src/services/keyword_export_service.dart';

// ─── Free API Services ────────────────────────────────────────────────────────
export 'src/services/free_apis/google_autocomplete_service.dart';
export 'src/services/free_apis/datamuse_service.dart';
export 'src/services/free_apis/google_trends_service.dart';
export 'src/services/free_apis/wikipedia_service.dart';
export 'src/services/free_apis/google_search_console_service.dart';

// ─── Pipeline ─────────────────────────────────────────────────────────────────
export 'src/services/pipeline/real_metrics_service.dart';
export 'src/services/pipeline/keyword_cluster_builder.dart';

// ─── Cache & Rate Limiting ────────────────────────────────────────────────────
export 'src/services/cache/keyword_cache_service.dart';
export 'src/services/cache/rate_limiter.dart';

// ─── Widgets ──────────────────────────────────────────────────────────────────
export 'src/widgets/keyword_list_widget.dart';
export 'src/widgets/keyword_search_bar.dart';
export 'src/widgets/keyword_filter_panel.dart';
export 'src/widgets/keyword_metrics_card.dart';
export 'src/widgets/intent_badge.dart';
export 'src/widgets/export_bottom_sheet.dart';
export 'src/widgets/keyword_cluster_widget.dart';
export 'src/widgets/gsc_connect_widget.dart';
export 'src/widgets/trend_chip.dart';
export 'src/widgets/progress_overlay.dart';

// ─── Utils ────────────────────────────────────────────────────────────────────
export 'src/utils/keyword_constants.dart';
export 'src/utils/seosiri_backlink_helper.dart';
