import 'package:flutter/material.dart';

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
        Text(
          'Recent searches',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        ...searches.map(
          (String search) => ListTile(
            key: ValueKey<String>('history-$search'),
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.history_rounded),
            title: Text(search, maxLines: 1, overflow: TextOverflow.ellipsis),
            trailing: const Icon(Icons.north_west_rounded, size: 18),
            onTap: () => onSelected(search),
          ),
        ),
      ],
    );
  }
}

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
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(icon, size: 52, color: theme.colorScheme.primary),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            if (actionLabel != null && onAction != null) ...<Widget>[
              const SizedBox(height: 20),
              FilledButton.tonal(
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
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 22),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Flexible(
            child: Text(
              message,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium,
            ),
          ),
          const SizedBox(width: 12),
          TextButton(
            key: const Key('paginationRetryButton'),
            onPressed: onRetry,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}
