import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/agenda.dart';

const String kBackendUrl = String.fromEnvironment(
  'BACKEND_URL',
  defaultValue: 'http://10.0.2.2:8000', // emulador → localhost del host
);

class AgendaService {
  Future<Agenda> fetchAgenda() async {
    final resp = await http
        .get(Uri.parse('$kBackendUrl/agenda'))
        .timeout(const Duration(seconds: 12));
    if (resp.statusCode != 200) {
      throw Exception('Backend ${resp.statusCode}');
    }
    final json = jsonDecode(utf8.decode(resp.bodyBytes)) as Map<String, dynamic>;
    return Agenda.fromJson(json);
  }
}
