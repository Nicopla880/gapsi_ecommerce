/// Configuración de la API de búsqueda de productos (RapidAPI / Axesso Walmart).
abstract final class ApiConstants {
  static const String baseUrl =
      'https://axesso-walmart-data-service.p.rapidapi.com';

  static const String searchEndpoint = '/wlm/walmart-search-by-keyword';

  /// Criterio de orden por defecto del endpoint de búsqueda.
  static const String defaultSortBy = 'best_match';

  /// Nombres de los headers que exige RapidAPI en cada request.
  static const String apiKeyHeader = 'x-rapidapi-key';
  static const String apiHostHeader = 'x-rapidapi-host';

  /// Valor del header `x-rapidapi-host`, derivado del [baseUrl].
  static const String apiHost = 'axesso-walmart-data-service.p.rapidapi.com';

  /// La key se inyecta en tiempo de compilación, nunca se versiona:
  /// `flutter run --dart-define=RAPIDAPI_KEY=tu_key`
  static const String apiKey = String.fromEnvironment('RAPIDAPI_KEY');

  /// `false` cuando la app se compiló sin `--dart-define=RAPIDAPI_KEY`.
  static bool get hasApiKey => apiKey.isNotEmpty;

  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 20);
}
