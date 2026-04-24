import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../departures/bloc/departures_bloc.dart';
import '../../departures/data/departures_repository.dart';
import '../../departures/presentation/stop_departures_screen.dart';
import '../../settings/presentation/settings_screen.dart';
import '../../widgets/empty_state.dart';
import '../bloc/locations_bloc.dart';

class LocationsScreen extends StatefulWidget {
  const LocationsScreen({super.key});

  @override
  State<LocationsScreen> createState() => _LocationsScreenState();
}

class _LocationsScreenState extends State<LocationsScreen> {
  static const _debounceMs = 300;

  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _clearSearch() {
    _debounce?.cancel();
    _controller.clear();
    context.read<LocationsBloc>().add(LocationsSearchRequested(''));
    _focusNode.requestFocus();
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
    HapticFeedback.lightImpact();
    FocusScope.of(context).unfocus();
    final q = _controller.text.trim();
    context.read<LocationsBloc>().add(LocationsSearchRequested(q));
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 8, 12),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Haltestellen',
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Finde deine Station in Karlsruhe',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: scheme.onSurfaceVariant,
                              ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.settings_outlined),
                    tooltip: 'Einstellungen',
                    onPressed: () {
                      Navigator.of(context).push<void>(
                        MaterialPageRoute<void>(
                          builder: (_) => const SettingsScreen(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(width: 4),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: TextField(
                controller: _controller,
                focusNode: _focusNode,
                textInputAction: TextInputAction.search,
                style: Theme.of(context).textTheme.bodyLarge,
                decoration: InputDecoration(
                  hintText: 'z. B. Tullastr, Hbf …',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _controller.text.isEmpty
                      ? null
                      : IconButton(
                          icon: const Icon(Icons.close_rounded),
                          tooltip: 'Eingabe löschen',
                          onPressed: _clearSearch,
                        ),
                ),
                onChanged: (_) => _scheduleSearchFromTyping(),
                onSubmitted: (_) => _searchNow(),
              ),
            ),
            Expanded(
              child: BlocBuilder<LocationsBloc, LocationsState>(
                builder: (context, state) {
                  return switch (state) {
                    LocationsInitial() => const EmptyState(
                        message: 'Tippen, um Haltestellen zu suchen.',
                        subtitle: 'Dein Abfahrts- oder Startpunkt – in Sekunden.',
                        icon: Icons.travel_explore,
                      ),
                    LocationsLoading() => const Center(
                        child: CircularProgressIndicator(),
                      ),
                    LocationsLoaded(:final locations) => locations.isEmpty
                        ? const EmptyState(
                            message: 'Keine Treffer.',
                            subtitle: 'Versuche einen anderen Suchbegriff.',
                            icon: Icons.location_off_outlined,
                          )
                        : ListView.separated(
                            keyboardDismissBehavior:
                                ScrollViewKeyboardDismissBehavior.onDrag,
                            padding: const EdgeInsets.fromLTRB(12, 4, 12, 96),
                            itemCount: locations.length,
                            separatorBuilder: (_, _) => const SizedBox(height: 2),
                            itemBuilder: (context, i) {
                              final loc = locations[i];
                              final name =
                                  loc.name.isEmpty ? loc.id : loc.name;
                              return _LocationTile(
                                name: name,
                                onTap: () {
                                  HapticFeedback.lightImpact();
                                  Navigator.of(context).push<void>(
                                    MaterialPageRoute<void>(
                                      builder: (routeContext) => BlocProvider(
                                        create: (_) => DeparturesBloc(
                                          repository: routeContext
                                              .read<DeparturesRepository>(),
                                        )..add(
                                            DeparturesLoadRequested(loc.id),
                                          ),
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
                    LocationsFailure(:final message) => _ErrorView(
                        message: message,
                        onRetry: () {
                          final q = _controller.text.trim();
                          if (q.isEmpty) return;
                          context
                              .read<LocationsBloc>()
                              .add(LocationsSearchRequested(q));
                        },
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

class _LocationTile extends StatelessWidget {
  const _LocationTile({required this.name, required this.onTap});

  final String name;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: scheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.place_outlined,
                  size: 20,
                  color: scheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  name,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: scheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, color: scheme.error, size: 40),
            const SizedBox(height: 12),
            SelectableText(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: scheme.error),
            ),
            const SizedBox(height: 16),
            FilledButton.tonalIcon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Erneut versuchen'),
            ),
          ],
        ),
      ),
    );
  }
}
