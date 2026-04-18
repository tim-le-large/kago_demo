import 'package:equatable/equatable.dart';

class Departure extends Equatable {
  final String line;
  final String destination;
  final String plannedTime;

  const Departure({
    required this.line,
    required this.destination,
    required this.plannedTime,
  });

  factory Departure.fromJson(Map<String, dynamic> json) {
    return Departure(
      line: (json['line'] as String?) ?? '',
      destination: (json['destination'] as String?) ?? '',
      plannedTime: (json['plannedTime'] as String?) ?? '',
    );
  }

  @override
  List<Object?> get props => [line, destination, plannedTime];
}
