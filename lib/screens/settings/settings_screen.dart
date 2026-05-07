import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_constants.dart';
import '../../database/hive_database.dart';
import '../../providers/theme_provider.dart';
import '../../providers/trip_providers.dart';

/// Settings screen with theme toggle, profile, and data management.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);
    final userName = HiveDatabase().getSetting<String>(AppConstants.userNameKey, 'Traveler');
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Profile section
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: theme.cardTheme.color,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.1)),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: theme.colorScheme.primary,
                  child: Text(
                    userName.isNotEmpty ? userName[0].toUpperCase() : '?',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(userName, style: theme.textTheme.titleLarge),
                      Text('Guest User', style: theme.textTheme.bodySmall),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () => _editName(context),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Appearance
          Text('Appearance', style: theme.textTheme.titleMedium),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: theme.cardTheme.color,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.1)),
            ),
            child: Column(
              children: [
                _ThemeTile(
                  icon: Icons.light_mode,
                  title: 'Light Mode',
                  isSelected: themeMode == ThemeMode.light,
                  onTap: () => ref.read(themeProvider.notifier).setTheme(ThemeMode.light),
                ),
                Divider(height: 1, color: theme.colorScheme.outline.withValues(alpha: 0.1)),
                _ThemeTile(
                  icon: Icons.dark_mode,
                  title: 'Dark Mode',
                  isSelected: themeMode == ThemeMode.dark,
                  onTap: () => ref.read(themeProvider.notifier).setTheme(ThemeMode.dark),
                ),
                Divider(height: 1, color: theme.colorScheme.outline.withValues(alpha: 0.1)),
                _ThemeTile(
                  icon: Icons.settings_suggest,
                  title: 'System Default',
                  isSelected: themeMode == ThemeMode.system,
                  onTap: () => ref.read(themeProvider.notifier).setTheme(ThemeMode.system),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Data
          Text('Data', style: theme.textTheme.titleMedium),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: theme.cardTheme.color,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.1)),
            ),
            child: ListTile(
              leading: Icon(Icons.delete_forever, color: theme.colorScheme.error),
              title: const Text('Clear All Data'),
              subtitle: const Text('Delete all trips, expenses, and settings'),
              onTap: () => _clearData(context, ref),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
          ),
          const SizedBox(height: 24),

          // About
          Text('About', style: theme.textTheme.titleMedium),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.cardTheme.color,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.1)),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Icon(Icons.flight_takeoff, color: theme.colorScheme.primary),
                    const SizedBox(width: 12),
                    Text(AppConstants.appName, style: theme.textTheme.titleMedium),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.info_outline, size: 20),
                    const SizedBox(width: 12),
                    Text('Version ${AppConstants.appVersion}', style: theme.textTheme.bodySmall),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.code, size: 20),
                    const SizedBox(width: 12),
                    Text('Built with Flutter & Dart', style: theme.textTheme.bodySmall),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _editName(BuildContext context) {
    final controller = TextEditingController(
      text: HiveDatabase().getSetting<String>(AppConstants.userNameKey, ''),
    );
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Name'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Enter your name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                HiveDatabase().setSetting(AppConstants.userNameKey, controller.text.trim());
                Navigator.pop(context);
                // Force rebuild
                (context as Element).markNeedsBuild();
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _clearData(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Data?'),
        content: const Text(
          'This will permanently delete all your trips, expenses, and itinerary data. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final db = HiveDatabase();
              await db.tripsBox.clear();
              await db.itineraryBox.clear();
              await db.expensesBox.clear();
              ref.read(tripListProvider.notifier).loadTrips();
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('All data cleared')),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Clear Everything'),
          ),
        ],
      ),
    );
  }
}

class _ThemeTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final bool isSelected;
  final VoidCallback onTap;

  const _ThemeTile({
    required this.icon,
    required this.title,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      leading: Icon(icon,
        color: isSelected ? theme.colorScheme.primary : null),
      title: Text(title),
      trailing: isSelected
          ? Icon(Icons.check_circle, color: theme.colorScheme.primary)
          : null,
      onTap: onTap,
    );
  }
}
