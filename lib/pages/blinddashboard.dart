import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:smartsacco/pages/loan.dart';
import 'package:smartsacco/pages/loanapplication.dart';
import 'package:smartsacco/models/momopayment.dart';
import 'package:smartsacco/pages/login.dart';
import 'package:smartsacco/pages/feedback.dart';
import 'package:smartsacco/models/notification.dart';

class SavingsHistory {
  final double amount;
  final DateTime date;
  final String type;
  final String transactionId;

  SavingsHistory({
    required this.amount,
    required this.date,
    required this.type,
    required this.transactionId,
  });
}

class VoiceMemberDashboard extends StatefulWidget {
  const VoiceMemberDashboard({super.key});

  @override
  State<VoiceMemberDashboard> createState() => _VoiceMemberDashboardState();
}

class _VoiceMemberDashboardState extends State<VoiceMemberDashboard> {
  final Color _savingsColor = const Color(0xFF4CAF50);
  final Color _activeLoansColor = const Color(0xFF9C27B0);
  final Color _overdueColor = const Color(0xFFFF9800);
  final Color _totalDueColor = const Color(0xFF009688);
  final Color _primaryColor = Colors.blue;
  final Color _bgColor = const Color(0xFFF5F6FA);
  final Color _textSecondary = const Color.fromARGB(255, 8, 56, 71);

  // Voice components
  late FlutterTts _flutterTts;
  late stt.SpeechToText _speechToText;
  bool _isListening = false;
  bool _speechEnabled = false;
  String _lastWords = '';
  bool _isProcessing = false;
  bool _isSpeaking = false;
  String _enteredPin = '';
  bool _waitingForPin = false;


  int _currentIndex = 0;
  int _unreadNotifications = 0;
  String memberId = '';
  String memberName = '';
  String memberEmail = '';

  double _currentSavings = 0;
  List<Loan> _loans = [];
  List<AppNotification> _notifications = [];
  List<SavingsHistory> _savingsHistory = [];
  final List<Transaction> _transactions = [];

  // Voice interaction state
  VoiceAction _currentVoiceAction = VoiceAction.none;
  String _pendingConfirmation = '';
  double _pendingAmount = 0;
  bool _waitingForConfirmation = false;
  String _lastInformationType = '';

  @override
  void initState() {
    super.initState();
    _initializeSpeech();
    _initializeTts();
    _fetchTransactions();
  }

  void _initializeSpeech() async {
    _speechToText = stt.SpeechToText();
    try {
      _speechEnabled = await _speechToText.initialize(
        onError: (error) {
          print('Speech recognition error: $error');
          setState(() {
            _isListening = false;
          });
          _handleSpeechError();
        },
        onStatus: (status) {
          print('Speech recognition status: $status');
          if (status == 'notListening') {
            setState(() {
              _isListening = false;
            });
          }
        },
      );
      print('Speech recognition initialized: $_speechEnabled');
    } catch (e) {
      print('Error initializing speech recognition: $e');
      _speechEnabled = false;
    }
    setState(() {});
  }

  void _initializeTts() async {
    _flutterTts = FlutterTts();
    try {
      await _flutterTts.setLanguage("en-US");
      await _flutterTts.setSpeechRate(0.5);
      await _flutterTts.setVolume(1.0);
      await _flutterTts.setPitch(1.0);
      
      // Set completion handler to automatically start listening
      _flutterTts.setCompletionHandler(() async {
        setState(() {
          _isSpeaking = false;
          _isProcessing = false;
        });
        await Future.delayed(const Duration(milliseconds: 300)); // let state update
        if (!_isListening && !_isSpeaking && !_isProcessing) {
          print("Starting listening after TTS");
          _startAutoListening();
        }else{
          print("Not starting listening. Conditions not met.");
        }
        });
        
      _flutterTts.setStartHandler(() {
        setState(() {
          _isSpeaking = true;
        });
      });

      _flutterTts.setErrorHandler((msg) {
        print('TTS Error: $msg');
        setState(() {
          _isSpeaking = false;
        });
      });
      
      // Welcome message with automatic listening
      Future.delayed(const Duration(seconds: 2), () {
        _speakWelcomeMessage();
      });
    } catch (e) {
      print('Error initializing TTS: $e');
    }
    Future.delayed(const Duration(seconds: 6), () {
      if (!_isListening && !_isSpeaking && !_isProcessing) {
        _startAutoListening();
      }
    });

  }

  void _speakWelcomeMessage() {
    _speakAndWaitForResponse(
      "Welcome to Members Dashboard. I will read you the menu options. "
      "After I finish, I will listen for your choice. "
      "Option 3: Check your total savings. "
      "Option 4: Check active loans and their cost. "
      "Option 5: Check your amount due. "
      "Option 6: Make a deposit. "
      "Option 7: Logout. "
      "Option 8: Repeat these options. "
      "Which option would you like to choose? Please say the number."
    );
  }

  void _handleSpeechError() {
    if (!_isSpeaking) {
      _speakAndWaitForResponse(
        "Sorry, I couldn't understand you clearly. Let me repeat the options. "
        "Option 3: Check savings. "
        "Option 4: Check loans. "
        "Option 5: Check amount due. "
        "Option 6: Make deposit. "
        "Option 7: Logout. "
        "Option 8: Repeat options. "
        "Which option would you like?"
      );
    }
  }

  Future<void> _speak(String text) async {
    if (_isSpeaking) {
      await _flutterTts.stop();
    }
    
    setState(() {
      _isProcessing = true;
      _isSpeaking = true;
    });
    
    try {
      await _flutterTts.speak(text);
    } catch (e) {
      print('Error speaking: $e');
      setState(() {
        _isSpeaking = false;
        _isProcessing = false;
      });
    }
  }
  Future<void> _speakAndWaitForResponse(String text) async {
    await _speak(text);
    // The TTS completion handler will automatically start listening again
  }

  void _startAutoListening() {
    if (!_speechEnabled || _isProcessing || _isSpeaking || _isListening) {
      print('Cannot start listening: speechEnabled=$_speechEnabled, processing=$_isProcessing, speaking=$_isSpeaking, listening=$_isListening');
      return;
    }

    setState(() {
      _isListening = true;
      _isProcessing = false;
      _lastWords = '';
    });

    print('Starting to listen...');

    try {
      _speechToText.listen(
        onResult: (result) {
          setState(() {
            _lastWords = result.recognizedWords.toLowerCase();
          });

          print('Recognized: ${result.recognizedWords}');

          if (result.finalResult) {
            print('Final result: ${result.recognizedWords}');

            if (_lastWords.trim().isEmpty) {
              _speakAndWaitForResponse(
                "Sorry, I didn’t hear anything. Please try again. "
                "Option 3: Check savings. "
                "Option 4: Check loans. "
                "Option 5: Check amount due. "
                "Option 6: Make deposit. "
                "Option 7: Logout. "
                "Which option would you like?"
              );
            } else {
              _processVoiceCommand(_lastWords);
            }
          }
        },
        listenFor: const Duration(seconds: 15), // Longer listening time
        pauseFor: const Duration(seconds: 3),   // Pause before auto-ending
        partialResults: true,
        localeId: "en_US",
        onSoundLevelChange: (level) {
          print('Sound level: $level');
        },
      );
    } catch (e) {
      print('Error starting listening: $e');
      setState(() {
        _isListening = false;
      });
      _speakAndWaitForResponse(
        "There was a problem starting the microphone. Please try again."
      );
    }
  }


  void _stopListening() {
    if (_isListening) {
      _speechToText.stop();
      setState(() {
        _isListening = false;
      });
      print('Stopped listening');
    }
  }

  void _processVoiceCommand(String command) {
    _stopListening();
    command = command.trim();
    print('Processing command: $command');

    if (_waitingForPin) {
      _handlePinInput(command);
      return;
    }

    
    if (_waitingForConfirmation) {
      _handleConfirmationResponse(command);
      return;
    }
    
    if (_currentVoiceAction == VoiceAction.deposit || _currentVoiceAction == VoiceAction.withdraw) {
      _handleAmountInput(command);
      return;
    }
    
    // Check if this is a menu return response
    if (command.contains('yes') || command.contains('menu')) {
      _returnToMainMenu();
      return;
    }
    
    // Main menu options
    if (command.contains('3') || command.contains('three')) {
      _confirmChoice("3", "check your total savings");
    } else if (command.contains('2') || command.contains('four')) {
      _confirmChoice("4", "check your active loans");
    } else if (command.contains('5') || command.contains('five')) {
      _confirmChoice("5", "check your amount due");
    } else if (command.contains('6') || command.contains('six')) {
      _confirmChoice("6", "make a deposit");
    } else if (command.contains('7') || command.contains('seven')) {
      _confirmChoice("7", "logout");
    } else if (command.contains('8') || command.contains('eight') || command.contains('repeat')) {
      _repeatOptions();
    } else {
      _speakAndWaitForResponse(
        "I didn't understand that. Please say a number from 3 to 8. "
        "Option 3: Check savings. "
        "Option 4: Check loans. "
        "Option 5: Check amount due. "
        "Option 6: Make deposit. "
        "Option 7: Logout. "
        "Option 8: Repeat options. "
        "Which option?"
      );
    }
  }

  void _handlePinInput(String command) {
    final cleanedPin = command.replaceAll(RegExp(r'[^0-9]'), '');

    if (cleanedPin.length == 4) {
      _verifyPinAndDeposit(cleanedPin);
    } else {
      _speakAndWaitForResponse("I didn’t catch a valid 4-digit PIN. Please try again.");
    }
  }

  Future<void> _verifyPinAndDeposit(String pin) async {
    _waitingForPin = false;

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(memberId)
          .get();

      final storedPin = doc['pin'] ?? '';

      if (storedPin == pin) {
        _processDeposit(_pendingAmount, 'Voice PIN');
        _speakAndWaitForResponse(
          "Deposit successful. Your new balance is ${_formatCurrencyForSpeech(_currentSavings + _pendingAmount)} Uganda Shillings. Say yes to return to the main menu."
        );
        _resetVoiceState();
      } else {
        _speakAndWaitForResponse("Incorrect PIN. Please say your 4-digit PIN again.");
        _waitingForPin = true;
      }
    } catch (e) {
      print("PIN verification error: $e");
      _speakAndWaitForResponse("Error verifying PIN. Please try again.");
    }
  }



  void _repeatOptions() {
    _speakAndWaitForResponse(
      "Here are your options again. "
      "Option 3: Check your total savings. "
      "Option 4: Check active loans and their cost. "
      "Option 5: Check your amount due. "
      "Option 6: Make a deposit. "
      "Option 7: Logout. "
      "Option 8: Repeat these options. "
      "Which option would you like to choose?"
    );
  }

  void _confirmChoice(String option, String description) {
    setState(() {
      _waitingForConfirmation = true;
      _pendingConfirmation = option;
    });
    
    _speakAndWaitForResponse(
      "Did you say option $option to $description? Please say yes to confirm or no to go back to the menu."
    );
  }

  void _handleConfirmationResponse(String response) {
    setState(() {
      _waitingForConfirmation = false;
    });
    
    if (response.contains('yes') || response.contains('confirm')) {
      // Handle the confirmed action based on current state
      if (_currentVoiceAction == VoiceAction.deposit || _currentVoiceAction == VoiceAction.withdraw) {
        _handleConfirmation(); // Process the transaction
      } else {
        _executeChoice(_pendingConfirmation); // Execute the menu choice
      }
    } else if (response.contains('no') || response.contains('cancel')) {
      _handleCancellation(); // Cancel and return to appropriate state
    } else {
      // Didn't understand the response, ask again
      _speakAndWaitForResponse(
        "Please say yes to confirm or no to cancel. Did you want to proceed?"
      );
      setState(() {
        _waitingForConfirmation = true;
      });
    }
  }

  void _executeChoice(String option) {
    switch (option) {
      case "3":
        _speakSavingsInfo();
        break;
      case "4":
        _speakLoansInfo();
        break;
      case "5":
        _speakDueInfo();
        break;
      case "6":
        _initiateVoiceDeposit();
        break;
      case "7":
        _confirmLogout();
        break;
    }
  }

  void _speakSavingsInfo() {
    _lastInformationType = 'savings';
    final formattedSavings = _formatCurrencyForSpeech(_currentSavings);
    _speakAndWaitForResponse(
      "Your total savings balance is $formattedSavings Uganda Shillings. "
      "You have ${_savingsHistory.length} transactions in your savings history. "
      "Would you like to return to the main menu? Say yes to go back to the menu."
    );
  }

  void _speakLoansInfo() {
    _lastInformationType = 'loans';
    final activeLoans = _loans.where((loan) => loan.status == 'Active').toList();
    final overdueLoans = _loans.where((loan) => loan.status == 'Overdue').toList();
    
    String message = "";
    
    if (activeLoans.isEmpty && overdueLoans.isEmpty) {
      message = "You currently have no active or overdue loans. ";
    } else {
      if (activeLoans.isNotEmpty) {
        final totalActiveCost = activeLoans.fold(0.0, (sum, loan) => sum + loan.remainingBalance);
        message += "You have ${activeLoans.length} active loans. "
            "Total remaining balance is ${_formatCurrencyForSpeech(totalActiveCost)} Uganda Shillings. ";
      }
      
      if (overdueLoans.isNotEmpty) {
        final totalOverdueCost = overdueLoans.fold(0.0, (sum, loan) => sum + loan.remainingBalance);
        message += "You have ${overdueLoans.length} overdue loans. "
            "Total overdue amount is ${_formatCurrencyForSpeech(totalOverdueCost)} Uganda Shillings. ";
      }
    }
    
    message += "Would you like to return to the main menu? Say yes to go back to the menu.";
    _speakAndWaitForResponse(message);
  }

  void _speakDueInfo() {
    _lastInformationType = 'due';
    final totalDue = _calculateTotalDue();
    String message = "";
    
    if (totalDue > 0) {
      message = "Your total amount due is ${_formatCurrencyForSpeech(totalDue)} Uganda Shillings. "
          "This includes all upcoming loan payments. ";
    } else {
      message = "You have no payments due at this time. ";
    }
    
    message += "Would you like to return to the main menu? Say yes to go back to the menu.";
    _speakAndWaitForResponse(message);
  }

  void _initiateVoiceDeposit() {
    setState(() {
      _currentVoiceAction = VoiceAction.deposit;
    });
    
    _speakAndWaitForResponse(
      "To make a deposit, please tell me the amount you want to deposit. "
      "For example, say 'fifty thousand' for 50,000 Uganda Shillings. "
      "What amount would you like to deposit?"
    );
  }

  
    
    
  void _handleAmountInput(String spokenAmount) {
    final amount = _parseSpokenAmount(spokenAmount);
    
    if (amount <= 0) {
      String actionType = _currentVoiceAction == VoiceAction.deposit ? "deposit" : "withdraw";
      _speakAndWaitForResponse(
        "I couldn't understand the amount. Please say the amount clearly. "
        "For example, say 'ten thousand' for 10,000 shillings. "
        "How much would you like to $actionType?"
      );
      return;
    }
    
    setState(() {
      _pendingAmount = amount;
      _waitingForConfirmation = true;
    });
    
    String actionType = _currentVoiceAction == VoiceAction.deposit ? "deposit" : "withdraw";
    _speakAndWaitForResponse(
      "You want to $actionType ${_formatCurrencyForSpeech(amount)} Uganda Shillings. "
      "Is this correct? Say yes to confirm or no to try again."
    );
  }

  void _confirmLogout() {
    setState(() {
      _currentVoiceAction = VoiceAction.logout;
      _waitingForConfirmation = true;
    });
    
    _speakAndWaitForResponse(
      "Are you sure you want to logout? Say yes to confirm or no to go back to the menu."
    );
  }

  void _handleConfirmation() {
    switch (_currentVoiceAction) {
      case VoiceAction.logout:
        _logout();
        break;
      case VoiceAction.deposit:
        // Request the PIN instead of processing payment
        _waitingForPin = true;
        _speakAndWaitForResponse("Please say your 4-digit PIN to confirm the deposit.");
        break;
      default:
        _returnToMainMenu();
    }

    if (_currentVoiceAction != VoiceAction.deposit) {
      _resetVoiceState();
    }
  }


  void _handleCancellation() {
    if (_currentVoiceAction == VoiceAction.deposit || _currentVoiceAction == VoiceAction.withdraw) {
      String actionType = _currentVoiceAction == VoiceAction.deposit ? "deposit" : "withdraw";
      setState(() {
        _waitingForConfirmation = false;
        _pendingAmount = 0;
        // Keep the current action so they can try again
      });
      _speakAndWaitForResponse(
        "Let's try again. How much would you like to $actionType?"
      );
    } else {
      _returnToMainMenu();
    }
  }

  void _returnToMainMenu() {
    _resetVoiceState();
    _speakAndWaitForResponse(
      "Returning to main menu. "
      "Option 3: Check savings. "
      "Option 4: Check loans. "
      "Option 5: Check amount due. "
      "Option 6: Make deposit. "
      "Option 7: Logout. "
      "Option 8: Repeat options. "
      "Which option would you like?"
    );
  }

  void _resetVoiceState() {
    setState(() {
      _currentVoiceAction = VoiceAction.none;
      _pendingAmount = 0;
      _waitingForConfirmation = false;
      _pendingConfirmation = '';
      _lastInformationType = '';
    });
  }

  double _parseSpokenAmount(String spokenAmount) {
    // Enhanced number parsing
    spokenAmount = spokenAmount.toLowerCase()
        .replaceAll(' ', '')
        .replaceAll('thousand', '000')
        .replaceAll('million', '000000')
        .replaceAll('hundred', '00')
        .replaceAll('fifty', '50')
        .replaceAll('forty', '40')
        .replaceAll('thirty', '30')
        .replaceAll('twenty', '20')
        .replaceAll('ten', '10')
        .replaceAll('nine', '9')
        .replaceAll('eight', '8')
        .replaceAll('seven', '7')
        .replaceAll('six', '6')
        .replaceAll('five', '5')
        .replaceAll('four', '4')
        .replaceAll('three', '3')
        .replaceAll('two', '2')
        .replaceAll('one', '1')
        .replaceAll(RegExp(r'[^0-9]'), '');
    
    return double.tryParse(spokenAmount) ?? 0;
  }

  void _processVoiceDeposit(double amount) {
    _speak("Processing deposit of ${_formatCurrencyForSpeech(amount)} Uganda Shillings. Please wait...");
    
    // Use mobile money payment
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MomoPaymentPage(
          amount: amount,
          onPaymentComplete: (success) {
            if (success) {
              _processDeposit(amount, 'Mobile Money');
              _speakAndWaitForResponse(
                "Deposit successful. Your new balance is ${_formatCurrencyForSpeech(_currentSavings + amount)} Uganda Shillings. "
                "Would you like to hear the main menu? Say yes for menu."
              );
            } else {
              _speakAndWaitForResponse(
                "Deposit failed. Please try again. "
                "Would you like to hear the main menu? Say yes for menu."
              );
            }
            _resetVoiceState();
          },
        ),
      ),
    );
  }

  

  String _formatCurrencyForSpeech(double amount) {
    final formatter = NumberFormat('#,###');
    return formatter.format(amount);
  }

  // Keep all existing Firebase methods unchanged
  Future<void> _fetchTransactions() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      memberId = user.uid;

      final memberDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(memberId)
          .get();

      setState(() {
        memberName = memberDoc['fullName'] ?? 'Member';
        memberEmail = memberDoc['email'] ?? 'member@sacco.com';
      });

      _fetchSavingsData();
      _fetchLoansData();
      _fetchNotifications();
    }
  }
  
  Future<void> _fetchSavingsData() async {
    final savingsSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(memberId)
        .collection('savings')
        .orderBy('date', descending: true)
        .get();

    double totalSavings = 0;
    List<SavingsHistory> history = [];

    for (var doc in savingsSnapshot.docs) {
      final amount = doc['amount']?.toDouble() ?? 0;
      totalSavings += amount;
      history.add(
        SavingsHistory(
          amount: amount,
          date: doc['date'].toDate(),
          type: doc['type'] ?? 'Deposit',
          transactionId: doc.id,
        ),
      );
    }

    setState(() {
      _currentSavings = totalSavings;
      _savingsHistory = history;
    });
  }

  Future<void> _fetchLoansData() async {
    final loansSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(memberId)
        .collection('loans')
        .where('status', whereIn: ['Active', 'Overdue', 'Pending'])
        .get();

    List<Loan> loans = [];

    for (var doc in loansSnapshot.docs) {
      final payments = await FirebaseFirestore.instance
          .collection('users')
          .doc(memberId)
          .collection('loans')
          .doc(doc.id)
          .collection('payments')
          .get();

      loans.add(
        Loan(
          id: doc.id,
          amount: doc['amount']?.toDouble() ?? 0,
          remainingBalance: doc['remainingBalance']?.toDouble() ?? 0,
          disbursementDate: doc['disbursementDate']?.toDate() ?? DateTime.now(),
          dueDate: doc['dueDate']?.toDate() ?? DateTime.now(),
          status: doc['status'] ?? 'Pending',
          type: doc['type'] ?? 'Personal',
          interestRate: doc['interestRate']?.toDouble() ?? 12.0,
          totalRepayment: doc['totalRepayment']?.toDouble() ?? 0,
          repaymentPeriod: doc['repaymentPeriod']?.toInt() ?? 12,
          payments: payments.docs
              .map(
                (p) => Payment(
                  amount: p['amount']?.toDouble() ?? 0,
                  date: p['date']?.toDate() ?? DateTime.now(),
                  reference: p['reference'] ?? '',
                ),
              )
              .toList(),
        ),
      );
    }

    setState(() {
      _loans = loans;
    });
  }

  Future<void> _fetchNotifications() async {
    final notificationsSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(memberId)
        .collection('notifications')
        .orderBy('date', descending: true)
        .limit(10)
        .get();

    int unread = 0;
    List<AppNotification> notifications = [];

    for (var doc in notificationsSnapshot.docs) {
      final isRead = doc['isRead'] ?? false;
      if (!isRead) unread++;

      notifications.add(
        AppNotification(
          id: doc.id,
          title: doc['title'] ?? 'Notification',
          message: doc['message'] ?? '',
          date: doc['date']?.toDate() ?? DateTime.now(),
          type: NotificationType.values[doc['type'] ?? 0],
          isRead: isRead,
          actionUrl: doc['actionUrl'],
        ),
      );
    }

    setState(() {
      _notifications = notifications;
      _unreadNotifications = unread;
    });
  }

  Future<void> _processDeposit(double amount, String method) async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(memberId)
          .collection('savings')
          .add({
            'amount': amount,
            'date': DateTime.now(),
            'type': 'Deposit',
            'method': method,
          });

      await FirebaseFirestore.instance
          .collection('users')
          .doc(memberId)
          .collection('transactions')
          .add({
            'amount': amount,
            'date': DateTime.now(),
            'type': 'Deposit',
            'status': 'Completed',
            'method': method,
          });

      setState(() {
        _currentSavings += amount;
      });

      _fetchSavingsData();
    } catch (e) {
      _speakAndWaitForResponse("Error processing deposit. Please try again or contact support.");
    }
  }

  
  void _logout() {
    _speak("Logging out. Thank you for using our service.");
    FirebaseAuth.instance.signOut();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginPage()),
      (route) => false,
    );
  }

  double _calculateTotalDue() {
    return _loans.fold(0, (acc, loan) => acc + loan.nextPaymentAmount);
  }

  String _formatCurrency(double amount) {
    return NumberFormat.currency(
      symbol: 'UGX ',
      decimalDigits: 0,
    ).format(amount);
  }

  // Manual control methods for testing
  void _manualStartListening() {
    if (_speechEnabled && !_isListening && !_isSpeaking) {
      _startAutoListening();
    }
  }

  void _manualStopListening() {
    _stopListening();
  }

  
  @override
  void dispose() {
    _flutterTts.stop();
    _speechToText.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      appBar: AppBar(
        title: Text(
          'Voice Dashboard',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        backgroundColor: _primaryColor,
        elevation: 0,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.record_voice_over,
              size: 80,
              color: _primaryColor,
            ),
            const SizedBox(height: 20),
            Text(
              'Voice Member Dashboard',
              style: GoogleFonts.poppins(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: _primaryColor,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Welcome, $memberName',
              style: GoogleFonts.poppins(
                fontSize: 18,
                color: _textSecondary,
              ),
            ),
            const SizedBox(height: 40),
            Container(
              padding: const EdgeInsets.all(20),
              margin: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: _isListening ? Colors.green.withOpacity(0.1) : Colors.white,
                borderRadius: BorderRadius.circular(15),
                border: Border.all(
                  color: _isListening ? Colors.green : Colors.transparent,
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.2),
                    spreadRadius: 2,
                    blurRadius: 5,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Icon(
                    _isListening ? Icons.mic : Icons.mic_off,
                    size: 40,
                    color: _isListening ? Colors.green : Colors.grey,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _isListening ? 'Listening...' : 'Ready to Listen',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: _isListening ? Colors.green : Colors.grey,
                    ),
                  ),
                  if (_isListening && _lastWords.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: Text(
                        'Heard: "$_lastWords"',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

enum VoiceAction {
  none,
  deposit,
  withdraw,
  logout,
}