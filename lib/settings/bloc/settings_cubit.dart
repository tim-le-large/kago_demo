import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/settings_repository.dart';

class SettingsCubit extends Cubit<ThemeMode> {
  final SettingsRepository _repository;

  SettingsCubit({required SettingsRepository repository})
      : _repository = repository,
        super(ThemeMode.system);

  Future<void> load() async {
    final mode = await _repository.loadThemeMode();
    emit(mode);
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    emit(mode);
    await _repository.saveThemeMode(mode);
  }
}

