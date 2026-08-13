# Cómo generar la APK de producción

> ⚠️ **La APK necesita la `RESERVE_API_KEY` grabada al compilar.**
> Sin ella, la agenda se ve bien pero el botón **"Reservar sala" no funciona**
> (el servidor rechaza la reserva). La key vive en el **`.env` del servidor**
> de graph-api (línea `RESERVE_API_KEY=...`) y NUNCA se sube a GitHub.

## Forma recomendada (con `dart_defines.json`)

En la raíz del proyecto debe existir `dart_defines.json` (está en `.gitignore`;
si no existe, créalo copiando la key desde el `.env` del servidor):

```json
{
  "BACKEND_URL": "https://graph-api.favric.cl",
  "RESERVE_API_KEY": "<valor de RESERVE_API_KEY del .env del servidor>"
}
```

Y compilar con:

```bash
flutter build apk --release --dart-define-from-file=dart_defines.json
# APK resultante: build/app/outputs/flutter-apk/app-release.apk
```

## Forma manual (equivalente)

```bash
flutter build apk --release \
  --dart-define=BACKEND_URL=https://graph-api.favric.cl \
  --dart-define=RESERVE_API_KEY=<valor del .env del servidor>
```

## Errores clásicos a evitar

- ❌ `flutter build apk --release` **a secas**: compila apuntando a
  `http://10.0.2.2:8000` (el emulador) y sin key → en una tablet real sale
  "Sin conexión con el servidor". Siempre pasar los dart-define.
- ❌ Poner la key o `dart_defines.json` en un commit: es una contraseña;
  queda solo en esta máquina y en el `.env` del servidor.

## Otros parámetros opcionales

| Variable | Default | Para qué |
|---|---|---|
| `SAVER_MINUTES` | 15 | Minutos de inactividad antes del modo descanso (0 = desactivado) |
| `ROOM_STATE` | (vacío) | Forzar `busy`/`soon`/`free` para fotos o demos |

## Después de compilar

- Renombrar con versión: `cp build/app/outputs/flutter-apk/app-release.apk ~/Downloads/tabletroom-agenda-vX.Y.Z.apk`
- La sala de cada tablet NO va en la APK: se elige en la primera ejecución
  (cambiarla después: mantener presionado el logo Inarco + PIN `00`+día, ej. `0029`).
