import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smartsacco/services/analytics_service.dart';
import 'package:smartsacco/services/error_handling_service.dart';
import 'dart:async';

class AccessibilityService {
  static final AccessibilityService _instance =
      AccessibilityService._internal();
  factory AccessibilityService() => _instance;
  AccessibilityService._internal();

  final FlutterTts _flutterTts = FlutterTts();
  final SpeechToText _speechToText = SpeechToText();
  final AnalyticsService _analytics = AnalyticsService();
  final ErrorHandlingService _errorHandler = ErrorHandlingService();

  // Accessibility settings
  bool _voiceEnabled = true;
  bool _voiceCommandsEnabled = true;
  bool _screenReaderEnabled = true;
  bool _highContrastEnabled = false;
  bool _largeTextEnabled = false;
  bool _hapticFeedbackEnabled = true;
  double _speechRate = 0.5;
  double _pitch = 1.0;
  double _volume = 1.0;
  String _selectedLanguage = 'English';
  String _selectedVoice = 'default';

  // Voice command patterns
  final Map<String, List<String>> _voiceCommands = {
    'navigation': [
      'go to home',
      'go to dashboard',
      'go to profile',
      'go to settings',
      'go back',
      'go forward',
      'close',
      'exit',
    ],
    'transactions': [
      'make deposit',
      'make withdrawal',
      'check balance',
      'view transactions',
      'view statement',
    ],
    'loans': ['apply for loan', 'view loans', 'pay loan', 'loan status'],
    'general': [
      'help',
      'what can I say',
      'repeat',
      'stop speaking',
      'pause',
      'resume',
    ],
  };

  // Accessibility modes
  static const String _modeBasic = 'basic';
  // static const String _modeAdvanced = 'advanced'; // Removed unused field
  // static const String _modeExpert = 'expert'; // Removed unused field

  String _currentMode = _modeBasic;

  // Initialize accessibility service
  Future<void> initialize() async {
    try {
      await _loadSettings();
      await _initializeTTS();
      await _initializeSTT();

      // Track initialization
      await _analytics.trackFeatureUsage(
        featureName: 'accessibility_initialized',
        parameters: {
          'voice_enabled': _voiceEnabled,
          'voice_commands_enabled': _voiceCommandsEnabled,
          'screen_reader_enabled': _screenReaderEnabled,
          'current_mode': _currentMode,
        },
      );

      debugPrint('Accessibility service initialized');
    } catch (e) {
      await _errorHandler.handleVoiceError('accessibility_initialization', e);
    }
  }

  // Load accessibility settings
  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      _voiceEnabled = prefs.getBool('accessibility_voice_enabled') ?? true;
      _voiceCommandsEnabled =
          prefs.getBool('accessibility_voice_commands_enabled') ?? true;
      _screenReaderEnabled =
          prefs.getBool('accessibility_screen_reader_enabled') ?? true;
      _highContrastEnabled =
          prefs.getBool('accessibility_high_contrast_enabled') ?? false;
      _largeTextEnabled =
          prefs.getBool('accessibility_large_text_enabled') ?? false;
      _hapticFeedbackEnabled =
          prefs.getBool('accessibility_haptic_feedback_enabled') ?? true;

      _speechRate = prefs.getDouble('accessibility_speech_rate') ?? 0.5;
      _pitch = prefs.getDouble('accessibility_pitch') ?? 1.0;
      _volume = prefs.getDouble('accessibility_volume') ?? 1.0;
      _selectedLanguage =
          prefs.getString('accessibility_language') ?? 'English';
      _selectedVoice = prefs.getString('accessibility_voice') ?? 'default';
      _currentMode = prefs.getString('accessibility_mode') ?? _modeBasic;
    } catch (e) {
      await _errorHandler.handleVoiceError('load_accessibility_settings', e);
    }
  }

  // Save accessibility settings
  Future<void> _saveSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      await prefs.setBool('accessibility_voice_enabled', _voiceEnabled);
      await prefs.setBool(
        'accessibility_voice_commands_enabled',
        _voiceCommandsEnabled,
      );
      await prefs.setBool(
        'accessibility_screen_reader_enabled',
        _screenReaderEnabled,
      );
      await prefs.setBool(
        'accessibility_high_contrast_enabled',
        _highContrastEnabled,
      );
      await prefs.setBool(
        'accessibility_large_text_enabled',
        _largeTextEnabled,
      );
      await prefs.setBool(
        'accessibility_haptic_feedback_enabled',
        _hapticFeedbackEnabled,
      );

      await prefs.setDouble('accessibility_speech_rate', _speechRate);
      await prefs.setDouble('accessibility_pitch', _pitch);
      await prefs.setDouble('accessibility_volume', _volume);
      await prefs.setString('accessibility_language', _selectedLanguage);
      await prefs.setString('accessibility_voice', _selectedVoice);
      await prefs.setString('accessibility_mode', _currentMode);
    } catch (e) {
      await _errorHandler.handleVoiceError('save_accessibility_settings', e);
    }
  }

  // Initialize Text-to-Speech
  Future<void> _initializeTTS() async {
    try {
      await _flutterTts.setLanguage(_getLanguageCode(_selectedLanguage));
      await _flutterTts.setSpeechRate(_speechRate);
      await _flutterTts.setPitch(_pitch);
      await _flutterTts.setVolume(_volume);

      // Set up TTS callbacks
      _flutterTts.setStartHandler(() {
        debugPrint('TTS started');
      });

      _flutterTts.setCompletionHandler(() {
        debugPrint('TTS completed');
      });

      _flutterTts.setErrorHandler((msg) {
        debugPrint('TTS error: $msg');
        _errorHandler.handleVoiceError('tts_speak', msg);
      });
    } catch (e) {
      await _errorHandler.handleVoiceError('tts_initialization', e);
    }
  }

  // Initialize Speech-to-Text
  Future<void> _initializeSTT() async {
    try {
      final available = await _speechToText.initialize(
        onError: (error) {
          debugPrint('STT error: $error');
          _errorHandler.handleVoiceError('stt_initialize', error);
        },
        onStatus: (status) {
          debugPrint('STT status: $status');
        },
      );

      if (!available) {
        await _errorHandler.handleVoiceError(
          'stt_initialization',
          'Speech recognition not available',
        );
      }
    } catch (e) {
      await _errorHandler.handleVoiceError('stt_initialization', e);
    }
  }

  // Speak text with accessibility features
  Future<void> speak(
    String text, {
    bool interrupt = true,
    String? context,
    Map<String, dynamic>? voiceData,
  }) async {
    if (!_voiceEnabled) return;

    try {
      if (interrupt) {
        await _flutterTts.stop();
      }

      await _flutterTts.speak(text);

      // Track speech analytics
      await _analytics.trackVoiceCommand(command: text, isSuccess: true);

      // Add context to parameters
      if (voiceData != null) {
        voiceData['context'] = context;
        voiceData['text_length'] = text.length;
      }
    } catch (e) {
      await _errorHandler.handleVoiceError('speak', e, voiceData: voiceData);
    }
  }

  // Listen for voice commands
  Future<String?> listenForCommand({
    Duration timeout = const Duration(seconds: 10),
    String? prompt,
  }) async {
    if (!_voiceCommandsEnabled) return null;

    try {
      if (prompt != null) {
        await speak(prompt);
      }

      final result = await _speechToText.listen(
        onResult: (result) {
          debugPrint('Voice command: ${result.recognizedWords}');
        },
        listenFor: timeout,
      );

      if (result.finalResult) {
        final command = result.recognizedWords.toLowerCase();

        // Track voice command
        await _analytics.trackVoiceCommand(
          command: command,
          isSuccess: true,
          responseTime: result.duration?.inMilliseconds,
        );

        return command;
      }

      return null;
    } catch (e) {
      await _errorHandler.handleVoiceError('listen_for_command', e);
      return null;
    }
  }

  // Process voice command
  Future<Map<String, dynamic>> processVoiceCommand(String command) async {
    try {
      final processedCommand = command.toLowerCase().trim();
      final response = <String, dynamic>{
        'success': false,
        'action': null,
        'parameters': {},
        'message': 'Command not recognized',
      };

      // Check navigation commands
      for (final navCommand in _voiceCommands['navigation']!) {
        if (processedCommand.contains(navCommand)) {
          response['success'] = true;
          response['action'] = 'navigate';
          response['parameters'] = {'destination': navCommand};
          response['message'] = 'Navigating to $navCommand';
          break;
        }
      }

      // Check transaction commands
      for (final transCommand in _voiceCommands['transactions']!) {
        if (processedCommand.contains(transCommand)) {
          response['success'] = true;
          response['action'] = 'transaction';
          response['parameters'] = {'type': transCommand};
          response['message'] = 'Processing $transCommand';
          break;
        }
      }

      // Check loan commands
      for (final loanCommand in _voiceCommands['loans']!) {
        if (processedCommand.contains(loanCommand)) {
          response['success'] = true;
          response['action'] = 'loan';
          response['parameters'] = {'type': loanCommand};
          response['message'] = 'Processing $loanCommand';
          break;
        }
      }

      // Check general commands
      for (final genCommand in _voiceCommands['general']!) {
        if (processedCommand.contains(genCommand)) {
          response['success'] = true;
          response['action'] = 'general';
          response['parameters'] = {'type': genCommand};
          response['message'] = 'Processing $genCommand';
          break;
        }
      }

      // Track command processing
      await _analytics.trackVoiceCommand(
        command: command,
        isSuccess: response['success'],
      );

      return response;
    } catch (e) {
      await _errorHandler.handleVoiceError('process_voice_command', e);
      return {
        'success': false,
        'action': null,
        'parameters': {},
        'message': 'Error processing command',
      };
    }
  }

  // Provide contextual help
  Future<void> provideContextualHelp(String context) async {
    try {
      String helpText = '';

      switch (context.toLowerCase()) {
        case 'dashboard':
          helpText =
              'You are on the dashboard. Say "make deposit" to add money, "check balance" to view your balance, or "apply for loan" to request a loan.';
          break;
        case 'deposit':
          helpText =
              'To make a deposit, say the amount you want to deposit. For example, "deposit 50000 shillings".';
          break;
        case 'withdrawal':
          helpText =
              'To make a withdrawal, say the amount you want to withdraw. For example, "withdraw 20000 shillings".';
          break;
        case 'loan':
          helpText =
              'To apply for a loan, say "apply for loan" followed by the amount. For example, "apply for loan 100000 shillings".';
          break;
        case 'navigation':
          helpText =
              'Say "go to dashboard" to return to the main screen, "go to profile" to view your profile, or "go to settings" to change app settings.';
          break;
        default:
          helpText =
              'Say "help" for assistance, "what can I say" for available commands, or "go back" to return to the previous screen.';
      }

      await speak(helpText);
    } catch (e) {
      await _errorHandler.handleVoiceError('provide_contextual_help', e);
    }
  }

  // Announce page changes
  Future<void> announcePageChange(String pageName) async {
    try {
      await speak('Now on $pageName page');
    } catch (e) {
      await _errorHandler.handleVoiceError('announce_page_change', e);
    }
  }

  // Announce actions
  Future<void> announceAction(String action, {String? result}) async {
    try {
      String announcement = action;
      if (result != null) {
        announcement += '. $result';
      }
      await speak(announcement);
    } catch (e) {
      await _errorHandler.handleVoiceError('announce_action', e);
    }
  }

  // Provide haptic feedback
  Future<void> provideHapticFeedback(String type) async {
    if (!_hapticFeedbackEnabled) return;

    try {
      // This would be implemented with haptic feedback package
      // For now, we'll just track the event
      await _analytics.trackFeatureUsage(
        featureName: 'haptic_feedback',
        parameters: {'type': type},
      );
    } catch (e) {
      await _errorHandler.handleVoiceError('haptic_feedback', e);
    }
  }

  // Update accessibility settings
  Future<void> updateSettings({
    bool? voiceEnabled,
    bool? voiceCommandsEnabled,
    bool? screenReaderEnabled,
    bool? highContrastEnabled,
    bool? largeTextEnabled,
    bool? hapticFeedbackEnabled,
    double? speechRate,
    double? pitch,
    double? volume,
    String? language,
    String? voice,
    String? mode,
  }) async {
    try {
      if (voiceEnabled != null) { _voiceEnabled = voiceEnabled; }
      if (voiceCommandsEnabled != null) { _voiceCommandsEnabled = voiceCommandsEnabled; }
      if (screenReaderEnabled != null) { _screenReaderEnabled = screenReaderEnabled; }
      if (highContrastEnabled != null) { _highContrastEnabled = highContrastEnabled; }
      if (largeTextEnabled != null) { _largeTextEnabled = largeTextEnabled; }
      if (hapticFeedbackEnabled != null) { _hapticFeedbackEnabled = hapticFeedbackEnabled; }

      if (speechRate != null) {
        _speechRate = speechRate;
        await _flutterTts.setSpeechRate(speechRate);
      }
      if (pitch != null) {
        _pitch = pitch;
        await _flutterTts.setPitch(pitch);
      }
      if (volume != null) {
        _volume = volume;
        await _flutterTts.setVolume(volume);
      }
      if (language != null) {
        _selectedLanguage = language;
        await _flutterTts.setLanguage(_getLanguageCode(language));
      }
      if (voice != null) _selectedVoice = voice;
      if (mode != null) _currentMode = mode;

      await _saveSettings();

      // Track settings update
      await _analytics.trackFeatureUsage(
        featureName: 'accessibility_settings_updated',
        parameters: {
          'voice_enabled': _voiceEnabled,
          'voice_commands_enabled': _voiceCommandsEnabled,
          'screen_reader_enabled': _screenReaderEnabled,
          'current_mode': _currentMode,
        },
      );

      await speak('Accessibility settings updated');
    } catch (e) {
      await _errorHandler.handleVoiceError('update_accessibility_settings', e);
    }
  }

  // Get accessibility status
  Map<String, dynamic> getAccessibilityStatus() {
    return {
      'voice_enabled': _voiceEnabled,
      'voice_commands_enabled': _voiceCommandsEnabled,
      'screen_reader_enabled': _screenReaderEnabled,
      'high_contrast_enabled': _highContrastEnabled,
      'large_text_enabled': _largeTextEnabled,
      'haptic_feedback_enabled': _hapticFeedbackEnabled,
      'speech_rate': _speechRate,
      'pitch': _pitch,
      'volume': _volume,
      'language': _selectedLanguage,
      'voice': _selectedVoice,
      'mode': _currentMode,
      'available_commands': _voiceCommands,
    };
  }

  // Get available voice commands
  List<String> getAvailableCommands() {
    final commands = <String>[];
    for (final category in _voiceCommands.values) {
      commands.addAll(category);
    }
    return commands;
  }

  // Get language code for TTS
  String _getLanguageCode(String language) {
    switch (language.toLowerCase()) {
      case 'english':
        return 'en-US';
      case 'luganda':
        return 'lg-UG';
      case 'swahili':
        return 'sw-KE';
      default:
        return 'en-US';
    }
  }

  // Stop speaking
  Future<void> stopSpeaking() async {
    try {
      await _flutterTts.stop();
    } catch (e) {
      await _errorHandler.handleVoiceError('stop_speaking', e);
    }
  }

  // Pause speaking
  Future<void> pauseSpeaking() async {
    try {
      await _flutterTts.pause();
    } catch (e) {
      await _errorHandler.handleVoiceError('pause_speaking', e);
    }
  }

  // Dispose resources
  void dispose() {
    _flutterTts.stop();
  }
}
