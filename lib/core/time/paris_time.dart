import 'package:timezone/data/latest.dart' as data;
import 'package:timezone/timezone.dart' as tz;

/// Les dates métier sont des heures de Paris, indépendantes du téléphone.
class ParisTime {
  ParisTime._();

  static final tz.Location _location = _initialize();
  static tz.Location _initialize() {
    data.initializeTimeZones();
    return tz.getLocation('Europe/Paris');
  }

  static DateTime now() => tz.TZDateTime.now(_location);

  static DateTime at(DateTime day, int hour, int minute) =>
      tz.TZDateTime(_location, day.year, day.month, day.day, hour, minute);

  static DateTime parse(String value) {
    final parsed = DateTime.parse(value);
    if (RegExp(
      r'(Z|[+-]\d{2}:?\d{2})$',
      caseSensitive: false,
    ).hasMatch(value)) {
      return tz.TZDateTime.from(parsed, _location);
    }
    return tz.TZDateTime(
      _location,
      parsed.year,
      parsed.month,
      parsed.day,
      parsed.hour,
      parsed.minute,
      parsed.second,
      parsed.millisecond,
      parsed.microsecond,
    );
  }

  static bool isValidSlot(DateTime day, int hour, int minute) {
    bool matches(DateTime instant) =>
        instant.year == day.year &&
        instant.month == day.month &&
        instant.day == day.day &&
        instant.hour == hour &&
        instant.minute == minute;
    final candidate = at(day, hour, minute);
    return matches(candidate) &&
        !matches(
          tz.TZDateTime.from(
            candidate.subtract(const Duration(hours: 1)),
            _location,
          ),
        ) &&
        !matches(
          tz.TZDateTime.from(
            candidate.add(const Duration(hours: 1)),
            _location,
          ),
        );
  }

  /// Sans suffixe UTC : l'API conserve explicitement l'heure locale métier.
  static String serialize(DateTime value) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${value.year.toString().padLeft(4, '0')}-${two(value.month)}-${two(value.day)}T${two(value.hour)}:${two(value.minute)}:${two(value.second)}';
  }
}
