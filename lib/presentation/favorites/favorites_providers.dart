import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'favorites_notifier.dart';

final AsyncNotifierProvider<FavoritesNotifier, Set<String>> favoritesProvider =
    AsyncNotifierProvider<FavoritesNotifier, Set<String>>(
      FavoritesNotifier.new,
    );
