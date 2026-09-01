import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show FloatingHeaderSnapConfiguration;
import 'package:flutter_riverpod/flutter_riverpod.dart';

class PrimarySearchHeader extends StatelessWidget {
  const PrimarySearchHeader({
    required this.controller,
    required this.focusNode,
    required this.onChanged,
    required this.onClear,
    super.key,
  });

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
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
    required this.history,
    required this.quickSearches,
    required this.activeKeyword,
    required this.onSearchSelected,
    required this.onAllSelected,
    super.key,
  });

  final AsyncValue<List<String>> history;
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
        padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            SizedBox(
              height: 36,
              child: history.when(
                data: (List<String> searches) {
                  if (searches.isEmpty) {
                    return const Align(
                      alignment: Alignment.centerLeft,
                      child: Text('Discover products'),
                    );
                  }
                  final String recent = searches.first;
                  return TextButton.icon(
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
                  );
                },
                loading: () => const Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Loading recent searches…'),
                ),
                error: (Object error, StackTrace stackTrace) => const Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Discover products'),
                ),
              ),
            ),
            const SizedBox(height: 4),
            Expanded(
              child: SingleChildScrollView(
                key: const Key('quickSearchList'),
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: quickSearches
                      .map((item) {
                        final bool selected = activeKeyword == item.keyword;
                        return Padding(
                          padding: const EdgeInsets.only(right: 22),
                          child: InkWell(
                            key: ValueKey<String>('quickSearch-${item.label}'),
                            onTap: item.keyword.isEmpty
                                ? onAllSelected
                                : () => onSearchSelected(item.keyword),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: <Widget>[
                                  Text(
                                    item.label,
                                    style: theme.textTheme.labelLarge?.copyWith(
                                      color: selected
                                          ? theme.colorScheme.primary
                                          : theme.colorScheme.onSurfaceVariant,
                                      fontWeight: selected
                                          ? FontWeight.w700
                                          : FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 5),
                                  AnimatedContainer(
                                    duration: const Duration(milliseconds: 160),
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

class FixedHeaderDelegate extends SliverPersistentHeaderDelegate {
  FixedHeaderDelegate({
    required this.extent,
    required this.child,
    this.snap = false,
    this.tickerProvider,
  });

  final double extent;
  final Widget child;
  final bool snap;
  final TickerProvider? tickerProvider;

  @override
  double get minExtent => extent;

  @override
  double get maxExtent => extent;

  @override
  TickerProvider? get vsync => tickerProvider;

  @override
  FloatingHeaderSnapConfiguration? get snapConfiguration => snap
      ? FloatingHeaderSnapConfiguration(
          curve: Curves.easeOut,
          duration: const Duration(milliseconds: 180),
        )
      : null;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return SizedBox.expand(child: child);
  }

  @override
  bool shouldRebuild(covariant FixedHeaderDelegate oldDelegate) {
    return extent != oldDelegate.extent ||
        child != oldDelegate.child ||
        snap != oldDelegate.snap ||
        tickerProvider != oldDelegate.tickerProvider;
  }
}
