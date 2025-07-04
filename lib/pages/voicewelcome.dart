// ignore_for_file: library_private_types_in_public_api, deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:permission_handler/permission_handler.dart';

class VoiceWelcomeScreen extends StatefulWidget {
  const VoiceWelcomeScreen({super.key});

  @override
  _VoiceWelcomeScreenState createState() => _VoiceWelcomeScreenState();
}

class _VoiceWelcomeScreenState extends State<VoiceWelcomeScreen>
    with TickerProviderStateMixin {
  FlutterTts flutterTts = FlutterTts();
  stt.SpeechToText speech = stt.SpeechToText();
  bool isListening = false;
  String spokenText = "";
  late AnimationController _fadeController;
  late AnimationController _scaleController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _initTTS();
    _requestPermissions();
    _startWelcomeSequence();
  }

  void _initAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _scaleController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeIn),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.elasticOut),
    );
  }

  Future<void> _initTTS() async {
    await flutterTts.setLanguage("en-US");
    await flutterTts.setSpeechRate(0.5);
    await flutterTts.setVolume(1.0);
    await flutterTts.setPitch(1.0);
  }

  Future<void> _requestPermissions() async {
    var status = await Permission.microphone.request();
    if (status != PermissionStatus.granted) {
      _showError("Microphone permission is required for voice commands");
    }
  }

  Future<void> _startWelcomeSequence() async {
    _fadeController.forward();
    await Future.delayed(const Duration(milliseconds: 500));
    _scaleController.forward();

    await Future.delayed(const Duration(seconds: 1));
    await _speakWelcome();
  }

  Future<void> _speakWelcome() async {
    const String welcomeMessage =
        "Welcome Back again. To register say one and to login say two";

    await flutterTts.speak(welcomeMessage);
    
    flutterTts.setCompletionHandler(() {
      _startListening();
    });
  }

  Future<void> _startListening() async {
    print("Initializing speech recognition...");
    bool available = await speech.initialize(
      onStatus: (val) {
        print("Speech status: $val");
        if (mounted) {
          setState(() {
            isListening = val == 'listening';
          });
        }
      },
      onError: (val) {
        print("Speech error: $val");
        if (mounted) {
          setState(() {
            isListening = false;
          });
          _showError("Speech recognition error. Please say that again.");
        }
      },
    );

    print("Speech available: $available");
    if (available) {
      if (mounted) {
        setState(() {
          isListening = true;
        });
      }

      speech.listen(
        onResult: (val) {
          print("Recognized words: ${val.recognizedWords}");
          if (mounted) {
            setState(() {
              spokenText = val.recognizedWords.toLowerCase();
            });
            _handleVoiceNavigation();
          }
        },
        listenFor: const Duration(seconds: 10),
        pauseFor: const Duration(seconds: 3),
      );
    } else {
      _showError("Speech recognition not available. Please tap to continue.");
    }
  }

  void _handleVoiceNavigation() {
    print("Handling voice navigation with text: $spokenText");
    
    if (spokenText.contains('one') || spokenText.contains('1')) {
      print("Detected 'one' - navigating to register");
      flutterTts.speak("Navigating you to the register screen!");
      Future.delayed(const Duration(seconds: 2), () {
        print("Executing navigation to register");
        Navigator.pushReplacementNamed(context, '/voiceRegister');
      });
    } else if (spokenText.contains('two') || spokenText.contains('2')) {
      print("Detected 'two' - navigating to login");
      flutterTts.speak("Navigating you to the login screen!");
      Future.delayed(const Duration(seconds: 2), () {
        print("Executing navigation to login");
        Navigator.pushReplacementNamed(context, '/voiceLogin');
      });
    } else {
      print("Unrecognized command: $spokenText");
      flutterTts.speak("Sorry, I didn't get that. Please say one for register or two for login.");
      _startListening();
    }
  }

  void _navigateToMainApp({bool accessibilityMode = true}) {
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        if (accessibilityMode) {
          Navigator.pushReplacementNamed(context, '/voiceRegister');
        } else {
          Navigator.pushReplacementNamed(context, '/home');
        }
      }
    });
  }

  void _showError(String message) {
    flutterTts.speak(message);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _scaleController.dispose();
    flutterTts.stop();
    speech.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue.shade50,
      body: GestureDetector(
        onTap: () => _navigateToMainApp(),
        child: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.blue.shade100, Colors.blue.shade50],
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedBuilder(
                animation: _scaleAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _scaleAnimation.value,
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          color: Colors.blue.shade600,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.blue.shade300.withOpacity(0.5),
                              spreadRadius: 5,
                              blurRadius: 15,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.account_balance,
                          size: 60,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(height: 30),

              FadeTransition(
                opacity: _fadeAnimation,
                child: Text(
                  'SmartSacco',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade800,
                    letterSpacing: 1.2,
                  ),
                ),
              ),

              const SizedBox(height: 10),

              FadeTransition(
                opacity: _fadeAnimation,
                child: Text(
                  'Your Smart Financial Partner',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.blue.shade600,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),

              const SizedBox(height: 50),

              if (isListening)
                Column(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Colors.red.shade100,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.mic,
                        size: 40,
                        color: Colors.red.shade600,
                      ),
                    ),
                    const SizedBox(height: 15),
                    Text(
                      'Listening... Say "one or two" to continue',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.blue.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),

              if (!isListening)
                Column(
                  children: [
                    Icon(
                      Icons.touch_app,
                      size: 40,
                      color: Colors.blue.shade600,
                    ),
                    const SizedBox(height: 15),
                    Text(
                      'Tap anywhere to continue',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.blue.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}