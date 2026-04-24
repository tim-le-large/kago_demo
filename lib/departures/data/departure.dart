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

  /// TRIAS / HTTP may use `YYYY-MM-DD HH:MM:SS` or ISO-8601; normalize for [DateTime.tryParse].
  static DateTime? parsePlannedTime(String raw) {
    final t = raw.trim();
    if (t.isEmpty) return null;
    var s = t;
    if (RegExp(r'^\d{4}-\d{2}-\d{2} \d{2}:').hasMatch(s)) {
      s = '${s.substring(0, 10)}T${s.substring(11)}';
    }
    return DateTime.tryParse(s);
  }

  @override
  List<Object?> get props => [line, destination, plannedTime];
}
