import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/favorites_collection.dart';
import 'favorites_notifier.dart';

final AsyncNotifierProvider<FavoritesNotifier, FavoritesCollection>
favoritesProvider =
    AsyncNotifierProvider<FavoritesNotifier, FavoritesCollection>(
      FavoritesNotifier.new,
    );
