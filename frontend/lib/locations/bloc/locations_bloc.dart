import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/location.dart';
import '../data/location_repository.dart';

part 'locations_event.dart';
part 'locations_state.dart';

class LocationsBloc extends Bloc<LocationsEvent, LocationsState> {
  final LocationsRepository _repository;

  LocationsBloc({required LocationsRepository repository})
      : _repository = repository,
        super(LocationsInitial()) {
    on<LocationsSearchRequested>(
      _onSearch,
      transformer: restartable(),
    );
  }

  Future<void> _onSearch(
    LocationsSearchRequested event,
    Emitter<LocationsState> emit,
  ) async {
    final q = event.query.trim();
    if (q.isEmpty) {
      emit(LocationsInitial());
      return;
    }

    emit(LocationsLoading());

    try {
      final locations = await _repository.search(q);
      emit(LocationsLoaded(locations));
    } catch (e) {
      emit(LocationsFailure(e.toString()));
    }
  }
}
