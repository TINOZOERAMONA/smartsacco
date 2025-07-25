
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart' as firestore;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:smartsacco/pages/loan.dart';
//import 'package:smartsacco/pages/loanapplication.dart';
import 'package:smartsacco/models/momopayment.dart';
import 'package:smartsacco/pages/login.dart';
import 'package:smartsacco/pages/feedback.dart';
import 'package:smartsacco/models/notification.dart';
import 'package:smartsacco/models/transactionmodel.dart';

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

    // Check authentication before fetching data
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      memberId = user.uid;
      print('✅ User authenticated in initState: $memberId');
      _fetchTransactions();
    } else {
      print('❌ No authenticated user in initState');
      // Redirect to login if not authenticated
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _redirectToLogin();
      });
    }
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
        await Future.delayed(
          const Duration(milliseconds: 300),
        ); // let state update
        if (!_isListening && !_isSpeaking && !_isProcessing) {
          print("Starting listening after TTS");
          _startAutoListening();
        } else {
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
      "Option 1: Withdraw money"
      "Option 2: Apply for a loan."
      "Option 3: Check your total savings. "
      "Option 4: Check active loans and their cost. "
      "Option 5: Check your amount due. "
      "Option 6: Make a deposit - just say the amount and confirm. "
      "Option 7: Logout. "
      "Option 8: Repeat these options. "
      "Which option would you like to choose? Please say the number.",
    );
  }

  void _handleSpeechError() {
    if (!_isSpeaking) {
      _speakAndWaitForResponse(
        "Sorry, I couldn't understand you clearly. Let me repeat the options. "
        "Option 1: Withdraw money"
        "Option 2: Apply for a loan."
        "Option 3: Check savings. "
        "Option 4: Check loans. "
        "Option 5: Check amount due. "
        "Option 6: Make deposit - just say amount and confirm. "
        "Option 7: Logout. "
        "Option 8: Repeat options. "
        "Which option would you like?",
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
      print(
        'Cannot start listening: speechEnabled=$_speechEnabled, processing=$_isProcessing, speaking=$_isSpeaking, listening=$_isListening',
      );
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
                "Option 1: Withdraw money"
                "Option 2: Apply for a loan."
                "Option 3: Check savings. "
                "Option 4: Check loans. "
                "Option 5: Check amount due. "
                "Option 6: Make deposit. "
                "Option 7: Logout. "
                "Which option would you like?",
              );
            } else {
              _processVoiceCommand(_lastWords);
            }
          }
        },
        listenFor: const Duration(seconds: 15), // Longer listening time
        pauseFor: const Duration(seconds: 3), // Pause before auto-ending
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
        "There was a problem starting the microphone. Please try again.",
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

    // Ensure user is authenticated before processing any commands
    if (!_ensureUserAuthenticated()) {
      return;
    }

    if (_waitingForConfirmation) {
      _handleConfirmationResponse(command);
      return;
    }

    if (_currentVoiceAction == VoiceAction.deposit ||
        _currentVoiceAction == VoiceAction.withdraw) {
      _handleAmountInput(command);
      return;
    }

    // Check if this is a menu return response
    if (command.contains('yes') || command.contains('menu')) {
      _returnToMainMenu();
      return;
    }

    // Main menu options
    if (command.contains('1') || command.contains('one')) {
      _confirmChoice("1", "Withdraw money");
    } else if (command.contains('2') || command.contains('two')) {
      _confirmChoice("2", "Apply for a loan");
    } else if (command.contains('3') || command.contains('three')) {
      _confirmChoice("3", "check your savings");
    } else if (command.contains('2') || command.contains('four')) {
      _confirmChoice("4", "check your active loans");
    } else if (command.contains('5') || command.contains('five')) {
      _confirmChoice("5", "check your amount due");
    } else if (command.contains('6') || command.contains('six')) {
      _confirmChoice("6", "make a deposit");
    } else if (command.contains('7') || command.contains('seven')) {
      _confirmChoice("7", "logout");
    } else if (command.contains('8') ||
        command.contains('eight') ||
        command.contains('repeat')) {
      _repeatOptions();
    } else {
      _speakAndWaitForResponse(
        "I didn't understand that. Please say a number from 1 to 8. "
        "Option 1: Withdraw money"
        "Option 2: Apply for a loan."
        "Option 3: Check savings. "
        "Option 4: Check loans. "
        "Option 5: Check amount due. "
        "Option 6: Make deposit - just say amount and confirm. "
        "Option 7: Logout. "
        "Option 8: Repeat options. "
        "Which option?",
      );
    }
  }

  

  void _repeatOptions() {
    _speakAndWaitForResponse(
      "Here are your options again. "
      "Option 1: Withdraw money"
      "Option 2: Apply for a loan."
      "Option 3: Check your total savings. "
      "Option 4: Check active loans and their cost. "
      "Option 5: Check your amount due. "
      "Option 6: Make a deposit - just say the amount and confirm. "
      "Option 7: Logout. "
      "Option 8: Repeat these options. "
      "Which option would you like to choose?",
    );
  }

  void _confirmChoice(String option, String description) {
    setState(() {
      _waitingForConfirmation = true;
      _pendingConfirmation = option;
    });

    _speakAndWaitForResponse(
      "Did you say option $option to $description? Please say yes to confirm or no to go back to the menu.",
    );
  }

  void _handleConfirmationResponse(String response) {
    setState(() {
      _waitingForConfirmation = false;
    });

    if (response.contains('yes') || response.contains('confirm')) {
      // Handle the confirmed action based on current state
      if (_currentVoiceAction == VoiceAction.deposit ||
          _currentVoiceAction == VoiceAction.withdraw) {
        _handleConfirmation(); // Process the transaction
      } else {
        _executeChoice(_pendingConfirmation); // Execute the menu choice
      }
    } else if (response.contains('no') || response.contains('cancel')) {
      _handleCancellation(); // Cancel and return to appropriate state
    } else {
      // Didn't understand the response, ask again
      _speakAndWaitForResponse(
        "Please say yes to confirm or no to cancel. Did you want to proceed?",
      );
      setState(() {
        _waitingForConfirmation = true;
      });
    }
  }

  void _executeChoice(String option) {
    // Ensure user is authenticated before executing any choice
    if (!_ensureUserAuthenticated()) {
      return;
    }

    switch (option) {
      case "1":
        _speak(
          "For security reasons, to withdraw money please visit your SACCO administrator.",
        );
        break;
      case "2":
        _speak(
          "For security reasons, to apply for a loan please visit your SACCO administrator.",
        );
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

  void _speakSavingsInfo() async {
    _lastInformationType = 'savings';

    // Refresh savings data before speaking
    await _fetchSavingsData();

    final formattedSavings = _formatCurrencyForSpeech(_currentSavings);
    _speakAndWaitForResponse(
      "Your total savings balance is $formattedSavings Uganda Shillings. "
      "You have ${_savingsHistory.length} transactions in your savings history. "
      "Would you like to return to the main menu? Say yes to go back to the menu.",
    );
  }

  void _speakLoansInfo() async {
    _lastInformationType = 'loans';

    // Refresh loans data before speaking
    //await _fetchLoansData();

    final activeLoans = _loans
        .where((loan) => loan.status == 'Active')
        .toList();
    final overdueLoans = _loans
        .where((loan) => loan.status == 'Overdue')
        .toList();

    String message = "";

    if (activeLoans.isEmpty && overdueLoans.isEmpty) {
      message = "You currently have no active or overdue loans. ";
    } else {
      if (activeLoans.isNotEmpty) {
        final totalActiveCost = activeLoans.fold(
          0.0,
          (sum, loan) => sum + loan.remainingBalance,
        );
        message +=
            "You have ${activeLoans.length} active loans. "
            "Total remaining balance is ${_formatCurrencyForSpeech(totalActiveCost)} Uganda Shillings. ";
      }

      if (overdueLoans.isNotEmpty) {
        final totalOverdueCost = overdueLoans.fold(
          0.0,
          (sum, loan) => sum + loan.remainingBalance,
        );
        message +=
            "You have ${overdueLoans.length} overdue loans. "
            "Total overdue amount is ${_formatCurrencyForSpeech(totalOverdueCost)} Uganda Shillings. ";
      }
    }

    message +=
        "Would you like to return to the main menu? Say yes to go back to the menu.";
    _speakAndWaitForResponse(message);
  }

  void _speakDueInfo() async {
    _lastInformationType = 'due';

    // Refresh loans data before calculating due amount
    //await _fetchLoansData();

    final totalDue = _calculateTotalDue();
    String message = "";

    if (totalDue > 0) {
      message =
          "Your total amount due is ${_formatCurrencyForSpeech(totalDue)} Uganda Shillings. "
          "This includes all upcoming loan payments. ";
    } else {
      message = "You have no payments due at this time. ";
    }

    message +=
        "Would you like to return to the main menu? Say yes to go back to the menu.";
    _speakAndWaitForResponse(message);
  }

  void _initiateVoiceDeposit() {
    setState(() {
      _currentVoiceAction = VoiceAction.deposit;
    });

    _speakAndWaitForResponse(
      "To make a deposit, please tell me the amount you want to deposit. "
      "For example, say 'fifty thousand' for 50,000 Uganda Shillings. "
      "After you say the amount, I'll ask you to confirm once, then process the deposit immediately. "
      "What amount would you like to deposit?",
    );
  }

  void _handleAmountInput(String spokenAmount) {
    final amount = _parseSpokenAmount(spokenAmount);

    if (amount <= 0) {
      String actionType = _currentVoiceAction == VoiceAction.deposit
          ? "deposit"
          : "withdraw";
      _speakAndWaitForResponse(
        "I couldn't understand the amount. Please say the amount clearly. "
        "For example, say 'ten thousand' for 10,000 shillings. "
        "How much would you like to $actionType?",
      );
      return;
    }

    setState(() {
      _pendingAmount = amount;
      _waitingForConfirmation = true;
    });

    String actionType = _currentVoiceAction == VoiceAction.deposit
        ? "deposit"
        : "withdraw";
    _speakAndWaitForResponse(
      "You want to $actionType ${_formatCurrencyForSpeech(amount)} Uganda Shillings. "
      "Is this correct? Say yes to confirm or no to try again.",
    );
  }

  void _confirmLogout() {
    setState(() {
      _currentVoiceAction = VoiceAction.logout;
      _waitingForConfirmation = true;
    });

    _speakAndWaitForResponse(
      "Are you sure you want to logout? Say yes to confirm or no to go back to the menu.",
    );
  }

  void _handleConfirmation() {
    // Ensure user is authenticated before processing any confirmation
    if (!_ensureUserAuthenticated()) {
      return;
    }

    switch (_currentVoiceAction) {
      case VoiceAction.logout:
        _logout();
        break;
      case VoiceAction.deposit:
        // Process the deposit and wait for completion before speaking
        _processDepositAndSpeakResult(_pendingAmount, 'Voice Deposit');
        break;
      default:
        _returnToMainMenu();
    }
  }

  Future<void> _processDepositAndSpeakResult(
    double amount,
    String method,
  ) async {
    try {
      // Ensure user is authenticated before processing deposit
      if (!_ensureUserAuthenticated()) {
        return;
      }

      // Process the deposit
      await _processDeposit(amount, method);

      // Now speak the result with the updated balance from database
      _speakAndWaitForResponse(
        "Deposit successful. Your new balance is ${_formatCurrencyForSpeech(_currentSavings)} Uganda Shillings. "
        "Would you like to hear the main menu? Say yes for menu.",
      );
      _resetVoiceState();
    } catch (e) {
      print('❌ Error in deposit process: $e');
      _speakAndWaitForResponse(
        "Error processing deposit. Please try again or contact support. "
        "Would you like to hear the main menu? Say yes for menu.",
      );
      _resetVoiceState();
    }
  }

  void _handleCancellation() {
    if (_currentVoiceAction == VoiceAction.deposit ||
        _currentVoiceAction == VoiceAction.withdraw) {
      String actionType = _currentVoiceAction == VoiceAction.deposit
          ? "deposit"
          : "withdraw";
      setState(() {
        _waitingForConfirmation = false;
        _pendingAmount = 0;
        // Keep the current action so they can try again
      });
      _speakAndWaitForResponse(
        "Let's try again. How much would you like to $actionType?",
      );
    } else {
      _returnToMainMenu();
    }
  }

  void _returnToMainMenu() {
    _resetVoiceState();
    _speakAndWaitForResponse(
      "Returning to main menu. "
      "Option 1: Withdraw money"
      "Option 2: Apply for a loan"
      "Option 3: Check savings. "
      "Option 4: Check loans. "
      "Option 5: Check amount due. "
      "Option 6: Make deposit - just say amount and confirm. "
      "Option 7: Logout. "
      "Option 8: Repeat options. "
      "Which option would you like?",
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

  // Ensure user is authenticated before processing commands
  bool _ensureUserAuthenticated() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      print('❌ User not authenticated in voice command');
      _redirectToLogin();
      return false;
    }

    if (memberId.isEmpty) {
      memberId = user.uid;
      print('✅ Updated memberId from authenticated user: $memberId');
    }

    return true;
  }

  double _parseSpokenAmount(String spokenAmount) {
    // Enhanced number parsing
    spokenAmount = spokenAmount
        .toLowerCase()
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
    _speak(
      "Processing deposit of ${_formatCurrencyForSpeech(amount)} Uganda Shillings. Please wait...",
    );

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
                "Would you like to hear the main menu? Say yes for menu.",
              );
            } else {
              _speakAndWaitForResponse(
                "Deposit failed. Please try again. "
                "Would you like to hear the main menu? Say yes for menu.",
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
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        print('❌ No authenticated user found in _fetchTransactions');
        return;
      }

      memberId = user.uid;
      print('✅ User authenticated: $memberId');

      final memberDoc = await firestore.FirebaseFirestore.instance
          .collection('users')
          .doc(memberId)
          .get();

      if (memberDoc.exists) {
        setState(() {
          memberName = memberDoc['fullName'] ?? 'Member';
          memberEmail = memberDoc['email'] ?? 'member@sacco.com';
        });

        print('✅ Member data loaded: $memberName ($memberEmail)');

        await _fetchSavingsData();
        //await _fetchLoansData();
        await _fetchNotifications();
        await _fetchTransactionHistory();
      } else {
        print('❌ Member document not found for user: $memberId');
        // Create a basic member document if it doesn't exist
        await _createMemberDocument(user.uid);
      }
    } catch (e) {
      print('❌ Error in _fetchTransactions: $e');
    }
  }

  Future<void> _fetchTransactionHistory() async {
    try {
      // Ensure memberId is available
      if (memberId.isEmpty) {
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          memberId = user.uid;
        } else {
          print('❌ No authenticated user for transaction history');
          return;
        }
      }

      print('🔄 Fetching transaction history for member: $memberId');

      final transactionsSnapshot = await firestore.FirebaseFirestore.instance
          .collection('users')
          .doc(memberId)
          .collection('transactions')
          .orderBy('date', descending: true)
          .limit(50)
          .get();

      List<Transaction> transactions = [];

      for (var doc in transactionsSnapshot.docs) {
        final data = doc.data();

        // Validate transaction data
        if (data['amount'] != null && data['date'] != null) {
          transactions.add(
            Transaction(
              id: doc.id,
              amount: data['amount']?.toDouble() ?? 0,
              type: data['type'] ?? 'Unknown',
              date: data['date']?.toDate() ?? DateTime.now(),
              status: data['status'] ?? 'Pending',
              method: data['method'] ?? 'Unknown',
              reference: data['reference'],
              phoneNumber: data['phoneNumber'],
            ),
          );
        } else {
          print('⚠️ Skipping invalid transaction: ${doc.id}');
        }
      }

      if (mounted) {
        setState(() {
          _transactions.clear();
          _transactions.addAll(transactions);
        });
      }

      print('✅ Transaction history fetched:');
      print('   - Total transactions: ${transactions.length}');
      print(
        '   - Recent transactions: ${transactions.take(5).map((t) => '${t.type}: ${_formatCurrency(t.amount)}').join(', ')}',
      );
    } catch (e) {
      print('❌ Error fetching transaction history: $e');
      debugPrint('Error fetching transaction history: $e');
    }
  }

  Future<void> _fetchSavingsData() async {
    // Ensure memberId is available
    if (memberId.isEmpty) {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        memberId = user.uid;
      } else {
        print('❌ No authenticated user for savings data');
        return;
      }
    }

    final savingsSnapshot = await firestore.FirebaseFirestore.instance
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
          transactionId: doc['transactionId'] ?? '',
        ),
      );
    }

    setState(() {
      _currentSavings = totalSavings;
      _savingsHistory = history;
    });
  }

  // Future<void> _fetchLoansData() async {
  //   // Ensure memberId is available
  //   if (memberId.isEmpty) {
  //     final user = FirebaseAuth.instance.currentUser;
  //     if (user != null) {
  //       memberId = user.uid;
  //     } else {
  //       print('❌ No authenticated user for loans data');
  //       return;
  //     }
  //   }

  //   final loansSnapshot = await firestore.FirebaseFirestore.instance
  //       .collection('users')
  //       .doc(memberId)
  //       .collection('loans')
  //       .where('status', whereIn: ['Active', 'Overdue', 'Pending'])
  //       .get();

  //   List<Loan> loans = [];

  //   for (var doc in loansSnapshot.docs) {
  //     final payments = await firestore.FirebaseFirestore.instance
  //         .collection('users')
  //         .doc(memberId)
  //         .collection('loans')
  //         .doc(doc.id)
  //         .collection('payments')
  //         .get();

  //     loans.add(
  //       Loan(
  //         id: doc.id,
  //         amount: doc['amount']?.toDouble() ?? 0,
  //         remainingBalance: doc['remainingBalance']?.toDouble() ?? 0,
  //         disbursementDate: doc['disbursementDate']?.toDate() ?? DateTime.now(),
  //         dueDate: doc['dueDate']?.toDate() ?? DateTime.now(),
  //         status: doc['status'] ?? 'Pending',
  //         type: doc['type'] ?? 'Personal',
  //         interestRate: doc['interestRate']?.toDouble() ?? 12.0,
  //         totalRepayment: doc['totalRepayment']?.toDouble() ?? 0,
  //         repaymentPeriod: doc['repaymentPeriod']?.toInt() ?? 12,
  //         payments: payments.docs
  //             .map(
  //               (p) => Payment(
  //                 amount: p['amount']?.toDouble() ?? 0,
  //                 date: p['date']?.toDate() ?? DateTime.now(),
  //                 reference: p['reference'] ?? '',
  //               ),
  //             )
  //             .toList(),          
  //       ),
  //     );
  //   }

  //   setState(() {
  //     _loans = loans;
  //   });
  // }

  Future<void> _fetchNotifications() async {
    // Ensure memberId is available
    if (memberId.isEmpty) {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        memberId = user.uid;
      } else {
        print('❌ No authenticated user for notifications');
        return;
      }
    }

    final notificationsSnapshot = await firestore.FirebaseFirestore.instance
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
      // Ensure user is authenticated and memberId is available
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        print('❌ No authenticated user found');
        _speakAndWaitForResponse("Authentication error. Please login again.");
        return;
      }

      // Use the authenticated user's ID if memberId is empty
      final userId = memberId.isNotEmpty ? memberId : user.uid;

      print('🔄 Processing deposit: $amount via $method');
      print('👤 User ID: $userId');
      print(
        '💰 Current balance before deposit: ${_formatCurrency(_currentSavings)}',
      );

      // Generate unique transaction ID
      final transactionId = DateTime.now().millisecondsSinceEpoch.toString();
      print('📝 Transaction ID: $transactionId');

      // Start transaction batch for atomic operations
      final batch = firestore.FirebaseFirestore.instance.batch();

      // Add to savings collection
      final savingsRef = firestore.FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('savings')
          .doc(transactionId);

      batch.set(savingsRef, {
        'amount': amount,
        'date': firestore.FieldValue.serverTimestamp(),
        'type': 'Deposit',
        'method': method,
        'transactionId': transactionId,
        'userId': userId,
        'status': 'Completed',
      });

      // Add to transactions collection
      final transactionRef = firestore.FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('transactions')
          .doc(transactionId);

      batch.set(transactionRef, {
        'amount': amount,
        'date': firestore.FieldValue.serverTimestamp(),
        'type': 'Deposit',
        'status': 'Completed',
        'method': method,
        'transactionId': transactionId,
        'userId': userId,
        'description': 'Deposit via $method',
      });

      // Commit the batch
      await batch.commit();

      print('✅ Deposit transaction committed successfully');
      print('📊 Savings record created: ${savingsRef.id}');
      print('📊 Transaction record created: ${transactionRef.id}');

      // Update local state immediately for responsive UI
      setState(() {
        _currentSavings += amount;
      });

      print('💰 Balance updated locally: ${_formatCurrency(_currentSavings)}');

      // Refresh data from database to ensure consistency
      await _fetchSavingsData();
      await _fetchTransactionHistory();

      print('✅ Data refreshed successfully');
      print(
        '💰 Final balance from database: ${_formatCurrency(_currentSavings)}',
      );
      print('📊 Total transactions: ${_transactions.length}');
      print('📊 Total savings records: ${_savingsHistory.length}');

      // Verify the transaction was actually saved
      final verificationDoc = await firestore.FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('transactions')
          .doc(transactionId)
          .get();

      if (verificationDoc.exists) {
        print(
          '✅ Transaction verification successful: ${verificationDoc.data()}',
        );
      } else {
        print('❌ Transaction verification failed: Document not found');
      }
    } catch (e) {
      print('❌ Error processing deposit: $e');
      _speakAndWaitForResponse(
        "Error processing deposit. Please try again or contact support.",
      );
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

  void _redirectToLogin() {
    _speak("Authentication required. Redirecting to login.");
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginPage()),
      (route) => false,
    );
  }

  // Create a basic member document if it doesn't exist
  Future<void> _createMemberDocument(String userId) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      await firestore.FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .set({
            'uid': userId,
            'email': user.email ?? 'member@sacco.com',
            'fullName': user.displayName ?? 'Member',
            'createdAt': firestore.FieldValue.serverTimestamp(),
            'role': 'member',
            'status': 'active',
          });

      setState(() {
        memberName = user.displayName ?? 'Member';
        memberEmail = user.email ?? 'member@sacco.com';
      });

      print('✅ Created member document for user: $userId');
    } catch (e) {
      print('❌ Error creating member document: $e');
    }
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
            Icon(Icons.record_voice_over, size: 80, color: _primaryColor),
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
              style: GoogleFonts.poppins(fontSize: 18, color: _textSecondary),
            ),
            const SizedBox(height: 40),
            Container(
              padding: const EdgeInsets.all(20),
              margin: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: _isListening
                    ? Colors.green.withOpacity(0.1)
                    : Colors.white,
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

enum VoiceAction { none, deposit, withdraw, logout }