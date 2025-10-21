import 'package:timezone/timezone.dart' as tz;

class TimezoneUtils {
  static final tz.Location _peru = tz.getLocation('America/Lima');
  
  /// Hora actual en Perú
  static tz.TZDateTime now() => tz.TZDateTime.now(_peru);
  
  /// Convertir DateTime a timezone Perú
  static tz.TZDateTime toPeru(DateTime dateTime) => tz.TZDateTime.from(dateTime, _peru);
  
  /// Crear fecha en timezone Perú
  static tz.TZDateTime create(int year, int month, int day, [int hour = 0, int minute = 0]) {
    return tz.TZDateTime(_peru, year, month, day, hour, minute);
  }
  
  /// Fecha de "hoy" para DatePicker (sin hora)
  static DateTime today() {
    final now = tz.TZDateTime.now(_peru);
    return DateTime(now.year, now.month, now.day);
  }
}