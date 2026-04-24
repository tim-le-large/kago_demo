import 'package:flutter_test/flutter_test.dart';
import 'package:kago/departures/data/departure.dart';

void main() {
  group('Departure.fromJson', () {
    test('maps fields', () {
      final d = Departure.fromJson({
        'line': 'S2',
        'destination': 'Hbf',
        'plannedTime': '2026-04-24T14:30:00.000Z',
      });
      expect(d.line, 'S2');
      expect(d.destination, 'Hbf');
      expect(d.plannedTime, '2026-04-24T14:30:00.000Z');
    });

    test('uses empty strings for missing keys', () {
      final d = Departure.fromJson({});
      expect(d.line, '');
      expect(d.destination, '');
      expect(d.plannedTime, '');
    });
  });

  group('Departure.parsePlannedTime', () {
    test('parses ISO-8601', () {
      final dt = Departure.parsePlannedTime('2026-04-24T14:30:00.000Z');
      expect(dt, isNotNull);
      expect(dt!.toUtc().hour, 14);
      expect(dt.toUtc().minute, 30);
    });

    test('normalizes space between date and time', () {
      final dt = Departure.parsePlannedTime('2026-04-24 14:30:00');
      expect(dt, isNotNull);
      expect(dt!.hour, 14);
      expect(dt.minute, 30);
    });

    test('returns null for empty or invalid input', () {
      expect(Departure.parsePlannedTime(''), isNull);
      expect(Departure.parsePlannedTime('   '), isNull);
      expect(Departure.parsePlannedTime('not-a-date'), isNull);
    });
  });
}
