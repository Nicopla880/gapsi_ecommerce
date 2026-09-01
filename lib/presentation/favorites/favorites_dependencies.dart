import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/di/service_locator.dart';
import '../../domain/repositories/favorites_repository.dart';
import '../../domain/usecases/get_favorites.dart';
import '../../domain/usecases/set_favorite_status.dart';

final Provider<GetFavorites> getFavoritesUseCaseProvider =
    Provider<GetFavorites>(
      (Ref ref) => GetFavorites(getIt<FavoritesRepository>()),
    );

final Provider<SetFavoriteStatus> setFavoriteStatusUseCaseProvider =
    Provider<SetFavoriteStatus>(
      (Ref ref) => SetFavoriteStatus(getIt<FavoritesRepository>()),
    );
