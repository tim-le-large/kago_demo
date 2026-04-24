import 'package:flutter_test/flutter_test.dart';
import 'package:kago/trips/data/trip.dart';

void main() {
  group('Leg', () {
    test('isWalk is true when line is walk', () {
      expect(const Leg(line: 'walk').isWalk, isTrue);
      expect(const Leg(line: 'S2').isWalk, isFalse);
      expect(const Leg().isWalk, isFalse);
    });
  });

  group('Journey.fromJson', () {
    test('parses legs and transfers', () {
      final j = Journey.fromJson({
        'departureTime': '2026-04-24T08:00:00Z',
        'arrivalTime': '2026-04-24T08:25:00Z',
        'durationMinutes': 25,
        'transfers': 1,
        'legs': [
          {
            'line': '5',
            'departureStop': 'A',
            'arrivalStop': 'B',
            'departureTime': '08:00',
            'arrivalTime': '08:25',
          },
        ],
      });
      expect(j.departureTime, '2026-04-24T08:00:00Z');
      expect(j.durationMinutes, 25);
      expect(j.transfers, 1);
      expect(j.legs, hasLength(1));
      expect(j.legs.single.line, '5');
    });

    test('defaults transfers and legs when omitted', () {
      final j = Journey.fromJson({});
      expect(j.transfers, 0);
      expect(j.legs, isEmpty);
    });
  });
}
