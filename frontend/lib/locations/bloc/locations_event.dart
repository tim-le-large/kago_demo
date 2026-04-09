part of 'locations_bloc.dart';

sealed class LocationsEvent {}

final class LocationsSearchRequested extends LocationsEvent {
  final String query;

  LocationsSearchRequested(this.query);
}
