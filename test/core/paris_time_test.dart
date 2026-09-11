import 'package:flutter_test/flutter_test.dart';
import 'package:table_master_mobile/core/time/paris_time.dart';

void main() {
  test('les instants UTC sont affichés en heure de Paris hiver et été', () {
    expect(ParisTime.parse('2026-01-15T12:00:00Z').hour, 13);
    expect(ParisTime.parse('2026-07-15T12:00:00Z').hour, 14);
    expect(ParisTime.parse('2026-07-15T12:00:00').hour, 12);
    expect(
      ParisTime.serialize(ParisTime.parse('2026-07-15T12:00:00Z')),
      '2026-07-15T14:00:00',
    );
  });
  test('une heure inexistante ou ambiguë ne peut pas être réservée', () {
    expect(ParisTime.isValidSlot(DateTime(2026, 3, 29), 2, 30), isFalse);
    expect(ParisTime.isValidSlot(DateTime(2026, 10, 25), 2, 30), isFalse);
    expect(ParisTime.isValidSlot(DateTime(2026, 10, 25), 3, 30), isTrue);
  });
}
