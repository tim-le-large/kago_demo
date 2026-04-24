import 'package:flutter_test/flutter_test.dart';
import 'package:kago/locations/data/location.dart';

void main() {
  group('Location.fromJson', () {
    test('maps id and name', () {
      final loc = Location.fromJson({
        'id': 'de:08212:90',
        'name': 'ZKM',
      });
      expect(loc.id, 'de:08212:90');
      expect(loc.name, 'ZKM');
    });

    test('defaults name to empty when null', () {
      final loc = Location.fromJson({'id': 'de:08212:1'});
      expect(loc.id, 'de:08212:1');
      expect(loc.name, '');
    });
  });
}
