import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import '../models/actividad.dart';

class NotificacionesService {
  static final NotificacionesService _instance = NotificacionesService._internal();
  factory NotificacionesService() => _instance;
  NotificacionesService._internal();

  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestSoundPermission: true,
      requestBadgePermission: true,
      requestAlertPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(initSettings);
  }

  Future<void> programarRecordatorio({
    required String actividadId,
    required String nombreActividad,
    required String zona,
    required DateTime fechaInicio,
    required int minutosAntes,
  }) async {
    print('=== INICIO programarRecordatorio ===');
    print('ActividadId: $actividadId');
    print('NombreActividad: $nombreActividad');
    print('MinutosAntes: $minutosAntes');
    
    final id = actividadId.hashCode;
    
    final fechaNotificacion = fechaInicio.subtract(Duration(minutes: minutosAntes));
    final ahora = DateTime.now();
    
    print('=== DEBUG FECHAS ===');
    print('DateTime.now(): $ahora');
    print('fechaInicio: $fechaInicio');
    print('fechaNotificacion: $fechaNotificacion');
    print('fechaNotificacion.isBefore(ahora): ${fechaNotificacion.isBefore(ahora)}');
    print('Diferencia en minutos: ${fechaNotificacion.difference(ahora).inMinutes}');
    print('==================');
    
    // Verificar que la fecha de notificación sea futura
    if (fechaNotificacion.isBefore(DateTime.now())) {
      print('No se puede programar notificación en el pasado para $nombreActividad');
      return;
    }

    const androidDetails = AndroidNotificationDetails(
      'actividades_recordatorio',
      'Recordatorio de Actividades',
      channelDescription: 'Notificaciones para recordar actividades agendadas',
      importance: Importance.max, // Cambiar a max
      priority: Priority.max,     // Cambiar a max
      icon: '@mipmap/ic_launcher',
      playSound: true,
      enableVibration: true,
      showWhen: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    try {
      // Usar directamente la fecha sin conversión adicional
      final tzDateTime = tz.TZDateTime.from(fechaNotificacion, tz.local);

      await _notifications.zonedSchedule(
        id,
        'Recordatorio de Actividad',
        '$nombreActividad comenzará en $minutosAntes minutos en $zona',
        tzDateTime,
        notificationDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      );

      print('=== NOTIFICACIÓN PROGRAMADA ===');
      print('Fecha inicio actividad (Perú): $fechaInicio');
      print('Fecha notificación (Perú): $fechaNotificacion');
      print('TZ DateTime: $tzDateTime');
      print('Notificación programada para $nombreActividad en $minutosAntes minutos antes');
      
      print('===============================');
    } catch (e) {
      print('ERROR al programar notificación: $e');
      // Fallback: mostrar notificación inmediata si falla la programada
      await mostrarNotificacionInmediata(
        'Error de Programación',
        'No se pudo programar el recordatorio para $nombreActividad'
      );
    }
  }

  Future<void> cancelarRecordatorio(String actividadId) async {
    final id = actividadId.hashCode;
    await _notifications.cancel(id);
    print('Notificación cancelada para actividad: $actividadId');
  }

  int calcularMinutosRecordatorio(DateTime fechaInicio) {
    final ahora = DateTime.now();
    final minutosHastaInicio = fechaInicio.difference(ahora).inMinutes;
    
    if (minutosHastaInicio > 60) {
      return 60; // 1 hora antes
    } else if (minutosHastaInicio > 30) {
      return 30; // 30 minutos antes
    } else if (minutosHastaInicio > 15) {
      return 15; // 15 minutos antes
    } else if (minutosHastaInicio > 5) {
      return 5; // 5 minutos antes
    } else {
      return 0; // No programar si falta menos de 5 minutos
    }
  }

  // Método para probar notificaciones inmediatas
  Future<void> mostrarNotificacionInmediata(String titulo, String mensaje) async {
    const androidDetails = AndroidNotificationDetails(
      'test_channel',
      'Test Channel',
      channelDescription: 'Canal de prueba',
      importance: Importance.high,
      priority: Priority.high,
    );

    const notificationDetails = NotificationDetails(android: androidDetails);

    await _notifications.show(
      999,
      titulo,
      mensaje,
      notificationDetails,
    );
  }
}