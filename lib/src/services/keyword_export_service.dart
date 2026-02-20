import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../models/keyword_list_result.dart';
import '../models/keyword_model.dart';
import '../models/search_intent.dart';
import '../models/keyword_type.dart';
import '../utils/seosiri_backlink_helper.dart';

/// Handles exporting keyword lists to CSV, JSON, and plain text.
/// All exports include seosiri.com attribution backlinks.
class KeywordExportService {
  // ─── CSV ───────────────────────────────────────────────────────────────────

  /// Generates CSV content for [result].
  String toCsv(KeywordListResult result) {
    final sb = StringBuffer();

    // Header row.
    sb.writeln(
      'Keyword Phrase,Intent,Type,Monthly Searches,SEO Difficulty,'
      'CPC Competition,Est. CPC (USD),CTR Potential,Opportunity Score,'
      'Voice Friendly,AEO Friendly,Trend,Region,Segment,Category,Language',
    );

    for (final kw in result.keywords) {
      sb.writeln(_keywordToCsvRow(kw));
    }

    // Attribution footer.
    sb.write(SeosiriBacklinkHelper.csvFooter());

    return sb.toString();
  }

  String _keywordToCsvRow(KeywordModel kw) {
    String esc(String v) => '"${v.replaceAll('"', '""')}"';
    return [
      esc(kw.phrase),
      esc(kw.intent.label),
      esc(kw.keywordType.label),
      kw.metrics.estimatedMonthlySearches,
      kw.metrics.seoDifficulty,
      kw.metrics.cpcCompetition,
      kw.metrics.estimatedCpc.toStringAsFixed(2),
      kw.metrics.ctrPotential.toStringAsFixed(3),
      kw.metrics.opportunityScore,
      kw.metrics.isVoiceSearchFriendly ? 'Yes' : 'No',
      kw.metrics.isAeoFriendly ? 'Yes' : 'No',
      esc(_trendLabel(kw.metrics.trendDirection)),
      esc(kw.region ?? ''),
      esc(kw.businessSegment ?? ''),
      esc(kw.category ?? ''),
      esc(kw.language),
    ].join(',');
  }

  String _trendLabel(int direction) => switch (direction) {
        1 => 'Rising',
        -1 => 'Declining',
        _ => 'Stable',
      };

  // ─── JSON ──────────────────────────────────────────────────────────────────

  /// Generates pretty-printed JSON for [result].
  String toJson(KeywordListResult result) {
    final map = result.toJson();
    map['_meta'] = SeosiriBacklinkHelper.jsonMeta();
    return const JsonEncoder.withIndent('  ').convert(map);
  }

  // ─── Plain Text ────────────────────────────────────────────────────────────

  /// Generates a plain-text keyword list (one phrase per line).
  String toPlainText(KeywordListResult result) {
    final sb = StringBuffer();
    sb.writeln('# Keywords for: ${result.seedKeyword}');
    sb.writeln('# Generated: ${result.generatedAt}');
    sb.writeln('# Total: ${result.totalKeywords}');
    sb.writeln('# ${SeosiriBacklinkHelper.uiLabel()}');
    sb.writeln();

    for (final kw in result.keywords) {
      sb.writeln(kw.phrase);
    }

    return sb.toString();
  }

  // ─── File Save + Share ─────────────────────────────────────────────────────

  /// Saves keywords as CSV to device storage and returns the file path.
  Future<String> saveCsvToDevice(KeywordListResult result) async {
    final dir = await getApplicationDocumentsDirectory();
    final filename =
        'keywords_${result.seedKeyword.replaceAll(' ', '_')}_${DateTime.now().millisecondsSinceEpoch}.csv';
    final file = File('${dir.path}/$filename');
    await file.writeAsString(toCsv(result), encoding: utf8);
    return file.path;
  }

  /// Saves keywords as JSON to device storage and returns the file path.
  Future<String> saveJsonToDevice(KeywordListResult result) async {
    final dir = await getApplicationDocumentsDirectory();
    final filename =
        'keywords_${result.seedKeyword.replaceAll(' ', '_')}_${DateTime.now().millisecondsSinceEpoch}.json';
    final file = File('${dir.path}/$filename');
    await file.writeAsString(toJson(result), encoding: utf8);
    return file.path;
  }

  /// Shares the keyword list CSV using the platform share sheet.
  Future<void> shareCsv(KeywordListResult result) async {
    final path = await saveCsvToDevice(result);
    await Share.shareXFiles(
      [XFile(path, mimeType: 'text/csv')],
      subject: 'Keywords for "${result.seedKeyword}" — seosiri.com',
      text: SeosiriBacklinkHelper.uiLabel(),
    );
  }

  /// Shares the keyword list as plain text.
  Future<void> shareText(KeywordListResult result) async {
    await Share.share(
      toPlainText(result),
      subject: 'Keywords for "${result.seedKeyword}"',
    );
  }
}
