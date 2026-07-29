import 'package:flutter/material.dart';

import '../services/agenda_service.dart';
import '../services/room_config.dart';
import 'agenda_screen.dart';

// Paleta Inarco (misma de agenda_screen).
const _navy = Color(0xFF0F1E3D);
const _gold = Color(0xFFF5C21F);
const _inkSoft = Color(0xFF9FB0CF);
const _panel = Colors.white;
const _ink = Color(0xFF16213B);
const _inkSoft2 = Color(0xFF56617A);
const _inkMute = Color(0xFF8A93A6);
const _line = Color(0x14000000);

/// Configuración inicial de la tablet: elegir qué sala mostrará.
///
/// Se abre solo cuando no hay sala guardada (primera ejecución o tras
/// "Cambiar sala"). Consulta `GET /salas`; si el backend no soporta
/// multi-sala, permite continuar con la sala por defecto.
class RoomSetupScreen extends StatefulWidget {
  const RoomSetupScreen({super.key});

  @override
  State<RoomSetupScreen> createState() => _RoomSetupScreenState();
}

class _RoomSetupScreenState extends State<RoomSetupScreen> {
  final _service = AgendaService();
  List<RoomInfo>? _rooms; // null = cargando
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _rooms = null);
    final rooms = await _service.fetchRooms();
    if (mounted) setState(() => _rooms = rooms);
  }

  Future<void> _select(RoomConfig config) async {
    if (_saving) return;
    setState(() => _saving = true);
    await RoomConfig.save(config);
    if (!mounted) return;
    Navigator.of(context).pushReplacement(MaterialPageRoute(
      builder: (_) => AgendaScreen(roomUpn: config.upn, roomName: config.name),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final rooms = _rooms;
    return Scaffold(
      backgroundColor: _navy,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('CONSTRUCTORA INARCO',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color: _inkSoft,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 4)),
                  const SizedBox(height: 8),
                  const Text('Configurar tablet',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color: Colors.white, fontSize: 30, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 6),
                  const Text('Elige la sala que mostrará esta pantalla',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: _inkSoft, fontSize: 15)),
                  const SizedBox(height: 28),
                  if (rooms == null)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 40),
                      child: Center(
                          child: CircularProgressIndicator(color: _gold, strokeWidth: 3)),
                    )
                  else if (rooms.isEmpty)
                    _emptyState()
                  else
                    Flexible(child: _roomList(rooms)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _roomList(List<RoomInfo> rooms) {
    return Container(
      decoration: BoxDecoration(
        color: _panel,
        borderRadius: BorderRadius.circular(18),
      ),
      clipBehavior: Clip.antiAlias,
      child: ListView.separated(
        shrinkWrap: true,
        itemCount: rooms.length,
        separatorBuilder: (_, __) => const Divider(height: 1, color: _line),
        itemBuilder: (_, i) {
          final r = rooms[i];
          return ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 22, vertical: 8),
            leading: const CircleAvatar(
              backgroundColor: _navy,
              child: Icon(Icons.meeting_room_outlined, color: _gold, size: 22),
            ),
            title: Text(r.name,
                style: const TextStyle(
                    color: _ink, fontSize: 18, fontWeight: FontWeight.w700)),
            subtitle: Text(r.upn,
                style: const TextStyle(color: _inkMute, fontSize: 13)),
            trailing: const Icon(Icons.chevron_right, color: _inkSoft2),
            onTap: () => _select(RoomConfig(upn: r.upn, name: r.name)),
          );
        },
      ),
    );
  }

  Widget _emptyState() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _panel,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          const Icon(Icons.cloud_off_outlined, color: _inkMute, size: 36),
          const SizedBox(height: 12),
          const Text('No se pudo obtener la lista de salas',
              textAlign: TextAlign.center,
              style: TextStyle(color: _ink, fontSize: 17, fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          const Text(
              'Revisa la conexión, o continúa con la sala por defecto del servidor.',
              textAlign: TextAlign.center,
              style: TextStyle(color: _inkSoft2, fontSize: 14)),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _load,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _navy,
                    side: const BorderSide(color: _navy),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text('Reintentar'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: () =>
                      _select(const RoomConfig(upn: '', name: 'Tablet Room')),
                  style: FilledButton.styleFrom(
                    backgroundColor: _navy,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text('Continuar'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
