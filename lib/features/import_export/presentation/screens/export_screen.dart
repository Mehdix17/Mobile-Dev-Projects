import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ExportScreen extends ConsumerStatefulWidget {
  final String? deckId;

  const ExportScreen({super.key, this.deckId});

  @override
  ConsumerState<ExportScreen> createState() => _ExportScreenState();
}

class _ExportScreenState extends ConsumerState<ExportScreen> {
  String _selectedFormat = 'csv';
  bool _includeMedia = true;
  bool _includeStatistics = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Export'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Export Options',
              style: theme.textTheme.headlineSmall,
            ),
            const SizedBox(height: 24),

            // Format selection
            Text(
              'Format',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            _buildFormatSelector(),
            const SizedBox(height: 24),

            // Options
            Text(
              'Options',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              title: const Text('Include Media'),
              subtitle: const Text('Export audio and image files'),
              value: _includeMedia,
              onChanged: (value) {
                setState(() => _includeMedia = value);
              },
            ),
            SwitchListTile(
              title: const Text('Include Statistics'),
              subtitle: const Text('Export review history and progress'),
              value: _includeStatistics,
              onChanged: (value) {
                setState(() => _includeStatistics = value);
              },
            ),

            const Spacer(),

            // Export button
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _handleExport,
                icon: const Icon(Icons.download),
                label: const Text('Export'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormatSelector() {
    return RadioGroup<String>(
      groupValue: _selectedFormat,
      onChanged: (value) {
        setState(() => _selectedFormat = value!);
      },
      child: const Column(
        children: [
          RadioListTile<String>(
            title: Text('CSV'),
            subtitle: Text('Comma-separated values (universal)'),
            value: 'csv',
          ),
          RadioListTile<String>(
            title: Text('JSON'),
            subtitle: Text('Full backup with all data'),
            value: 'json',
          ),
          RadioListTile<String>(
            title: Text('Anki Package'),
            subtitle: Text('Compatible with Anki (.apkg)'),
            value: 'anki',
          ),
        ],
      ),
    );
  }

  void _handleExport() {
    // Export functionality will be implemented in future updates
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Exporting as \$_selectedFormat...'),
      ),
    );
  }
}
