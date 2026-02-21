import 'package:flutter/material.dart';
import '../services/free_apis/google_search_console_service.dart';

/// Widget to connect Google Search Console via access token.
///
/// Obtain an OAuth access token using your preferred auth library
/// (google_sign_in, oauth2, etc.) and pass it via [onTokenProvided].
class GscConnectWidget extends StatefulWidget {
  final GoogleSearchConsoleService gscService;
  final void Function(List<GscKeywordRow> keywords)? onDataLoaded;

  const GscConnectWidget({
    super.key,
    required this.gscService,
    this.onDataLoaded,
  });

  @override
  State<GscConnectWidget> createState() => _GscConnectWidgetState();
}

class _GscConnectWidgetState extends State<GscConnectWidget> {
  bool _loading = false;
  List<GscProperty> _properties = [];
  GscProperty? _selected;
  List<GscKeywordRow> _strikingDistance = [];
  List<GscKeywordRow> _topKeywords = [];
  String? _error;
  final _tokenController = TextEditingController();

  @override
  void dispose() {
    _tokenController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.gscService.isSignedIn) return _tokenInputCard();
    if (_properties.isEmpty) return _loadPropertiesCard();
    if (_selected == null) return _propertyPicker();
    return _dataView();
  }

  Widget _tokenInputCard() {
    return Card(
      margin: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🔍', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 12),
            Text(
              'Connect Google Search Console',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Paste your Google OAuth access token to load real '
              'keyword data from your verified GSC properties.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
            ),
            const SizedBox(height: 16),
            const _FeatureRow(icon: '📈', label: 'Striking distance keywords (pos 11–20)'),
            const _FeatureRow(icon: '🥇', label: 'Top performing keywords'),
            const _FeatureRow(icon: '⚠️', label: 'Cannibalization risk detection'),
            const SizedBox(height: 16),
            TextField(
              controller: _tokenController,
              decoration: InputDecoration(
                labelText: 'OAuth Access Token',
                hintText: 'ya29.a0...',
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8)),
                suffixIcon: const Icon(Icons.vpn_key),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _loading ? null : _connectWithToken,
                icon: _loading
                    ? const SizedBox(
                        width: 16, height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.login),
                label: const Text('Connect'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(_error!,
                  style: const TextStyle(color: Colors.red, fontSize: 12)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _loadPropertiesCard() {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Connected as ${widget.gscService.userEmail ?? "GSC User"}',
                style: const TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _loading ? null : _loadProperties,
              icon: _loading
                  ? const SizedBox(
                      width: 16, height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.web),
              label: const Text('Load my properties'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _propertyPicker() {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Select a property:',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ..._properties.map((p) => ListTile(
                  title: Text(p.siteUrl,
                      style: const TextStyle(fontSize: 13)),
                  subtitle: Text(p.permissionLevel,
                      style: const TextStyle(fontSize: 11)),
                  leading: const Icon(Icons.language),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _loadData(p),
                )),
          ],
        ),
      ),
    );
  }

  Widget _dataView() {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '📊 ${_selected!.siteUrl}',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 13),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                TextButton(
                  onPressed: () => setState(() {
                    _selected = null;
                    _strikingDistance = [];
                    _topKeywords = [];
                  }),
                  child: const Text('Change'),
                ),
              ],
            ),
          ),
          const TabBar(
            tabs: [
              Tab(text: '🎯 Striking Distance'),
              Tab(text: '🥇 Top Keywords'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                _KeywordTable(_strikingDistance,
                    emptyMsg: 'No striking distance keywords found'),
                _KeywordTable(_topKeywords,
                    emptyMsg: 'No top keywords found'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _connectWithToken() async {
    final token = _tokenController.text.trim();
    if (token.isEmpty) {
      setState(() => _error = 'Please enter an access token.');
      return;
    }
    setState(() { _loading = true; _error = null; });
    widget.gscService.setAccessToken(token);
    await _loadProperties();
    setState(() => _loading = false);
    if (_properties.isEmpty) {
      widget.gscService.signOut();
      setState(() => _error = 'Invalid token or no properties found.');
    }
  }

  Future<void> _loadProperties() async {
    setState(() => _loading = true);
    final props = await widget.gscService.listProperties();
    setState(() { _properties = props; _loading = false; });
  }

  Future<void> _loadData(GscProperty property) async {
    setState(() { _selected = property; _loading = true; });
    final striking = await widget.gscService
        .strikingDistanceKeywords(siteUrl: property.siteUrl);
    final top =
        await widget.gscService.topKeywords(siteUrl: property.siteUrl);
    setState(() {
      _strikingDistance = striking;
      _topKeywords = top;
      _loading = false;
    });
    widget.onDataLoaded?.call([...striking, ...top]);
  }
}

class _FeatureRow extends StatelessWidget {
  final String icon;
  final String label;
  const _FeatureRow({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          children: [
            Text(icon),
            const SizedBox(width: 8),
            Text(label, style: const TextStyle(fontSize: 13)),
          ],
        ),
      );
}

class _KeywordTable extends StatelessWidget {
  final List<GscKeywordRow> rows;
  final String emptyMsg;
  const _KeywordTable(this.rows, {required this.emptyMsg});

  @override
  Widget build(BuildContext context) {
    if (rows.isEmpty) {
      return Center(
          child: Text(emptyMsg,
              style: const TextStyle(color: Colors.grey)));
    }
    return ListView.builder(
      itemCount: rows.length,
      itemBuilder: (ctx, i) {
        final r = rows[i];
        return ListTile(
          dense: true,
          title: Text(r.query, style: const TextStyle(fontSize: 13)),
          subtitle: Text(
            'Pos ${r.positionLabel} · ${r.clicks} clicks · '
            '${r.impressions} impr · ${r.ctrPercent} CTR',
            style: const TextStyle(fontSize: 11),
          ),
          leading: CircleAvatar(
            radius: 14,
            backgroundColor: r.isStrikingDistance
                ? Colors.orange.shade100
                : Colors.green.shade100,
            child: Text(
              '${i + 1}',
              style: TextStyle(
                fontSize: 10,
                color:
                    r.isStrikingDistance ? Colors.orange : Colors.green,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        );
      },
    );
  }
}