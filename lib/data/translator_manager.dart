import 'package:google_mlkit_translation/google_mlkit_translation.dart';

class TranslatorManager {
  // El modelo se gestiona con hilos nativos, así que lo mantenemos estático
  static final _modelManager = OnDeviceTranslatorModelManager();
  
  // Definimos el traductor de En a Es
  static final _translator = OnDeviceTranslator(
    sourceLanguage: TranslateLanguage.english,
    targetLanguage: TranslateLanguage.spanish,
  );

  static Future<String> traducir(String texto) async {
    // CORRECCIÓN: Quitamos el "texto == null" que daba error de compilación
    if (texto.isEmpty) return "";
    
    try {
      // Pasamos 'es' como un String normal y corriente.
      final bool esDescargado = await _modelManager.isModelDownloaded('es');
      
      if (!esDescargado) {
        await _modelManager.downloadModel('es');
      }

      // Traducimos el texto
      return await _translator.translateText(texto);
    } catch (e) {
      // Si algo peta (falta de internet, etc.), devolvemos el inglés
      print("Error traducción: $e");
      return texto; 
    }
  }

  static void dispose() {
    _translator.close();
  }
}