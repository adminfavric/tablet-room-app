/// Modelos tipados para el JSON que expone el backend (`GET /agenda`).
///
/// La tablet es solo lectura: estos modelos solo deserializan, nunca envían.
library;

class Event {
  final String subject;
  final String organizer;
  final DateTime start;
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
      start: DateTime.parse(json['start'] as String),
      end: DateTime.parse(json['end'] as String),
      isOnlineMeeting: (json['isOnlineMeeting'] as bool?) ?? false,
    );
  }
}

class Agenda {
  final String room;
  final DateTime now;
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
      now: DateTime.parse(json['now'] as String),
      ocupada: json['status'] == 'ocupada',
      current: parseOptional(json['current']),
      next: parseOptional(json['next']),
      events: ((json['events'] as List?) ?? const [])
          .map((e) => Event.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
