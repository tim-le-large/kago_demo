import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'config/api_config.dart';
import 'departures/data/departures_repository.dart';
import 'locations/bloc/locations_bloc.dart';
import 'locations/data/location_repository.dart';
import 'settings/bloc/settings_cubit.dart';
import 'settings/data/settings_repository.dart';
import 'shell/main_navigation_shell.dart';
import 'theme/app_scroll_behavior.dart';
import 'theme/app_theme.dart';
import 'trips/data/trips_repository.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const KaAbfahrtApp());
}

class KaAbfahrtApp extends StatelessWidget {
  const KaAbfahrtApp({super.key});

  @override
  Widget build(BuildContext context) {
    final LocationsRepository locationsRepository = ApiConfig.useFakeLocations
        ? FakeLocationsRepository()
        : HttpLocationsRepository();

    final DeparturesRepository departuresRepository = ApiConfig.useFakeLocations
        ? FakeDeparturesRepository()
        : HttpDeparturesRepository();

    final TripsRepository tripsRepository = ApiConfig.useFakeLocations
        ? FakeTripsRepository()
        : HttpTripsRepository();

    final settingsRepository = SettingsRepository();
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<LocationsRepository>.value(value: locationsRepository),
        RepositoryProvider<DeparturesRepository>.value(value: departuresRepository),
        RepositoryProvider<TripsRepository>.value(value: tripsRepository),
        RepositoryProvider<SettingsRepository>.value(value: settingsRepository),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider(create: (_) => LocationsBloc(repository: locationsRepository)),
          BlocProvider(
            create: (_) => SettingsCubit(repository: settingsRepository)..load(),
          ),
        ],
        child: BlocBuilder<SettingsCubit, ThemeMode>(
          builder: (context, themeMode) {
            return MaterialApp(
              title: 'KaGo',
              themeMode: themeMode,
              theme: AppTheme.light,
              darkTheme: AppTheme.dark,
              scrollBehavior: const AppScrollBehavior(),
              home: const MainNavigationShell(),
              debugShowCheckedModeBanner: false,
            );
          },
        ),
      ),
    );
  }
}
