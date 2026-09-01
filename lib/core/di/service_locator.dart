import 'package:get_it/get_it.dart';
import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/datasources/local/favorites_local_datasource.dart';
import '../../data/datasources/local/search_history_local_datasource.dart';
import '../../data/datasources/remote/walmart_remote_datasource.dart';
import '../../data/repositories/favorites_repository_impl.dart';
import '../../data/repositories/product_repository_impl.dart';
import '../../data/repositories/search_history_repository_impl.dart';
import '../../domain/repositories/favorites_repository.dart';
import '../../domain/repositories/product_repository.dart';
import '../../domain/repositories/search_history_repository.dart';
import '../network/dio_client.dart';

/// Contenedor de dependencias de las capas de datos y core.
///
/// El estado de UI se maneja con Riverpod; acá solo viven las piezas sin estado
/// de presentación (clientes HTTP, datasources, repositorios).
final GetIt getIt = GetIt.instance;

/// Registra las dependencias. Se llama una sola vez desde `main()`, antes de
/// `runApp`, y hay que esperarla: `SharedPreferences` se resuelve async.
Future<void> setupServiceLocator() async {
  // Core
  getIt.registerLazySingleton<DioClient>(DioClient.new);

  // Externas. Dos motores de persistencia, cada uno donde corresponde:
  // `shared_preferences` para la preferencia plana (historial) y Hive para la
  // coleccion de entidades (favoritos).
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  getIt.registerLazySingleton<SharedPreferences>(() => prefs);

  final Box<dynamic> favoritesBox = await Hive.openBox<dynamic>(
    FavoritesLocalDataSourceImpl.boxName,
  );

  // Datasources
  getIt.registerLazySingleton<WalmartRemoteDataSource>(
    () => WalmartRemoteDataSourceImpl(getIt<DioClient>().dio),
  );
  getIt.registerLazySingleton<SearchHistoryLocalDataSource>(
    () => SearchHistoryLocalDataSourceImpl(getIt<SharedPreferences>()),
  );
  getIt.registerLazySingleton<FavoritesLocalDataSource>(
    () => FavoritesLocalDataSourceImpl(favoritesBox),
  );

  // Repositorios: el domain solo conoce la interfaz.
  getIt.registerLazySingleton<ProductRepository>(
    () => ProductRepositoryImpl(getIt<WalmartRemoteDataSource>()),
  );
  getIt.registerLazySingleton<SearchHistoryRepository>(
    () => SearchHistoryRepositoryImpl(getIt<SearchHistoryLocalDataSource>()),
  );
  getIt.registerLazySingleton<FavoritesRepository>(
    () => FavoritesRepositoryImpl(getIt<FavoritesLocalDataSource>()),
  );
}
