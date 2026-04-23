import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/settings_cubit.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Einstellungen')),
      body: ListView(
        children: [
          const SizedBox(height: 8),
          ListTile(
            title: const Text('Design'),
            subtitle: const Text('Dark Mode / System'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).push<void>(
              MaterialPageRoute<void>(builder: (_) => const ThemeModeScreen()),
            ),
          ),
        ],
      ),
    );
  }
}

class ThemeModeScreen extends StatelessWidget {
  const ThemeModeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Design')),
      body: BlocBuilder<SettingsCubit, ThemeMode>(
        builder: (context, mode) {
          return RadioGroup<ThemeMode>(
            groupValue: mode,
            onChanged: (v) {
              if (v == null) return;
              context.read<SettingsCubit>().setThemeMode(v);
            },
            child: ListView(
              children: const [
                RadioListTile<ThemeMode>(
                  value: ThemeMode.system,
                  title: Text('System'),
                  subtitle: Text('Folgt den Systemeinstellungen'),
                ),
                RadioListTile<ThemeMode>(
                  value: ThemeMode.light,
                  title: Text('Hell'),
                ),
                RadioListTile<ThemeMode>(
                  value: ThemeMode.dark,
                  title: Text('Dunkel'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

