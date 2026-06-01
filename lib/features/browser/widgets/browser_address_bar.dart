import 'package:flutter/material.dart';

/// The browser address / search bar. Displays the current URL or title and
/// enters an editable state on tap (selecting all text). Reports focus and text
/// changes so the host page can show search suggestions.
class BrowserAddressBar extends StatefulWidget {
  const BrowserAddressBar({
    super.key,
    required this.value,
    required this.isLoading,
    required this.isPrivate,
    required this.isBookmarked,
    required this.canBookmark,
    required this.onSubmit,
    required this.onReloadStop,
    required this.onToggleBookmark,
    required this.onFocusChange,
    required this.onChanged,
  });

  final String value;
  final bool isLoading;
  final bool isPrivate;
  final bool isBookmarked;
  final bool canBookmark;
  final ValueChanged<String> onSubmit;
  final VoidCallback onReloadStop;
  final VoidCallback onToggleBookmark;
  final ValueChanged<bool> onFocusChange;
  final ValueChanged<String> onChanged;

  @override
  State<BrowserAddressBar> createState() => _BrowserAddressBarState();
}

class _BrowserAddressBarState extends State<BrowserAddressBar> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value);
    _focusNode = FocusNode();
    _focusNode.addListener(_handleFocusChange);
  }

  @override
  void didUpdateWidget(covariant BrowserAddressBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Keep the text in sync with the page only while not actively editing.
    if (!_focused && widget.value != _controller.text) {
      _controller.text = widget.value;
    }
  }

  @override
  void dispose() {
    _focusNode.removeListener(_handleFocusChange);
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _handleFocusChange() {
    final focused = _focusNode.hasFocus;
    if (focused == _focused) return;
    setState(() => _focused = focused);
    if (focused) {
      _controller.selection = TextSelection(
        baseOffset: 0,
        extentOffset: _controller.text.length,
      );
    } else {
      // Reset to the page value when leaving edit mode without submitting.
      _controller.text = widget.value;
    }
    widget.onFocusChange(focused);
  }

  void _submit(String value) {
    _focusNode.unfocus();
    widget.onSubmit(value);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final hasText = _controller.text.isNotEmpty;
    return Container(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withOpacity(0.6),
        borderRadius: BorderRadius.circular(24),
        border: widget.isPrivate
            ? Border.all(color: scheme.tertiary, width: 1.2)
            : null,
      ),
      padding: const EdgeInsets.only(left: 12, right: 4),
      child: Row(
        children: [
          Icon(
            widget.isPrivate
                ? Icons.shield_outlined
                : (_focused ? Icons.search : Icons.lock_outline),
            size: 18,
            color: scheme.onSurfaceVariant,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _controller,
              focusNode: _focusNode,
              textInputAction: TextInputAction.go,
              keyboardType: TextInputType.url,
              autocorrect: false,
              enableSuggestions: false,
              style: Theme.of(context).textTheme.bodyMedium,
              decoration: const InputDecoration(
                isDense: true,
                border: InputBorder.none,
                hintText: '搜索或输入网址',
              ),
              onChanged: widget.onChanged,
              onSubmitted: _submit,
            ),
          ),
          if (_focused && hasText)
            IconButton(
              tooltip: '清空',
              icon: const Icon(Icons.close, size: 18),
              onPressed: () {
                _controller.clear();
                widget.onChanged('');
              },
            )
          else ...[
            if (widget.canBookmark)
              IconButton(
                tooltip: widget.isBookmarked ? '取消收藏' : '收藏',
                icon: Icon(
                  widget.isBookmarked ? Icons.star : Icons.star_border,
                  size: 20,
                  color: widget.isBookmarked ? scheme.primary : null,
                ),
                onPressed: widget.onToggleBookmark,
              ),
            IconButton(
              tooltip: widget.isLoading ? '停止' : '刷新',
              icon: Icon(
                widget.isLoading ? Icons.close : Icons.refresh,
                size: 20,
              ),
              onPressed: widget.canBookmark ? widget.onReloadStop : null,
            ),
          ],
        ],
      ),
    );
  }
}
