import 'package:flutter/material.dart';

import '../../../design_system/gapsi_design_system.dart';

class RecentSearches extends StatelessWidget {
  const RecentSearches({
    required this.searches,
    required this.onSelected,
    super.key,
  });

  final List<String> searches;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Column(
      key: const Key('recentSearchesSection'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text('Recent searches', style: theme.textTheme.titleLarge),
        const SizedBox(height: GapsiSpacing.md),
        ...searches.map(
          (String search) => Padding(
            padding: const EdgeInsets.only(bottom: GapsiSpacing.sm),
            child: Material(
              key: ValueKey<String>('history-$search'),
              color: theme.colorScheme.surface,
              shape: const RoundedRectangleBorder(
                borderRadius: GapsiRadius.smAll,
                side: BorderSide(color: GapsiColors.border),
              ),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: () => onSelected(search),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: GapsiSpacing.md,
                    vertical: GapsiSpacing.md,
                  ),
                  child: Row(
                    children: <Widget>[
                      const Icon(
                        Icons.history_rounded,
                        size: 20,
                        color: GapsiColors.textSecondary,
                      ),
                      const SizedBox(width: GapsiSpacing.md),
                      Expanded(
                        child: Text(
                          search,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodyLarge,
                        ),
                      ),
                      const SizedBox(width: GapsiSpacing.sm),
                      const Icon(
                        Icons.north_west_rounded,
                        size: 18,
                        color: GapsiColors.textSecondary,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Presentación común de los estados sin contenido: historial vacío, sin
/// resultados, sin favoritos y errores de búsqueda.
class SearchMessage extends StatelessWidget {
  const SearchMessage({
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.actionKey,
    this.onAction,
    super.key,
  });

  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final Key? actionKey;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(GapsiSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Container(
              padding: const EdgeInsets.all(GapsiSpacing.lg),
              decoration: const BoxDecoration(
                color: GapsiColors.blueSoft,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 32, color: GapsiColors.navy),
            ),
            const SizedBox(height: GapsiSpacing.lg),
            Text(
              title,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleLarge,
            ),
            if (message.isNotEmpty) ...<Widget>[
              const SizedBox(height: GapsiSpacing.sm),
              Text(
                message,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            if (actionLabel != null && onAction != null) ...<Widget>[
              const SizedBox(height: GapsiSpacing.xl),
              FilledButton(
                key: actionKey,
                onPressed: onAction,
                child: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class PaginationError extends StatelessWidget {
  const PaginationError({
    required this.message,
    required this.onRetry,
    super.key,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Padding(
      key: const Key('paginationError'),
      padding: const EdgeInsets.fromLTRB(
        GapsiSpacing.lg,
        GapsiSpacing.md,
        GapsiSpacing.lg,
        GapsiSpacing.xl,
      ),
      child: Container(
        padding: const EdgeInsets.fromLTRB(
          GapsiSpacing.lg,
          GapsiSpacing.sm,
          GapsiSpacing.sm,
          GapsiSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: theme.colorScheme.errorContainer,
          borderRadius: GapsiRadius.smAll,
        ),
        child: Row(
          children: <Widget>[
            Expanded(
              child: Text(
                message,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onErrorContainer,
                ),
              ),
            ),
            const SizedBox(width: GapsiSpacing.sm),
            TextButton(
              key: const Key('paginationRetryButton'),
              onPressed: onRetry,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
