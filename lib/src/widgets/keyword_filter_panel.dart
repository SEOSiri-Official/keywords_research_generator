import 'package:flutter/material.dart';
import '../models/keyword_filter.dart';
import '../models/search_intent.dart';
import '../models/keyword_type.dart';
import '../utils/keyword_constants.dart';

/// A slide-out or inline panel for configuring [KeywordFilter] parameters.
class KeywordFilterPanel extends StatefulWidget {
  final KeywordFilter initialFilter;
  final ValueChanged<KeywordFilter> onFilterChanged;

  const KeywordFilterPanel({
    super.key,
    required this.initialFilter,
    required this.onFilterChanged,
  });

  @override
  State<KeywordFilterPanel> createState() => _KeywordFilterPanelState();
}

class _KeywordFilterPanelState extends State<KeywordFilterPanel> {
  late KeywordFilter _filter;

  @override
  void initState() {
    super.initState();
    _filter = widget.initialFilter;
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      shrinkWrap: true,
      children: [
        _sectionTitle('Search Intent'),
        Wrap(
          spacing: 8,
          children: SearchIntent.values.map((intent) {
            final selected = _filter.intents?.contains(intent) ?? false;
            return FilterChip(
              label: Text('${intent.emoji} ${intent.label}'),
              selected: selected,
              onSelected: (val) {
                final current =
                    List<SearchIntent>.from(_filter.intents ?? SearchIntent.values);
                val ? current.add(intent) : current.remove(intent);
                _update(_filter.copyWith(intents: current));
              },
            );
          }).toList(),
        ),
        const SizedBox(height: 16),

        _sectionTitle('Keyword Type'),
        Wrap(
          spacing: 8,
          children: KeywordType.values.map((type) {
            final selected = _filter.keywordTypes?.contains(type) ?? false;
            return FilterChip(
              label: Text(type.label),
              selected: selected,
              onSelected: (val) {
                final current =
                    List<KeywordType>.from(_filter.keywordTypes ?? KeywordType.values);
                val ? current.add(type) : current.remove(type);
                _update(_filter.copyWith(keywordTypes: current));
              },
            );
          }).toList(),
        ),
        const SizedBox(height: 16),

        _sectionTitle('Region'),
        DropdownButtonFormField<String>(
          initialValue: _filter.region,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
          hint: const Text('All Regions'),
          items: KeywordConstants.regions
              .map((r) => DropdownMenuItem(value: r, child: Text(r)))
              .toList(),
          onChanged: (v) => _update(_filter.copyWith(region: v)),
        ),
        const SizedBox(height: 12),

        _sectionTitle('Business Segment'),
        DropdownButtonFormField<String>(
          initialValue: _filter.businessSegment,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
          hint: const Text('All Segments'),
          items: KeywordConstants.businessSegments
              .map((s) => DropdownMenuItem(value: s, child: Text(s)))
              .toList(),
          onChanged: (v) => _update(_filter.copyWith(businessSegment: v)),
        ),
        const SizedBox(height: 12),

        _sectionTitle('Max SEO Difficulty (${_filter.maxSeoDifficulty ?? 100})'),
        Slider(
          value: (_filter.maxSeoDifficulty ?? 100).toDouble(),
          min: 0,
          max: 100,
          divisions: 20,
          label: '${_filter.maxSeoDifficulty ?? 100}',
          onChanged: (v) => _update(_filter.copyWith(maxSeoDifficulty: v.toInt())),
        ),
        const SizedBox(height: 8),

        _sectionTitle(
            'Min Opportunity Score (${_filter.minOpportunityScore ?? 0})'),
        Slider(
          value: (_filter.minOpportunityScore ?? 0).toDouble(),
          min: 0,
          max: 100,
          divisions: 20,
          label: '${_filter.minOpportunityScore ?? 0}',
          onChanged: (v) =>
              _update(_filter.copyWith(minOpportunityScore: v.toInt())),
        ),
        const SizedBox(height: 12),

        Row(
          children: [
            Expanded(
              child: SwitchListTile.adaptive(
                title: const Text('Voice Search Only'),
                value: _filter.voiceSearchOnly ?? false,
                dense: true,
                contentPadding: EdgeInsets.zero,
                onChanged: (v) => _update(_filter.copyWith(voiceSearchOnly: v)),
              ),
            ),
            Expanded(
              child: SwitchListTile.adaptive(
                title: const Text('AEO Ready Only'),
                value: _filter.aeoOnly ?? false,
                dense: true,
                contentPadding: EdgeInsets.zero,
                onChanged: (v) => _update(_filter.copyWith(aeoOnly: v)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        ElevatedButton.icon(
          onPressed: () => _update(const KeywordFilter()),
          icon: const Icon(Icons.refresh),
          label: const Text('Reset Filters'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.grey.shade200,
            foregroundColor: Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _sectionTitle(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(
          text,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
        ),
      );

  void _update(KeywordFilter filter) {
    setState(() => _filter = filter);
    widget.onFilterChanged(filter);
  }
}
