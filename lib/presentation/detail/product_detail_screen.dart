import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/favorites_collection.dart';
import '../../domain/entities/product.dart';
import '../favorites/favorites_providers.dart';
import '../widgets/product_image.dart';

class ProductDetailScreen extends ConsumerWidget {
  const ProductDetailScreen({required this.product, super.key});

  final Product product;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeData theme = Theme.of(context);
    final String title = product.title.trim().isEmpty
        ? 'Product name unavailable'
        : product.title.trim();
    final String price = product.price == null
        ? 'Price unavailable'
        : '\$${product.price!.toStringAsFixed(2)}';
    final String description =
        _descriptionToPlainText(product.description) ??
        'Description unavailable';
    final double bottomInset = MediaQuery.paddingOf(context).bottom;
    final AsyncValue<FavoritesCollection> favorites = ref.watch(
      favoritesProvider,
    );
    final bool isFavorite = switch (favorites) {
      AsyncData<FavoritesCollection>(:final value) => value.contains(
        product.id,
      ),
      _ => false,
    };
    final bool favoritesReady = favorites is AsyncData<FavoritesCollection>;

    return Scaffold(
      key: const Key('productDetailScreen'),
      backgroundColor: theme.colorScheme.surfaceContainerLowest,
      appBar: AppBar(
        leading: const BackButton(key: Key('productDetailBackButton')),
        title: const Text(
          'Product details',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        backgroundColor: theme.colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 1,
        actions: <Widget>[
          IconButton(
            key: const Key('productDetailFavoriteButton'),
            tooltip: isFavorite ? 'Remove from favorites' : 'Add to favorites',
            onPressed: favoritesReady
                ? () async {
                    final bool saved = await ref
                        .read(favoritesProvider.notifier)
                        .toggleFavorite(product);
                    if (!saved && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Could not update favorites.'),
                        ),
                      );
                    }
                  }
                : null,
            icon: Icon(
              isFavorite ? Icons.favorite : Icons.favorite_border,
              key: Key(
                isFavorite
                    ? 'productDetailFavoriteFilled'
                    : 'productDetailFavoriteOutline',
              ),
              color: isFavorite ? theme.colorScheme.primary : null,
            ),
          ),
        ],
      ),
      body: CustomScrollView(
        key: const Key('productDetailScrollView'),
        slivers: <Widget>[
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            sliver: SliverToBoxAdapter(
              child: AspectRatio(
                aspectRatio: 1,
                child: Material(
                  color: theme.colorScheme.surface,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide(color: theme.colorScheme.outlineVariant),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: ProductImage(
                    product: product,
                    networkImageKey: const Key('productDetailNetworkImage'),
                    placeholderKey: const Key('productDetailImagePlaceholder'),
                    placeholderIconSize: 56,
                  ),
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    title,
                    key: const Key('productDetailTitle'),
                    style: theme.textTheme.headlineSmall?.copyWith(
                      height: 1.2,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    price,
                    key: const Key('productDetailPrice'),
                    style: product.price == null
                        ? theme.textTheme.titleMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          )
                        : theme.textTheme.headlineSmall?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w800,
                          ),
                  ),
                  const SizedBox(height: 24),
                  Divider(color: theme.colorScheme.outlineVariant),
                  const SizedBox(height: 18),
                  Text(
                    'Description',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    description,
                    key: const Key('productDetailDescription'),
                    style: theme.textTheme.bodyLarge?.copyWith(height: 1.5),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(child: SizedBox(height: bottomInset + 32)),
        ],
      ),
    );
  }
}

String? _descriptionToPlainText(String? source) {
  if (source == null || source.trim().isEmpty) return null;

  String text = source.trim();
  text = text.replaceAll(
    RegExp(
      r'<\s*script\b[^>]*>.*?<\s*/\s*script\s*>',
      caseSensitive: false,
      dotAll: true,
    ),
    '',
  );
  text = text.replaceAll(
    RegExp(
      r'<\s*style\b[^>]*>.*?<\s*/\s*style\s*>',
      caseSensitive: false,
      dotAll: true,
    ),
    '',
  );
  text = text.replaceAll(
    RegExp(r'<\s*br\s*/?\s*>', caseSensitive: false),
    '\n',
  );
  text = text.replaceAll(RegExp(r'<\s*li\b[^>]*>', caseSensitive: false), '• ');
  text = text.replaceAll(RegExp(r'<\s*/\s*li\s*>', caseSensitive: false), '\n');
  text = text.replaceAll(
    RegExp(r'<\s*/\s*(p|div|ul|ol)\s*>', caseSensitive: false),
    '\n',
  );
  text = text.replaceAll(RegExp(r'<[^>]*>'), '');
  text = _decodeHtmlEntities(text);

  final List<String> lines = text
      .split('\n')
      .map((String line) => line.replaceAll(RegExp(r'[ \t\r]+'), ' ').trim())
      .where((String line) => line.isNotEmpty)
      .toList(growable: false);
  return lines.isEmpty ? null : lines.join('\n');
}

String _decodeHtmlEntities(String source) {
  String text = source;
  const Map<String, String> namedEntities = <String, String>{
    '&nbsp;': ' ',
    '&quot;': '"',
    '&#39;': "'",
    '&apos;': "'",
    '&lt;': '<',
    '&gt;': '>',
    '&amp;': '&',
  };
  for (final MapEntry<String, String> entity in namedEntities.entries) {
    text = text.replaceAll(entity.key, entity.value);
  }
  text = text.replaceAllMapped(RegExp(r'&#(\d+);'), (Match match) {
    final int? codePoint = int.tryParse(match.group(1)!);
    return _characterFromCodePoint(codePoint) ?? match.group(0)!;
  });
  text = text.replaceAllMapped(
    RegExp(r'&#x([0-9a-f]+);', caseSensitive: false),
    (Match match) {
      final int? codePoint = int.tryParse(match.group(1)!, radix: 16);
      return _characterFromCodePoint(codePoint) ?? match.group(0)!;
    },
  );
  return text;
}

String? _characterFromCodePoint(int? codePoint) {
  if (codePoint == null || codePoint < 0 || codePoint > 0x10ffff) return null;
  return String.fromCharCode(codePoint);
}
