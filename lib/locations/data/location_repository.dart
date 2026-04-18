import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../config/api_config.dart';
import 'location.dart';

abstract class LocationsRepository {
  Future<List<Location>> search(String query);
}

class HttpLocationsRepository implements LocationsRepository {
  final String baseUrl;
  final http.Client _client;

  HttpLocationsRepository({
    String? baseUrl,
    http.Client? client,
  })  : baseUrl = baseUrl ?? ApiConfig.defaultBaseUrl,
        _client = client ?? http.Client();

  @override
  Future<List<Location>> search(String query) async {
    final uri = Uri.parse('$baseUrl/api/v1/locations')
        .replace(queryParameters: {'q': query, 'limit': '10'});

    final response = await _client.get(uri);

    if (response.statusCode != 200) {
      throw Exception('Fehler bei der Haltestellensuche: ${response.statusCode}');
    }

    final List<dynamic> jsonList = jsonDecode(response.body) as List<dynamic>;
    return jsonList.map((j) => Location.fromJson(j as Map<String, dynamic>)).toList();
  }
}

class FakeLocationsRepository implements LocationsRepository {
  FakeLocationsRepository();

  static final List<Location> _all = [
    const Location(id: 'de:82121:1', name: 'Karlsruhe Hbf'),
    const Location(id: 'de:82121:2', name: 'Marktplatz (Kaiserstraße)'),
    const Location(id: 'de:82121:3', name: 'Durlach Bahnhof'),
    const Location(id: 'de:82121:4', name: 'Mühlburg Poststraße'),
    const Location(id: 'de:82121:5', name: 'Tullastraße/Alter Schlachthof'),
  ];

  @override
  Future<List<Location>> search(String query) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    final q = query.trim().toLowerCase();
    if (q.isEmpty) {
      return [];
    }
    return _all
        .where(
          (l) =>
              l.name.toLowerCase().contains(q) || l.id.toLowerCase().contains(q),
        )
        .take(10)
        .toList();
  }
}
