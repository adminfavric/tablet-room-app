/// Modelos tipados para el JSON que expone el backend (`GET /agenda`).
///
/// La tablet es solo lectura: estos modelos solo deserializan, nunca envían.
library;

/// Extrae la "hora de pared" del ISO que manda el backend, SIN reconvertir a la
/// zona horaria del dispositivo.
///
/// El backend ya entrega la hora en horario de Chile (ej. "2026-07-07T01:30:00-04:00").
/// Usar `DateTime.parse` la convertiría a la zona del equipo (si la tablet está en
/// UTC, mostraría 05:30). Tomando los componentes literales, mostramos 01:30 siempre,
/// independientemente de cómo esté configurada la tablet.
DateTime parseWallClock(String iso) {
  final m = RegExp(r'(\d{4})-(\d{2})-(\d{2})T(\d{2}):(\d{2})').firstMatch(iso);
  if (m == null) return DateTime.parse(iso);
  return DateTime(
    int.parse(m.group(1)!),
    int.parse(m.group(2)!),
    int.parse(m.group(3)!),
    int.parse(m.group(4)!),
    int.parse(m.group(5)!),
  );
}

class Event {
  final String subject;
  final String organizer;
  final DateTime start; // hora de pared (Chile)
  final DateTime end;
  final bool isOnlineMeeting;

  const Event({
    required this.subject,
    required this.organizer,
    required this.start,
    required this.end,
    required this.isOnlineMeeting,
  });

  factory Event.fromJson(Map<String, dynamic> json) {
    return Event(
      subject: (json['subject'] as String?) ?? '(Sin título)',
      organizer: (json['organizer'] as String?) ?? '',
      start: parseWallClock(json['start'] as String),
      end: parseWallClock(json['end'] as String),
      isOnlineMeeting: (json['isOnlineMeeting'] as bool?) ?? false,
    );
  }
}

class Agenda {
  final String room;
  final DateTime now; // hora de pared (Chile), según el backend
  final bool ocupada;
  final Event? current;
  final Event? next;
  final List<Event> events;

  const Agenda({
    required this.room,
    required this.now,
    required this.ocupada,
    required this.current,
    required this.next,
    required this.events,
  });

  factory Agenda.fromJson(Map<String, dynamic> json) {
    Event? parseOptional(dynamic value) =>
        value == null ? null : Event.fromJson(value as Map<String, dynamic>);

    return Agenda(
      room: (json['room'] as String?) ?? '',
      now: parseWallClock(json['now'] as String),
      ocupada: json['status'] == 'ocupada',
      current: parseOptional(json['current']),
      next: parseOptional(json['next']),
      events: ((json['events'] as List?) ?? const [])
          .map((e) => Event.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
