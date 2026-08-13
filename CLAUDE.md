# TabletRoom Viewer

Panel de agenda de sala de reuniones para tablets Android (Flutter, kiosko 24/7).
Backend: FastAPI + Microsoft Graph en `https://graph-api.favric.cl`
(repo hermano: `../graph-api`, GitHub `adminfavric/graph-api`).

## Al generar una APK — LEER SIEMPRE

Seguir **BUILD.md**. Regla de oro: la APK necesita `BACKEND_URL` y
`RESERVE_API_KEY` vía `--dart-define` (o `--dart-define-from-file=dart_defines.json`,
archivo local gitignoreado). La `RESERVE_API_KEY` está en el `.env` del
**servidor** de graph-api; sin ella el botón "Reservar sala" no funciona.
Si `dart_defines.json` no existe y no se conoce la key, **avisar al usuario
que falta la API key (está generalmente en el .env del servidor)** antes de
compilar. Nunca commitear la key.

## Datos útiles

- Una sola APK para todas las salas: la sala se elige en la primera ejecución
  (endpoint `GET /salas`); cambiar sala = mantener presionado el logo + PIN
  `00`+día del mes (ej. día 29 → `0029`).
- La agenda lee directo el calendario del buzón Microsoft 365 de la sala:
  reservas hechas desde Outlook/correo aparecen solas (polling cada 30 s).
- Salas nuevas: crear buzón M365 + agregarlo a la Application Access Policy
  de Entra + sumarlo a `ROOMS=` en el `.env` del servidor. Sin tocar la APK.
- Modo descanso anti burn-in tras 15 min sin toques (`SAVER_MINUTES`).
- Probar en emulador: `flutter run -d emulator-5554` usa `10.0.2.2:8000`
  (backend local) por defecto; para producción agregar `--dart-define=BACKEND_URL=...`.
