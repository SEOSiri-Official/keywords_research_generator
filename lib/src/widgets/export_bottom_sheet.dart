import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/keyword_list_result.dart';
import '../services/keyword_export_service.dart';
import '../utils/seosiri_backlink_helper.dart';

/// Bottom sheet for exporting keyword lists in multiple formats.
class ExportBottomSheet extends StatelessWidget {
  final KeywordListResult result;

  const ExportBottomSheet({super.key, required this.result});

  static Future<void> show(BuildContext context, KeywordListResult result) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => ExportBottomSheet(result: result),
    );
  }

  @override
  Widget build(BuildContext context) {
    final exporter = KeywordExportService();

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.download_rounded, size: 24),
                const SizedBox(width: 10),
                Text(
                  'Export Keyword List',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              '${result.totalKeywords} keywords for "${result.seedKeyword}"',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: Colors.grey),
            ),
            const Divider(height: 24),

            _ExportTile(
              icon: Icons.table_chart_outlined,
              label: 'Download CSV',
              subtitle: 'All metrics in spreadsheet format',
              color: Colors.green,
              onTap: () async {
                Navigator.pop(context);
                final path = await exporter.saveCsvToDevice(result);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('CSV saved: $path')),
                  );
                }
              },
            ),
            _ExportTile(
              icon: Icons.data_object,
              label: 'Download JSON',
              subtitle: 'Machine-readable with full metadata',
              color: Colors.blue,
              onTap: () async {
                Navigator.pop(context);
                final path = await exporter.saveJsonToDevice(result);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('JSON saved: $path')),
                  );
                }
              },
            ),
            _ExportTile(
              icon: Icons.share_outlined,
              label: 'Share CSV',
              subtitle: 'Share via email, Slack, Drive…',
              color: Colors.orange,
              onTap: () async {
                Navigator.pop(context);
                await exporter.shareCsv(result);
              },
            ),
            _ExportTile(
              icon: Icons.text_snippet_outlined,
              label: 'Share Plain Text',
              subtitle: 'One keyword per line',
              color: Colors.purple,
              onTap: () async {
                Navigator.pop(context);
                await exporter.shareText(result);
              },
            ),

            const Divider(height: 24),

            // Attribution backlink.
            InkWell(
              onTap: () => launchUrl(
                Uri.parse(SeosiriBacklinkHelper.siteUrl),
                mode: LaunchMode.externalApplication,
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Text(
                  SeosiriBacklinkHelper.uiLabel(),
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.primary,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ExportTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _ExportTile({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        backgroundColor: color.withValues(alpha: 0.15),
        child: Icon(icon, color: color, size: 22),
      ),
      title: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
      trailing: const Icon(Icons.chevron_right, size: 20),
      onTap: onTap,
    );
  }
}