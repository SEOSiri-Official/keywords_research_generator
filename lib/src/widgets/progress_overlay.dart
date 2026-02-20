import 'package:flutter/material.dart';

/// Animated progress overlay displayed while keyword generation runs.
/// Shows real step-by-step progress from the multi-API pipeline.
class ProgressOverlay extends StatelessWidget {
  final int progress; // 0–100
  final String message;
  final String seedKeyword;

  const ProgressOverlay({
    super.key,
    required this.progress,
    required this.message,
    required this.seedKeyword,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      color: theme.scaffoldBackgroundColor,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Animated icon
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.8, end: 1.0),
                duration: const Duration(milliseconds: 800),
                builder: (_, v, child) =>
                    Transform.scale(scale: v, child: child),
                child: const Text('🔍', style: TextStyle(fontSize: 56)),
              ),
              const SizedBox(height: 24),

              Text(
                'Researching: "$seedKeyword"',
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),

              // API pipeline stages
              _PipelineStages(progress: progress),
              const SizedBox(height: 20),

              // Progress bar
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: progress / 100,
                  backgroundColor: Colors.grey.shade200,
                  valueColor: AlwaysStoppedAnimation(
                    theme.colorScheme.primary,
                  ),
                  minHeight: 8,
                ),
              ),
              const SizedBox(height: 12),

              Text(
                message,
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: Colors.grey.shade600),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),

              Text(
                '$progress%',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),

              const SizedBox(height: 24),
              Text(
                '🔗 Powered by seosiri.com',
                style: TextStyle(
                  fontSize: 11,
                  color: theme.colorScheme.primary.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PipelineStages extends StatelessWidget {
  final int progress;

  const _PipelineStages({required this.progress});

  @override
  Widget build(BuildContext context) {
    final stages = [
      (icon: '🔍', label: 'Google Autocomplete', threshold: 5),
      (icon: '📚', label: 'Semantic Expansion', threshold: 30),
      (icon: '🌐', label: 'Wikipedia Entities', threshold: 45),
      (icon: '📈', label: 'Google Trends', threshold: 58),
      (icon: '⚙️', label: 'Building Models', threshold: 65),
      (icon: '🗂️', label: 'Clustering', threshold: 95),
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 6,
      alignment: WrapAlignment.center,
      children: stages.map((stage) {
        final done = progress >= stage.threshold;
        final active = progress >= stage.threshold &&
            progress < (stages.indexOf(stage) < stages.length - 1
                ? stages[stages.indexOf(stage) + 1].threshold
                : 101);

        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: done
                ? Colors.green.withValues(alpha: 0.15)
                : Colors.grey.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: active
                  ? Colors.blue.shade300
                  : done
                      ? Colors.green.shade300
                      : Colors.grey.shade300,
              width: active ? 1.5 : 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(stage.icon, style: const TextStyle(fontSize: 12)),
              const SizedBox(width: 4),
              Text(
                stage.label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: active ? FontWeight.bold : FontWeight.normal,
                  color: done ? Colors.green.shade700 : Colors.grey.shade600,
                ),
              ),
              if (done) ...[
                const SizedBox(width: 4),
                Icon(Icons.check_circle,
                    size: 12, color: Colors.green.shade600),
              ],
            ],
          ),
        );
      }).toList(),
    );
  }
}