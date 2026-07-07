import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../models/agenda.dart';
import '../services/agenda_service.dart';
import '../services/reservation_service.dart';

const int kRefreshSeconds = 30;

// --- Paleta Inarco ---
// Marca / header oscuro
const _navy = Color(0xFF0F1E3D);
const _navyTop = Color(0xFF12213F);
const _navyBot = Color(0xFF0D1A34);
const _gold = Color(0xFFF5C21F);
// Estados
const _free = Color(0xFF1E8E3E);
const _busy = Color(0xFFC7362B);
// Inks sobre header oscuro
const _inkSoft = Color(0xFF9FB0CF);
// Cuerpo claro
const _bg = Color(0xFFF3F0E8); // crema (papel de plano)
const _panel = Colors.white;
const _ink = Color(0xFF16213B); // texto principal (navy)
const _inkSoft2 = Color(0xFF56617A); // secundario
const _inkMute2 = Color(0xFF8A93A6); // terciario
const _line = Color(0x14000000); // bordes sutiles
const _kick = Color(0xFF9A7B10); // dorado legible sobre claro (kickers)
const _fieldBg = Color(0xFFF3F0E8);

class AgendaScreen extends StatefulWidget {
  const AgendaScreen({super.key});

  @override
  State<AgendaScreen> createState() => _AgendaScreenState();
}

class _AgendaScreenState extends State<AgendaScreen> {
  final _service = AgendaService();
  Agenda? _data;
  String? _error;
  Timer? _poll;
  Timer? _clock;

  // Reloj basado en el `now` del backend (hora de Chile), no en el reloj del equipo.
  DateTime? _serverNow;
  DateTime _syncedAt = DateTime.now();
  DateTime _display = DateTime.now();

  @override
  void initState() {
    super.initState();
    WakelockPlus.enable();
    _load();
    _poll = Timer.periodic(const Duration(seconds: kRefreshSeconds), (_) => _load());
    _clock = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        final base = _serverNow;
        _display = base == null
            ? DateTime.now()
            : base.add(DateTime.now().difference(_syncedAt));
      });
    });
  }

  Future<void> _load() async {
    try {
      final data = await _service.fetchAgenda();
      if (!mounted) return;
      setState(() {
        _data = data;
        _error = null;
        _serverNow = data.now;
        _syncedAt = DateTime.now();
        _display = data.now;
      });
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    }
  }

  @override
  void dispose() {
    _poll?.cancel();
    _clock?.cancel();
    WakelockPlus.disable();
    super.dispose();
  }

  String _hm(DateTime t) => DateFormat('HH:mm').format(t);

  Future<void> _openReserve() async {
    final ok = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: .55),
      builder: (_) => _ReserveDialog(now: _display),
    );
    if (ok == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Reunión reservada  ✓'),
          backgroundColor: _free,
          behavior: SnackBarBehavior.floating,
        ),
      );
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _navy,
      body: LayoutBuilder(
        builder: (context, c) {
          // Escala relativa a ancho Y alto (responsivo a cualquier tablet).
          final s = math.min(c.maxWidth / 1280, c.maxHeight / 820).clamp(0.5, 1.7);
          final d = _data;
          return Column(
            children: [
              _header(d, s),
              Expanded(
                child: Container(
                  color: _bg,
                  child: SafeArea(
                    top: false,
                    child: d == null ? _loading(s) : _body(d, s),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // ---------- Header oscuro ----------
  Widget _header(Agenda? d, double s) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [_navyTop, _navyBot],
        ),
      ),
      child: Column(
        children: [
          SafeArea(
            bottom: false,
            child: Padding(
              padding: EdgeInsets.fromLTRB(28 * s, 18 * s, 28 * s, 16 * s),
              child: _topBar(d, s),
            ),
          ),
          _Hazard(height: 6 * s, margin: EdgeInsets.zero),
        ],
      ),
    );
  }

  Widget _topBar(Agenda? d, double s) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _InarcoLogo(size: 40 * s),
        const Spacer(),
        Column(
          children: [
            Text('SALA DE REUNIONES',
                style: TextStyle(
                    color: _gold, fontSize: 10 * s, fontWeight: FontWeight.w700, letterSpacing: 3 * s)),
            SizedBox(height: 3 * s),
            Text(_roomLabel(d?.room ?? ''),
                style: TextStyle(
                    color: const Color(0xFFE9EEFB), fontSize: 18 * s, fontWeight: FontWeight.w600)),
          ],
        ),
        const Spacer(),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(_hm(_display),
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 42 * s,
                    height: 1,
                    fontWeight: FontWeight.w800,
                    fontFeatures: const [FontFeature.tabularFigures()])),
            SizedBox(height: 5 * s),
            Text(_capitalize(DateFormat('EEEE d MMM', 'es').format(_display)),
                style: TextStyle(color: _inkSoft, fontSize: 13 * s)),
          ],
        ),
      ],
    );
  }

  // ---------- Estado de carga / error ----------
  Widget _loading(double s) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 26 * s,
            height: 26 * s,
            child: CircularProgressIndicator(color: _navy, strokeWidth: 3 * s),
          ),
          SizedBox(height: 20 * s),
          Text(
            _error == null ? 'Cargando agenda…' : 'Sin conexión con el servidor',
            style: TextStyle(color: _inkSoft2, fontSize: 18 * s),
          ),
          if (_error != null) ...[
            SizedBox(height: 6 * s),
            Text('Reintentando cada $kRefreshSeconds s',
                style: TextStyle(color: _inkMute2, fontSize: 13 * s)),
          ],
        ],
      ),
    );
  }

  // ---------- Cuerpo claro ----------
  Widget _body(Agenda d, double s) {
    return Stack(
      children: [
        Positioned.fill(
          child: IgnorePointer(child: CustomPaint(painter: _BlueprintPainter())),
        ),
        Column(
          children: [
            Expanded(
              child: Padding(
                padding: EdgeInsets.all(26 * s),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(flex: 145, child: _statusBlock(d, s)),
                    SizedBox(width: 26 * s),
                    Expanded(flex: 100, child: _agenda(d, s)),
                  ],
                ),
              ),
            ),
            _footer(d, s),
          ],
        ),
      ],
    );
  }

  Widget _statusBlock(Agenda d, double s) {
    final accent = d.ocupada ? _busy : _free;
    return Container(
      decoration: BoxDecoration(
        color: _panel,
        borderRadius: BorderRadius.circular(22 * s),
        border: Border.all(color: _line),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: .06), blurRadius: 22 * s, offset: Offset(0, 8 * s)),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(width: 10 * s, color: accent),
          Expanded(
            child: Padding(
              padding: EdgeInsets.all(30 * s),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _Dot(color: accent, size: 22 * s),
                      SizedBox(width: 16 * s),
                      Flexible(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            d.ocupada ? 'OCUPADA' : 'LIBRE',
                            style: TextStyle(
                              color: accent,
                              fontSize: 108 * s,
                              height: .92,
                              letterSpacing: -3 * s,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8 * s),
                  Text(
                    d.ocupada ? 'Reunión en curso' : 'Sala disponible ahora',
                    style: TextStyle(color: _inkSoft2, fontSize: 22 * s, fontWeight: FontWeight.w500),
                  ),
                  const Spacer(),
                  _detail(d, s, accent),
                  SizedBox(height: 18 * s),
                  _reserveButton(s),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _reserveButton(double s) {
    return SizedBox(
      width: double.infinity,
      child: Material(
        color: _navy,
        borderRadius: BorderRadius.circular(14 * s),
        child: InkWell(
          borderRadius: BorderRadius.circular(14 * s),
          onTap: _openReserve,
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 16 * s),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.add_rounded, color: _gold, size: 24 * s),
                SizedBox(width: 10 * s),
                Text('Reservar sala',
                    style: TextStyle(
                        color: Colors.white, fontSize: 19 * s, fontWeight: FontWeight.w700, letterSpacing: .3)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _detail(Agenda d, double s, Color accent) {
    final current = d.current;
    final next = d.next;

    Widget nowCard;
    if (current != null) {
      final total = current.end.difference(current.start).inSeconds;
      final done = _display.difference(current.start).inSeconds;
      final frac = total <= 0 ? 0.0 : (done / total).clamp(0.0, 1.0);
      nowCard = _card(s, children: [
        _kicker('AHORA EN LA SALA', s),
        SizedBox(height: 8 * s),
        Text(current.subject,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: _ink, fontSize: 30 * s, height: 1.1, fontWeight: FontWeight.w700)),
        SizedBox(height: 12 * s),
        _metaRow([
          if (current.organizer.isNotEmpty) _meta('Organiza', current.organizer, s),
          _meta('Termina', _hm(current.end), s),
        ], s),
        SizedBox(height: 16 * s),
        ClipRRect(
          borderRadius: BorderRadius.circular(20 * s),
          child: LinearProgressIndicator(
            value: frac,
            minHeight: 8 * s,
            backgroundColor: const Color(0x14000000),
            valueColor: AlwaysStoppedAnimation(accent),
          ),
        ),
      ]);
    } else {
      nowCard = _card(s, children: [
        _kicker('DISPONIBLE', s),
        SizedBox(height: 8 * s),
        Text(next == null ? 'Sin más reuniones hoy' : 'Sin reunión en curso',
            style: TextStyle(color: _ink, fontSize: 30 * s, height: 1.1, fontWeight: FontWeight.w700)),
        if (next != null) ...[
          SizedBox(height: 12 * s),
          _metaRow([_meta('Libre hasta', _hm(next.start), s)], s),
        ],
      ]);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        nowCard,
        if (next != null) ...[
          SizedBox(height: 16 * s),
          Row(
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12 * s, vertical: 4 * s),
                decoration: BoxDecoration(color: _gold, borderRadius: BorderRadius.circular(20 * s)),
                child: Text(_hm(next.start),
                    style: TextStyle(
                        color: _navy,
                        fontSize: 17 * s,
                        fontWeight: FontWeight.w800,
                        fontFeatures: const [FontFeature.tabularFigures()])),
              ),
              SizedBox(width: 12 * s),
              Flexible(
                child: RichText(
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  text: TextSpan(
                    style: TextStyle(color: _inkSoft2, fontSize: 17 * s),
                    children: [
                      const TextSpan(text: 'Próxima: '),
                      TextSpan(
                          text: next.subject,
                          style: const TextStyle(color: _ink, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _agenda(Agenda d, double s) {
    return Container(
      decoration: BoxDecoration(
        color: _panel,
        borderRadius: BorderRadius.circular(22 * s),
        border: Border.all(color: _line),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: .06), blurRadius: 22 * s, offset: Offset(0, 8 * s)),
        ],
      ),
      padding: EdgeInsets.all(22 * s),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('AGENDA DE HOY',
                  style: TextStyle(color: _kick, fontSize: 12 * s, fontWeight: FontWeight.w800, letterSpacing: 3 * s)),
              Text('${d.events.length} ${d.events.length == 1 ? "reunión" : "reuniones"}',
                  style: TextStyle(color: _inkMute2, fontSize: 12 * s, fontWeight: FontWeight.w600)),
            ],
          ),
          SizedBox(height: 14 * s),
          Expanded(
            child: d.events.isEmpty
                ? Center(
                    child: Text('Sin reuniones hoy',
                        style: TextStyle(color: _inkMute2, fontSize: 18 * s)))
                : ListView.separated(
                    itemCount: d.events.length,
                    separatorBuilder: (_, __) => SizedBox(height: 8 * s),
                    itemBuilder: (_, i) => _eventRow(d, d.events[i], s),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _eventRow(Agenda d, Event e, double s) {
    final live = d.current != null && e.start == d.current!.start;
    final done = !live && e.end.isBefore(_display);

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16 * s, vertical: 13 * s),
      decoration: BoxDecoration(
        color: live ? const Color(0x14C7362B) : const Color(0x05000000),
        borderRadius: BorderRadius.circular(13 * s),
        border: Border.all(color: live ? const Color(0x66C7362B) : Colors.transparent),
      ),
      child: Opacity(
        opacity: done ? 0.4 : 1,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 54 * s,
              child: Text(_hm(e.start),
                  style: TextStyle(
                      color: live ? _busy : _ink,
                      fontSize: 19 * s,
                      fontWeight: FontWeight.w700,
                      fontFeatures: const [FontFeature.tabularFigures()])),
            ),
            SizedBox(width: 14 * s),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(e.subject,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          color: _ink,
                          fontSize: 18 * s,
                          fontWeight: FontWeight.w600,
                          decoration: done ? TextDecoration.lineThrough : null,
                          decorationColor: _inkMute2)),
                  SizedBox(height: 2 * s),
                  Text(
                      e.organizer.isEmpty
                          ? '${_hm(e.start)}–${_hm(e.end)}'
                          : '${e.organizer} · ${_hm(e.start)}–${_hm(e.end)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: _inkMute2, fontSize: 13 * s)),
                ],
              ),
            ),
            if (live) ...[
              SizedBox(width: 8 * s),
              Padding(padding: EdgeInsets.only(top: 4 * s), child: _Dot(color: _busy, size: 10 * s)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _footer(Agenda d, double s) {
    final ok = _error == null;
    return Padding(
      padding: EdgeInsets.fromLTRB(30 * s, 0, 30 * s, 16 * s),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(d.room, style: TextStyle(color: _inkMute2, fontSize: 12 * s)),
          Row(
            children: [
              _Dot(color: ok ? _free : _busy, size: 8 * s),
              SizedBox(width: 8 * s),
              Text(ok ? 'En línea' : 'Reintentando conexión…',
                  style: TextStyle(color: _inkMute2, fontSize: 12 * s)),
            ],
          ),
        ],
      ),
    );
  }

  // ---------- helpers de UI ----------
  Widget _card(double s, {required List<Widget> children}) => Container(
        width: double.infinity,
        padding: EdgeInsets.all(22 * s),
        decoration: BoxDecoration(
          color: _bg,
          borderRadius: BorderRadius.circular(16 * s),
          border: Border.all(color: _line),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
      );

  Widget _kicker(String t, double s) => Text(t,
      style: TextStyle(color: _kick, fontSize: 11 * s, fontWeight: FontWeight.w800, letterSpacing: 2.6 * s));

  Widget _metaRow(List<Widget> items, double s) =>
      Wrap(spacing: 22 * s, runSpacing: 6 * s, children: items);

  Widget _meta(String k, String v, double s) => RichText(
        text: TextSpan(
          style: TextStyle(color: _inkSoft2, fontSize: 16 * s),
          children: [
            TextSpan(text: '$k '),
            TextSpan(text: v, style: const TextStyle(color: _ink, fontWeight: FontWeight.w700)),
          ],
        ),
      );

  String _roomLabel(String upn) => 'Tablet Room';
  String _capitalize(String s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
}

// ==================== Popup de reserva ====================
class _ReserveDialog extends StatefulWidget {
  final DateTime now; // hora de pared (Chile)
  const _ReserveDialog({required this.now});

  @override
  State<_ReserveDialog> createState() => _ReserveDialogState();
}

class _ReserveDialogState extends State<_ReserveDialog> {
  final _subject = TextEditingController();
  final _service = ReservationService();
  late DateTime _start;
  int _dur = 30; // minutos
  bool _sending = false;
  String? _err;

  @override
  void initState() {
    super.initState();
    _start = _roundUp(widget.now);
  }

  @override
  void dispose() {
    _subject.dispose();
    super.dispose();
  }

  // Redondea al próximo múltiplo de 15 min.
  DateTime _roundUp(DateTime t) {
    final base = DateTime(t.year, t.month, t.day, t.hour, t.minute);
    final add = (15 - base.minute % 15) % 15;
    return add == 0 ? base : base.add(Duration(minutes: add));
  }

  DateTime get _end => _start.add(Duration(minutes: _dur));
  String _hm(DateTime t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: _start.hour, minute: _start.minute),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(colorScheme: const ColorScheme.light(primary: _navy)),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        _start = DateTime(widget.now.year, widget.now.month, widget.now.day, picked.hour, picked.minute);
        _err = null;
      });
    }
  }

  Future<void> _submit() async {
    final subj = _subject.text.trim();
    if (subj.isEmpty) {
      setState(() => _err = 'Escribe un título para la reunión');
      return;
    }
    setState(() {
      _sending = true;
      _err = null;
    });
    final res = await _service.reserve(subject: subj, start: _start, end: _end);
    if (!mounted) return;
    if (res.ok) {
      Navigator.of(context).pop(true);
    } else {
      setState(() {
        _sending = false;
        _err = res.message;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: _panel,
      insetPadding: const EdgeInsets.all(24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const _Hazard(height: 7, margin: EdgeInsets.zero),
              Padding(
                padding: const EdgeInsets.all(26),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Reservar sala',
                        style: TextStyle(color: _ink, fontSize: 24, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 4),
                    const Text('Tablet Room · hoy',
                        style: TextStyle(color: _inkMute2, fontSize: 13)),
                    const SizedBox(height: 22),
                    _label('TÍTULO'),
                    const SizedBox(height: 7),
                    TextField(
                      controller: _subject,
                      autofocus: true,
                      textCapitalization: TextCapitalization.sentences,
                      style: const TextStyle(color: _ink, fontSize: 16, fontWeight: FontWeight.w600),
                      decoration: _fieldDeco('Ej. Reunión de obra'),
                      onSubmitted: (_) => _submit(),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _label('INICIO'),
                              const SizedBox(height: 7),
                              _timeButton(),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _label('TERMINA'),
                              const SizedBox(height: 7),
                              Container(
                                height: 48,
                                alignment: Alignment.centerLeft,
                                padding: const EdgeInsets.symmetric(horizontal: 14),
                                decoration: BoxDecoration(
                                    color: _fieldBg, borderRadius: BorderRadius.circular(10)),
                                child: Text(_hm(_end),
                                    style: const TextStyle(
                                        color: _ink, fontSize: 18, fontWeight: FontWeight.w700)),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    _label('DURACIÓN'),
                    const SizedBox(height: 9),
                    Wrap(spacing: 8, runSpacing: 8, children: [30, 60, 90, 120].map(_durChip).toList()),
                    if (_err != null) ...[
                      const SizedBox(height: 18),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                            color: const Color(0x14C7362B), borderRadius: BorderRadius.circular(10)),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline, color: _busy, size: 18),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(_err!,
                                  style: const TextStyle(
                                      color: _busy, fontSize: 13.5, fontWeight: FontWeight.w600)),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        TextButton(
                          onPressed: _sending ? null : () => Navigator.of(context).pop(false),
                          child: const Text('Cancelar',
                              style: TextStyle(color: _inkSoft2, fontSize: 16, fontWeight: FontWeight.w600)),
                        ),
                        const Spacer(),
                        SizedBox(
                          height: 50,
                          child: FilledButton(
                            onPressed: _sending ? null : _submit,
                            style: FilledButton.styleFrom(
                              backgroundColor: _navy,
                              padding: const EdgeInsets.symmetric(horizontal: 28),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: _sending
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(strokeWidth: 2.4, color: _gold))
                                : const Text('Reservar',
                                    style: TextStyle(
                                        fontSize: 16.5, fontWeight: FontWeight.w700, color: Colors.white)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _label(String t) => Text(t,
      style: const TextStyle(color: _inkMute2, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1.5));

  InputDecoration _fieldDeco(String hint) => InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: _inkMute2, fontWeight: FontWeight.w400),
        filled: true,
        fillColor: _fieldBg,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: _navy, width: 1.6)),
      );

  Widget _timeButton() => Material(
        color: _fieldBg,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: _pickTime,
          child: Container(
            height: 48,
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              children: [
                const Icon(Icons.schedule, size: 18, color: _inkSoft2),
                const SizedBox(width: 8),
                Text(_hm(_start),
                    style: const TextStyle(color: _ink, fontSize: 18, fontWeight: FontWeight.w700)),
                const Spacer(),
                const Icon(Icons.edit, size: 15, color: _inkMute2),
              ],
            ),
          ),
        ),
      );

  Widget _durChip(int m) {
    final sel = _dur == m;
    return GestureDetector(
      onTap: () => setState(() => _dur = m),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: sel ? _navy : _fieldBg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: sel ? _navy : _line),
        ),
        child: Text('$m min',
            style: TextStyle(
                color: sel ? Colors.white : _ink, fontSize: 14.5, fontWeight: FontWeight.w700)),
      ),
    );
  }
}

// ==================== Widgets de marca ====================
class _Dot extends StatelessWidget {
  final Color color;
  final double size;
  const _Dot({required this.color, required this.size});
  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color,
          boxShadow: [BoxShadow(color: color.withValues(alpha: .3), blurRadius: 0, spreadRadius: size * .28)],
        ),
      );
}

class _InarcoLogo extends StatelessWidget {
  final double size;
  const _InarcoLogo({required this.size});
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        CustomPaint(size: Size(size * 1.15, size), painter: _CheckPainter()),
        SizedBox(width: size * 0.32),
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('CONSTRUCTORA',
                style: TextStyle(
                    color: _inkSoft, fontSize: size * 0.19, fontWeight: FontWeight.w600, letterSpacing: size * 0.09)),
            SizedBox(height: size * 0.06),
            Text('INARCO',
                style: TextStyle(
                    color: Colors.white, fontSize: size * 0.66, fontWeight: FontWeight.w800, letterSpacing: size * 0.05)),
          ],
        ),
      ],
    );
  }
}

class _CheckPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final p = Paint()..color = _gold;
    final path = Path()
      ..moveTo(0.06 * w, 0.56 * h)
      ..lineTo(0.36 * w, 0.92 * h)
      ..lineTo(0.96 * w, 0.10 * h)
      ..lineTo(0.76 * w, 0.10 * h)
      ..lineTo(0.35 * w, 0.66 * h)
      ..lineTo(0.22 * w, 0.56 * h)
      ..close();
    canvas.drawPath(path, p);
    final p2 = Paint()..color = _gold.withValues(alpha: .55);
    final path2 = Path()
      ..moveTo(0.06 * w, 0.56 * h)
      ..lineTo(0.36 * w, 0.92 * h)
      ..lineTo(0.44 * w, 0.75 * h)
      ..lineTo(0.22 * w, 0.56 * h)
      ..close();
    canvas.drawPath(path2, p2);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _Hazard extends StatelessWidget {
  final double height;
  final EdgeInsets margin;
  const _Hazard({required this.height, required this.margin});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: margin,
      child: CustomPaint(size: Size(double.infinity, height), painter: _HazardPainter()),
    );
  }
}

class _HazardPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xFF0E1C38));
    final stripe = Paint()..color = _gold;
    const band = 16.0;
    final path = Path();
    for (double x = -size.height; x < size.width + size.height; x += band * 2) {
      path.moveTo(x, size.height);
      path.lineTo(x + size.height, 0);
      path.lineTo(x + size.height + band, 0);
      path.lineTo(x + band, size.height);
      path.close();
    }
    canvas.drawPath(path, stripe);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Rejilla tenue estilo plano arquitectónico sobre el fondo claro.
class _BlueprintPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = const Color(0x0A16213B)
      ..strokeWidth = 1;
    const step = 46.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), p);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), p);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
