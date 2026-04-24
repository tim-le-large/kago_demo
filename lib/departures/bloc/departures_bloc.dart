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
    final showFullScreenLoader = state is! DeparturesLoaded;
    if (showFullScreenLoader) {
      emit(DeparturesLoading());
    }
    try {
      final list = await _repository.fetchDepartures(event.stopRef);
      final sorted = [...list]..sort((a, b) {
          final ta = Departure.parsePlannedTime(a.plannedTime);
          final tb = Departure.parsePlannedTime(b.plannedTime);
          if (ta == null && tb == null) return 0;
          if (ta == null) return 1;
          if (tb == null) return -1;
          return ta.compareTo(tb);
        });
      emit(DeparturesLoaded(sorted));
    } catch (e) {
      emit(DeparturesFailure(e.toString()));
    }
  }
}
