import 'package:flutter/material.dart';

/// A search bar for entering a seed keyword.
class KeywordSearchBar extends StatefulWidget {
  final String? hint;
  final ValueChanged<String>? onSearch;
  final bool isLoading;

  const KeywordSearchBar({
    super.key,
    this.hint,
    this.onSearch,
    this.isLoading = false,
  });

  @override
  State<KeywordSearchBar> createState() => _KeywordSearchBarState();
}

class _KeywordSearchBarState extends State<KeywordSearchBar> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final text = _controller.text.trim();
    if (text.isNotEmpty) widget.onSearch?.call(text);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withValues(alpha: 0.12),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: _controller,
        onSubmitted: (_) => _submit(),
        decoration: InputDecoration(
          hintText: widget.hint ?? 'Enter seed keyword (e.g. "flutter plugin")',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: widget.isLoading
              ? const Padding(
                  padding: EdgeInsets.all(12),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              : IconButton(
                  icon: const Icon(Icons.arrow_forward_ios, size: 18),
                  onPressed: _submit,
                ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: theme.cardColor,
          contentPadding:
              const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        ),
      ),
    );
  }
}