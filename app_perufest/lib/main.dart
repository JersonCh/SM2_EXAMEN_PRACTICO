import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:timezone/data/latest.dart' as tz; // Add this import
import 'package:timezone/timezone.dart' as tz; // Add this import
import 'app.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'services/notificaciones_service.dart';
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize timezone database FIRST
  tz.initializeTimeZones(); // Add this line
  tz.setLocalLocation(tz.getLocation('America/Lima')); // Add this line

  // Inicializar datos locales para formateo de fechas en español
  await initializeDateFormatting('es_ES', null);

    // Inicializar notificaciones
  await NotificacionesService().initialize();

  try {
    await Firebase.initializeApp();
  } catch (e) {
    if (kDebugMode) {
      debugPrint('Error al inicializar Firebase: $e');
    }
  }
  // Inicializar Supabase
  await Supabase.initialize(
    url: 'https://miiavhizwsbjhqmwfsac.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1paWF2aGl6d3NiamhxbXdmc2FjIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTc1NzQ4ODgsImV4cCI6MjA3MzE1MDg4OH0.qpvupYcgB37twSDvlExCKXklf-X1lm2rfx6UJhWx-b8',
  );
  runApp(const MyApp());
}