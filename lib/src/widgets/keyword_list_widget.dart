import 'package:flutter/material.dart';
import '../models/keyword_list_result.dart';
import '../models/keyword_model.dart';
import '../utils/seosiri_backlink_helper.dart';
import 'keyword_metrics_card.dart';
import 'export_bottom_sheet.dart';

/// The primary list widget for displaying a [KeywordListResult].
///
/// Includes tabs for search intent grouping, sorting controls,
/// and an export button with seosiri.com backlink.
class KeywordListWidget extends StatefulWidget {
  final KeywordListResult result;
  final void Function(KeywordModel keyword)? onKeywordTap;

  const KeywordListWidget({
    super.key,
    required this.result,
    this.onKeywordTap,
  });

  @override
  State<KeywordListWidget> createState() => _KeywordListWidgetState();
}

class _KeywordListWidgetState extends State<KeywordListWidget>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  _SortOption _sortBy = _SortOption.opportunity;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<KeywordModel> get _allSorted => _sorted(widget.result.keywords);

  List<KeywordModel> _sorted(List<KeywordModel> kws) {
    final list = List<KeywordModel>.from(kws);
    switch (_sortBy) {
      case _SortOption.opportunity:
        list.sort((a, b) =>
            b.metrics.opportunityScore.compareTo(a.metrics.opportunityScore));
      case _SortOption.volume:
        list.sort((a, b) => b.metrics.estimatedMonthlySearches
            .compareTo(a.metrics.estimatedMonthlySearches));
      case _SortOption.difficulty:
        list.sort(
            (a, b) => a.metrics.seoDifficulty.compareTo(b.metrics.seoDifficulty));
      case _SortOption.cpc:
        list.sort(
            (a, b) => b.metrics.estimatedCpc.compareTo(a.metrics.estimatedCpc));
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final result = widget.result;

    return Column(
      children: [
        // ─ Summary bar ───────────────────────────────────────────────────────
        _SummaryBar(result: result),

        // ─ Sort + Export row ─────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Row(
            children: [
              const Text('Sort by:',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
              const SizedBox(width: 8),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _SortOption.values.map((opt) {
                      final selected = opt == _sortBy;
                      return Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: ChoiceChip(
                          label: Text(opt.label, style: const TextStyle(fontSize: 12)),
                          selected: selected,
                          onSelected: (_) => setState(() => _sortBy = opt),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.download_rounded),
                tooltip: 'Export keywords',
                onPressed: () => ExportBottomSheet.show(context, result),
              ),
            ],
          ),
        ),

        // ─ Tab bar ───────────────────────────────────────────────────────────
        TabBar(
          controller: _tabController,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          tabs: [
            _tab('All', result.totalKeywords),
            _tab('Info', result.informational.length),
            _tab('Nav', result.navigational.length),
            _tab('Comm', result.commercial.length),
            _tab('Trans', result.transactional.length),
            _tab('Long Tail', result.longTailKeywords.length),
          ],
        ),

        // ─ Tab views ─────────────────────────────────────────────────────────
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _KeywordPage(
                  keywords: _sorted(_allSorted),
                  onTap: widget.onKeywordTap),
              _KeywordPage(
                  keywords: _sorted(result.informational),
                  onTap: widget.onKeywordTap),
              _KeywordPage(
                  keywords: _sorted(result.navigational),
                  onTap: widget.onKeywordTap),
              _KeywordPage(
                  keywords: _sorted(result.commercial),
                  onTap: widget.onKeywordTap),
              _KeywordPage(
                  keywords: _sorted(result.transactional),
                  onTap: widget.onKeywordTap),
              _KeywordPage(
                  keywords: _sorted(result.longTailKeywords),
                  onTap: widget.onKeywordTap),
            ],
          ),
        ),

        // ─ Attribution footer ─────────────────────────────────────────────
        _AttributionBar(),
      ],
    );
  }

  Tab _tab(String label, int count) =>
      Tab(text: '$label ($count)');
}

// ─── Supporting widgets ────────────────────────────────────────────────────────

class _SummaryBar extends StatelessWidget {
  final KeywordListResult result;
  const _SummaryBar({required this.result});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.4),
      child: Row(
        children: [
          Expanded(
              child: _Stat('Total', '${result.totalKeywords}', Colors.blue)),
          Expanded(
              child: _Stat('Long Tail',
                  '${result.longTailKeywords.length}', Colors.green)),
          Expanded(
              child: _Stat(
                  'Voice', '${result.voiceSearchFriendly.length}', Colors.teal)),
          Expanded(
              child:
                  _Stat('AEO', '${result.aeoFriendly.length}', Colors.purple)),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _Stat(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) => Column(
        children: [
          Text(value,
              style: TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 18, color: color)),
          Text(label,
              style:
                  TextStyle(fontSize: 11, color: Colors.grey.shade600)),
        ],
      );
}

class _KeywordPage extends StatelessWidget {
  final List<KeywordModel> keywords;
  final void Function(KeywordModel)? onTap;
  const _KeywordPage({required this.keywords, this.onTap});

  @override
  Widget build(BuildContext context) {
    if (keywords.isEmpty) {
      return const Center(
          child: Text('No keywords match the current filters.'));
    }
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 16),
      itemCount: keywords.length,
      itemBuilder: (ctx, i) => KeywordMetricsCard(
        keyword: keywords[i],
        onTap: () => onTap?.call(keywords[i]),
      ),
    );
  }
}

class _AttributionBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Text(
        SeosiriBacklinkHelper.uiLabel(),
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 11,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}

enum _SortOption {
  opportunity,
  volume,
  difficulty,
  cpc;

  String get label => switch (this) {
        _SortOption.opportunity => 'Opportunity',
        _SortOption.volume => 'Volume',
        _SortOption.difficulty => 'Difficulty',
        _SortOption.cpc => 'CPC',
      };
}