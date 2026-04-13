import 'package:shared_preferences/shared_preferences.dart';

class HistoryService {
  // Una "llave" única para identificar nuestra lista en el almacén
  static const String _key = 'ejercicios_recientes';

  // Función para GUARDAR un ejercicio en el historial
  static Future<void> guardarEjercicio(String nombreEjercicio) async {
    final prefs = await SharedPreferences.getInstance();
    
    // 1. Leemos lo que ya hay guardado (si no hay nada, lista vacía)
    List<String> historial = prefs.getStringList(_key) ?? [];

    // 2. Lo borramos si ya existe (para que no esté repetido)
    historial.remove(nombreEjercicio);

    // 3. Lo añadimos al principio de la lista
    historial.insert(0, nombreEjercicio);

    // 4. Limitamos el historial a los últimos 5, por ejemplo
    if (historial.length > 5) {
      historial = historial.sublist(0, 5);
    }

    // 5. Guardamos la nueva lista en el disco
    await prefs.setStringList(_key, historial);
  }

  // Función para LEER el historial
  static Future<List<String>> obtenerHistorial() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_key) ?? [];
  }
}