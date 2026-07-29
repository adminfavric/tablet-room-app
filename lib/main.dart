import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'screens/agenda_screen.dart';
import 'screens/room_setup_screen.dart';
import 'services/room_config.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('es');
  await SystemChrome.setPreferredOrientations(
    [DeviceOrientation.landscapeLeft, DeviceOrientation.landscapeRight],
  );
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

  // Sala guardada en el dispositivo: si no hay, se muestra el selector inicial.
  final saved = await RoomConfig.load();

  runApp(MaterialApp(
    debugShowCheckedModeBanner: false,
    home: saved == null
        ? const RoomSetupScreen()
        : AgendaScreen(roomUpn: saved.upn, roomName: saved.name),
  ));
}
