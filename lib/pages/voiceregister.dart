import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

class VoiceRegisterPage extends StatefulWidget {
  const VoiceRegisterPage({super.key});

  @override
  _VoiceRegisterPageState createState() => _VoiceRegisterPageState();
}

class _VoiceRegisterPageState extends State<VoiceRegisterPage>
    with TickerProviderStateMixin {
  FlutterTts flutterTts = FlutterTts();
  stt.SpeechToText speech = stt.SpeechToText();
  bool isListening = false;
  String spokenText = "";
  
  // Registration data
  String fullName = "";
  String email = "";
  String pin = "";
  String password = "";
  String role = "";
  
  // Registration steps
  int currentStep = 0;
  List<String> steps = [
    "full_name",
    "email", 
    "pin",
    "password",
    "role",
    "confirm"
  ];
  
  late AnimationController _fadeController;
  late AnimationController _pulseController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _initTTS();
    _startRegistrationProcess();
  }

  void _initAnimations() {
    _fadeController = AnimationController(
      duration: Duration(seconds: 1),
      vsync: this,
    );
    _pulseController = AnimationController(
      duration: Duration(seconds: 1),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeIn),
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  Future<void> _initTTS() async {
    await flutterTts.setLanguage("en-US");
    await flutterTts.setSpeechRate(0.5);
    await flutterTts.setVolume(1.0);
    await flutterTts.setPitch(1.0);
  }

  Future<void> _startRegistrationProcess() async {
    _fadeController.forward();
    _pulseController.repeat(reverse: true);
    
    await Future.delayed(Duration(seconds: 1));
    await _speakCurrentStep();
  }

  Future<void> _speakCurrentStep() async {
    String message = "";
    
    switch (steps[currentStep]) {
      case "full_name":
        message = "Welcome to registration! Please say your full name clearly.";
        break;
      case "email":
        message = "Great! Now please say your email address. Speak slowly and clearly.";
        break;
      case "pin":
        message = "Now please say your 4-digit PIN. This will be used for quick access.";
        break;
      case "password":
        message = "Please say your password. Make it secure and memorable.";
        break;
      case "role":
        message = "Finally, please say your role. Say 'member' if you are a member, or say 'admin' if you are an administrator.";
        break;
      case "confirm":
        message = "Let me confirm your details. Full name: $fullName. Email: $email. PIN: $pin. Password: $password. Role: $role. Say 'yes' to confirm or 'no' to start over.";
        break;
    }

    await flutterTts.speak(message);
    
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
          _showError("Sorry, I didn't catch that. Let me try again.");
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

            // Process input when user stops speaking (after a short delay)
            Future.delayed(Duration(milliseconds: 1500), () {
              if (mounted && !isListening) {
                return; // Already processed or stopped
              }
              speech.stop();
              _processSpokenInput(val.recognizedWords);
            });
          }
        },
        listenFor: Duration(seconds: 15),
        pauseFor: Duration(seconds: 2),
      );
    } else {
      _showError("Speech recognition not available. Please try again.");
    }
  }

  void _processSpokenInput(String input) {
    setState(() {
      isListening = false;
    });

    switch (steps[currentStep]) {
      case "full_name":
        _processFullName(input);
        break;
      case "email":
        _processEmail(input);
        break;
      case "pin":
        _processPin(input);
        break;
      case "password":
        _processPassword(input);
        break;
      case "role":
        _processRole(input);
        break;
      case "confirm":
        _processConfirmation(input);
        break;
    }
  }

  void _processFullName(String input) {
    if (input.trim().isNotEmpty) {
      fullName = input.trim();
      _speakAndProceed("Thank you, $fullName.");
    } else {
      _askAgain("I didn't catch your name. Please say your full name again.");
    }
  }

  void _processEmail(String input) {
    // Simple email validation - contains @ and .
    String cleanInput = input.replaceAll(' ', '').toLowerCase();
    if (cleanInput.contains('@') && cleanInput.contains('.')) {
      email = cleanInput;
      _speakAndProceed("Email recorded as $email.");
    } else {
      _askAgain("That doesn't sound like a valid email address. Please say your email again, including the 'at' symbol and domain.");
    }
  }

  void _processPin(String input) {
    // Extract digits from speech
    String digits = input.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length == 4) {
      pin = digits;
      _speakAndProceed("PIN recorded as $pin.");
    } else {
      _askAgain("Please say exactly 4 digits for your PIN.");
    }
  }

  void _processPassword(String input) {
    if (input.trim().isNotEmpty && input.trim().length >= 4) {
      password = input.trim();
      _speakAndProceed("Password recorded.");
    } else {
      _askAgain("Password must be at least 4 characters. Please say your password again.");
    }
  }

  void _processRole(String input) {
    String lowerInput = input.toLowerCase();
    if (lowerInput.contains('member')) {
      role = "member";
      _speakAndProceed("Role set as member.");
    } else if (lowerInput.contains('admin')) {
      role = "admin";
      _speakAndProceed("Role set as admin.");
    } else {
      _askAgain("Please say either 'member' or 'admin' for your role.");
    }
  }

  void _processConfirmation(String input) {
    String lowerInput = input.toLowerCase();
    if (lowerInput.contains('yes')) {
      _completeRegistration();
    } else if (lowerInput.contains('no')) {
      _restartRegistration();
    } else {
      _askAgain("Please say 'yes' to confirm or 'no' to start over.");
    }
  }

  void _speakAndProceed(String message) {
    flutterTts.speak(message);
    
    Future.delayed(Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          currentStep++;
        });
        _speakCurrentStep();
      }
    });
  }

  void _askAgain(String message) {
    flutterTts.speak(message);
    
    Future.delayed(Duration(seconds: 2), () {
      if (mounted) {
        _speakCurrentStep();
      }
    });
  }

  void _completeRegistration() {
    flutterTts.speak("Registration successful! Welcome to SmartSacco, $fullName!");
    
    Future.delayed(Duration(seconds: 3), () {
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/home');
      }
    });
  }

  void _restartRegistration() {
    setState(() {
      currentStep = 0;
      fullName = "";
      email = "";
      pin = "";
      password = "";
      role = "";
    });
    
    flutterTts.speak("Starting registration over.");
    
    Future.delayed(Duration(seconds: 2), () {
      if (mounted) {
        _speakCurrentStep();
      }
    });
  }

  void _showError(String message) {
    flutterTts.speak(message);
    Future.delayed(Duration(seconds: 2), () {
      if (mounted) {
        _speakCurrentStep();
      }
    });
  }

  String _getCurrentStepText() {
    switch (steps[currentStep]) {
      case "full_name":
        return "Say your full name";
      case "email":
        return "Say your email address";
      case "pin":
        return "Say your 4-digit PIN";
      case "password":
        return "Say your password";
      case "role":
        return "Say 'member' or 'admin'";
      case "confirm":
        return "Say 'yes' to confirm or 'no' to restart";
      default:
        return "Processing...";
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _pulseController.dispose();
    flutterTts.stop();
    speech.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.green.shade50,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.green.shade100, Colors.green.shade50],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo/Icon
            FadeTransition(
              opacity: _fadeAnimation,
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: Colors.green.shade600,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.green.shade300.withOpacity(0.5),
                      spreadRadius: 5,
                      blurRadius: 15,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.person_add,
                  size: 50,
                  color: Colors.white,
                ),
              ),
            ),

            SizedBox(height: 30),

            // Title
            FadeTransition(
              opacity: _fadeAnimation,
              child: Text(
                'Voice Registration',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.green.shade800,
                  letterSpacing: 1.2,
                ),
              ),
            ),

            SizedBox(height: 20),

            // Step indicator
            FadeTransition(
              opacity: _fadeAnimation,
              child: Text(
                'Step ${currentStep + 1} of ${steps.length}',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.green.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),

            SizedBox(height: 40),

            // Current step instruction
            FadeTransition(
              opacity: _fadeAnimation,
              child: Container(
                padding: EdgeInsets.all(20),
                margin: EdgeInsets.symmetric(horizontal: 20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.green.shade200.withOpacity(0.5),
                      spreadRadius: 2,
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  _getCurrentStepText(),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.green.shade700,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),

            SizedBox(height: 40),

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
                    'Listening... Speak clearly',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.green.shade700,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),

            if (!isListening)
              Column(
                children: [
                  Icon(
                    Icons.voice_chat,
                    size: 40,
                    color: Colors.green.shade600,
                  ),
                  SizedBox(height: 15),
                  Text(
                    'Ready to listen',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.green.shade700,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),

            SizedBox(height: 40),

            // Progress indicator
            FadeTransition(
              opacity: _fadeAnimation,
              child: Container(
                margin: EdgeInsets.symmetric(horizontal: 40),
                child: LinearProgressIndicator(
                  value: (currentStep + 1) / steps.length,
                  backgroundColor: Colors.green.shade200,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.green.shade600),
                  minHeight: 8,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}