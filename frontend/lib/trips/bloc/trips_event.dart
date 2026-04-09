part of 'trips_bloc.dart';

sealed class TripsEvent {}

final class TripsSearchRequested extends TripsEvent {
  final String originRef;
  final String destRef;
  final DateTime? departureTime;

  TripsSearchRequested({
    required this.originRef,
    required this.destRef,
    this.departureTime,
  });
}
