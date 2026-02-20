import 'package:flutter/material.dart';
import 'package:keywords_research_generator/keywords_research_generator.dart';

void main() => runApp(const KeywordsResearchApp());

class KeywordsResearchApp extends StatelessWidget {
  const KeywordsResearchApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Keywords Research Generator',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: const Color(0xFF1A73E8),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}

// ─── Home Screen ───────────────────────────────────────────────────────────────

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _generator = KeywordGeneratorService();
  final _gscService = GoogleSearchConsoleService();

  KeywordListResult? _result;
  bool _loading = false;
  int _progress = 0;
  String _progressMsg = '';
  KeywordFilter _filter = const KeywordFilter();
  bool _showFilter = false;
  int _tabIndex = 0;

  Future<void> _onSearch(String seed) async {
    setState(() {
      _loading = true;
      _progress = 0;
      _progressMsg = 'Starting…';
    });

    try {
      final result = await _generator.generate(
        seedKeyword: seed,
        filter: _filter,
        maxKeywords: 80,
        fetchTrends: true,
        fetchWikipedia: true,
        fetchDatumuse: true,
        onProgress: (pct, msg) {
          if (mounted) {
            setState(() {
              _progress = pct;
              _progressMsg = msg;
            });
          }
        },
      );

      if (mounted) setState(() => _result = result);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('🔍 Keywords Research Generator',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            Text('seosiri.com — Free API powered',
                style: TextStyle(fontSize: 10, color: Colors.white70)),
          ],
        ),
        actions: [
          if (_result != null)
            IconButton(
              icon: const Icon(Icons.download_rounded),
              tooltip: 'Export',
              onPressed: () =>
                  ExportBottomSheet.show(context, _result!),
            ),
          IconButton(
            icon: Icon(_showFilter
                ? Icons.filter_alt
                : Icons.filter_alt_outlined),
            tooltip: 'Filters',
            onPressed: () => setState(() => _showFilter = !_showFilter),
          ),
        ],
      ),
      body: Column(
        children: [
          // Trend banner when result loaded
          if (_result != null)
            _TrendBanner(result: _result!),

          KeywordSearchBar(
            isLoading: _loading,
            onSearch: _onSearch,
          ),

          if (_showFilter)
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 420),
              child: KeywordFilterPanel(
                initialFilter: _filter,
                onFilterChanged: (f) => setState(() => _filter = f),
              ),
            ),

          // Main content
          Expanded(
            child: _loading
                ? ProgressOverlay(
                    progress: _progress,
                    message: _progressMsg,
                    seedKeyword: '',
                  )
                : _result == null
                    ? _EmptyState()
                    : _ResultView(
                        result: _result!,
                        gscService: _gscService,
                        tabIndex: _tabIndex,
                        onTabChange: (i) => setState(() => _tabIndex = i),
                      ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _generator.dispose();
    _gscService.dispose();
    super.dispose();
  }
}

// ─── Trend Banner ─────────────────────────────────────────────────────────────

class _TrendBanner extends StatelessWidget {
  final KeywordListResult result;
  const _TrendBanner({required this.result});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.5),
      child: Row(
        children: [
          TrendChip(
            direction: result.trendDirection,
            interestScore: result.trendInterestScore,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '"${result.seedKeyword}" — ${result.totalKeywords} keywords · '
              '${result.clusterSummaries.length} clusters',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Result View ──────────────────────────────────────────────────────────────

class _ResultView extends StatelessWidget {
  final KeywordListResult result;
  final GoogleSearchConsoleService gscService;
  final int tabIndex;
  final ValueChanged<int> onTabChange;

  const _ResultView({
    required this.result,
    required this.gscService,
    required this.tabIndex,
    required this.onTabChange,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        NavigationBar(
          selectedIndex: tabIndex,
          onDestinationSelected: onTabChange,
          labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
          destinations: const [
            NavigationDestination(
                icon: Icon(Icons.list), label: 'Keywords'),
            NavigationDestination(
                icon: Icon(Icons.bubble_chart), label: 'Clusters'),
            NavigationDestination(
                icon: Icon(Icons.search), label: 'Search Console'),
          ],
        ),
        Expanded(
          child: IndexedStack(
            index: tabIndex,
            children: [
              // Keywords list
              KeywordListWidget(
                result: result,
                onKeywordTap: (kw) => _showDetail(context, kw),
              ),
              // Clusters view
              KeywordClusterWidget(
                clusters: result.clusterSummaries,
                onKeywordTap: (kw) => _showDetail(context, kw),
              ),
              // Google Search Console
              GscConnectWidget(
                gscService: gscService,
                onDataLoaded: (keywords) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text(
                            'Loaded ${keywords.length} real keywords from GSC')),
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showDetail(BuildContext context, KeywordModel kw) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _DetailSheet(keyword: kw),
    );
  }
}

// ─── Detail Sheet ─────────────────────────────────────────────────────────────

class _DetailSheet extends StatelessWidget {
  final KeywordModel keyword;
  const _DetailSheet({required this.keyword});

  @override
  Widget build(BuildContext context) {
    final m = keyword.metrics;

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.72,
      maxChildSize: 0.95,
      builder: (_, ctrl) => ListView(
        controller: ctrl,
        padding: const EdgeInsets.all(20),
        children: [
          Center(
            child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 16),

          // Phrase + badges
          Text(keyword.phrase,
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            children: [
              IntentBadge(intent: keyword.intent),
              TrendChip(direction: m.trendDirection, compact: true),
              if (m.isVoiceSearchFriendly)
                _tag('🎙 Voice', Colors.teal),
              if (m.isAeoFriendly)
                _tag('⚡ AEO', Colors.deepPurple),
            ],
          ),
          const Divider(height: 24),

          _section('📊 Metrics'),
          _row('Monthly Volume (est.)',
              _fmtVol(m.estimatedMonthlySearches)),
          _row('SEO Difficulty', '${m.seoDifficulty}/100'),
          _row('Opportunity Score', '${m.opportunityScore}/100'),
          _row('CPC Competition', '${m.cpcCompetition}/100'),
          _row('Est. CPC', '\$${m.estimatedCpc.toStringAsFixed(2)}'),
          _row('CTR Potential',
              '${(m.ctrPotential * 100).toStringAsFixed(1)}%'),
          _row('Keyword Type', keyword.keywordType.label),

          if (keyword.questionVariants.isNotEmpty) ...[
            const Divider(height: 24),
            _section('🎙 Voice / Question Variants'),
            ...keyword.questionVariants.map((q) => _bullet(q)),
          ],

          if (keyword.hints.isNotEmpty) ...[
            const Divider(height: 24),
            _section('💡 SEO / SEM Hints'),
            ...keyword.hints.map((h) => _HintCard(hint: h)),
          ],
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _section(String t) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(t,
            style: const TextStyle(
                fontWeight: FontWeight.bold, fontSize: 15)),
      );

  Widget _row(String l, String v) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(l,
                style: TextStyle(
                    color: Colors.grey.shade600, fontSize: 13)),
            Text(v,
                style: const TextStyle(
                    fontWeight: FontWeight.w600, fontSize: 13)),
          ],
        ),
      );

  Widget _bullet(String t) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('• ', style: TextStyle(color: Colors.grey)),
          Expanded(child: Text(t, style: const TextStyle(fontSize: 13))),
        ]),
      );

  Widget _tag(String t, Color c) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: c.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(t,
            style: TextStyle(
                fontSize: 11, color: c, fontWeight: FontWeight.w500)),
      );

  String _fmtVol(int v) {
    if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(1)}M/mo';
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(1)}K/mo';
    return '$v/mo';
  }
}

class _HintCard extends StatelessWidget {
  final SeoHint hint;
  const _HintCard({required this.hint});

  @override
  Widget build(BuildContext context) => Card(
        margin: const EdgeInsets.only(bottom: 8),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                      child: Text(hint.title,
                          style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 13))),
                  Text(hint.priority.label,
                      style: const TextStyle(fontSize: 11)),
                ],
              ),
              const SizedBox(height: 4),
              Text(hint.description,
                  style: const TextStyle(fontSize: 12)),
            ],
          ),
        ),
      );
}

// ─── Empty state ──────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🔍', style: TextStyle(fontSize: 64)),
            const SizedBox(height: 16),
            Text(
              'Enter a seed keyword to research',
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Powered by Google Autocomplete · Datamuse\n'
              'Google Trends · Wikipedia · Google Search Console',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 12, color: Colors.grey.shade500),
            ),
            const SizedBox(height: 4),
            const Text(
              'All FREE — no API keys required',
              style: TextStyle(
                  fontSize: 12,
                  color: Colors.green,
                  fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            const Text(
              '🔗 seosiri.com',
              style: TextStyle(
                  fontSize: 12,
                  color: Colors.blue,
                  decoration: TextDecoration.underline),
            ),
          ],
        ),
      ),
    );
  }
}