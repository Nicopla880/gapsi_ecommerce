# GAPSI eCommerce

Buscador de productos sobre la API de Walmart (RapidAPI / Axesso), construido con
Flutter siguiendo Clean Architecture.

Cubre búsqueda con debounce, paginación infinita, historial persistente, detalle
de producto y favoritos, con estados explícitos de carga, resultados, vacío y
error.

## Versiones

| Herramienta | Versión |
| --- | --- |
| Flutter | **3.44.0** (canal `stable`) |
| Dart | **3.12.0** |

La restricción queda declarada en `pubspec.yaml` (`environment: sdk: ^3.12.0`) y
la revisión exacta del SDK con la que se generó el proyecto en `.metadata`
(`559ffa3f75e7402d65a8def9c28389a9b2e6fe42`).

Para verificar tu instalación:

```bash
flutter --version
```

## Configuración

La API key de RapidAPI **no vive en el repositorio**: se inyecta en tiempo de
compilación con `--dart-define-from-file`.

1. Copia el archivo de ejemplo y completa tu key real:

   ```bash
   cp env.json.example env.json
   ```

   ```json
   {
     "RAPIDAPI_KEY": "tu-key-real-de-rapidapi"
   }
   ```

2. Instala dependencias:

   ```bash
   flutter pub get
   ```

`env.json` está en `.gitignore`, así que nunca se commitea. Si compilas sin
`--dart-define-from-file`, `ApiConstants.hasApiKey` devuelve `false` y las
llamadas a la API fallan con 401.

No hace falta ninguna otra configuración: no hay codegen, no hay `build_runner`,
no hay plugins nativos que requieran pasos manuales. En iOS, CocoaPods se
resuelve solo en el primer `flutter run`.

> **Nota de seguridad:** en producción la API key debería vivir en un backend
> propio que actúe de proxy, no embebida en el cliente. Un `--dart-define` no es
> un secreto: queda dentro del binario y es recuperable de un APK o IPA
> descompilado.

## Ejecutar

```bash
# Android o iOS (el dispositivo/emulador que esté conectado)
flutter run --dart-define-from-file=env.json

# Elegir dispositivo explícitamente
flutter devices
flutter run -d <device-id> --dart-define-from-file=env.json
```

La app está verificada en emulador Android y simulador iOS. Está fijada a
orientación vertical (`main.dart`).

En VS Code hay una configuración de lanzamiento lista (`.vscode/launch.json`,
perfil **GAPSI**) que ya pasa el `--dart-define-from-file`.

## Pruebas

```bash
flutter analyze   # sin issues
flutter test      # 110 pruebas
```

Para una sola suite o con cobertura:

```bash
flutter test test/presentation/search/search_notifier_test.dart
flutter test --coverage
```

Las pruebas **no requieren `env.json`**: nada de la suite toca la red. El cliente
HTTP se prueba con un `MockAdapter` de Dio, el historial con
`SharedPreferences.setMockInitialValues` y los favoritos contra un box de Hive
real en un directorio temporal, de modo que el ida y vuelta a disco se ejercita
de verdad.

Qué cubre la suite:

| Área | Archivo |
| --- | --- |
| Búsqueda, debounce, errores, paginación, respuestas obsoletas | `test/presentation/search/search_notifier_test.dart` |
| Traducción de errores de red y redacción de headers | `test/core/network/dio_client_test.dart` |
| Parseo del contrato real del API | `test/data/models/product_model_test.dart`, `test/data/datasources/walmart_remote_datasource_test.dart` |
| Repositorios y persistencia (incluida la migración de favoritos) | `test/data/repositories/*` |
| Favoritos: toggle optimista y reversión ante fallo | `test/presentation/favorites/favorites_notifier_test.dart` |
| Widgets: búsqueda, grilla, detalle, escalado de texto, headers | `test/presentation/**/*_screen_test.dart` |
| ProductCard aislada: fallbacks de precio y título, favorito | `test/presentation/search/widgets/product_card_test.dart` |
| Design system: tema, tipografía, animaciones, accesibilidad | `test/design_system/gapsi_design_system_test.dart` |

## Arquitectura

```
lib/
  core/           # errores, red, DI, constantes y utilidades transversales
  design_system/  # tokens de marca, tema y widgets reutilizables
  data/           # models, datasources (remote/local) y repository impls
  domain/         # entities, interfaces de repositorio y usecases
  presentation/   # UI + estado con Riverpod, por feature
```

La dependencia apunta siempre hacia adentro: `presentation` conoce `domain`,
`data` implementa las interfaces de `domain`, y `domain` no conoce a nadie. Un
cambio de API o de motor de persistencia se resuelve en `data` sin tocar UI ni
lógica de negocio.

Flujo de una búsqueda:

```
SearchScreen → SearchNotifier → SearchProducts (usecase)
             → ProductRepository (interfaz, domain)
             → ProductRepositoryImpl → WalmartRemoteDataSource → DioClient
```

## Decisiones técnicas

### Manejo de estado — Riverpod

`flutter_riverpod` sin codegen. Elegido sobre BLoC y `provider` porque:

- **La asincronía es el problema central de esta app**, y `AsyncNotifier`
  modela carga/dato/error sin escribir esa máquina de estados a mano.
- **Los providers se sobreescriben en tests** (`ProviderScope(overrides:)`), lo
  que permite probar pantallas completas contra notifiers falsos sin inyección
  manual ni `mockito` en la capa de UI.
- **No depende de `BuildContext`**, así que la lógica de estado se testea sin
  bombear widgets.
- Frente a BLoC, evita la ceremonia de eventos para intenciones que aquí son
  simples llamadas a método (`onSearchChanged`, `loadNextPage`, `retry`).

`SearchState` es una jerarquía sellada (`SearchInitial`, `SearchLoading`,
`SearchLoaded`, `SearchError`), así que el `switch` de la UI es exhaustivo y el
compilador avisa si se agrega un estado y falta renderizarlo.

### Persistencia — Hive + shared_preferences

Se usan **dos motores, cada uno según la forma del dato**. La decisión no es
acumular librerías: es que persistir una preferencia plana y persistir una
colección de entidades son problemas distintos.

| Dato | Motor | Por qué |
| --- | --- | --- |
| Historial de búsquedas | `shared_preferences` | Lista plana de strings, sin estructura ni consultas. Es una preferencia del usuario, no un registro. Un key-value alcanza y no justifica abrir una base. |
| Favoritos | **Hive** | Colección de entidades con campos (id, título, precio, thumbnail, descripción). Es un problema de base de datos local, y Hive lo resuelve como tal. |

Por qué Hive para los favoritos:

- Es una **base NoSQL local real**, no un mapa de preferencias: guarda en boxes
  tipados, lee y escribe desde disco de forma binaria y escala a colecciones de
  objetos, que es exactamente lo que son los favoritos.
- **Guarda estructuras nativas** (mapas y listas de primitivos) sin serializar a
  JSON a mano y sin generar adaptadores con `build_runner`, en línea con la
  decisión de no usar codegen en el resto del proyecto.
- El día que los favoritos necesiten consultas, orden o más campos, el motor ya
  está: no hay que migrar de un key-value a una base.

Frente a `sqflite`, Hive evita SQL y mapeo manual para un caso que no tiene
relaciones. Frente a Isar, no requiere codegen.

Los favoritos se guardan como **snapshots mínimos de producto** bajo la clave
`products_v2` del box `favorites`, no como IDs sueltos: así la pantalla de
favoritos se renderiza sin depender de la red. El formato anterior de solo IDs
(`favorite_product_ids`) se sigue leyendo y migra a snapshot cuando el producto
reaparece en una búsqueda, sin inventar datos que no se tienen.

En ambos casos el motor queda encapsulado en su `*LocalDataSource`: los
repositorios y el dominio no saben qué hay debajo, así que cambiar de motor no
se propaga hacia arriba.

### Caché de resultados

Las páginas de resultados se cachean en Hive por `(keyword, página)`, con una
estrategia **cache-first con TTL de 10 minutos y respaldo ante fallo**:

1. Si hay una página cacheada **fresca**, se sirve sin tocar la red. Repetir una
   búsqueda dentro de la sesión es instantáneo, algo que se nota porque el API
   tarda varios segundos por request.
2. Si venció o no existe, se pide al API y la respuesta se cachea.
3. Si el API falla y hay una copia **vencida**, se sirve esa copia. Una caché
   vieja es mejor que una pantalla de error, y nunca se antepone a una respuesta
   fresca.

El TTL es un compromiso deliberado: los precios cambian, así que la caché no
puede durar horas, pero tampoco tiene sentido repetir una espera de varios
segundos por la misma consulta.

El box está acotado a 60 páginas y descarta las entradas más viejas primero: es
una comodidad, no un espejo del catálogo. Y la caché es una optimización, no una
dependencia: si la lectura o la escritura fallan, la búsqueda sigue su curso
contra el API en lugar de romper.

### Consumo de API — dio

`dio` sobre el `http` de la SDK por los interceptores, los timeouts por request y
los `CancelToken`.

`DioClient` es un envoltorio delgado que centraliza `baseUrl`, headers de
RapidAPI, timeouts y **la traducción de `DioException` a excepciones propias**
(`NetworkException`, `ServerException`). Los datasources nunca ven un tipo de
Dio, así que cambiar de cliente HTTP no se propaga hacia arriba.

En debug se registra el tráfico con `pretty_dio_logger`, con
`requestHeader: false` y `responseHeader: false` para que la API key no termine
impresa en los logs.

Detalles del consumo:

- **Debounce de 500 ms** (`core/utils/debouncer.dart`): una ráfaga de tecleo
  dispara un solo request.
- **Respuestas obsoletas descartadas**: cada búsqueda lleva un token, y una
  respuesta que llega tarde no pisa una consulta más nueva.
- **Paginación sin duplicados**: no se pide otra página si ya hay una en vuelo o
  si se alcanzó el máximo; los productos se deduplican por `Product.id`
  conservando el orden.
- **Errores de página no destruyen resultados**: un fallo al paginar deja el
  listado intacto y ofrece reintentar.

### Modelos — sin codegen

`ProductModel` parsea a mano. La respuesta del API es profunda e irregular
(precios que llegan como número o como string con símbolo, campos ausentes), y un
parser explícito documenta y tolera eso mejor que un `fromJson` generado.

Los campos que el API no siempre informa son **nullable a propósito**: es
preferible que la UI decida qué mostrar ante un dato ausente a inventar un
default engañoso — un precio `0.0` se leería como "gratis".

### Inyección de dependencias — get_it + Riverpod

Dos contenedores con responsabilidades separadas: `get_it` arma las piezas sin
estado de presentación (cliente HTTP, datasources, repositorios) en
`setupServiceLocator()`, y Riverpod maneja el estado de UI. Los providers de
usecases leen de `get_it`, así que la capa de datos se puede reemplazar entera
sin tocar los notifiers.

### Pruebas

`flutter_test` con `mocktail` para los dobles. Se eligió `mocktail` sobre
`mockito` porque **no requiere codegen**, en línea con el resto del proyecto.

La estrategia es probar comportamiento y no implementación: los tests de notifier
verifican secuencias de estados, y los de widget verifican lo que ve el usuario y
qué intención se delega, no la estructura interna del árbol.

### Design system

`lib/design_system/` centraliza color, espaciado, radios, tipografía y motion en
un único `GapsiTheme.light()`. La paleta se derivó del icono de marca; la
tipografía es Manrope, empaquetada en `assets/fonts` como cuatro instancias
estáticas (400/600/700/800) en lugar de `google_fonts`, para no depender de la
red en runtime ni en los tests.

Hay un solo tema claro, bien resuelto, en vez de dos a medias. Los tokens ya
están centralizados, así que sumar modo oscuro sería agregar un `ColorScheme`.

## Requisitos cubiertos

Obligatorios: búsqueda por texto, debounce, listado con título/precio/thumbnail,
detalle con descripción, historial persistente entre reinicios, paginación
infinita sin duplicados ni pedidos de más al llegar al final, UI no bloqueante,
estados de carga/resultados/vacío/error, errores que no destruyen resultados
previos, iOS y Android, `flutter analyze` limpio, separación de capas y pruebas
automatizadas de búsqueda, errores y paginación.

Bonus implementados:

- **Favoritos persistentes** con toggle optimista y reversión si falla la
  escritura, más una colección de favoritos navegable desde el header.
- **Caché local de resultados** en Hive, con TTL y respaldo ante fallo del API.
- **Reintento** de la búsqueda inicial y de la página que falló.
- **Pruebas de widget** además de las de lógica.
- **Accesibilidad y tamaños de pantalla**: escalado de texto del sistema
  respetado y probado a 0.8× y 2×, grilla adaptable por ancho disponible,
  etiquetas semánticas en los controles de favorito y respeto por la preferencia
  de movimiento reducido.

## Limitaciones conocidas

- **Solo tema claro**, decisión deliberada explicada arriba.
- **Orientación fija en vertical**.
- El API de RapidAPI es lento e inestable por momentos (respuestas de más de
  10 s y algún timeout); el manejo de error y el reintento están pensados para
  eso.
