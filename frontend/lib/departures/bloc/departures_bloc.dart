import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/departure.dart';
import '../data/departures_repository.dart';

part 'departures_event.dart';
part 'departures_state.dart';

class DeparturesBloc extends Bloc<DeparturesEvent, DeparturesState> {
  final DeparturesRepository _repository;

  DeparturesBloc({required DeparturesRepository repository})
      : _repository = repository,
        super(DeparturesInitial()) {
    on<DeparturesLoadRequested>(
      _onLoad,
      transformer: restartable(),
    );
  }

  Future<void> _onLoad(
    DeparturesLoadRequested event,
    Emitter<DeparturesState> emit,
  ) async {
    emit(DeparturesLoading());
    try {
      final list = await _repository.fetchDepartures(event.stopRef);
      emit(DeparturesLoaded(list));
    } catch (e) {
      emit(DeparturesFailure(e.toString()));
    }
  }
}
