import 'package:flutter/material.dart';
import '../core/constants/api_config.dart';

/// Agora Settings Screen
/// 
/// Instructions for setting up Agora video calls
class AgoraSettingsScreen extends StatelessWidget {
  const AgoraSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Video Call Settings'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Card
            _buildStatusCard(),
            const SizedBox(height: 24),

            // Setup Instructions
            _buildInstructions(),
            const SizedBox(height: 24),

            // Current Settings
            _buildCurrentSettings(),
            const SizedBox(height: 24),

            // Test Button
            _buildTestButton(context),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard() {
    final bool isUsingDefault = ApiConfig.agoraAppId == '068164ddaed64ec482c4dcbb6329786e';
    
    return Card(
      color: isUsingDefault ? Colors.orange.shade50 : Colors.green.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              isUsingDefault ? Icons.warning : Icons.check_circle,
              color: isUsingDefault ? Colors.orange : Colors.green,
              size: 40,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isUsingDefault ? 'Default App ID' : 'Custom App ID',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isUsingDefault
                        ? 'You are using the default App ID. Video calls may not work in production.'
                        : 'You are using a custom App ID. Video calls should work.',
                    style: TextStyle(
                      color: isUsingDefault ? Colors.orange.shade800 : Colors.green.shade800,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInstructions() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'How to set up Agora:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 16),
            _buildStep(1, 'Go to https://console.agora.io/'),
            _buildStep(2, 'Sign up or log in'),
            _buildStep(3, 'Click "Create Project"'),
            _buildStep(4, 'Enter a project name'),
            _buildStep(5, 'Copy the App ID'),
            _buildStep(6, 'Open lib/core/constants/api_config.dart'),
            _buildStep(7, 'Replace the agoraAppId value with your App ID'),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'Note: For testing, you can use the default App ID. For production, you must use your own App ID and set up a token server.',
                style: TextStyle(fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep(int number, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: Colors.blue,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                '$number',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(text),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentSettings() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Current Settings:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 12),
            _buildSettingRow('App ID:', ApiConfig.agoraAppId.substring(0, 8) + '...'),
            _buildSettingRow('Video Width:', '${ApiConfig.videoWidth}px'),
            _buildSettingRow('Video Height:', '${ApiConfig.videoHeight}px'),
            _buildSettingRow('Frame Rate:', '${ApiConfig.videoFrameRate}fps'),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey.shade600,
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTestButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Test Video Call'),
              content: const Text(
                'To test video calls:\n\n'
                '1. Make sure you have two devices (or emulator + device)\n'
                '2. Both devices must use the same App ID\n'
                '3. Join the same channel (same appointment ID)\n\n'
                'Note: If using the default App ID, it may not work in production mode.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        },
        icon: const Icon(Icons.videocam),
        label: const Text('How to Test'),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    );
  }
}
