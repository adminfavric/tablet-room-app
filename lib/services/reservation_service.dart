import 'dart:convert';

import 'package:http/http.dart' as http;

import 'agenda_service.dart' show kBackendUrl;

/// Clave de API para crear reuniones (header X-API-Key). Debe coincidir con
/// RESERVE_API_KEY del backend. Se inyecta al compilar:
///   flutter build apk --dart-define=RESERVE_API_KEY=xxxxx
const String kReserveApiKey = String.fromEnvironment('RESERVE_API_KEY', defaultValue: '');

class ReservationResult {
  final bool ok;
  final String message;
  const ReservationResult(this.ok, this.message);
}

class ReservationService {
  /// Envía la reserva al backend. `start`/`end` son hora de pared (Chile).
  Future<ReservationResult> reserve({
    required String subject,
    required DateTime start,
    required DateTime end,
  }) async {
    try {
      final resp = await http
          .post(
            Uri.parse('$kBackendUrl/reservar'),
            headers: {
              'Content-Type': 'application/json',
              if (kReserveApiKey.isNotEmpty) 'X-API-Key': kReserveApiKey,
            },
            body: jsonEncode({
              'subject': subject,
              'start': _isoLocal(start),
              'end': _isoLocal(end),
            }),
          )
          .timeout(const Duration(seconds: 15));

      if (resp.statusCode == 200) {
        return const ReservationResult(true, 'Reserva creada');
      }
      // El backend manda {"detail": "..."} con el motivo.
      String detail;
      try {
        final json = jsonDecode(utf8.decode(resp.bodyBytes)) as Map<String, dynamic>;
        detail = (json['detail'] ?? 'Error ${resp.statusCode}').toString();
      } catch (_) {
        detail = resp.statusCode == 404
            ? 'Reservas no habilitadas en el servidor'
            : 'Error ${resp.statusCode}';
      }
      return ReservationResult(false, detail);
    } catch (e) {
      return const ReservationResult(false, 'Sin conexión con el servidor');
    }
  }

  /// ISO local sin zona ni milisegundos: "2026-07-07T15:00:00".
  static String _isoLocal(DateTime t) {
    String p(int n, [int w = 2]) => n.toString().padLeft(w, '0');
    return '${p(t.year, 4)}-${p(t.month)}-${p(t.day)}T${p(t.hour)}:${p(t.minute)}:00';
  }
}
