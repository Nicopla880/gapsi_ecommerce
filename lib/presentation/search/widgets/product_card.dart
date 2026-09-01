import 'package:flutter/material.dart';

import '../../../design_system/gapsi_design_system.dart';
import '../../../domain/entities/product.dart';
import '../../widgets/product_image.dart';

class ProductCard extends StatelessWidget {
  const ProductCard({
    required this.product,
    this.onTap,
    this.isFavorite = false,
    this.onFavoriteToggle,
    super.key,
  });

  final Product product;
  final VoidCallback? onTap;
  final bool isFavorite;
  final VoidCallback? onFavoriteToggle;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool hasPrice = product.price != null;

    return Material(
      color: theme.colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: GapsiRadius.lgAll,
        side: BorderSide(color: GapsiColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        borderRadius: GapsiRadius.lgAll,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(GapsiSpacing.sm),
                child: Stack(
                  fit: StackFit.expand,
                  children: <Widget>[
                    // La imagen vive en su propio panel redondeado: separa el
                    // producto del borde de la tarjeta y da un fondo neutro a
                    // los PNG recortados que devuelve el API.
                    ClipRRect(
                      borderRadius: GapsiRadius.smAll,
                      child: ColoredBox(
                        color: GapsiColors.surfaceVariant,
                        child: Padding(
                          padding: const EdgeInsets.all(GapsiSpacing.sm),
                          child: ProductImage(
                            product: product,
                            heroTag: 'productImage-${product.id}',
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      top: -GapsiSpacing.xs,
                      right: -GapsiSpacing.xs,
                      child: GapsiFavoriteButton(
                        key: ValueKey<String>('favoriteButton-${product.id}'),
                        isFavorite: isFavorite,
                        onPressed: onFavoriteToggle,
                        filled: true,
                        filledIconKey: ValueKey<String>(
                          'favoriteFilled-${product.id}',
                        ),
                        outlineIconKey: ValueKey<String>(
                          'favoriteOutline-${product.id}',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                GapsiSpacing.md,
                GapsiSpacing.xs,
                GapsiSpacing.md,
                GapsiSpacing.md,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    product.title.isEmpty
                        ? 'Product name unavailable'
                        : product.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall,
                  ),
                  const SizedBox(height: GapsiSpacing.sm),
                  Text(
                    hasPrice
                        ? '\$${product.price!.toStringAsFixed(2)}'
                        : 'Price unavailable',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: hasPrice
                        ? theme.textTheme.titleMedium?.copyWith(
                            color: theme.colorScheme.primary,
                          )
                        : theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
