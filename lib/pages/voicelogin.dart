import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

class VoiceLoginPage extends StatefulWidget {
  const VoiceLoginPage({super.key});

  @override
  State<VoiceLoginPage> createState() => _VoiceLoginPageState();
}

class _VoiceLoginPageState extends State<VoiceLoginPage> {
  final FlutterTts flutterTts = FlutterTts();
  final stt.SpeechToText speech = stt.SpeechToText();
  bool isListening = false;
  String spokenText = "";
  final String correctPin = "1234";

  final Map<String, String> wordToDigit = {
    "zero": "0",
    "one": "1",
    "two": "2",
    "three": "3",
    "four": "4",
    "five": "5",
    "six": "6",
    "seven": "7",
    "eight": "8",
    "nine": "9",
  };

  @override
  void initState() {
    super.initState();
    _initTTS();
    _speakPrompt();
  }

  Future<void> _initTTS() async {
    await flutterTts.setLanguage("en-US");
    await flutterTts.setSpeechRate(0.5);
    await flutterTts.setVolume(1.0);
    await flutterTts.setPitch(1.0);
  }

  Future<void> _speakPrompt() async {
    await flutterTts.speak("Please say your four digit pin now.");

    flutterTts.setCompletionHandler(() {
      _startListening();
    });
  }

  Future<void> _startListening() async {
    bool available = await speech.initialize(
      onStatus: (val) => setState(() => isListening = val == 'listening'),
      onError: (val) => _retry("Speech error. Try again."),
    );

    if (available) {
      speech.listen(
        listenFor: Duration(seconds: 8),
        pauseFor: Duration(seconds: 3),
        onResult: (val) {
          spokenText = val.recognizedWords.toLowerCase();
          _processSpokenPin(spokenText);
        },
      );
    } else {
      _retry("Microphone not available.");
    }
  }

  void _processSpokenPin(String input) {
    List<String> words = input.split(" ");
    String pin = words.map((word) => wordToDigit[word] ?? "").join();

    if (pin.length == 4) {
      if (pin == correctPin) {
        flutterTts.speak("Login successful.");
        Future.delayed(Duration(seconds: 2), () {
          Navigator.pushReplacementNamed(context, '/home');
        });
      } else {
        _retry("Incorrect PIN. Please try again.");
      }
    } else {
      _retry("I heard an incomplete PIN. Please say four digits.");
    }
  }

  void _retry(String message) async {
    await flutterTts.speak(message);
    _speakPrompt();
  }

  @override
  void dispose() {
    flutterTts.stop();
    speech.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isListening ? Icons.mic : Icons.mic_off,
              size: 80,
              color: isListening ? Colors.green : Colors.grey,
            ),
            SizedBox(height: 20),
            Text(
              isListening ? 'Listening for PIN...' : 'Waiting...',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
            ),
            SizedBox(height: 10),
            Text(
              spokenText,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
