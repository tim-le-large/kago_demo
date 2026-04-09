import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'config/api_config.dart';
import 'departures/data/departures_repository.dart';
import 'locations/bloc/locations_bloc.dart';
import 'locations/data/location_repository.dart';
import 'shell/main_navigation_shell.dart';
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

    final bannerText =
        ApiConfig.useFakeLocations ? 'Demo ohne API' : ApiConfig.defaultBaseUrl;

    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<LocationsRepository>.value(value: locationsRepository),
        RepositoryProvider<DeparturesRepository>.value(value: departuresRepository),
        RepositoryProvider<TripsRepository>.value(value: tripsRepository),
      ],
      child: BlocProvider(
        create: (_) => LocationsBloc(repository: locationsRepository),
        child: MaterialApp(
          title: 'KA Abfahrt',
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
            useMaterial3: true,
          ),
          home: const MainNavigationShell(),
          debugShowCheckedModeBanner: false,
          builder: (context, child) {
            return Banner(
              message: bannerText,
              location: BannerLocation.bottomStart,
              child: child ?? const SizedBox.shrink(),
            );
          },
        ),
      ),
    );
  }
}
