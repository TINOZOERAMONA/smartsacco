import 'package:flutter/material.dart';
import 'package:smartsacco/services/user_preferences_service.dart';
import 'package:smartsacco/utils/constants.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final UserPreferencesService _prefsService = UserPreferencesService();

  bool _voiceEnabled = false;
  bool _autoStartVoice = false;
  bool _continuousListening = false;
  bool _textToSpeech = false;
  bool _screenReader = false;
  String _accessibilityMode = AccessibilityModes.normal;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    setState(() {
      _voiceEnabled = _prefsService.getVoiceEnabled();
      _autoStartVoice = _prefsService.getAutoStartVoice();
      _continuousListening = _prefsService.getContinuousListening();
      _textToSpeech = _prefsService.getTextToSpeech();
      _screenReader = _prefsService.getScreenReader();
      _accessibilityMode = _prefsService.getAccessibilityMode();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: const Color(0xFF007C91),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader('Accessibility & Voice Features'),
            const SizedBox(height: 16),

            // Accessibility Mode
            _buildDropdownSetting(
              title: 'Accessibility Mode',
              subtitle: 'Choose your preferred interaction mode',
              value: _accessibilityMode,
              items: [
                DropdownMenuItem(
                  value: AccessibilityModes.normal,
                  child: Text('Normal Mode - Standard visual interface'),
                ),
                DropdownMenuItem(
                  value: AccessibilityModes.voice,
                  child: Text('Voice Mode - Voice commands enabled'),
                ),
                DropdownMenuItem(
                  value: AccessibilityModes.blind,
                  child: Text('Blind Mode - Full voice navigation'),
                ),
                DropdownMenuItem(
                  value: AccessibilityModes.visuallyImpaired,
                  child: Text('Visually Impaired - Enhanced accessibility'),
                ),
              ],
              onChanged: (value) async {
                if (value != null) {
                  await _prefsService.setAccessibilityMode(value);
                  setState(() {
                    _accessibilityMode = value;
                  });
                  _updateVoiceSettings();
                }
              },
            ),

            const SizedBox(height: 16),

            // Voice Settings Section
            if (_accessibilityMode != AccessibilityModes.normal) ...[
            _buildSectionHeader('Voice Settings'),
              const SizedBox(height: 16),

              _buildSwitchSetting(
                title: 'Enable Voice Features',
                subtitle: 'Turn on voice commands and speech',
              value: _voiceEnabled,
                onChanged: (value) async {
                  await _prefsService.setVoiceEnabled(value);
                  setState(() {
                    _voiceEnabled = value;
                  });
                },
              ),

              if (_voiceEnabled) ...[
                _buildSwitchSetting(
                  title: 'Auto-start Voice',
                  subtitle: 'Automatically start voice features on app launch',
                  value: _autoStartVoice,
                  onChanged: (value) async {
                    await _prefsService.setAutoStartVoice(value);
                    setState(() {
                      _autoStartVoice = value;
                    });
                  },
                ),

                _buildSwitchSetting(
                  title: 'Continuous Listening',
                  subtitle: 'Keep listening for voice commands',
                  value: _continuousListening,
                  onChanged: (value) async {
                    await _prefsService.setContinuousListening(value);
                    setState(() {
                      _continuousListening = value;
                    });
                  },
                ),

                _buildSwitchSetting(
                  title: 'Text-to-Speech',
                  subtitle: 'Read screen content aloud',
                  value: _textToSpeech,
                  onChanged: (value) async {
                    await _prefsService.setTextToSpeech(value);
                    setState(() {
                      _textToSpeech = value;
                    });
                  },
                ),
              ],
            ],

            const SizedBox(height: 16),

            // Screen Reader Settings
            _buildSectionHeader('Screen Reader'),
            const SizedBox(height: 16),

            _buildSwitchSetting(
              title: 'Enable Screen Reader',
              subtitle: 'Enhanced screen reading for accessibility',
              value: _screenReader,
              onChanged: (value) async {
                await _prefsService.setScreenReader(value);
                setState(() {
                  _screenReader = value;
                });
              },
            ),

            const SizedBox(height: 32),

            // Reset Button
            Center(
              child: ElevatedButton(
                onPressed: _resetToDefaults,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 12,
                  ),
                ),
                child: const Text('Reset to Defaults'),
              ),
            ),

            const SizedBox(height: 16),

            // Info Text
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue.shade700),
                      const SizedBox(width: 8),
                      Text(
                        'Voice Features Info',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Voice features are designed for users with visual impairments or those who prefer voice interaction. Normal mode provides a standard visual interface without voice commands.',
                    style: TextStyle(color: Colors.blue.shade700),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
        color: Color(0xFF007C91),
      ),
    );
  }

  Widget _buildSwitchSetting({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: SwitchListTile(
        title: Text(title),
        subtitle: Text(subtitle),
        value: value,
        onChanged: onChanged,
        activeColor: const Color(0xFF007C91),
      ),
    );
  }

  Widget _buildDropdownSetting({
    required String title,
    required String subtitle,
    required String value,
    required List<DropdownMenuItem<String>> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: DropdownButton<String>(
          value: value,
          items: items,
          onChanged: onChanged,
          underline: Container(),
        ),
      ),
    );
  }

  void _updateVoiceSettings() {
    // Automatically update voice settings based on accessibility mode
    bool shouldEnableVoice = _accessibilityMode != AccessibilityModes.normal;

    if (shouldEnableVoice && !_voiceEnabled) {
      _prefsService.setVoiceEnabled(true);
      setState(() {
        _voiceEnabled = true;
      });
    } else if (!shouldEnableVoice && _voiceEnabled) {
      _prefsService.setVoiceEnabled(false);
      setState(() {
        _voiceEnabled = false;
      });
    }
  }

  Future<void> _resetToDefaults() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Settings'),
        content: const Text(
          'Are you sure you want to reset all settings to defaults? This will disable all voice features.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Reset'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _prefsService.resetToDefaults();
      await _loadPreferences();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Settings reset to defaults'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }
}
