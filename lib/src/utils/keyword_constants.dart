/// Static word lists used to expand seed keywords into rich phrase sets.
/// All lists have been curated for SEO/SEM relevance.
class KeywordConstants {
  KeywordConstants._();

  // ─── Short-tail modifiers (1–2 words added) ───────────────────────────────
  static const shortTailModifiers = [
    'best', 'top', 'free', 'online', 'fast', 'easy',
    'professional', 'affordable', 'advanced', 'simple',
  ];

  // ─── Medium-tail prefixes (intent-neutral) ────────────────────────────────
  static const mediumTailPrefixes = [
    'how to use', 'what is the best', 'top rated',
    'complete guide to', 'introduction to', 'beginners guide to',
    'everything about', 'learn about', 'tips for',
  ];

  static const mediumTailSuffixes = [
    'for beginners', 'in 2025', 'tutorial', 'guide', 'review',
    'comparison', 'alternatives', 'pricing', 'features', 'benefits',
    'for small business', 'for enterprises', 'for startups',
  ];

  // ─── Long-tail question starters ─────────────────────────────────────────
  static const longTailQuestions = [
    'what is the best way to',
    'how do I get started with',
    'what are the benefits of',
    'how can businesses use',
    'what should I know about',
    'is it worth investing in',
    'what are common mistakes with',
    'how to choose the right',
    'why do experts recommend',
    'what are the top strategies for',
    'how to improve results with',
    'what are the latest trends in',
  ];

  static const longTailQualifiers = [
    'step by step for beginners',
    'without experience',
    'in under 10 minutes',
    'for small businesses in 2025',
    'that actually works',
    'without spending money',
    'for ecommerce websites',
    'for mobile apps',
    'for local businesses',
    'for B2B companies',
  ];

  // ─── Intent-specific modifier pools ──────────────────────────────────────

  static const informationalModifiers = [
    'what is', 'how to', 'why use', 'benefits of',
    'examples of', 'types of', 'guide to', 'learn',
    'understanding', 'explained',
  ];

  static const navigationalModifiers = [
    'official site', 'login', 'app download', 'docs',
    'website', 'dashboard', 'sign in',
  ];

  static const commercialModifiers = [
    'best', 'top', 'review', 'compare', 'vs',
    'alternatives to', 'pricing', 'worth it', 'recommended',
  ];

  static const transactionalModifiers = [
    'buy', 'get', 'download', 'try', 'sign up for',
    'subscribe to', 'free trial', 'order', 'hire',
  ];

  // ─── Business segments ────────────────────────────────────────────────────
  static const businessSegments = [
    'E-commerce',
    'SaaS',
    'Healthcare',
    'Finance',
    'Education',
    'Real Estate',
    'Travel',
    'Food & Beverage',
    'Retail',
    'Technology',
    'Legal',
    'Marketing Agency',
    'Non-profit',
    'Hospitality',
    'Manufacturing',
  ];

  // ─── Common regions ───────────────────────────────────────────────────────
  static const regions = [
    'Global',
    'US', 'UK', 'CA', 'AU', 'IN',
    'DE', 'FR', 'ES', 'IT', 'NL',
    'BD', 'PK', 'NG', 'ZA', 'BR',
    'SG', 'AE', 'JP', 'KR',
  ];

  // ─── Languages ────────────────────────────────────────────────────────────
  static const languages = [
    'en', 'es', 'fr', 'de', 'pt',
    'it', 'nl', 'bn', 'hi', 'ar', 'ja',
  ];
}
