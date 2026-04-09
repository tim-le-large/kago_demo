import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../departures/bloc/departures_bloc.dart';
import '../../departures/data/departures_repository.dart';
import '../../departures/presentation/stop_departures_screen.dart';
import '../bloc/locations_bloc.dart';

class LocationsScreen extends StatefulWidget {
  const LocationsScreen({super.key});

  @override
  State<LocationsScreen> createState() => _LocationsScreenState();
}

class _LocationsScreenState extends State<LocationsScreen> {
  static const _debounceMs = 300;

  final _controller = TextEditingController();
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _scheduleSearchFromTyping() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: _debounceMs), () {
      if (!mounted) return;
      final q = _controller.text.trim();
      context.read<LocationsBloc>().add(LocationsSearchRequested(q));
    });
  }

  void _searchNow() {
    _debounce?.cancel();
    final q = _controller.text.trim();
    context.read<LocationsBloc>().add(LocationsSearchRequested(q));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Haltestellen'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(
                      hintText: 'z. B. Tullastr, Hbf …',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (_) => _scheduleSearchFromTyping(),
                    onSubmitted: (_) => _searchNow(),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: _searchNow,
                  child: const Text('Suchen'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: BlocBuilder<LocationsBloc, LocationsState>(
                builder: (context, state) {
                  return switch (state) {
                    LocationsInitial() => const Center(
                        child: Text('Tippen, um Haltestellen zu suchen.'),
                      ),
                    LocationsLoading() => const Center(
                        child: CircularProgressIndicator(),
                      ),
                    LocationsLoaded(:final locations) =>
                      locations.isEmpty
                          ? const Center(
                              child: Text('Keine Treffer.'),
                            )
                          : ListView.separated(
                              itemCount: locations.length,
                              separatorBuilder: (_, _) => const Divider(height: 1),
                              itemBuilder: (context, i) {
                                final loc = locations[i];
                                return ListTile(
                                  title: Text(loc.name.isEmpty ? loc.id : loc.name),
                                  subtitle: Text(loc.id),
                                  onTap: () {
                                    final name = loc.name.isEmpty ? loc.id : loc.name;
                                    Navigator.of(context).push<void>(
                                      MaterialPageRoute<void>(
                                        builder: (routeContext) => BlocProvider(
                                          create: (_) => DeparturesBloc(
                                            repository:
                                                routeContext.read<DeparturesRepository>(),
                                          )..add(DeparturesLoadRequested(loc.id)),
                                          child: StopDeparturesScreen(
                                            stopName: name,
                                            stopRef: loc.id,
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                );
                              },
                            ),
                    LocationsFailure(:final message) => Center(
                        child: SelectableText(
                          message,
                          style: TextStyle(color: Theme.of(context).colorScheme.error),
                        ),
                      ),
                  };
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
