import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/agenda.dart';

const String kBackendUrl = String.fromEnvironment(
  'BACKEND_URL',
  defaultValue: 'http://10.0.2.2:8000', // emulador → localhost del host
);

/// Sala disponible según el backend (`GET /salas`).
class RoomInfo {
  final String upn;
  final String name;
  const RoomInfo({required this.upn, required this.name});

  factory RoomInfo.fromJson(Map<String, dynamic> json) => RoomInfo(
        upn: (json['upn'] as String?) ?? '',
        name: (json['name'] as String?) ?? (json['upn'] as String?) ?? '',
      );
}

class AgendaService {
  /// [room] es el UPN de la sala; vacío/null → sala por defecto del backend
  /// (compatible con backends antiguos que ignoran el parámetro).
  Future<Agenda> fetchAgenda({String? room}) async {
    var uri = Uri.parse('$kBackendUrl/agenda');
    if (room != null && room.isNotEmpty) {
      uri = uri.replace(queryParameters: {'room': room});
    }
    final resp = await http.get(uri).timeout(const Duration(seconds: 12));
    if (resp.statusCode != 200) {
      throw Exception('Backend ${resp.statusCode}');
    }
    final json = jsonDecode(utf8.decode(resp.bodyBytes)) as Map<String, dynamic>;
    return Agenda.fromJson(json);
  }

  /// Salas habilitadas en el backend. Devuelve lista vacía si el backend es
  /// antiguo (sin `/salas`) o no responde: la app sigue con la sala por defecto.
  Future<List<RoomInfo>> fetchRooms() async {
    try {
      final resp = await http
          .get(Uri.parse('$kBackendUrl/salas'))
          .timeout(const Duration(seconds: 12));
      if (resp.statusCode != 200) return const [];
      final json = jsonDecode(utf8.decode(resp.bodyBytes)) as Map<String, dynamic>;
      return ((json['rooms'] as List?) ?? const [])
          .map((e) => RoomInfo.fromJson(e as Map<String, dynamic>))
          .where((r) => r.upn.isNotEmpty)
          .toList();
    } catch (_) {
      return const [];
    }
  }
}
