import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/settings_cubit.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Einstellungen')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
        children: [
          _SectionLabel(text: 'Darstellung'),
          const SizedBox(height: 8),
          _SettingsGroup(
            children: [
              BlocBuilder<SettingsCubit, ThemeMode>(
                builder: (context, mode) {
                  final darkOn = mode == ThemeMode.dark;
                  return _SettingsRow(
                    leadingIcon:
                        darkOn ? Icons.dark_mode : Icons.light_mode_rounded,
                    leadingColor: scheme.primary,
                    title: 'Erscheinungsbild',
                    subtitle: darkOn ? 'Dunkel' : 'Hell',
                    trailing: Semantics(
                      label: 'Erscheinungsbild',
                      value: darkOn ? 'Dunkel' : 'Hell',
                      child: SegmentedButton<ThemeMode>(
                        showSelectedIcon: false,
                        style: SegmentedButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 2,
                          ),
                          side: BorderSide(color: scheme.outlineVariant),
                        ),
                        segments: const [
                          ButtonSegment<ThemeMode>(
                            value: ThemeMode.light,
                            icon: Icon(Icons.wb_sunny_outlined, size: 20),
                            tooltip: 'Hell',
                          ),
                          ButtonSegment<ThemeMode>(
                            value: ThemeMode.dark,
                            icon: Icon(Icons.dark_mode_outlined, size: 20),
                            tooltip: 'Dunkel',
                          ),
                        ],
                        selected: {mode},
                        onSelectionChanged: (next) {
                          if (next.isEmpty) return;
                          context
                              .read<SettingsCubit>()
                              .setDarkMode(next.first == ThemeMode.dark);
                        },
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 24),
          _SectionLabel(text: 'Über'),
          const SizedBox(height: 8),
          _SettingsGroup(
            children: [
              _SettingsRow(
                leadingIcon: Icons.train_rounded,
                leadingColor: scheme.primary,
                title: 'KaGo',
                subtitle: 'Haltestellen, Abfahrten & Verbindungen im KVV-Netz',
              ),
              _Divider(),
              _SettingsRow(
                leadingIcon: Icons.verified_outlined,
                leadingColor: scheme.secondary,
                title: 'Daten',
                subtitle: 'Fahrplandaten über TRIAS (KVV)',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(left: 6),
      child: Text(
        text.toUpperCase(),
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: scheme.onSurfaceVariant,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
      ),
    );
  }
}

class _SettingsGroup extends StatelessWidget {
  const _SettingsGroup({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(children: children),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Divider(
        height: 1,
        color: scheme.outlineVariant.withValues(alpha: 0.5),
      ),
    );
  }
}

class _SettingsRow extends StatelessWidget {
  const _SettingsRow({
    required this.leadingIcon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.leadingColor,
  });

  final IconData leadingIcon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final Color? leadingColor;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: (leadingColor ?? scheme.primary).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              leadingIcon,
              color: leadingColor ?? scheme.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: 8),
            trailing!,
          ],
        ],
      ),
    );
  }
}
