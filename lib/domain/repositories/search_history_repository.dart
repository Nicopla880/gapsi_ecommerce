/// Historial de búsquedas del usuario. La implementación vive en
/// `data/repositories/` y persiste localmente.
abstract class SearchHistoryRepository {
  /// Devuelve los términos buscados, del más reciente al más antiguo.
  ///
  /// Devuelve una lista vacía si todavía no se buscó nada.
  /// Lanza `CacheException` si falla la lectura del almacenamiento local.
  Future<List<String>> getSearchHistory();

  /// Guarda [term] como la búsqueda más reciente.
  ///
  /// Contrato que la implementación debe respetar:
  /// - El historial no admite duplicados. Si [term] ya estaba guardado, se
  ///   mueve al principio de la lista en lugar de agregarse otra vez.
  /// - Los términos nuevos se insertan al principio.
  ///
  /// Lanza `CacheException` si falla la escritura en el almacenamiento local.
  Future<void> saveSearchTerm(String term);
}
