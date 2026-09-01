import 'package:get_it/get_it.dart';

import '../network/dio_client.dart';

/// Contenedor de dependencias de las capas de datos y core.
///
/// El estado de UI se maneja con Riverpod; acá solo viven las piezas sin estado
/// de presentación (clientes HTTP, datasources, repositorios).
final GetIt getIt = GetIt.instance;

/// Registra las dependencias. Se llama una sola vez desde `main()`, antes de
/// `runApp`.
void setupServiceLocator() {
  // Core
  getIt.registerLazySingleton<DioClient>(DioClient.new);

  // TODO(gaspi): registrar datasources y repositorios a medida que se agreguen.
}
