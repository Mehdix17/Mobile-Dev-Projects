import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/colors.dart';
import '../../../../core/router/route_names.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/settings_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final settings = ref.watch(settingsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        children: [
          // Appearance section
          _buildSectionHeader(theme, 'Appearance'),
          ListTile(
            leading: const Icon(Icons.dark_mode),
            title: const Text('Theme'),
            subtitle: Text(_getThemeModeName(settings.themeMode)),
            onTap: () => _showThemePicker(context, ref, settings.themeMode),
          ),
          const Divider(),

          // Account section
          _buildSectionHeader(theme, 'Account'),
          _buildAccountSection(context, ref, theme),
          const Divider(),

          // Study settings section
          _buildSectionHeader(theme, 'Study Settings'),
          ListTile(
            leading: const Icon(Icons.library_books),
            title: const Text('New Cards Per Day'),
            subtitle: Text('${settings.newCardsPerDay} cards'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showNumberPicker(
              context,
              'New Cards Per Day',
              settings.newCardsPerDay,
              1,
              100,
              (value) =>
                  ref.read(settingsProvider.notifier).setNewCardsPerDay(value),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.refresh),
            title: const Text('Reviews Per Day'),
            subtitle: Text('${settings.reviewsPerDay} cards'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showNumberPicker(
              context,
              'Reviews Per Day',
              settings.reviewsPerDay,
              10,
              500,
              (value) =>
                  ref.read(settingsProvider.notifier).setReviewsPerDay(value),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.shuffle),
            title: const Text('Card Direction'),
            subtitle: Text(_getCardDirectionName(settings.cardDirectionMode)),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showCardDirectionPicker(
              context,
              ref,
              settings.cardDirectionMode,
            ),
          ),
          const Divider(),

          // Notifications section
          _buildSectionHeader(theme, 'Notifications'),
          SwitchListTile(
            secondary: const Icon(Icons.notifications),
            title: const Text('Daily Reminder'),
            subtitle: const Text('Get reminded to study'),
            value: settings.notificationsEnabled,
            onChanged: (value) {
              ref
                  .read(settingsProvider.notifier)
                  .setNotificationsEnabled(value);
            },
          ),
          if (settings.notificationsEnabled)
            ListTile(
              leading: const Icon(Icons.access_time),
              title: const Text('Reminder Time'),
              subtitle: Text(settings.reminderTime.format(context)),
              trailing: const Icon(Icons.chevron_right),
              onTap: () async {
                final time = await showTimePicker(
                  context: context,
                  initialTime: settings.reminderTime,
                );
                if (time != null) {
                  ref.read(settingsProvider.notifier).setReminderTime(time);
                }
              },
            ),
          const Divider(),

          // About section
          _buildSectionHeader(theme, 'About'),
          const ListTile(
            leading: Icon(Icons.info),
            title: Text('Version'),
            subtitle: Text('1.0.0'),
          ),
          ListTile(
            leading: const Icon(Icons.privacy_tip),
            title: const Text('Privacy Policy'),
            trailing: const Icon(Icons.open_in_new),
            onTap: () {
              // Open privacy policy
            },
          ),
          ListTile(
            leading: const Icon(Icons.description),
            title: const Text('Terms of Service'),
            trailing: const Icon(Icons.open_in_new),
            onTap: () {
              // Open terms
            },
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildAccountSection(
    BuildContext context,
    WidgetRef ref,
    ThemeData theme,
  ) {
    final isAnonymous = ref.watch(isAnonymousProvider);
    final userEmail = ref.watch(userEmailProvider);
    final displayName = ref.watch(userDisplayNameProvider);
    final authService = ref.read(authServiceProvider);

    if (isAnonymous) {
      // Guest user - show sign in/sign up options
      return Column(
        children: [
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'You\'re using Guest Mode',
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: theme.colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Sign up to save your progress and sync across devices',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.login),
            title: const Text('Sign In'),
            subtitle: const Text('Already have an account?'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              context.push(RouteNames.signIn);
            },
          ),
          ListTile(
            leading: const Icon(Icons.person_add),
            title: const Text('Sign Up'),
            subtitle: const Text('Create a new account'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              context.push(RouteNames.signUp);
            },
          ),
        ],
      );
    } else {
      // Signed-in user - show profile and sign out
      return Column(
        children: [
          ListTile(
            leading: CircleAvatar(
              backgroundColor: theme.colorScheme.primaryContainer,
              child: Text(
                displayName.isNotEmpty ? displayName[0].toUpperCase() : 'U',
                style: TextStyle(
                  color: theme.colorScheme.onPrimaryContainer,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            title: Text(displayName),
            subtitle: Text(userEmail ?? 'No email'),
          ),
          ListTile(
            leading: const Icon(Icons.logout, color: AppColors.error),
            title: const Text(
              'Sign Out',
              style: TextStyle(color: AppColors.error),
            ),
            onTap: () => _showSignOutConfirmation(context, authService),
          ),
        ],
      );
    }
  }

  void _showSignOutConfirmation(
    BuildContext context,
    authService,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await authService.signOut();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Signed out successfully'),
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(e.toString())),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(ThemeData theme, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: theme.textTheme.titleSmall?.copyWith(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  String _getThemeModeName(ThemeMode mode) {
    return switch (mode) {
      ThemeMode.system => 'System',
      ThemeMode.light => 'Light',
      ThemeMode.dark => 'Dark',
    };
  }

  void _showThemePicker(
    BuildContext context,
    WidgetRef ref,
    ThemeMode current,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('Choose Theme'),
        children: [
          RadioGroup<ThemeMode>(
            groupValue: current,
            onChanged: (value) {
              if (value != null) {
                ref.read(settingsProvider.notifier).setThemeMode(value);
              }
              Navigator.pop(ctx);
            },
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: ThemeMode.values.map((mode) {
                return RadioListTile<ThemeMode>(
                  title: Text(_getThemeModeName(mode)),
                  value: mode,
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  void _showNumberPicker(
    BuildContext context,
    String title,
    int currentValue,
    int min,
    int max,
    void Function(int) onChanged,
  ) {
    int value = currentValue;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Text(title),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove_circle),
                      onPressed:
                          value > min ? () => setState(() => value -= 5) : null,
                    ),
                    SizedBox(
                      width: 80,
                      child: Text(
                        '$value',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add_circle),
                      onPressed:
                          value < max ? () => setState(() => value += 5) : null,
                    ),
                  ],
                ),
                Slider(
                  value: value.toDouble(),
                  min: min.toDouble(),
                  max: max.toDouble(),
                  divisions: (max - min) ~/ 5,
                  onChanged: (v) => setState(() => value = v.toInt()),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  onChanged(value);
                  Navigator.pop(ctx);
                },
                child: const Text('Save'),
              ),
            ],
          );
        },
      ),
    );
  }

  String _getCardDirectionName(String mode) {
    return switch (mode) {
      'shuffle' => 'Shuffle (Random)',
      'frontFirst' => 'Always Front First',
      'backFirst' => 'Always Back First',
      _ => 'Shuffle (Random)',
    };
  }

  void _showCardDirectionPicker(
    BuildContext context,
    WidgetRef ref,
    String current,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('Card Direction'),
        children: [
          RadioGroup<String>(
            groupValue: current,
            onChanged: (value) {
              if (value != null) {
                ref.read(settingsProvider.notifier).setCardDirectionMode(value);
              }
              Navigator.pop(ctx);
            },
            child: const Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                RadioListTile<String>(
                  title: Text('Shuffle (Random)'),
                  subtitle: Text('Front and back shown randomly'),
                  value: 'shuffle',
                ),
                RadioListTile<String>(
                  title: Text('Always Front First'),
                  subtitle: Text('Show front card (question) first'),
                  value: 'frontFirst',
                ),
                RadioListTile<String>(
                  title: Text('Always Back First'),
                  subtitle: Text('Show back card (answer) first'),
                  value: 'backFirst',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
