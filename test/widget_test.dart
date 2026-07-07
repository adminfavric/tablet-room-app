// Smoke test del visor de agenda.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:tabletroom_viewer/screens/agenda_screen.dart';

void main() {
  testWidgets('Muestra el estado de carga inicial', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: AgendaScreen()));
    // Antes de la primera respuesta del backend debe verse el estado de carga.
    expect(find.text('Cargando agenda…'), findsOneWidget);
  });
}
