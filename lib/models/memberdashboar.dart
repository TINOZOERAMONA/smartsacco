import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:smartsacco/models/member_home_screen.dart';
import 'package:smartsacco/models/savings_screen.dart';
import 'package:smartsacco/models/transaction_screen.dart';
import 'package:smartsacco/models/notification_screen.dart';
import 'package:smartsacco/pages/login.dart';
import 'package:smartsacco/pages/feedback.dart';
import 'package:smartsacco/pages/loanapplication.dart';

class MemberDashboard extends StatefulWidget {
  const MemberDashboard({super.key});

  @override
  _MemberDashboardState createState() => _MemberDashboardState();
}

class _MemberDashboardState extends State<MemberDashboard> {
  int _currentIndex = 0;
  int _unreadNotifications = 0;
  String memberId = '';
  String memberName = '';
  String memberEmail = '';
  String memberPhone = '';

  // Color scheme
  final Color _primaryColor = const Color(0xFF3366CC);
  final Color _accentColor = const Color(0xFFFFA726);
  final Color _dangerColor = const Color(0xFFF44336);

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        memberId = user.uid;
        final memberDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(memberId)
            .get();

        final data = memberDoc.data();
        setState(() {
          memberName = data?['fullName'] ?? 'Member';
          memberEmail = data?['email'] ?? 'member@sacco.com';
          memberPhone = data?['phone'] ?? '';
        });
      }
    } catch (e) {
      debugPrint('Initialization error: $e');
    }
  }

  void _logout() {
    FirebaseAuth.instance.signOut();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginPage()),
      (route) => false,
    );



  }

  void _showLoanApplication() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LoanApplicationScreen(
          memberId: memberId,
          memberSavings: 0, // Will be updated in home screen
          onSubmit: (application) {}, // Handled in home screen
        ),
      ),
    );
  }

  void _submitFeedback() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SaccoFeedbackPage()),
    );
  }

  String _getAppBarTitle() {
    switch (_currentIndex) {
      case 0: return 'Dashboard';
      case 1: return 'Savings';
      case 2: return 'Transactions';
      case 3: return 'Notifications';
      default: return 'Dashboard';
    }
  }


Widget _buildNotificationBadge() {
  return Stack(
    children: [
      IconButton(
        icon: const Icon(Icons.notifications),
        onPressed: () => setState(() => _currentIndex = 3),
      ),
      if (_unreadNotifications > 0)
        Positioned(
          right: 8,
          top: 8,
          child: Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: _dangerColor,
              borderRadius: BorderRadius.circular(10),
            ),
            constraints: const BoxConstraints(minWidth: 16, minHeight: 16), // Move constraints outside decoration
            child: Text(
              '$_unreadNotifications',
              style: const TextStyle(color: Colors.white, fontSize: 10),
              textAlign: TextAlign.center,
            ),
          ),
        ),
    ],
  );
}

  Widget _getCurrentScreen() {
    switch (_currentIndex) {
      case 0: 
        return HomeScreen(
          memberId: memberId,
          memberName: memberName,
          memberEmail: memberEmail,
          memberPhone: memberPhone,
          onLoanApplication: _showLoanApplication,
          onNotificationsUpdate: (count) => setState(() => _unreadNotifications = count),
        );
      case 1: 
        return SavingsScreen(memberId: memberId);
      case 2: 
        return TransactionsScreen(memberId: memberId);
      case 3: 
        return NotificationsScreen(
          memberId: memberId,
          onNotificationsRead: (count) => setState(() => _unreadNotifications = count),
        );
      default: return HomeScreen(
        memberId: memberId,
        memberName: memberName,
        memberEmail: memberEmail,
        memberPhone: memberPhone,
        onLoanApplication: _showLoanApplication,
        onNotificationsUpdate: (count) => setState(() => _unreadNotifications = count),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Text(
          _getAppBarTitle(),
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        backgroundColor: _primaryColor,
        elevation: 0,
        actions: [
          if (_currentIndex == 0) _buildNotificationBadge(),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
            tooltip: 'Logout',
          ),
        ],
      ),
      body: _getCurrentScreen(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        selectedItemColor: _primaryColor,
        unselectedItemColor: const Color(0xFF666666),
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        elevation: 8,
        selectedLabelStyle: GoogleFonts.poppins(fontSize: 12),
        unselectedLabelStyle: GoogleFonts.poppins(fontSize: 12),
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.savings),
            label: 'Savings',
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.history),
            label: 'Transactions',
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.notifications),
            label: 'Notifications',
          ),
        ],
      ),
      floatingActionButton: _currentIndex == 0
          ? FloatingActionButton(
              onPressed: _showLoanApplication,
              backgroundColor: _primaryColor,
              child: const Icon(Icons.add, color: Colors.white),
            )
          : _currentIndex == 3
              ? FloatingActionButton(
                  onPressed: _submitFeedback,
                  backgroundColor: _accentColor,
                  child: const Icon(Icons.feedback, color: Colors.white),
                )
              : null,
    );
  }
}