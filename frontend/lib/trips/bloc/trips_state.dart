part of 'trips_bloc.dart';

sealed class TripsState {}

final class TripsInitial extends TripsState {}

final class TripsLoading extends TripsState {}

final class TripsLoaded extends TripsState {
  final List<Journey> journeys;

  TripsLoaded(this.journeys);
}

final class TripsFailure extends TripsState {
  final String message;

  TripsFailure(this.message);
}
