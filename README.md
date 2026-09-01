# gapsi_ecommerce

Buscador de productos sobre una API de eCommerce, construido con Flutter y Clean Architecture.

## Configuración

La API key de RapidAPI no vive en el repositorio: se inyecta en tiempo de compilación
con `--dart-define-from-file`.

1. Copia el archivo de ejemplo y completa tu key real:

   ```bash
   cp env.json.example env.json
   ```

   ```json
   {
     "RAPIDAPI_KEY": "tu-key-real-de-rapidapi"
   }
   ```

2. Corre la app pasándole ese archivo:

   ```bash
   flutter run --dart-define-from-file=env.json
   ```

`env.json` está en `.gitignore`, así que nunca se commitea. Si compilas sin
`--dart-define-from-file`, `ApiConstants.hasApiKey` devuelve `false` y las
llamadas a la API fallarán con 401.

> **Nota:** en producción, la API key debería vivir en un backend propio que actúe
> de proxy, no embebida en el cliente. Un `--dart-define` no es un secreto: queda
> dentro del binario y es recuperable de un APK o IPA descompilado.

## Ícono y splash screen

Ambos se generan a partir de dos imágenes que deben existir antes de correr nada:

| Archivo | Uso |
| --- | --- |
| `assets/branding/app_icon.png` | Ícono de la app, cuadrado, 1024x1024, sin transparencia |
| `assets/branding/splash_logo.png` | Logo centrado del splash, PNG con fondo transparente |

Con las imágenes en su lugar, correr **una sola vez** (y de nuevo cada vez que
cambien):

```bash
dart run flutter_launcher_icons
dart run flutter_native_splash:create
```

Ambos comandos reescriben archivos nativos de `android/` e `ios/`, así que
conviene correrlos con el worktree limpio para revisar el diff.

La configuración vive fuera del `pubspec.yaml`, en
[`flutter_launcher_icons.yaml`](flutter_launcher_icons.yaml) y
[`flutter_native_splash.yaml`](flutter_native_splash.yaml). Colores de marca
actuales: azul marino `#0B1E4D` (ícono) y celeste claro `#EAF1FB` (fondo del
splash).

## Arquitectura

```
lib/
  core/           # errores, red, DI, constantes y utilidades transversales
  design_system/  # tema y widgets reutilizables
  data/           # models, datasources (remote/local) y repository impls
  domain/         # entities, interfaces de repositorio y usecases
  presentation/   # UI + estado con Riverpod, por feature
```

- **Dependencias:** `get_it` para la capa de datos (datasources, repositorios);
  Riverpod para el estado de UI.
- **Sin codegen:** nada de `freezed`, `json_serializable` ni `riverpod_generator`.

## Comandos

```bash
flutter pub get
flutter analyze
flutter test
flutter run --dart-define-from-file=env.json
```
