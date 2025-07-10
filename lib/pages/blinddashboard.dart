import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart';

class VoiceDashboard extends StatefulWidget {
  const VoiceDashboard({super.key});

  @override
  State<VoiceDashboard> createState() => _VoiceDashboardState();
}

class _VoiceDashboardState extends State<VoiceDashboard> {
  final FlutterTts _tts = FlutterTts();
  final SpeechToText _speech = SpeechToText();

  bool _isListening = false;
  String _lastCommand = '';

  double savings = 50000;
  double loanDue = 10000;
  double maxLoanEligible = 200000;

  @override
  void initState() {
    super.initState();
    _initializeVoice();
  }

  Future<void> _initializeVoice() async {
    await _tts.setLanguage('en-US');
    await _tts.setSpeechRate(0.5);
    await _tts.setPitch(1.0);
    _speak("Welcome to your voice-enabled dashboard. Tap the microphone and speak your command.");
  }

  void _startListening() async {
    bool available = await _speech.initialize();
    if (available) {
      setState(() => _isListening = true);
      _speech.listen(onResult: (result) {
        setState(() => _lastCommand = result.recognizedWords.toLowerCase());
        _handleCommand(_lastCommand);
      });
    } else {
      _speak("Speech recognition not available.");
    }
  }

  void _stopListening() {
    _speech.stop();
    setState(() => _isListening = false);
  }

  Future<void> _speak(String text) async {
    await _tts.speak(text);
  }

  void _handleCommand(String command) async {
    if (command.contains("check savings")) {
      await _speak("Your savings balance is shillings $savings.");
    } else if (command.contains("deposit")) {
      savings += 10000;
      await _speak("Deposit of ten thousand completed. New balance is shillings $savings.");
    } else if (command.contains("request loan")) {
      if (savings >= 50000) {
        await _speak("You are eligible. You can request up to shillings $maxLoanEligible.");
      } else {
        await _speak("You are not eligible. Save at least fifty thousand to qualify.");
      }
    } else if (command.contains("loan due")) {
      await _speak("Your loan due is shillings $loanDue.");
    } else {
      await _speak("Command not recognized. Say check savings, deposit, request loan, or check loan due.");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: IconButton(
          icon: Icon(Icons.mic, size: 80, color: Colors.white),
          onPressed: _isListening ? _stopListening : _startListening,
        ),
      ),
    );
  }
}