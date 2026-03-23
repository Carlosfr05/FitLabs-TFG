import 'package:flutter/material.dart';
import 'package:pantallas_fitlabs/pantallas/login.dart';
import 'package:pantallas_fitlabs/pantallas/resumen_dia.dart';
import 'package:pantallas_fitlabs/pantallas/mis_clientes.dart';
import 'package:pantallas_fitlabs/pantallas/calendario_screen.dart';
import 'package:pantallas_fitlabs/pantallas/registrarse.dart';
import 'package:pantallas_fitlabs/pantallas/crear_rutina.dart';
import 'package:pantallas_fitlabs/pantallas/detalle_cliente.dart';
import 'package:pantallas_fitlabs/pantallas/mensajes_screen.dart';
import 'package:pantallas_fitlabs/pantallas/search_exercise_screen.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FitLabs',
      theme: ThemeData(useMaterial3: true),
      home: const LoginScreen(),
      routes: {
        '/login': (context) => const LoginScreen(),
        '/mensajes': (context) => const MensajesScreen(),
        '/resumen': (context) => const ResumenDiaScreen(),
        '/clientes': (context) => const MisClientesScreen(),
        '/calendario': (context) => const CalendarioScreen(),
        '/registrarse': (context) => const RegistrarseScreen(),
        '/crear-rutina': (context) => const CrearRutinaScreen(),
        '/detalle-cliente': (context) => const DetalleClienteScreen(),
        '/search-ejercicio': (context) => const SearchExerciseScreen(),
      },
    );
  }
}
