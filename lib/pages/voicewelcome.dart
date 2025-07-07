// ignore_for_file: library_private_types_in_public_api, deprecated_member_use, avoid_print, duplicate_ignore

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
  bool isSpeaking = false;
  String spokenText = "";
  int retryCount = 0;
  final int maxRetries = 3;
  
  // Confirmation state
  bool awaitingConfirmation = false;
  String pendingAction = "";
  
  late AnimationController _fadeController;
  late AnimationController _scaleController;
  late AnimationController _pulseController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _pulseAnimation;

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
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeIn),
    );

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
    
    flutterTts.setCompletionHandler(() {
      if (mounted) {
        setState(() {
          isSpeaking = false;
        });
        if (!isListening) {
          _startListening();
        }
      }
    });
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

    setState(() {
      isSpeaking = true;
    });

    await flutterTts.speak(welcomeMessage);
  }

  Future<void> _startListening() async {
    // ignore: avoid_print
    print("Initializing speech recognition...");
    
    // Stop any existing listening session
    if (isListening) {
      await speech.stop();
    }

    bool available = await speech.initialize(
      onStatus: (val) {
        print("Speech status: $val");
        if (mounted) {
          setState(() {
            isListening = val == 'listening';
          });
          
          if (val == 'done' || val == 'notListening') {
            _handleListeningComplete();
          }
        }
      },
      onError: (val) {
        print("Speech error: $val");
        if (mounted) {
          setState(() {
            isListening = false;
          });
          _handleSpeechError(val.errorMsg);
        }
      },
    );

    print("Speech available: $available");
    if (available) {
      if (mounted) {
        setState(() {
          isListening = true;
          spokenText = "";
        });
        
        _pulseController.repeat(reverse: true);
      }

      await speech.listen(
        onResult: (val) {
          print("Recognized words: ${val.recognizedWords}");
          if (mounted) {
            setState(() {
              spokenText = val.recognizedWords.toLowerCase();
            });
            _handleVoiceNavigation();
          }
        },
        listenFor: const Duration(seconds: 15),
        pauseFor: const Duration(seconds: 5),
        partialResults: true,
        cancelOnError: false,
        listenMode: stt.ListenMode.confirmation,
      );
    } else {
      _showError("Speech recognition not available. Please tap to continue.");
    }
  }

  void _handleListeningComplete() {
    _pulseController.stop();
    
    if (!awaitingConfirmation) {
      // If we're not awaiting confirmation and haven't heard a valid command
      if (!spokenText.contains('one') && 
          !spokenText.contains('1') && 
          !spokenText.contains('two') && 
          !spokenText.contains('2') &&
          !spokenText.contains('yes') &&
          !spokenText.contains('no') &&
          retryCount < maxRetries) {
        
        retryCount++;
        String retryMessage = retryCount == 1 
            ? "I didn't catch that. Please say 'one' to register or 'two' to login."
            : retryCount == 2 
                ? "Let's try again. Say 'one' for register or 'two' for login."
                : "One more time. Say 'one' to register or 'two' to login.";
        
        _speakAndRetry(retryMessage);
      } else if (retryCount >= maxRetries) {
        _speakAndRetry("Having trouble with voice recognition. You can tap the screen to continue.");
      }
    } else {
      // If we're awaiting confirmation but didn't hear yes/no
      if (!spokenText.contains('yes') && 
          !spokenText.contains('no') &&
          retryCount < maxRetries) {
        
        retryCount++;
        _speakAndRetry("Please say 'yes' to confirm or 'no' to cancel.");
      } else if (retryCount >= maxRetries) {
        _resetConfirmationState();
        _speakAndRetry("Let's start over. Say 'one' to register or 'two' to login.");
      }
    }
  }

  void _handleSpeechError(String errorMsg) {
    _pulseController.stop();
    
    print('Speech error details: $errorMsg');
    
    if (errorMsg.contains('network') || errorMsg.contains('connection')) {
      _speakAndRetry("Network issue detected. Please check your connection and try again.");
    } else if (errorMsg.contains('no-speech') || errorMsg.contains('speech-timeout')) {
      if (awaitingConfirmation) {
        _speakAndRetry("I didn't hear anything. Please say 'yes' to confirm or 'no' to cancel.");
      } else {
        _speakAndRetry("I didn't hear anything. Please say 'one' to register or 'two' to login.");
      }
    } else if (retryCount < maxRetries) {
      retryCount++;
      if (awaitingConfirmation) {
        _speakAndRetry("Let's try again. Please say 'yes' to confirm or 'no' to cancel.");
      } else {
        _speakAndRetry("Let's try again. Say 'one' to register or 'two' to login.");
      }
    } else {
      if (awaitingConfirmation) {
        _resetConfirmationState();
      }
      _speakAndRetry("Voice recognition is having trouble. Please tap the screen to continue.");
    }
  }

  Future<void> _speakAndRetry(String message) async {
    setState(() {
      isSpeaking = true;
    });
    
    await flutterTts.speak(message);
  }

  void _handleVoiceNavigation() {
    print("Handling voice navigation with text: $spokenText");
    
    if (awaitingConfirmation) {
      _handleConfirmation();
    } else {
      _handleInitialCommand();
    }
  }

  void _handleInitialCommand() {
    if (spokenText.contains('one') || spokenText.contains('1')) {
      print("Detected 'one' - requesting confirmation for register");
      _requestConfirmation("register", "one");
    } else if (spokenText.contains('two') || spokenText.contains('2')) {
      print("Detected 'two' - requesting confirmation for login");
      _requestConfirmation("login", "two");
    } else {
      print("Unrecognized command: $spokenText");
      _speakAndRetry("Navigating you back to home screen. Please say 'one' to register or 'two' to login.");
    }
  }

  void _requestConfirmation(String action, String number) {
    setState(() {
      awaitingConfirmation = true;
      pendingAction = action;
      isListening = false;
      retryCount = 0;
      spokenText = ""; // Clear previous spoken text
    });
    
    _pulseController.stop();
    speech.stop();
    
    String confirmationMessage = "Did you say $number to $action? Say 'yes' to confirm or 'no' to cancel.";
    
    setState(() {
      isSpeaking = true;
    });
    
    flutterTts.speak(confirmationMessage);
  }

  void _handleConfirmation() {
    if (spokenText.contains('yes')) {
      print("Confirmed - proceeding with $pendingAction");
      _executeAction();
    } else if (spokenText.contains('no')) {
      print("Cancelled - returning to main menu");
      
      // Stop current speech recognition
      speech.stop();
      _pulseController.stop();
      
      // Reset confirmation state and clear spoken text
      _resetConfirmationState();
      setState(() {
        spokenText = "";
        isListening = false;
        isSpeaking = true;
      });
      
      // Navigate back to home screen first, then repeat options
      _speakWelcomeAfterCancel();
    } else {
      print("Unrecognized confirmation: $spokenText");
      _speakAndRetry("Please say 'yes' to confirm or 'no' to cancel.");
    }
  }

  Future<void> _speakWelcomeAfterCancel() async {
    await flutterTts.speak("Navigating you back to home screen. Welcome Back again. To register say one and to login say two");
  }

  void _executeAction() {
    print("Executing action: $pendingAction");
    
    setState(() {
      isListening = false;
      isSpeaking = true;
    });
    
    _pulseController.stop();
    speech.stop();
    
    if (pendingAction == "register") {
      print("Navigating to register screen");
      flutterTts.speak("Navigating you to the register screen!");
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          print("Executing navigation to register");
          Navigator.pushReplacementNamed(context, '/voiceRegister');
        }
      });
    } else if (pendingAction == "login") {
      print("Navigating to login screen");
      flutterTts.speak("Navigating you to the login screen!");
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          print("Executing navigation to login");
          Navigator.pushReplacementNamed(context, '/voiceLogin');
        }
      });
    }
  }

  void _resetConfirmationState() {
    setState(() {
      awaitingConfirmation = false;
      pendingAction = "";
      retryCount = 0;
      spokenText = "";
    });
  }

  void _navigateToMainApp() {
    print("Navigating to main app - tap detected");
    speech.stop();
    flutterTts.stop();
    
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        // When tapping, go to regular home screen instead of voice screens
        Navigator.pushReplacementNamed(context, '/home');
      }
    });
  }

  void _showError(String message) {
    flutterTts.speak(message);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          duration: const Duration(seconds: 3),
        ),
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

  String _getStatusText() {
    if (awaitingConfirmation) {
      return 'Say "yes" to confirm or "no" to cancel';
    } else {
      return 'Say "one" for register or "two" for login';
    }
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
                              color: awaitingConfirmation 
                                  ? Colors.orange.shade100 
                                  : Colors.red.shade100,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: awaitingConfirmation 
                                    ? Colors.orange.shade400 
                                    : Colors.red.shade400,
                                width: 2,
                              ),
                            ),
                            child: Icon(
                              Icons.mic,
                              size: 40,
                              color: awaitingConfirmation 
                                  ? Colors.orange.shade600 
                                  : Colors.red.shade600,
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 15),
                    Text(
                      'Listening... ${_getStatusText()}',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.blue.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
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

              // Speaking indicator
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
                    const SizedBox(height: 15),
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

              // Idle state
              if (!isListening && !isSpeaking)
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