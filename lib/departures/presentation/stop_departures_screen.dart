import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../widgets/empty_state.dart';
import '../../widgets/line_badge.dart';
import '../bloc/departures_bloc.dart';
import '../data/departure.dart';

Future<void> _reloadDepartures(BuildContext context, String stopRef) async {
  final bloc = context.read<DeparturesBloc>();
  bloc.add(DeparturesLoadRequested(stopRef));
  await bloc.stream
      .firstWhere((s) => s is DeparturesLoaded || s is DeparturesFailure);
}

class StopDeparturesScreen extends StatefulWidget {
  const StopDeparturesScreen({
    super.key,
    required this.stopName,
    required this.stopRef,
  });

  final String stopName;
  final String stopRef;

  @override
  State<StopDeparturesScreen> createState() => _StopDeparturesScreenState();
}

class _StopDeparturesScreenState extends State<StopDeparturesScreen> {
  late Timer _ticker;

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.stopName,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          IconButton(
            tooltip: 'Aktualisieren',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () {
              HapticFeedback.selectionClick();
              context
                  .read<DeparturesBloc>()
                  .add(DeparturesLoadRequested(widget.stopRef));
            },
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: BlocBuilder<DeparturesBloc, DeparturesState>(
        builder: (context, state) {
          return switch (state) {
            DeparturesInitial() => const Center(child: CircularProgressIndicator()),
            DeparturesLoading() => const Center(child: CircularProgressIndicator()),
            DeparturesLoaded(:final departures) => RefreshIndicator(
                onRefresh: () => _reloadDepartures(context, widget.stopRef),
                child: departures.isEmpty
                    ? ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.only(top: 48),
                        children: const [
                          EmptyState(
                            message: 'Keine Abfahrten in diesem Zeitraum.',
                            subtitle: 'Später erneut probieren.',
                            icon: Icons.departure_board_outlined,
                          ),
                        ],
                      )
                    : ListView.separated(
                        physics: const AlwaysScrollableScrollPhysics(),
                        keyboardDismissBehavior:
                            ScrollViewKeyboardDismissBehavior.onDrag,
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
                        itemCount: departures.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 8),
                        itemBuilder: (context, i) =>
                            _DepartureTile(departure: departures[i]),
                      ),
              ),
            DeparturesFailure(:final message) => RefreshIndicator(
                onRefresh: () => _reloadDepartures(context, widget.stopRef),
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(24),
                  children: [
                    const SizedBox(height: 48),
                    Icon(Icons.error_outline, color: scheme.error, size: 40),
                    const SizedBox(height: 12),
                    SelectableText(
                      message,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: scheme.error),
                    ),
                    const SizedBox(height: 16),
                    Center(
                      child: FilledButton.tonalIcon(
                        onPressed: () => context
                            .read<DeparturesBloc>()
                            .add(DeparturesLoadRequested(widget.stopRef)),
                        icon: const Icon(Icons.refresh),
                        label: const Text('Erneut versuchen'),
                      ),
                    ),
                  ],
                ),
              ),
          };
        },
      ),
    );
  }
}

class _DepartureTile extends StatelessWidget {
  const _DepartureTile({required this.departure});

  final Departure departure;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final time = _formatTime(departure.plannedTime);
    final relative = _formatRelative(departure.plannedTime);

    return Material(
      color: scheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () {},
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              SizedBox(
                width: 56,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: LineBadge(line: departure.line),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      departure.destination.isEmpty ? '—' : departure.destination,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Planmäßig',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    time,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.3,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                  if (relative != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      relative,
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: scheme.primary,
                        fontWeight: FontWeight.w700,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _formatTime(String iso) {
  final dt = Departure.parsePlannedTime(iso);
  if (dt == null) return iso;
  final local = dt.toLocal();
  final h = local.hour.toString().padLeft(2, '0');
  final m = local.minute.toString().padLeft(2, '0');
  return '$h:$m';
}

String? _formatRelative(String iso) {
  final dt = Departure.parsePlannedTime(iso);
  if (dt == null) return null;
  final diff = dt.toLocal().difference(DateTime.now());
  final minutes = diff.inMinutes;
  if (minutes < -1) return null;
  if (minutes <= 0) return 'jetzt';
  if (minutes == 1) return 'in 1 Min';
  if (minutes < 60) return 'in $minutes Min';
  final hours = diff.inHours;
  final rest = minutes - hours * 60;
  if (rest == 0) return 'in ${hours}h';
  return 'in ${hours}h ${rest}m';
}
