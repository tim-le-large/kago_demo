import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/trip.dart';
import '../data/trips_repository.dart';

part 'trips_event.dart';
part 'trips_state.dart';

class TripsBloc extends Bloc<TripsEvent, TripsState> {
  final TripsRepository _repository;

  TripsBloc({required TripsRepository repository})
      : _repository = repository,
        super(TripsInitial()) {
    on<TripsSearchRequested>(
      _onSearch,
      transformer: restartable(),
    );
  }

  Future<void> _onSearch(
    TripsSearchRequested event,
    Emitter<TripsState> emit,
  ) async {
    final keepShowingResults = state is TripsLoaded;
    if (!keepShowingResults) {
      emit(TripsLoading());
    }
    try {
      final journeys = await _repository.searchTrips(
        event.originRef,
        event.destRef,
        departureTime: event.departureTime,
      );
      emit(TripsLoaded(journeys));
    } catch (e) {
      emit(TripsFailure(e.toString()));
    }
  }
}
