import '../models/keyword_model.dart';

/// Transforms standard keywords into voice-search and AEO-friendly variants.
///
/// Voice queries are typically conversational, longer, and question-based.
/// AEO (Answer Engine Optimization) targets featured snippets & knowledge panels.
class VoiceSearchService {
  static const _questionPrefixes = [
    'what is',
    'what are',
    'how to',
    'how do I',
    'how can I',
    'why is',
    'why does',
    'when should I',
    'where can I',
    'who can help with',
    'which is the best',
    'can I',
    'should I',
    'is there a',
    'tell me about',
  ];

  static const _voiceFillers = [
    'near me',
    'for beginners',
    'step by step',
    'for free',
    'in easy words',
    'explained',
    'complete guide',
    'examples',
  ];

  /// Generates question-form variants from a [phrase].
  List<String> generateQuestionVariants(String phrase) {
    final clean = phrase.trim().toLowerCase();
    final variants = <String>{};

    for (final prefix in _questionPrefixes) {
      variants.add('$prefix $clean');
      variants.add('$prefix $clean?');
    }

    return variants.take(8).toList();
  }

  /// Generates voice-search-optimised longer phrases.
  List<String> generateVoiceVariants(String phrase) {
    final clean = phrase.trim().toLowerCase();
    final variants = <String>{};

    for (final filler in _voiceFillers) {
      variants.add('$clean $filler');
    }

    // Conversational expansions.
    variants.add('best way to use $clean');
    variants.add('why should I use $clean');
    variants.add('$clean vs alternatives');
    variants.add('how does $clean work');

    return variants.toList();
  }

  /// Generates AEO-ready phrases targeting featured snippets.
  List<String> generateAeoVariants(String phrase) {
    final clean = phrase.trim().toLowerCase();
    return [
      'what is $clean',
      '$clean definition',
      '$clean meaning',
      '$clean explained',
      'how does $clean work',
      '$clean advantages and disadvantages',
      '$clean vs other options',
      'is $clean worth it',
    ];
  }

  /// Checks whether a keyword qualifies as voice-search-friendly.
  bool isVoiceFriendly(KeywordModel keyword) {
    return keyword.metrics.isVoiceSearchFriendly &&
        keyword.wordCount >= 4;
  }
}