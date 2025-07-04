// ignore_for_file: library_private_types_in_public_api, deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:permission_handler/permission_handler.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  _SplashPageState createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage>
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
      duration: Duration(seconds: 2),
      vsync: this,
    );
    _scaleController = AnimationController(
      duration: Duration(seconds: 1),
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
    await Permission.microphone.request();
  }

  Future<void> _startWelcomeSequence() async {
    // Start animations
    _fadeController.forward();
    await Future.delayed(Duration(milliseconds: 500));
    _scaleController.forward();

    // Wait a bit then start TTS
    await Future.delayed(Duration(seconds: 1));
    await _speakWelcome();
  }

  Future<void> _speakWelcome() async {
    String welcomeMessage =
        "Welcome to SmartSacco application. If you are visually impaired, say 'one' to continue with voice navigation, or tap anywhere on the screen to proceed normally.";

    await flutterTts.speak(welcomeMessage);

    // Start listening after TTS finishes
    flutterTts.setCompletionHandler(() {
      _startListening();
    });
  }

  Future<void> _startListening() async {
    bool available = await speech.initialize(
      onStatus: (val) {
        if (mounted) {
          setState(() {
            isListening = val == 'listening';
          });
        }
      },
      onError: (val) {
        if (mounted) {
          setState(() {
            isListening = false;
          });
          _showError("Speech recognition error. Please try tapping the screen.");
        }
      },
    );

    if (available) {
      if (mounted) {
        setState(() {
          isListening = true;
        });
      }

      speech.listen(
        onResult: (val) {
          if (mounted) {
            setState(() {
              spokenText = val.recognizedWords.toLowerCase();
            });

            if (spokenText.contains('one') || spokenText.contains('1')) {
              _handleVoiceNavigation();
            }
          }
        },
        listenFor: Duration(seconds: 10),
        pauseFor: Duration(seconds: 3),
      );
    } else {
      _showError("Speech recognition not available. Please tap to continue.");
    }
  }

  void _handleVoiceNavigation() {
    if (mounted) {
      setState(() {
        isListening = false;
      });
    }

    flutterTts.speak("Navigating you to the home screen!");
    _navigateToMainApp(accessibilityMode: true);
  }

  void _navigateToMainApp({bool accessibilityMode = true}) {
    Future.delayed(Duration(seconds: 2), () {
      if (mounted) {
        if (accessibilityMode){
          Navigator.pushReplacementNamed(context, '/voiceWelcome');
        }else{
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
              // Logo/Icon
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
                              offset: Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.account_balance,
                          size: 60,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  );
                },
              ),

              SizedBox(height: 30),

              // App Title
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

              SizedBox(height: 10),

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

              SizedBox(height: 50),

              // Listening indicator
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
                    SizedBox(height: 15),
                    Text(
                      'Listening... Say "one" to continue',
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
                    SizedBox(height: 15),
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