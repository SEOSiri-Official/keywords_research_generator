import 'package:flutter_test/flutter_test.dart';
import 'package:keywords_research_generator/keywords_research_generator.dart';

void main() {
  group('IntentAnalyzerService', () {
    final analyzer = IntentAnalyzerService();

    test('classifies informational keywords correctly', () {
      expect(analyzer.classify('what is flutter'), SearchIntent.informational);
      expect(analyzer.classify('how to do seo'), SearchIntent.informational);
      expect(analyzer.classify('guide to keyword research'), SearchIntent.informational);
    });

    test('classifies commercial keywords correctly', () {
      expect(analyzer.classify('best flutter plugins'), SearchIntent.commercial);
      expect(analyzer.classify('flutter vs react native'), SearchIntent.commercial);
      expect(analyzer.classify('top seo tools review'), SearchIntent.commercial);
    });

    test('classifies transactional keywords correctly', () {
      expect(analyzer.classify('buy seo tool'), SearchIntent.transactional);
      expect(analyzer.classify('sign up free trial'), SearchIntent.transactional);
    });
  });

  group('KeywordTypeExtension', () {
    test('classifies by word count', () {
      expect(KeywordTypeExtension.fromWordCount(1), KeywordType.shortTail);
      expect(KeywordTypeExtension.fromWordCount(2), KeywordType.shortTail);
      expect(KeywordTypeExtension.fromWordCount(3), KeywordType.mediumTail);
      expect(KeywordTypeExtension.fromWordCount(4), KeywordType.mediumTail);
      expect(KeywordTypeExtension.fromWordCount(5), KeywordType.longTail);
      expect(KeywordTypeExtension.fromWordCount(10), KeywordType.longTail);
    });
  });

  group('KeywordMetrics', () {
    test('computes reasonable opportunity scores', () {
      final high = KeywordMetrics.compute(
        estimatedMonthlySearches: 100000,
        seoDifficulty: 20,
        cpcCompetition: 40,
        estimatedCpc: 1.50,
        intent: SearchIntent.transactional,
        keywordType: KeywordType.longTail,
      );
      expect(high.opportunityScore, greaterThan(50));

      final low = KeywordMetrics.compute(
        estimatedMonthlySearches: 50,
        seoDifficulty: 95,
        cpcCompetition: 90,
        estimatedCpc: 0.10,
        intent: SearchIntent.informational,
        keywordType: KeywordType.shortTail,
      );
      expect(low.opportunityScore, lessThan(high.opportunityScore));
    });

    test('voice friendly only for long-tail informational', () {
      final m = KeywordMetrics.compute(
        estimatedMonthlySearches: 1000,
        seoDifficulty: 30,
        cpcCompetition: 30,
        estimatedCpc: 0.50,
        intent: SearchIntent.informational,
        keywordType: KeywordType.longTail,
      );
      expect(m.isVoiceSearchFriendly, isTrue);

      final m2 = KeywordMetrics.compute(
        estimatedMonthlySearches: 1000,
        seoDifficulty: 30,
        cpcCompetition: 30,
        estimatedCpc: 0.50,
        intent: SearchIntent.transactional,
        keywordType: KeywordType.shortTail,
      );
      expect(m2.isVoiceSearchFriendly, isFalse);
    });
  });

  group('VoiceSearchService', () {
    final service = VoiceSearchService();

    test('generates question variants', () {
      final variants = service.generateQuestionVariants('flutter seo plugin');
      expect(variants, isNotEmpty);
      expect(variants.any((v) => v.contains('flutter seo plugin')), isTrue);
    });

    test('generates AEO variants', () {
      final aeo = service.generateAeoVariants('keyword research');
      expect(aeo, isNotEmpty);
      expect(aeo.any((v) => v.contains('keyword research')), isTrue);
    });
  });

  group('KeywordGeneratorService', () {
    final generator = KeywordGeneratorService();

    test('generates keywords from seed', () async {
      final result = await generator.generate(
        seedKeyword: 'flutter',
        maxKeywords: 30,
      );
      expect(result.keywords, isNotEmpty);
      expect(result.seedKeyword, equals('flutter'));
    });

    test('filter by intent works', () async {
      final result = await generator.generate(
        seedKeyword: 'seo tool',
        filter: const KeywordFilter(
          intents: [SearchIntent.informational],
        ),
        maxKeywords: 50,
      );
      for (final kw in result.keywords) {
        expect(kw.intent, equals(SearchIntent.informational));
      }
    });

    test('result includes seosiri.com attribution', () async {
      final result = await generator.generate(seedKeyword: 'test');
      expect(result.backlinkUrl, contains('seosiri.com'));
      expect(result.poweredBy, isNotEmpty);
    });
  });

  group('KeywordExportService', () {
    final exporter = KeywordExportService();

    test('generates valid CSV with attribution footer', () async {
      final generator = KeywordGeneratorService();
      final result = await generator.generate(seedKeyword: 'flutter', maxKeywords: 5);
      final csv = exporter.toCsv(result);
      expect(csv, contains('Keyword Phrase'));
      expect(csv, contains('seosiri.com'));
    });

    test('generates valid JSON with meta', () async {
      final generator = KeywordGeneratorService();
      final result = await generator.generate(seedKeyword: 'seo', maxKeywords: 5);
      final json = exporter.toJson(result);
      expect(json, contains('"_meta"'));
      expect(json, contains('seosiri.com'));
    });
  });
}
