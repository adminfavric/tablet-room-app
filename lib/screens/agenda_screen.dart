import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../models/agenda.dart';
import '../services/agenda_service.dart';

const int kRefreshSeconds = 30;

// --- Paleta Inarco ---
const _navy = Color(0xFF0F1E3D);
const _navyTop = Color(0xFF12213F);
const _navyBot = Color(0xFF0D1A34);
const _gold = Color(0xFFF5C21F);
const _free = Color(0xFF1E8E3E);
const _busy = Color(0xFFC7362B);
const _inkSoft = Color(0xFF9FB0CF);
const _inkMute = Color(0xFF6B7EA3);
const _cardLine = Color(0x1AFFFFFF);

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [_navyTop, _navyBot],
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, c) {
              // Escala relativa a ancho Y alto (responsivo a cualquier tablet).
              final s = math.min(c.maxWidth / 1280, c.maxHeight / 820).clamp(0.5, 1.7);
              final d = _data;
              if (d == null) return _loading(s);
              return _content(d, s);
            },
          ),
        ),
      ),
    );
  }

  // ---------- Estados de carga / error ----------
  Widget _loading(double s) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const _InarcoLogo(size: 56),
          SizedBox(height: 24 * s),
          SizedBox(
            width: 26 * s,
            height: 26 * s,
            child: CircularProgressIndicator(color: _gold, strokeWidth: 3 * s),
          ),
          SizedBox(height: 20 * s),
          Text(
            _error == null ? 'Cargando agenda…' : 'Sin conexión con el servidor',
            style: TextStyle(color: _inkSoft, fontSize: 18 * s),
          ),
          if (_error != null) ...[
            SizedBox(height: 6 * s),
            Text('Reintentando cada $kRefreshSeconds s',
                style: TextStyle(color: _inkMute, fontSize: 13 * s)),
          ],
        ],
      ),
    );
  }

  // ---------- Contenido principal ----------
  Widget _content(Agenda d, double s) {
    return Column(
      children: [
        _topBar(d, s),
        _Hazard(height: 6 * s, margin: EdgeInsets.fromLTRB(28 * s, 14 * s, 28 * s, 0)),
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
    );
  }

  Widget _topBar(Agenda d, double s) {
    return Padding(
      padding: EdgeInsets.fromLTRB(28 * s, 20 * s, 28 * s, 0),
      child: Row(
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
              Text(_roomLabel(d.room),
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
      ),
    );
  }

  Widget _statusBlock(Agenda d, double s) {
    final accent = d.ocupada ? _busy : _free;
    return Container(
      decoration: BoxDecoration(
        color: const Color(0x0DFFFFFF),
        borderRadius: BorderRadius.circular(22 * s),
        border: Border.all(color: _cardLine),
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
                    style: TextStyle(color: const Color(0xFFDFE6F5), fontSize: 22 * s, fontWeight: FontWeight.w500),
                  ),
                  const Spacer(),
                  _detail(d, s, accent),
                ],
              ),
            ),
          ),
        ],
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
            style: TextStyle(color: Colors.white, fontSize: 30 * s, height: 1.1, fontWeight: FontWeight.w700)),
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
            backgroundColor: const Color(0x1FFFFFFF),
            valueColor: AlwaysStoppedAnimation(accent),
          ),
        ),
      ]);
    } else {
      nowCard = _card(s, children: [
        _kicker('DISPONIBLE', s),
        SizedBox(height: 8 * s),
        Text(next == null ? 'Sin más reuniones hoy' : 'Sin reunión en curso',
            style: TextStyle(color: Colors.white, fontSize: 30 * s, height: 1.1, fontWeight: FontWeight.w700)),
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
          SizedBox(height: 18 * s),
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
                    style: TextStyle(color: _inkSoft, fontSize: 17 * s),
                    children: [
                      const TextSpan(text: 'Próxima: '),
                      TextSpan(
                          text: next.subject,
                          style: const TextStyle(color: Color(0xFFEEF2FB), fontWeight: FontWeight.w600)),
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
        color: const Color(0x0DFFFFFF),
        borderRadius: BorderRadius.circular(22 * s),
        border: Border.all(color: _cardLine),
      ),
      padding: EdgeInsets.all(22 * s),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('AGENDA DE HOY',
                  style: TextStyle(color: _gold, fontSize: 12 * s, fontWeight: FontWeight.w700, letterSpacing: 3 * s)),
              Text('${d.events.length} ${d.events.length == 1 ? "reunión" : "reuniones"}',
                  style: TextStyle(color: _inkMute, fontSize: 12 * s, fontWeight: FontWeight.w600)),
            ],
          ),
          SizedBox(height: 14 * s),
          Expanded(
            child: d.events.isEmpty
                ? Center(
                    child: Text('Sin reuniones hoy',
                        style: TextStyle(color: _inkMute, fontSize: 18 * s)))
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
        color: live ? const Color(0x33C7362B) : const Color(0x08FFFFFF),
        borderRadius: BorderRadius.circular(13 * s),
        border: Border.all(color: live ? const Color(0x8CC7362B) : Colors.transparent),
      ),
      child: Opacity(
        opacity: done ? 0.42 : 1,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 54 * s,
              child: Text(_hm(e.start),
                  style: TextStyle(
                      color: live ? Colors.white : const Color(0xFFDFE6F5),
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
                          color: const Color(0xFFF3F6FC),
                          fontSize: 18 * s,
                          fontWeight: FontWeight.w600,
                          decoration: done ? TextDecoration.lineThrough : null,
                          decorationColor: Colors.white54)),
                  SizedBox(height: 2 * s),
                  Text(
                      e.organizer.isEmpty
                          ? '${_hm(e.start)}–${_hm(e.end)}'
                          : '${e.organizer} · ${_hm(e.start)}–${_hm(e.end)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: _inkMute, fontSize: 13 * s)),
                ],
              ),
            ),
            if (live) ...[
              SizedBox(width: 8 * s),
              Padding(padding: EdgeInsets.only(top: 4 * s), child: _Dot(color: const Color(0xFFE05346), size: 10 * s)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _footer(Agenda d, double s) {
    final ok = _error == null;
    return Padding(
      padding: EdgeInsets.fromLTRB(30 * s, 0, 30 * s, 18 * s),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(d.room, style: TextStyle(color: _inkMute, fontSize: 12 * s)),
          Row(
            children: [
              _Dot(color: ok ? const Color(0xFF34A853) : _busy, size: 8 * s),
              SizedBox(width: 8 * s),
              Text(ok ? 'En línea' : 'Reintentando conexión…',
                  style: TextStyle(color: _inkMute, fontSize: 12 * s)),
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
          color: const Color(0x38000000),
          borderRadius: BorderRadius.circular(16 * s),
          border: Border.all(color: _cardLine),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
      );

  Widget _kicker(String t, double s) => Text(t,
      style: TextStyle(color: _gold, fontSize: 11 * s, fontWeight: FontWeight.w700, letterSpacing: 2.6 * s));

  Widget _metaRow(List<Widget> items, double s) =>
      Wrap(spacing: 22 * s, runSpacing: 6 * s, children: items);

  Widget _meta(String k, String v, double s) => RichText(
        text: TextSpan(
          style: TextStyle(color: _inkSoft, fontSize: 16 * s),
          children: [
            TextSpan(text: '$k '),
            TextSpan(text: v, style: const TextStyle(color: Color(0xFFEEF2FB), fontWeight: FontWeight.w600)),
          ],
        ),
      );

  String _roomLabel(String upn) => 'Tablet Room';
  String _capitalize(String s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
}

// ---------- Widgets de marca ----------
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
    // Check angular estilo Inarco.
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
      child: ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: CustomPaint(size: Size(double.infinity, height), painter: _HazardPainter()),
      ),
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
