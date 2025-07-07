// ignore_for_file: library_private_types_in_public_api, use_key_in_widget_constructors

import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart';

void main() => runApp(SaccoVoiceApp());

class SaccoVoiceApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SACCO Voice Dashboard',
      home: VoiceDashboard(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class VoiceDashboard extends StatefulWidget {
  @override
  _VoiceDashboardState createState() => _VoiceDashboardState();
}

class _VoiceDashboardState extends State<VoiceDashboard> {
  final SpeechToText _speech = SpeechToText();
  final FlutterTts _tts = FlutterTts();

  bool _isListening = false;
  String _lastWords = '';
  double savings = 50000;
  double loanDue = 10000;
  double maxLoanEligible = 200000;

  @override
  void initState() {
    super.initState();
    _initTts();
  }

  void _initTts() async {
    await _tts.setLanguage('en-US');
    await _tts.setSpeechRate(0.5);
    await _tts.setPitch(1.0);
    await _tts.speak('Welcome to SACCO Voice Dashboard. Say your command after pressing the button.');
  }

  Future<void> _startListening() async {
    bool available = await _speech.initialize();
    if (available) {
      setState(() => _isListening = true);
      _speech.listen(onResult: (result) {
        setState(() {
          _lastWords = result.recognizedWords.toLowerCase();
        });
        _handleVoiceCommand(_lastWords);
      });
    }
  }

  void _stopListening() {
    _speech.stop();
    setState(() => _isListening = false);
  }

  void _handleVoiceCommand(String command) async {
    if (command.contains("check savings")) {
      await _tts.speak("Your current savings are Ugandan shillings $savings.");
    } else if (command.contains("check loan due")) {
      await _tts.speak("Your loan due is Ugandan shillings $loanDue.");
    } else if (command.contains("deposit")) {
      savings += 10000;
      await _tts.speak("Deposit successful. Your new savings balance is Ugandan shillings $savings.");
    } else if (command.contains("request loan")) {
      if (savings >= 50000) {
        await _tts.speak("You are eligible for a loan. You can request up to Ugandan shillings $maxLoanEligible.");
      } else {
        await _tts.speak("Sorry, you are not eligible for a loan. Please save more to qualify.");
      }
    } else {
      await _tts.speak("Sorry, I did not understand. Please try saying: check savings, deposit, request loan or check loan due.");
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
