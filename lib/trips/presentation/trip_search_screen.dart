import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../locations/data/location.dart';
import '../../locations/data/location_repository.dart';
import '../bloc/trips_bloc.dart';
import '../data/trip.dart';
import '../data/trips_repository.dart';

class TripSearchScreen extends StatefulWidget {
  const TripSearchScreen({super.key});

  @override
  State<TripSearchScreen> createState() => _TripSearchScreenState();
}

class _TripSearchScreenState extends State<TripSearchScreen> {
  Location? _origin;
  Location? _destination;
  late final TripsBloc _tripsBloc;

  @override
  void initState() {
    super.initState();
    _tripsBloc = TripsBloc(repository: context.read<TripsRepository>());
  }

  @override
  void dispose() {
    _tripsBloc.close();
    super.dispose();
  }

  void _swap() {
    setState(() {
      final tmp = _origin;
      _origin = _destination;
      _destination = tmp;
    });
  }

  Future<void> _pickLocation({required bool isOrigin}) async {
    final repo = context.read<LocationsRepository>();
    final picked = await showModalBottomSheet<Location>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _LocationSearchSheet(repository: repo),
    );
    if (picked != null && mounted) {
      setState(() {
        if (isOrigin) {
          _origin = picked;
        } else {
          _destination = picked;
        }
      });
    }
  }

  void _search() {
    if (_origin == null || _destination == null) return;
    _tripsBloc.add(TripsSearchRequested(
      originRef: _origin!.id,
      destRef: _destination!.id,
    ));
  }

  bool get _canSearch => _origin != null && _destination != null;

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _tripsBloc,
      child: Scaffold(
        appBar: AppBar(title: const Text('Verbindung')),
        body: Column(
          children: [
            _buildSearchForm(context),
            const Divider(height: 1),
            Expanded(child: _buildResults(context)),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchForm(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  children: [
                    _StopField(
                      label: 'Start',
                      location: _origin,
                      onTap: () => _pickLocation(isOrigin: true),
                    ),
                    const SizedBox(height: 12),
                    _StopField(
                      label: 'Ziel',
                      location: _destination,
                      onTap: () => _pickLocation(isOrigin: false),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: IconButton(
                  onPressed: (_origin != null || _destination != null) ? _swap : null,
                  icon: const Icon(Icons.swap_vert),
                  tooltip: 'Tauschen',
                  style: IconButton.styleFrom(
                    backgroundColor: theme.colorScheme.surfaceContainerHighest,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _canSearch ? _search : null,
              icon: const Icon(Icons.search),
              label: const Text('Verbindungen suchen'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResults(BuildContext context) {
    return BlocBuilder<TripsBloc, TripsState>(
      builder: (context, state) {
        return switch (state) {
          TripsInitial() => const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Text(
                  'Start und Ziel wählen, dann suchen.',
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          TripsLoading() => const Center(child: CircularProgressIndicator()),
          TripsLoaded(:final journeys) => journeys.isEmpty
              ? const Center(child: Text('Keine Verbindungen gefunden.'))
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: journeys.length,
                  itemBuilder: (context, i) => _JourneyCard(journey: journeys[i]),
                ),
          TripsFailure(:final message) => Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: SelectableText(
                  message,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            ),
        };
      },
    );
  }
}

class _StopField extends StatelessWidget {
  const _StopField({
    required this.label,
    required this.location,
    required this.onTap,
  });

  final String label;
  final Location? location;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          suffixIcon: const Icon(Icons.search),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        ),
        child: Text(
          location?.name ?? 'Haltestelle wählen …',
          style: location != null
              ? null
              : TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}

class _LocationSearchSheet extends StatefulWidget {
  const _LocationSearchSheet({required this.repository});

  final LocationsRepository repository;

  @override
  State<_LocationSearchSheet> createState() => _LocationSearchSheetState();
}

class _LocationSearchSheetState extends State<_LocationSearchSheet> {
  final _controller = TextEditingController();
  Timer? _debounce;
  List<Location> _results = [];
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      _search(value.trim());
    });
  }

  Future<void> _search(String query) async {
    if (query.isEmpty) {
      setState(() {
        _results = [];
        _loading = false;
        _error = null;
      });
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await widget.repository.search(query);
      if (!mounted) return;
      setState(() {
        _results = results;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 32,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: TextField(
                controller: _controller,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'Haltestelle suchen …',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.search),
                ),
                onChanged: _onChanged,
              ),
            ),
            if (_loading)
              const LinearProgressIndicator()
            else
              const SizedBox(height: 4),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
              ),
            Expanded(
              child: ListView.builder(
                controller: scrollController,
                itemCount: _results.length,
                itemBuilder: (context, i) {
                  final loc = _results[i];
                  return ListTile(
                    leading: const Icon(Icons.place_outlined),
                    title: Text(loc.name.isEmpty ? loc.id : loc.name),
                    subtitle: Text(loc.id, style: Theme.of(context).textTheme.bodySmall),
                    onTap: () => Navigator.of(context).pop(loc),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

class _JourneyCard extends StatelessWidget {
  const _JourneyCard({required this.journey});

  final Journey journey;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dep = _formatTime(journey.departureTime);
    final arr = _formatTime(journey.arrivalTime);
    final dur = journey.durationMinutes != null ? '${journey.durationMinutes} Min' : '';
    final transfers = journey.transfers == 0
        ? 'direkt'
        : '${journey.transfers}× Umst.';

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  '$dep → $arr',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
                const Spacer(),
                Text(
                  [dur, transfers].where((s) => s.isNotEmpty).join(' · '),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ...journey.legs.map((leg) => _LegRow(leg: leg)),
          ],
        ),
      ),
    );
  }
}

class _LegRow extends StatelessWidget {
  const _LegRow({required this.leg});

  final Leg leg;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isWalk = leg.isWalk;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          SizedBox(
            width: 56,
            child: isWalk
                ? Icon(Icons.directions_walk, size: 20, color: theme.colorScheme.onSurfaceVariant)
                : Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      leg.line ?? '?',
                      style: theme.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onPrimaryContainer,
                      ),
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '${leg.departureStop ?? '?'} → ${leg.arrivalStop ?? '?'}',
              style: theme.textTheme.bodySmall,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            _formatTime(leg.departureTime),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

String _formatTime(String? iso) {
  if (iso == null) return '—';
  final dt = DateTime.tryParse(iso);
  if (dt == null) return iso;
  return DateFormat.Hm().format(dt.toLocal());
}
