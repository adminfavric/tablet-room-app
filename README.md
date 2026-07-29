# TabletRoom Viewer — APK Android (Flutter, solo lectura)

App Flutter en modo kiosko/pantalla completa que cada ~30 s consulta
`GET {BACKEND_URL}/agenda` y muestra la agenda de la sala en una tablet montada.

**Solo lectura:** no crea ni edita reuniones, no tiene login y nunca contiene
credenciales de Microsoft. Solo consume el JSON del backend FastAPI.

## Qué muestra

- Estado grande: **LIBRE** (verde) u **OCUPADA** (rojo).
- Reunión en curso (título y hora de fin).
- Próxima reunión.
- Lista del resto del día.
- Reloj y fecha en hora de Chile.
- Mantiene la pantalla encendida (wakelock).

## Estructura

```
tabletroom_viewer/
├── lib/
│   ├── main.dart                      # arranque, landscape, immersive
│   ├── models/agenda.dart             # modelos tipados del JSON
│   ├── services/agenda_service.dart   # cliente HTTP
│   └── screens/agenda_screen.dart     # UI + polling cada 30 s
├── android/app/src/main/AndroidManifest.xml
└── pubspec.yaml
```

## Configuración

- **Sala de la tablet**: en la primera ejecución la app consulta `GET /salas`
  y muestra un selector; la sala elegida queda guardada en el dispositivo
  (`shared_preferences`). Para cambiarla después: **mantener presionado el
  logo Inarco** en el header → confirmar → vuelve el selector. Una misma APK
  sirve para todas las salas. Si el backend no soporta `/salas`, se puede
  continuar con la sala por defecto del servidor.
- `BACKEND_URL`: se inyecta en compilación con `--dart-define`. Por defecto
  `http://10.0.2.2:8000` (localhost del host desde el emulador Android).
- Intervalo de polling: `kRefreshSeconds = 30` (en `screens/agenda_screen.dart`).
- Orientación: landscape forzado.

## Generar el proyecto y la APK

Este repo contiene solo `lib/`, `pubspec.yaml` y el `AndroidManifest.xml`. El
andamiaje de plataforma (carpetas `android/`, `ios/`, etc.) lo genera Flutter:

```bash
# 1. Generar el andamiaje SIN sobrescribir lib/ ni pubspec.yaml
flutter create .

# 2. Resolver dependencias
flutter pub get

# 3. (Opcional) Probar en emulador apuntando al backend local
flutter run --dart-define=BACKEND_URL=http://10.0.2.2:8000

# 4. Build de release apuntando al backend de producción
flutter build apk --release --dart-define=BACKEND_URL=https://agenda-api.inarco.cl

# APK final en: build/app/outputs/flutter-apk/app-release.apk
```

> `flutter create .` respeta los archivos existentes (`lib/`, `pubspec.yaml`,
> `AndroidManifest.xml`); solo añade lo que falta. Tras generarlo, verifica que el
> manifest conserve `<uses-permission android:name="android.permission.INTERNET" />`.

## Modo kiosko (operación, no código)

Para que la tablet arranque sola en la app y no se pueda salir:

- Usar el **modo pantalla fijada (screen pinning)** de Android, o
- una app launcher/kiosko dedicada.

No es parte del build; se configura una vez en la tablet al montarla.
