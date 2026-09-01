import 'dart:math' as math;

import 'package:flutter/material.dart';

abstract final class SearchHeaderLayout {
  static const double horizontalPadding = 16;
  static const double primaryContentExtent = 72;
  static const double discoveryQuickOnlyExtent = 60;

  static const double _outerVerticalPadding = 12;
  static const double _quickOnlyBaseExtent = 48;
  static const double _quickVerticalPadding = 16;
  static const double _quickIndicatorGap = 5;
  static const double _quickIndicatorExtent = 2;

  static DiscoveryHeaderMetrics discoveryMetrics(BuildContext context) {
    final TextPainter labelPainter = TextPainter(
      text: TextSpan(
        text: 'Ag',
        style:
            Theme.of(context).textTheme.labelLarge ??
            const TextStyle(fontSize: 14),
      ),
      textDirection: Directionality.of(context),
      textScaler: MediaQuery.textScalerOf(context),
      maxLines: 1,
    )..layout();
    final double labelHeight = labelPainter.height;
    labelPainter.dispose();

    final double quickSearchRowExtent = math.max(
      _quickOnlyBaseExtent,
      labelHeight +
          _quickVerticalPadding +
          _quickIndicatorGap +
          _quickIndicatorExtent,
    );
    final double extent = _outerVerticalPadding + quickSearchRowExtent;

    return DiscoveryHeaderMetrics(
      extent: extent,
      quickSearchRowExtent: quickSearchRowExtent,
    );
  }
}

@immutable
final class DiscoveryHeaderMetrics {
  const DiscoveryHeaderMetrics({
    required this.extent,
    required this.quickSearchRowExtent,
  });

  final double extent;
  final double quickSearchRowExtent;
}

class PrimarySearchHeader extends StatelessWidget {
  const PrimarySearchHeader({
    required this.topInset,
    required this.controller,
    required this.focusNode,
    required this.onChanged,
    required this.onClear,
    super.key,
  });

  final double topInset;
  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.surface,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          SearchHeaderLayout.horizontalPadding,
          topInset + 10,
          SearchHeaderLayout.horizontalPadding,
          10,
        ),
        child: Row(
          children: <Widget>[
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Image.asset(
                'assets/branding/app_icon.png',
                key: const Key('gapsiLogo'),
                width: 44,
                height: 44,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ValueListenableBuilder<TextEditingValue>(
                valueListenable: controller,
                builder:
                    (
                      BuildContext context,
                      TextEditingValue value,
                      Widget? child,
                    ) {
                      return TextField(
                        key: const Key('searchField'),
                        controller: controller,
                        focusNode: focusNode,
                        textInputAction: TextInputAction.search,
                        onChanged: onChanged,
                        onSubmitted: (_) => focusNode.unfocus(),
                        onTapOutside: (_) => focusNode.unfocus(),
                        decoration: InputDecoration(
                          hintText: 'Search products',
                          prefixIcon: const Icon(Icons.search_rounded),
                          suffixIcon: value.text.isEmpty
                              ? null
                              : IconButton(
                                  key: const Key('clearSearchButton'),
                                  tooltip: 'Clear search',
                                  onPressed: onClear,
                                  icon: const Icon(Icons.close_rounded),
                                ),
                          filled: true,
                          fillColor: theme.colorScheme.surfaceContainerHighest,
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 12,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(
                              color: theme.colorScheme.outlineVariant,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(
                              color: theme.colorScheme.primary,
                              width: 1.5,
                            ),
                          ),
                        ),
                      );
                    },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class DiscoveryHeader extends StatelessWidget {
  const DiscoveryHeader({
    required this.metrics,
    required this.quickSearches,
    required this.activeKeyword,
    required this.favoritesSelected,
    required this.onFavoritesSelected,
    required this.onSearchSelected,
    super.key,
  });

  final DiscoveryHeaderMetrics metrics;
  final List<({String label, String keyword})> quickSearches;
  final String activeKeyword;
  final bool favoritesSelected;
  final VoidCallback onFavoritesSelected;
  final ValueChanged<String> onSearchSelected;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.surface,
      elevation: 1,
      shadowColor: theme.colorScheme.shadow.withValues(alpha: 0.12),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          SearchHeaderLayout.horizontalPadding,
          4,
          SearchHeaderLayout.horizontalPadding,
          8,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            SizedBox(
              height: metrics.quickSearchRowExtent,
              child: SingleChildScrollView(
                key: const Key('quickSearchList'),
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: <Widget>[
                    _DiscoveryItem(
                      label: 'Favorites',
                      icon: favoritesSelected
                          ? Icons.favorite
                          : Icons.favorite_border,
                      selected: favoritesSelected,
                      onTap: onFavoritesSelected,
                    ),
                    ...quickSearches.map((item) {
                      final bool selected = activeKeyword == item.keyword;
                      return _DiscoveryItem(
                        label: item.label,
                        selected: selected,
                        onTap: () => onSearchSelected(item.keyword),
                      );
                    }),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DiscoveryItem extends StatelessWidget {
  const _DiscoveryItem({
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Color foreground = selected
        ? theme.colorScheme.primary
        : theme.colorScheme.onSurfaceVariant;
    return Padding(
      padding: const EdgeInsets.only(right: 22),
      child: Semantics(
        key: ValueKey<String>('quickSearchSemantics-$label'),
        selected: selected,
        button: true,
        child: InkWell(
          key: ValueKey<String>('quickSearch-$label'),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    if (icon case final IconData value) ...<Widget>[
                      Icon(value, size: 18, color: foreground),
                      const SizedBox(width: 5),
                    ],
                    Text(
                      label,
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: foreground,
                        fontWeight: selected
                            ? FontWeight.w700
                            : FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                AnimatedContainer(
                  key: ValueKey<String>('quickSearchIndicator-$label'),
                  duration: const Duration(milliseconds: 160),
                  height: 2,
                  width: selected ? 36 : 0,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
