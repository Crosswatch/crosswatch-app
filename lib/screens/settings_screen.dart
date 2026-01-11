import 'package:flutter/material.dart';
import '../services/workout_import_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _hasApiKey = false;
  bool _onDeviceAvailable = false;
  bool _isLoading = true;
  final _apiKeyController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    final hasKey = await WorkoutImportService.hasApiKey();
    final onDevice = await WorkoutImportService.isOnDeviceAvailable();

    setState(() {
      _hasApiKey = hasKey;
      _onDeviceAvailable = onDevice;
      _isLoading = false;
    });
  }

  Future<void> _saveApiKey() async {
    final apiKey = _apiKeyController.text.trim();

    if (apiKey.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter an API key'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    await WorkoutImportService.saveApiKey(apiKey);
    _apiKeyController.clear();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('API key saved successfully'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
      _loadSettings();
    }
  }

  Future<void> _deleteApiKey() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete API Key?'),
        content: const Text(
          'Are you sure you want to delete your stored API key? '
          'You will need to enter it again to import workouts.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await WorkoutImportService.deleteApiKey();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('API key deleted')));
        _loadSettings();
      }
    }
  }

  void _showApiKeyDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Gemini API Key'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'To import workouts using AI, you need a Google Gemini API key.',
              ),
              const SizedBox(height: 16),
              const Text(
                'How to get a free API key:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text('1. Visit aistudio.google.com/apikey'),
              const Text('2. Sign in with your Google account'),
              const Text('3. Click "Create API Key"'),
              const Text('4. Copy the key and paste below'),
              const SizedBox(height: 16),
              const Text(
                'Cost: ~\$0.002 per workout import',
                style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _apiKeyController,
                decoration: const InputDecoration(
                  labelText: 'API Key',
                  hintText: 'Paste your Gemini API key',
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              _apiKeyController.clear();
              Navigator.pop(context);
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(onPressed: _saveApiKey, child: const Text('Save')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildWorkoutImportSection(),
                const SizedBox(height: 24),
                _buildAboutSection(),
              ],
            ),
    );
  }

  Widget _buildWorkoutImportSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.download,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Text(
                  'Workout Import',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const SizedBox(height: 16),

            // On-device AI status
            if (_onDeviceAvailable)
              ListTile(
                leading: const Icon(Icons.check_circle, color: Colors.green),
                title: const Text('On-device AI Available'),
                subtitle: const Text('Free, fast, and private workout import'),
                contentPadding: EdgeInsets.zero,
              )
            else
              ListTile(
                leading: const Icon(Icons.info_outline, color: Colors.grey),
                title: const Text('On-device AI Not Available'),
                subtitle: const Text(
                  'Requires Android 14+ with compatible device',
                ),
                contentPadding: EdgeInsets.zero,
              ),

            const Divider(),

            // API key status
            ListTile(
              leading: Icon(
                _hasApiKey ? Icons.vpn_key : Icons.vpn_key_off,
                color: _hasApiKey ? Colors.green : Colors.grey,
              ),
              title: Text(_hasApiKey ? 'API Key Configured' : 'No API Key'),
              subtitle: Text(
                _hasApiKey
                    ? 'You can import workouts using Gemini API'
                    : 'Add an API key to import workouts',
              ),
              trailing: _hasApiKey
                  ? IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: _deleteApiKey,
                      tooltip: 'Delete API Key',
                    )
                  : null,
              contentPadding: EdgeInsets.zero,
            ),

            const SizedBox(height: 8),

            if (!_hasApiKey)
              ElevatedButton.icon(
                onPressed: _showApiKeyDialog,
                icon: const Icon(Icons.add),
                label: const Text('Add API Key'),
              ),

            const SizedBox(height: 16),

            // Import method explanation
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.lightbulb_outline,
                        size: 16,
                        color: Colors.blue[700],
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'How it works',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue[700],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _onDeviceAvailable
                        ? 'Workouts will be converted using on-device AI (free). '
                              'If that fails, the API key will be used as backup.'
                        : 'Workouts will be converted using Google Gemini API. '
                              'You only pay for what you use (~\$0.002 per workout).',
                    style: TextStyle(fontSize: 12, color: Colors.blue[900]),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAboutSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Text('About', style: Theme.of(context).textTheme.titleLarge),
              ],
            ),
            const SizedBox(height: 16),
            const ListTile(
              title: Text('Version'),
              subtitle: Text('1.0.0'),
              contentPadding: EdgeInsets.zero,
            ),
            const ListTile(
              title: Text('Crosswatch'),
              subtitle: Text(
                'A cross-platform workout timer with nested set support',
              ),
              contentPadding: EdgeInsets.zero,
            ),
          ],
        ),
      ),
    );
  }
}
