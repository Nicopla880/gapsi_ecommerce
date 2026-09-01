import 'dart:math' as math;

import 'package:flutter/material.dart';

abstract final class SearchHeaderLayout {
  static const double horizontalPadding = 16;
  static const double primaryContentExtent = 72;
  static const double discoveryQuickOnlyExtent = 60;
  static const double discoveryWithRecentExtent = 96;

  static const double _outerVerticalPadding = 12;
  static const double _recentBaseExtent = 36;
  static const double _recentQuickGap = 4;
  static const double _quickOnlyBaseExtent = 48;
  static const double _quickWithRecentBaseExtent = 44;
  static const double _quickVerticalPadding = 16;
  static const double _quickIndicatorGap = 5;
  static const double _quickIndicatorExtent = 2;
  static const double _recentTextBreathingRoom = 8;

  static DiscoveryHeaderMetrics discoveryMetrics(
    BuildContext context, {
    required bool hasRecent,
  }) {
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
      hasRecent ? _quickWithRecentBaseExtent : _quickOnlyBaseExtent,
      labelHeight +
          _quickVerticalPadding +
          _quickIndicatorGap +
          _quickIndicatorExtent,
    );
    final double recentRowExtent = hasRecent
        ? math.max(_recentBaseExtent, labelHeight + _recentTextBreathingRoom)
        : 0;
    final double extent =
        _outerVerticalPadding +
        quickSearchRowExtent +
        (hasRecent ? recentRowExtent + _recentQuickGap : 0);

    return DiscoveryHeaderMetrics(
      extent: extent,
      recentRowExtent: recentRowExtent,
      quickSearchRowExtent: quickSearchRowExtent,
    );
  }
}

@immutable
final class DiscoveryHeaderMetrics {
  const DiscoveryHeaderMetrics({
    required this.extent,
    required this.recentRowExtent,
    required this.quickSearchRowExtent,
  });

  final double extent;
  final double recentRowExtent;
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
    required this.recentSearch,
    required this.quickSearches,
    required this.activeKeyword,
    required this.onSearchSelected,
    required this.onAllSelected,
    super.key,
  });

  final DiscoveryHeaderMetrics metrics;
  final String? recentSearch;
  final List<({String label, String keyword})> quickSearches;
  final String activeKeyword;
  final ValueChanged<String> onSearchSelected;
  final VoidCallback onAllSelected;

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
            if (recentSearch case final String recent) ...<Widget>[
              SizedBox(
                key: const Key('recentSearchRow'),
                height: metrics.recentRowExtent,
                child: TextButton.icon(
                  key: const Key('recentSearchShortcut'),
                  onPressed: () => onSearchSelected(recent),
                  icon: const Icon(Icons.history_rounded, size: 18),
                  label: Text(
                    'Recent: $recent',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    foregroundColor: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              const SizedBox(height: 4),
            ],
            SizedBox(
              height: metrics.quickSearchRowExtent,
              child: SingleChildScrollView(
                key: const Key('quickSearchList'),
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: quickSearches
                      .map((item) {
                        final bool selected = activeKeyword == item.keyword;
                        return Padding(
                          padding: const EdgeInsets.only(right: 22),
                          child: Semantics(
                            key: ValueKey<String>(
                              'quickSearchSemantics-${item.label}',
                            ),
                            selected: selected,
                            button: true,
                            child: InkWell(
                              key: ValueKey<String>(
                                'quickSearch-${item.label}',
                              ),
                              onTap: item.keyword.isEmpty
                                  ? onAllSelected
                                  : () => onSearchSelected(item.keyword),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 8,
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: <Widget>[
                                    Text(
                                      item.label,
                                      style: theme.textTheme.labelLarge
                                          ?.copyWith(
                                            color: selected
                                                ? theme.colorScheme.primary
                                                : theme
                                                      .colorScheme
                                                      .onSurfaceVariant,
                                            fontWeight: selected
                                                ? FontWeight.w700
                                                : FontWeight.w500,
                                          ),
                                    ),
                                    const SizedBox(height: 5),
                                    AnimatedContainer(
                                      key: ValueKey<String>(
                                        'quickSearchIndicator-${item.label}',
                                      ),
                                      duration: const Duration(
                                        milliseconds: 160,
                                      ),
                                      height: 2,
                                      width: selected ? 28 : 0,
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
                      })
                      .toList(growable: false),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
