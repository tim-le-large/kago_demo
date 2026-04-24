import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../locations/data/location.dart';
import '../../locations/data/location_repository.dart';
import '../../settings/presentation/settings_screen.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/line_badge.dart';
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
  final _resultsScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _tripsBloc = TripsBloc(repository: context.read<TripsRepository>());
  }

  @override
  void dispose() {
    _resultsScrollController.dispose();
    _tripsBloc.close();
    super.dispose();
  }

  void _swap() {
    HapticFeedback.lightImpact();
    setState(() {
      final tmp = _origin;
      _origin = _destination;
      _destination = tmp;
    });
  }

  Future<void> _pickLocation({required bool isOrigin}) async {
    HapticFeedback.selectionClick();
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

  void _search({bool feedback = true}) {
    if (_origin == null || _destination == null) return;
    if (feedback) HapticFeedback.lightImpact();
    FocusScope.of(context).unfocus();
    _tripsBloc.add(TripsSearchRequested(
      originRef: _origin!.id,
      destRef: _destination!.id,
    ));
  }

  Future<void> _refreshTrips() async {
    if (!_canSearch) return;
    _tripsBloc.add(TripsSearchRequested(
      originRef: _origin!.id,
      destRef: _destination!.id,
    ));
    await _tripsBloc.stream
        .firstWhere((s) => s is TripsLoaded || s is TripsFailure);
  }

  bool get _canSearch => _origin != null && _destination != null;

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _tripsBloc,
      child: Scaffold(
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              _buildHeader(context),
              _buildSearchForm(context),
              const SizedBox(height: 8),
              Expanded(child: _buildResults(context)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 8, 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Verbindung',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 2),
                Text(
                  'Von Haltestelle zu Haltestelle',
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
    );
  }

  Widget _buildSearchForm(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
      child: Container(
        decoration: BoxDecoration(
          color: scheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: scheme.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
        padding: const EdgeInsets.fromLTRB(12, 10, 10, 12),
        child: Column(
          children: [
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 6, right: 10),
                    child: _OriginDestRail(colorScheme: scheme),
                  ),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _StopField(
                          label: 'Start',
                          location: _origin,
                          onTap: () => _pickLocation(isOrigin: true),
                        ),
                        Divider(
                          height: 1,
                          color: scheme.outlineVariant.withValues(alpha: 0.4),
                        ),
                        _StopField(
                          label: 'Ziel',
                          location: _destination,
                          onTap: () => _pickLocation(isOrigin: false),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 4),
                  Center(
                    child: _SwapButton(
                      enabled: _origin != null || _destination != null,
                      onPressed: _swap,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _canSearch ? () => _search() : null,
                icon: const Icon(Icons.directions_rounded),
                label: const Text('Verbindungen suchen'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResults(BuildContext context) {
    return BlocConsumer<TripsBloc, TripsState>(
      listenWhen: (previous, current) => current is TripsLoaded,
      listener: (context, state) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          if (_resultsScrollController.hasClients) {
            _resultsScrollController.jumpTo(0);
          }
        });
      },
      builder: (context, state) {
        return switch (state) {
          TripsInitial() => const EmptyState(
              message: 'Start und Ziel wählen',
              subtitle: 'Dann zeigen wir dir passende Verbindungen.',
              icon: Icons.alt_route_rounded,
            ),
          TripsLoading() => const Center(child: CircularProgressIndicator()),
          TripsLoaded(:final journeys) => RefreshIndicator(
              onRefresh: _refreshTrips,
              child: journeys.isEmpty
                  ? ListView(
                      controller: _resultsScrollController,
                      physics: const AlwaysScrollableScrollPhysics(),
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      padding: const EdgeInsets.only(top: 48),
                      children: const [
                        EmptyState(
                          message: 'Keine Verbindungen gefunden.',
                          subtitle: 'Bitte Haltestellen prüfen.',
                          icon: Icons.search_off_outlined,
                        ),
                      ],
                    )
                  : ListView.separated(
                      controller: _resultsScrollController,
                      physics: const AlwaysScrollableScrollPhysics(),
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      padding:
                          const EdgeInsets.fromLTRB(16, 8, 16, 96),
                      itemCount: journeys.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 12),
                      itemBuilder: (context, i) =>
                          _JourneyCard(journey: journeys[i]),
                    ),
            ),
          TripsFailure(:final message) => RefreshIndicator(
              onRefresh: _refreshTrips,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsets.all(24),
                children: [
                  const SizedBox(height: 48),
                  Icon(
                    Icons.error_outline,
                    color: Theme.of(context).colorScheme.error,
                    size: 40,
                  ),
                  const SizedBox(height: 12),
                  SelectableText(
                    message,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.error),
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: FilledButton.tonalIcon(
                      onPressed: _canSearch ? () => _search() : null,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Erneut versuchen'),
                    ),
                  ),
                ],
              ),
            ),
        };
      },
    );
  }
}

class _OriginDestRail extends StatelessWidget {
  const _OriginDestRail({required this.colorScheme});

  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 14,
      child: Column(
        children: [
          const SizedBox(height: 22),
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: colorScheme.primary, width: 2),
            ),
          ),
          Expanded(
            child: Center(
              child: Container(
                width: 2,
                decoration: BoxDecoration(
                  color: colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: colorScheme.primary,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(height: 22),
        ],
      ),
    );
  }
}

class _SwapButton extends StatelessWidget {
  const _SwapButton({required this.enabled, required this.onPressed});

  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return IconButton(
      onPressed: enabled ? onPressed : null,
      icon: const Icon(Icons.swap_vert_rounded),
      tooltip: 'Tauschen',
      style: IconButton.styleFrom(
        backgroundColor: scheme.surfaceContainerHighest,
        foregroundColor: scheme.onSurface,
        shape: const CircleBorder(),
        padding: const EdgeInsets.all(12),
      ),
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
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    location?.name ?? 'Haltestelle wählen …',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: location != null
                          ? scheme.onSurface
                          : scheme.onSurfaceVariant,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: scheme.onSurfaceVariant,
            ),
          ],
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
  void initState() {
    super.initState();
    _controller.addListener(() => setState(() {}));
  }

  void _clearQuery() {
    _debounce?.cancel();
    _controller.clear();
    setState(() {
      _results = [];
      _loading = false;
      _error = null;
    });
  }

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
    final scheme = Theme.of(context).colorScheme;
    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
              child: Row(
                children: [
                  Text(
                    'Haltestelle suchen',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    tooltip: 'Schließen',
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: TextField(
                controller: _controller,
                autofocus: true,
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  hintText: 'z. B. Marktplatz, Hbf …',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _controller.text.isEmpty
                      ? null
                      : IconButton(
                          icon: const Icon(Icons.close_rounded),
                          tooltip: 'Eingabe löschen',
                          onPressed: _clearQuery,
                        ),
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
                child: Text(
                  _error!,
                  style: TextStyle(color: scheme.error),
                ),
              ),
            Expanded(
              child: ListView.separated(
                controller: scrollController,
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                itemCount: _results.length,
                separatorBuilder: (_, _) => const SizedBox(height: 2),
                itemBuilder: (context, i) {
                  final loc = _results[i];
                  return ListTile(
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    leading: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: scheme.primaryContainer,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.place_outlined,
                        size: 18,
                        color: scheme.onPrimaryContainer,
                      ),
                    ),
                    title: Text(loc.name.isEmpty ? loc.id : loc.name),
                    onTap: () {
                      HapticFeedback.lightImpact();
                      Navigator.of(context).pop(loc);
                    },
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
    final scheme = theme.colorScheme;
    final dep = _formatTime(journey.departureTime);
    final arr = _formatTime(journey.arrivalTime);
    final dur = journey.durationMinutes != null
        ? '${journey.durationMinutes} Min'
        : null;
    final direct = journey.transfers == 0;

    return Container(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                dep,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.4,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.arrow_forward_rounded,
                size: 18,
                color: scheme.onSurfaceVariant,
              ),
              const SizedBox(width: 8),
              Text(
                arr,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.4,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              const Spacer(),
              if (dur != null) _Chip(text: dur, emphasized: true),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              _Chip(
                text: direct
                    ? 'direkt'
                    : '${journey.transfers}× Umstieg',
                tone: direct ? _ChipTone.positive : _ChipTone.neutral,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _LineSummary(legs: journey.legs),
              ),
            ],
          ),
          if (journey.legs.isNotEmpty) ...[
            const SizedBox(height: 12),
            Divider(
              height: 1,
              color: scheme.outlineVariant.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 10),
            ...journey.legs.asMap().entries.map(
                  (e) => _LegRow(
                    leg: e.value,
                    isLast: e.key == journey.legs.length - 1,
                  ),
                ),
          ],
        ],
      ),
    );
  }
}

class _LineSummary extends StatelessWidget {
  const _LineSummary({required this.legs});

  final List<Leg> legs;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final widgets = <Widget>[];
    for (var i = 0; i < legs.length; i++) {
      final leg = legs[i];
      if (leg.isWalk) {
        widgets.add(Icon(
          Icons.directions_walk_rounded,
          size: 16,
          color: scheme.onSurfaceVariant,
        ));
      } else {
        widgets.add(LineBadge(line: leg.line ?? '', compact: true));
      }
      if (i < legs.length - 1) {
        widgets.add(Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Icon(
            Icons.chevron_right_rounded,
            size: 14,
            color: scheme.onSurfaceVariant,
          ),
        ));
      }
    }
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      reverse: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: widgets,
      ),
    );
  }
}

enum _ChipTone { neutral, positive }

class _Chip extends StatelessWidget {
  const _Chip({
    required this.text,
    this.emphasized = false,
    this.tone = _ChipTone.neutral,
  });

  final String text;
  final bool emphasized;
  final _ChipTone tone;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final Color bg;
    final Color fg;
    if (emphasized) {
      bg = scheme.primary;
      fg = scheme.onPrimary;
    } else if (tone == _ChipTone.positive) {
      bg = scheme.tertiaryContainer;
      fg = scheme.onTertiaryContainer;
    } else {
      bg = scheme.surfaceContainerHigh;
      fg = scheme.onSurfaceVariant;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: fg,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.1,
            ),
      ),
    );
  }
}

class _LegRow extends StatelessWidget {
  const _LegRow({required this.leg, required this.isLast});

  final Leg leg;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isWalk = leg.isWalk;

    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 56,
            child: Align(
              alignment: Alignment.centerLeft,
              child: isWalk
                  ? Container(
                      width: 36,
                      height: 24,
                      decoration: BoxDecoration(
                        color: scheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.directions_walk_rounded,
                        size: 16,
                        color: scheme.onSurfaceVariant,
                      ),
                    )
                  : LineBadge(line: leg.line ?? '', compact: true),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '${leg.departureStop ?? '?'} → ${leg.arrivalStop ?? '?'}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onSurface,
                height: 1.3,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            _formatTime(leg.departureTime),
            style: theme.textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
              fontFeatures: const [FontFeature.tabularFigures()],
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
