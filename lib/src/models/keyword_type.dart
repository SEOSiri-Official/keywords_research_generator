/// Classifies keywords by length / specificity for SEO targeting.
enum KeywordType {
  /// 1–2 words. High volume, high competition.
  /// e.g. "flutter", "SEO tools"
  shortTail,

  /// 3–4 words. Balanced volume and competition.
  /// e.g. "flutter keyword research", "SEO tools free"
  mediumTail,

  /// 5+ words. Lower volume, very specific, easier to rank.
  /// e.g. "best flutter plugin for keyword research 2025"
  longTail,
}

extension KeywordTypeExtension on KeywordType {
  String get label {
    switch (this) {
      case KeywordType.shortTail:
        return 'Short Tail';
      case KeywordType.mediumTail:
        return 'Medium Tail';
      case KeywordType.longTail:
        return 'Long Tail';
    }
  }

  String get wordCountRange {
    switch (this) {
      case KeywordType.shortTail:
        return '1–2 words';
      case KeywordType.mediumTail:
        return '3–4 words';
      case KeywordType.longTail:
        return '5+ words';
    }
  }

  /// Approximate competition level (0–100, higher = harder to rank).
  int get typicalCompetition {
    switch (this) {
      case KeywordType.shortTail:
        return 85;
      case KeywordType.mediumTail:
        return 55;
      case KeywordType.longTail:
        return 25;
    }
  }

  static KeywordType fromWordCount(int count) {
    if (count <= 2) return KeywordType.shortTail;
    if (count <= 4) return KeywordType.mediumTail;
    return KeywordType.longTail;
  }
}
