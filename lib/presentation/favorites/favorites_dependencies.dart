import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/di/service_locator.dart';
import '../../domain/repositories/favorites_repository.dart';
import '../../domain/usecases/get_favorite_ids.dart';
import '../../domain/usecases/set_favorite_status.dart';

final Provider<GetFavoriteIds> getFavoriteIdsUseCaseProvider =
    Provider<GetFavoriteIds>(
      (Ref ref) => GetFavoriteIds(getIt<FavoritesRepository>()),
    );

final Provider<SetFavoriteStatus> setFavoriteStatusUseCaseProvider =
    Provider<SetFavoriteStatus>(
      (Ref ref) => SetFavoriteStatus(getIt<FavoritesRepository>()),
    );
