part of 'departures_bloc.dart';

sealed class DeparturesState {}

final class DeparturesInitial extends DeparturesState {}

final class DeparturesLoading extends DeparturesState {}

final class DeparturesLoaded extends DeparturesState {
  final List<Departure> departures;

  DeparturesLoaded(this.departures);
}

final class DeparturesFailure extends DeparturesState {
  final String message;

  DeparturesFailure(this.message);
}
