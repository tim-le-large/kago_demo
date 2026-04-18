import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/departures_bloc.dart';
import '../data/departure.dart';

class StopDeparturesScreen extends StatelessWidget {
  const StopDeparturesScreen({
    super.key,
    required this.stopName,
    required this.stopRef,
  });

  final String stopName;
  final String stopRef;

  String _formatTime(String iso) {
    final dt = DateTime.tryParse(iso);
    if (dt == null) {
      return iso;
    }
    final local = dt.toLocal();
    final h = local.hour.toString().padLeft(2, '0');
    final m = local.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(stopName),
      ),
      body: BlocBuilder<DeparturesBloc, DeparturesState>(
        builder: (context, state) {
          return switch (state) {
            DeparturesInitial() => const Center(child: CircularProgressIndicator()),
            DeparturesLoading() => const Center(child: CircularProgressIndicator()),
            DeparturesLoaded(:final departures) =>
              departures.isEmpty
                  ? const Center(child: Text('Keine Abfahrten in diesem Zeitraum.'))
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: departures.length,
                      separatorBuilder: (_, _) => const Divider(height: 1),
                      itemBuilder: (context, i) {
                        final Departure d = departures[i];
                        return ListTile(
                          leading: CircleAvatar(
                            child: Text(
                              d.line.isEmpty ? '?' : d.line,
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                            ),
                          ),
                          title: Text(d.destination.isEmpty ? '—' : d.destination),
                          trailing: Text(
                            _formatTime(d.plannedTime),
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        );
                      },
                    ),
            DeparturesFailure(:final message) => Center(
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
      ),
    );
  }
}
