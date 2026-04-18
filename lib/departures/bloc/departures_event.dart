part of 'departures_bloc.dart';

sealed class DeparturesEvent {}

final class DeparturesLoadRequested extends DeparturesEvent {
  final String stopRef;

  DeparturesLoadRequested(this.stopRef);
}
