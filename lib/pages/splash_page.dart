// ignore_for_file: library_private_types_in_public_api, deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:permission_handler/permission_handler.dart';
import 'package:logging/logging.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  _SplashPageState createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> with TickerProviderStateMixin {
  FlutterTts flutterTts = FlutterTts();
  stt.SpeechToText speech = stt.SpeechToText();
  bool isListening = false;
  bool isSpeaking = false;
  String spokenText = "";
  int retryCount = 0;
  final int maxRetries = 3;
  late AnimationController _fadeController;
  late AnimationController _scaleController;
  late AnimationController _pulseController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _pulseAnimation;
  final Logger _logger = Logger('SplashPage');

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
    _pulseController = AnimationController(
      duration: Duration(milliseconds: 1500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeIn));

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.elasticOut),
    );

    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  Future<void> _initTTS() async {
    await flutterTts.setLanguage("en-US");
    await flutterTts.setSpeechRate(0.5);
    await flutterTts.setVolume(1.0);
    await flutterTts.setPitch(1.0);

    // Set up TTS completion handler
    flutterTts.setCompletionHandler(() {
      if (mounted) {
        setState(() {
          isSpeaking = false;
        });
        // Start listening after TTS finishes
        if (!isListening) {
          _startListening();
        }
      }
    });
  }

  Future<void> _requestPermissions() async {
    var status = await Permission.microphone.request();
    if (status != PermissionStatus.granted) {
      _showError(
        "Microphone permission is required for voice navigation. Please tap to continue.",
      );
    }
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

    setState(() {
      isSpeaking = true;
    });

    await flutterTts.speak(welcomeMessage);
  }

  Future<void> _startListening() async {
    // Stop any existing listening session
    if (isListening) {
      await speech.stop();
    }

    bool available = await speech.initialize(
      onStatus: (val) {
        _logger.info('Speech status: $val'); // Debug log
        if (mounted) {
          setState(() {
            isListening = val == 'listening';
          });

          // Handle different status scenarios
          if (val == 'done' || val == 'notListening') {
            _handleListeningComplete();
          }
        }
      },
      onError: (val) {
        _logger.warning('Speech error: $val'); // Debug log
        if (mounted) {
          setState(() {
            isListening = false;
          });
          _handleSpeechError(val.errorMsg);
        }
      },
    );

    if (available) {
      if (mounted) {
        setState(() {
          isListening = true;
          spokenText = "";
        });

        // Start pulse animation for microphone
        _pulseController.repeat(reverse: true);
      }

      await speech.listen(
        onResult: (val) {
          if (mounted) {
            setState(() {
              spokenText = val.recognizedWords.toLowerCase();
            });

            _logger.info('Recognized: $spokenText'); // Debug log

            // Check for trigger words
            if (spokenText.contains('one') ||
                spokenText.contains('1') ||
                spokenText.contains('won')) {
              _handleVoiceNavigation();
            }
          }
        },
        listenFor: Duration(seconds: 15), // Increased listening time
        pauseFor: Duration(seconds: 5), // Increased pause time
        partialResults: true, // Enable partial results
        cancelOnError: false, // Don't cancel on minor errors
        listenMode:
            stt.ListenMode.confirmation, // Better for command recognition
      );
    } else {
      _showError("Speech recognition not available. Please tap to continue.");
    }
  }

  void _handleListeningComplete() {
    _pulseController.stop();

    // If we haven't detected the trigger word and haven't exceeded retries
    if (!spokenText.contains('one') &&
        !spokenText.contains('1') &&
        !spokenText.contains('won') &&
        retryCount < maxRetries) {
      retryCount++;

      String retryMessage = retryCount == 1
          ? "I didn't catch that. Please say 'one' clearly to continue with voice navigation."
          : retryCount == 2
          ? "Let's try again. Say 'one' to continue with voice navigation."
          : "One more time. Say 'one' for voice navigation, or tap the screen to continue normally.";

      _speakAndRetry(retryMessage);
    } else if (retryCount >= maxRetries) {
      _speakAndRetry(
        "No problem. You can tap anywhere on the screen to continue.",
      );
    }
  }

  void _handleSpeechError(String errorMsg) {
    _pulseController.stop();

    _logger.warning('Speech error details: $errorMsg'); // Debug log

    // Handle specific error types
    if (errorMsg.contains('network') || errorMsg.contains('connection')) {
      _speakAndRetry(
        "Network issue detected. Please check your connection and try saying 'one' again.",
      );
    } else if (errorMsg.contains('no-speech') ||
        errorMsg.contains('speech-timeout')) {
      _speakAndRetry(
        "I didn't hear anything. Please say 'one' to continue with voice navigation.",
      );
    } else if (retryCount < maxRetries) {
      retryCount++;
      _speakAndRetry(
        "Let's try again. Say 'one' to continue with voice navigation.",
      );
    } else {
      _speakAndRetry(
        "Voice recognition is having trouble. Please tap the screen to continue.",
      );
    }
  }

  Future<void> _speakAndRetry(String message) async {
    setState(() {
      isSpeaking = true;
    });

    await flutterTts.speak(message);
    // TTS completion handler will trigger _startListening()
  }

  void _handleVoiceNavigation() async {
    if (mounted) {
      setState(() {
        isListening = false;
      });
    }

    _pulseController.stop();
    speech.stop();

    setState(() {
      isSpeaking = true;
    });

    flutterTts.setCompletionHandler(() {
      if (mounted) {
        setState(() {
          isSpeaking = false;
        });
        _navigateToMainApp(accessibilityMode: true);
      }
    });
    await flutterTts.speak("Navigating you to the welcome screen.");
  }

  void _navigateToMainApp({bool accessibilityMode = false}) {
    // Stop all audio activities
    speech.stop();
    flutterTts.stop();

    Future.delayed(Duration(seconds: 2), () {
      if (mounted) {
        if (accessibilityMode) {
          Navigator.pushReplacementNamed(context, '/voiceWelcome');
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
        SnackBar(content: Text(message), duration: Duration(seconds: 3)),
      );
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _scaleController.dispose();
    _pulseController.dispose();
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
                        child: ClipOval(
                          child: Image.asset(
                            'assets/smartsacco.png',
                            width: 110,
                            height: 110,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                width: 110,
                                height: 110,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.account_balance,
                                  size: 55,
                                  color: Colors.blue.shade600,
                                ),
                              );
                            },
                          ),
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
                    AnimatedBuilder(
                      animation: _pulseAnimation,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: _pulseAnimation.value,
                          child: Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              color: Colors.red.shade100,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.red.shade400,
                                width: 2,
                              ),
                            ),
                            child: Icon(
                              Icons.mic,
                              size: 40,
                              color: Colors.red.shade600,
                            ),
                          ),
                        );
                      },
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
                    if (retryCount > 0)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          'Attempt ${retryCount + 1} of ${maxRetries + 1}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.blue.shade500,
                          ),
                        ),
                      ),
                  ],
                ),

              if (isSpeaking && !isListening)
                Column(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Colors.green.shade100,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.volume_up,
                        size: 40,
                        color: Colors.green.shade600,
                      ),
                    ),
                    SizedBox(height: 15),
                    Text(
                      'Speaking...',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.blue.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),

              if (!isListening && !isSpeaking)
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
