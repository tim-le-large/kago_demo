part of 'locations_bloc.dart';

sealed class LocationsState {}

final class LocationsInitial extends LocationsState {}

final class LocationsLoading extends LocationsState {}

final class LocationsLoaded extends LocationsState {
  final List<Location> locations;

  LocationsLoaded(this.locations);
}

final class LocationsFailure extends LocationsState {
  final String message;

  LocationsFailure(this.message);
}
