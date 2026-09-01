import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../domain/entities/product.dart';

class ProductImage extends StatelessWidget {
  const ProductImage({
    required this.product,
    this.fit = BoxFit.contain,
    this.placeholderKey = const Key('productImagePlaceholder'),
    this.networkImageKey,
    this.placeholderIconSize = 42,
    super.key,
  });

  final Product product;
  final BoxFit fit;
  final Key placeholderKey;
  final Key? networkImageKey;
  final double placeholderIconSize;

  @override
  Widget build(BuildContext context) {
    final String? url = product.thumbnailUrl?.trim();
    if (url == null || url.isEmpty) {
      return _ImagePlaceholder(
        placeholderKey: placeholderKey,
        iconSize: placeholderIconSize,
      );
    }

    return CachedNetworkImage(
      key: networkImageKey,
      imageUrl: url,
      fit: fit,
      placeholder: (BuildContext context, String imageUrl) => const Center(
        child: SizedBox.square(
          dimension: 22,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
      errorWidget: (BuildContext context, String imageUrl, Object error) {
        return _ImagePlaceholder(
          placeholderKey: placeholderKey,
          iconSize: placeholderIconSize,
        );
      },
    );
  }
}

class _ImagePlaceholder extends StatelessWidget {
  const _ImagePlaceholder({
    required this.placeholderKey,
    required this.iconSize,
  });

  final Key placeholderKey;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    return Center(
      key: placeholderKey,
      child: Icon(
        Icons.image_outlined,
        size: iconSize,
        color: Theme.of(context).colorScheme.outline,
      ),
    );
  }
}
