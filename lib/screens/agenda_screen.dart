import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../models/agenda.dart';
import '../services/agenda_service.dart';

const int kRefreshSeconds = 30;

class AgendaScreen extends StatefulWidget {
  const AgendaScreen({super.key});

  @override
  State<AgendaScreen> createState() => _AgendaScreenState();
}

class _AgendaScreenState extends State<AgendaScreen> {
  final _service = AgendaService();
  Agenda? _data;
  String? _error;
  Timer? _timer;
  Timer? _clock;
  DateTime _now = DateTime.now();

  @override
  void initState() {
    super.initState();
    WakelockPlus.enable();
    _load();
    _timer = Timer.periodic(
      const Duration(seconds: kRefreshSeconds),
      (_) => _load(),
    );
    // Reloj de pared: refresca la hora mostrada cada segundo.
    _clock = Timer.periodic(
      const Duration(seconds: 1),
      (_) {
        if (mounted) setState(() => _now = DateTime.now());
      },
    );
  }

  Future<void> _load() async {
    try {
      final data = await _service.fetchAgenda();
      if (mounted) {
        setState(() {
          _data = data;
          _error = null;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _clock?.cancel();
    WakelockPlus.disable();
    super.dispose();
  }

  String _hm(DateTime t) => DateFormat('HH:mm').format(t);

  @override
  Widget build(BuildContext context) {
    final d = _data;
    final ocupada = d?.ocupada ?? false;
    final bg = ocupada ? const Color(0xFFB3261E) : const Color(0xFF1E8E3E);

    return Scaffold(
      backgroundColor: d == null ? Colors.grey.shade900 : bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: d == null
              ? Center(
                  child: Text(
                    _error ?? 'Cargando…',
                    style: const TextStyle(color: Colors.white, fontSize: 24),
                  ),
                )
              : _buildContent(d, ocupada),
        ),
      ),
    );
  }

  Widget _buildContent(Agenda d, bool ocupada) {
    final current = d.current;
    final next = d.next;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          ocupada ? 'OCUPADA' : 'LIBRE',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 72,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          DateFormat('EEEE d MMM • HH:mm', 'es').format(_now),
          style: const TextStyle(color: Colors.white70, fontSize: 22),
        ),
        const SizedBox(height: 24),
        if (current != null)
          Text(
            'Ahora: ${current.subject}  (hasta ${_hm(current.end)})',
            style: const TextStyle(color: Colors.white, fontSize: 28),
          ),
        if (next != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'Próxima: ${next.subject}  ${_hm(next.start)}',
              style: const TextStyle(color: Colors.white, fontSize: 24),
            ),
          ),
        const SizedBox(height: 24),
        const Divider(color: Colors.white24),
        Expanded(
          child: d.events.isEmpty
              ? const Center(
                  child: Text(
                    'Sin reuniones hoy',
                    style: TextStyle(color: Colors.white70, fontSize: 22),
                  ),
                )
              : ListView(
                  children: d.events.map((e) {
                    return ListTile(
                      dense: true,
                      title: Text(
                        e.subject,
                        style: const TextStyle(color: Colors.white, fontSize: 20),
                      ),
                      trailing: Text(
                        '${_hm(e.start)}–${_hm(e.end)}',
                        style: const TextStyle(color: Colors.white70, fontSize: 18),
                      ),
                    );
                  }).toList(),
                ),
        ),
      ],
    );
  }
}
