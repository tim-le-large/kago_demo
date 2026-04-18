import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../config/api_config.dart';
import 'trip.dart';

abstract class TripsRepository {
  Future<List<Journey>> searchTrips(String originRef, String destRef, {DateTime? departureTime});
}

class HttpTripsRepository implements TripsRepository {
  final String baseUrl;
  final http.Client _client;

  HttpTripsRepository({
    String? baseUrl,
    http.Client? client,
  })  : baseUrl = baseUrl ?? ApiConfig.defaultBaseUrl,
        _client = client ?? http.Client();

  @override
  Future<List<Journey>> searchTrips(
    String originRef,
    String destRef, {
    DateTime? departureTime,
  }) async {
    final uri = Uri.parse('$baseUrl/api/v1/trips');
    final body = <String, dynamic>{
      'originRef': originRef,
      'destRef': destRef,
    };
    if (departureTime != null) {
      body['departureTime'] = departureTime.toUtc().toIso8601String();
    }

    final response = await _client.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );

    if (response.statusCode != 200) {
      throw Exception('Verbindungssuche fehlgeschlagen: ${response.statusCode}');
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final journeys = (json['journeys'] as List<dynamic>?) ?? [];
    return journeys.map((j) => Journey.fromJson(j as Map<String, dynamic>)).toList();
  }
}

class FakeTripsRepository implements TripsRepository {
  @override
  Future<List<Journey>> searchTrips(
    String originRef,
    String destRef, {
    DateTime? departureTime,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 600));
    final now = departureTime ?? DateTime.now();
    return [
      Journey(
        departureTime: now.add(const Duration(minutes: 5)).toUtc().toIso8601String(),
        arrivalTime: now.add(const Duration(minutes: 11)).toUtc().toIso8601String(),
        durationMinutes: 6,
        transfers: 0,
        legs: [
          Leg(
            line: 'S11',
            departureStop: 'Hauptbahnhof (Vorplatz)',
            arrivalStop: 'Marktplatz (Pyramide U)',
            departureTime: now.add(const Duration(minutes: 5)).toUtc().toIso8601String(),
            arrivalTime: now.add(const Duration(minutes: 11)).toUtc().toIso8601String(),
          ),
        ],
      ),
      Journey(
        departureTime: now.add(const Duration(minutes: 12)).toUtc().toIso8601String(),
        arrivalTime: now.add(const Duration(minutes: 30)).toUtc().toIso8601String(),
        durationMinutes: 18,
        transfers: 1,
        legs: [
          Leg(
            line: '2',
            departureStop: 'Hauptbahnhof (Vorplatz)',
            arrivalStop: 'Kronenplatz',
            departureTime: now.add(const Duration(minutes: 12)).toUtc().toIso8601String(),
            arrivalTime: now.add(const Duration(minutes: 17)).toUtc().toIso8601String(),
          ),
          Leg(
            line: '5',
            departureStop: 'Kronenplatz',
            arrivalStop: 'Durlach Bahnhof',
            departureTime: now.add(const Duration(minutes: 20)).toUtc().toIso8601String(),
            arrivalTime: now.add(const Duration(minutes: 30)).toUtc().toIso8601String(),
          ),
        ],
      ),
    ];
  }
}
