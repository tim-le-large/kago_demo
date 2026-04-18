import 'package:equatable/equatable.dart';

class Leg extends Equatable {
  final String? line;
  final String? departureStop;
  final String? arrivalStop;
  final String? departureTime;
  final String? arrivalTime;

  const Leg({
    this.line,
    this.departureStop,
    this.arrivalStop,
    this.departureTime,
    this.arrivalTime,
  });

  factory Leg.fromJson(Map<String, dynamic> json) {
    return Leg(
      line: json['line'] as String?,
      departureStop: json['departureStop'] as String?,
      arrivalStop: json['arrivalStop'] as String?,
      departureTime: json['departureTime'] as String?,
      arrivalTime: json['arrivalTime'] as String?,
    );
  }

  bool get isWalk => line == 'walk';

  @override
  List<Object?> get props => [line, departureStop, arrivalStop, departureTime, arrivalTime];
}

class Journey extends Equatable {
  final String? departureTime;
  final String? arrivalTime;
  final int? durationMinutes;
  final int transfers;
  final List<Leg> legs;

  const Journey({
    this.departureTime,
    this.arrivalTime,
    this.durationMinutes,
    required this.transfers,
    required this.legs,
  });

  factory Journey.fromJson(Map<String, dynamic> json) {
    final legsList = (json['legs'] as List<dynamic>?) ?? [];
    return Journey(
      departureTime: json['departureTime'] as String?,
      arrivalTime: json['arrivalTime'] as String?,
      durationMinutes: json['durationMinutes'] as int?,
      transfers: (json['transfers'] as int?) ?? 0,
      legs: legsList.map((l) => Leg.fromJson(l as Map<String, dynamic>)).toList(),
    );
  }

  @override
  List<Object?> get props => [departureTime, arrivalTime, durationMinutes, transfers, legs];
}
