import 'package:shared_preferences/shared_preferences.dart';

/// Sala asignada a esta tablet, guardada en el dispositivo.
///
/// Se elige una vez en la pantalla de configuración inicial y persiste entre
/// reinicios. Si no hay sala guardada (`load()` → null), la app muestra el
/// selector; si el backend no soporta multi-sala, se opera con la sala por
/// defecto del backend (upn vacío).
class RoomConfig {
  static const _kUpn = 'room_upn';
  static const _kName = 'room_name';

  final String upn; // vacío = sala por defecto del backend
  final String name;

  const RoomConfig({required this.upn, required this.name});

  static Future<RoomConfig?> load() async {
    final prefs = await SharedPreferences.getInstance();
    final upn = prefs.getString(_kUpn);
    if (upn == null) return null;
    return RoomConfig(upn: upn, name: prefs.getString(_kName) ?? 'Tablet Room');
  }

  static Future<void> save(RoomConfig config) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kUpn, config.upn);
    await prefs.setString(_kName, config.name);
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kUpn);
    await prefs.remove(_kName);
  }
}
