import 'package:flutter/material.dart';
import 'package:mockathon/core/app_config.dart';
import 'package:mockathon/core/theme.dart';
import 'package:mockathon/services/data_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final DataService _dataService = DataService();
  late TextEditingController _nameController;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _nameController = TextEditingController(
      text: AppConfigScope.of(context)?.appName ?? 'Mockathon',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: AppTheme.bentoDecoration(color: Colors.white, radius: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Global Settings",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppTheme.bentoJacket,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            "App Name",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _nameController,
            decoration: InputDecoration(
              hintText: "Enter App Name",
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: AppTheme.bentoBg,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.bentoJacket,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 12,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () async {
              final newName = _nameController.text.trim();
              if (newName.isNotEmpty) {
                await _dataService.updateAppName(newName);
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("App Name updated successfully!"),
                      backgroundColor: Colors.green,
                    ),
                  );
              }
            },
            child: const Text("Save Settings"),
          ),
        ],
      ),
    );
  }
}
