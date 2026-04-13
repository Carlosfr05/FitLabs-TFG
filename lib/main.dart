import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pantallas_fitlabs/data/exercise.dart';
import 'package:pantallas_fitlabs/pantallas/exercise_detail_screen.dart';
import 'package:pantallas_fitlabs/pantallas/login.dart';
import 'package:pantallas_fitlabs/pantallas/resumen_dia.dart';
import 'package:pantallas_fitlabs/pantallas/mis_clientes.dart';
import 'package:pantallas_fitlabs/pantallas/calendario_screen.dart';
import 'package:pantallas_fitlabs/pantallas/registrarse.dart';
import 'package:pantallas_fitlabs/pantallas/crear_rutina.dart';
import 'package:pantallas_fitlabs/pantallas/detalle_cliente.dart';
import 'package:pantallas_fitlabs/pantallas/mensajes_screen.dart';
import 'package:pantallas_fitlabs/pantallas/search_exercise_screen.dart';

const String supabaseUrl = 'https://dsvxjscgruadxqelwqaj.supabase.co';
const String supabaseAnonKey =
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRzdnhqc2NncnVhZHhxZWx3cWFqIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzQyMDY1NTQsImV4cCI6MjA4OTc4MjU1NH0.oPtv_K9FnxcsnlsjDKdPe_rS_L_e50-oM2Wj4WeHq-E';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: supabaseUrl,
    anonKey: supabaseAnonKey,
    authOptions: FlutterAuthClientOptions(authFlowType: AuthFlowType.pkce),
  );
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FitLabs',
      theme: ThemeData(useMaterial3: true),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('es', 'ES')],
      locale: const Locale('es', 'ES'),
      home: Supabase.instance.client.auth.currentUser != null
          ? const ResumenDiaScreen()
          : const LoginScreen(),
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
      onGenerateRoute: (settings) {
        if (settings.name == '/exercise-detail') {
          final args = settings.arguments as Exercise;
          return MaterialPageRoute(
            builder: (context) => ExerciseDetailScreen(exercise: args),
          );
        }
        return null;
      },
    );
  }
}
