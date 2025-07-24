import 'package:flutter/material.dart';

const appPrimaryColor = Colors.blue;
const appAccentColor = Colors.blueAccent;

// User Preferences and Accessibility
class UserPreferences {
  static const String voiceEnabled = 'voice_enabled';
  static const String accessibilityMode = 'accessibility_mode';
  static const String autoStartVoice = 'auto_start_voice';
  static const String continuousListening = 'continuous_listening';
  static const String textToSpeech = 'text_to_speech';
  static const String screenReader = 'screen_reader';
}

// Accessibility Modes
class AccessibilityModes {
  static const String normal = 'normal';
  static const String voice = 'voice';
  static const String blind = 'blind';
  static const String visuallyImpaired = 'visually_impaired';
}

// Voice Settings
class VoiceSettings {
  static const String disabled = 'disabled';
  static const String enabled = 'enabled';
  static const String auto = 'auto';
}
