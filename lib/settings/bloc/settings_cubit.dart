import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/settings_repository.dart';

class SettingsCubit extends Cubit<ThemeMode> {
  final SettingsRepository _repository;

  SettingsCubit({required SettingsRepository repository})
      : _repository = repository,
        super(ThemeMode.light);

  Future<void> load() async {
    final mode = await _repository.loadThemeMode();
    emit(mode);
  }

  Future<void> setDarkMode(bool enabled) async {
    final mode = enabled ? ThemeMode.dark : ThemeMode.light;
    emit(mode);
    await _repository.saveThemeMode(mode);
  }
}

