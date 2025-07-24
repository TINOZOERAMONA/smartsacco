import 'package:shared_preferences/shared_preferences.dart';
import 'package:smartsacco/utils/constants.dart';
import 'package:logging/logging.dart';

class UserPreferencesService {
  static final UserPreferencesService _instance =
      UserPreferencesService._internal();
  factory UserPreferencesService() => _instance;
  UserPreferencesService._internal();

  final Logger _logger = Logger('UserPreferencesService');
  late SharedPreferences _prefs;

  // Initialize preferences
  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    _logger.info('UserPreferencesService initialized');
  }

  // Voice settings
  Future<void> setVoiceEnabled(bool enabled) async {
    await _prefs.setBool(UserPreferences.voiceEnabled, enabled);
    _logger.info('Voice enabled set to: $enabled');
  }

  bool getVoiceEnabled() {
    return _prefs.getBool(UserPreferences.voiceEnabled) ?? false;
  }

  Future<void> setAutoStartVoice(bool enabled) async {
    await _prefs.setBool(UserPreferences.autoStartVoice, enabled);
    _logger.info('Auto start voice set to: $enabled');
  }

  bool getAutoStartVoice() {
    return _prefs.getBool(UserPreferences.autoStartVoice) ?? false;
  }

  Future<void> setContinuousListening(bool enabled) async {
    await _prefs.setBool(UserPreferences.continuousListening, enabled);
    _logger.info('Continuous listening set to: $enabled');
  }

  bool getContinuousListening() {
    return _prefs.getBool(UserPreferences.continuousListening) ?? false;
  }

  // Accessibility mode
  Future<void> setAccessibilityMode(String mode) async {
    await _prefs.setString(UserPreferences.accessibilityMode, mode);
    _logger.info('Accessibility mode set to: $mode');
  }

  String getAccessibilityMode() {
    return _prefs.getString(UserPreferences.accessibilityMode) ??
        AccessibilityModes.normal;
  }

  // Text-to-speech settings
  Future<void> setTextToSpeech(bool enabled) async {
    await _prefs.setBool(UserPreferences.textToSpeech, enabled);
    _logger.info('Text-to-speech set to: $enabled');
  }

  bool getTextToSpeech() {
    return _prefs.getBool(UserPreferences.textToSpeech) ?? false;
  }

  // Screen reader settings
  Future<void> setScreenReader(bool enabled) async {
    await _prefs.setBool(UserPreferences.screenReader, enabled);
    _logger.info('Screen reader set to: $enabled');
  }

  bool getScreenReader() {
    return _prefs.getBool(UserPreferences.screenReader) ?? false;
  }

  // Check if user is in normal mode (no voice features)
  bool isNormalMode() {
    return getAccessibilityMode() == AccessibilityModes.normal;
  }

  // Check if user is in voice mode
  bool isVoiceMode() {
    return getAccessibilityMode() == AccessibilityModes.voice ||
        getAccessibilityMode() == AccessibilityModes.blind ||
        getAccessibilityMode() == AccessibilityModes.visuallyImpaired;
  }

  // Check if voice features should be active
  bool shouldUseVoiceFeatures() {
    return getVoiceEnabled() && isVoiceMode();
  }

  // Reset to default settings (normal mode, no voice)
  Future<void> resetToDefaults() async {
    await setVoiceEnabled(false);
    await setAutoStartVoice(false);
    await setContinuousListening(false);
    await setAccessibilityMode(AccessibilityModes.normal);
    await setTextToSpeech(false);
    await setScreenReader(false);
    _logger.info('User preferences reset to defaults');
  }

  // Get all preferences as a map
  Map<String, dynamic> getAllPreferences() {
    return {
      'voiceEnabled': getVoiceEnabled(),
      'autoStartVoice': getAutoStartVoice(),
      'continuousListening': getContinuousListening(),
      'accessibilityMode': getAccessibilityMode(),
      'textToSpeech': getTextToSpeech(),
      'screenReader': getScreenReader(),
    };
  }
}
 