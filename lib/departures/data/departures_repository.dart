import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../config/api_config.dart';
import 'departure.dart';

abstract class DeparturesRepository {
  Future<List<Departure>> fetchDepartures(String stopRef);
}

class HttpDeparturesRepository implements DeparturesRepository {
  final String baseUrl;
  final http.Client _client;

  HttpDeparturesRepository({
    String? baseUrl,
    http.Client? client,
  })  : baseUrl = baseUrl ?? ApiConfig.defaultBaseUrl,
        _client = client ?? http.Client();

  @override
  Future<List<Departure>> fetchDepartures(String stopRef) async {
    final uri = Uri.parse('$baseUrl/api/v1/departures').replace(
      queryParameters: {
        'stopRef': stopRef,
        'limit': '25',
      },
    );

    final response = await _client.get(uri);

    if (response.statusCode != 200) {
      throw Exception('Abfahrten konnten nicht geladen werden: ${response.statusCode}');
    }

    final List<dynamic> jsonList = jsonDecode(response.body) as List<dynamic>;
    return jsonList
        .map((j) => Departure.fromJson(j as Map<String, dynamic>))
        .toList();
  }
}

class FakeDeparturesRepository implements DeparturesRepository {
  @override
  Future<List<Departure>> fetchDepartures(String stopRef) async {
    await Future<void>.delayed(const Duration(milliseconds: 400));
    final now = DateTime.now();
    return [
      Departure(
        line: 'S2',
        destination: 'Rheinstetten',
        plannedTime: now.add(const Duration(minutes: 3)).toIso8601String(),
      ),
      Departure(
        line: '5',
        destination: 'Durlach',
        plannedTime: now.add(const Duration(minutes: 9)).toIso8601String(),
      ),
      Departure(
        line: 'Tram 2',
        destination: 'Siemensallee … Spöck',
        plannedTime: now.add(const Duration(minutes: 14)).toIso8601String(),
      ),
    ];
  }
}
