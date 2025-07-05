import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

// ✅ Only importing the 3 required pages
import 'admin/overview.dart';
import 'admin/loans_page.dart';
import 'admin/loan_approval_page.dart';

class AdminMainPage extends StatefulWidget {
  const AdminMainPage({Key? key}) : super(key: key);

  @override
  _AdminMainPageState createState() => _AdminMainPageState();
}

class _AdminMainPageState extends State<AdminMainPage> {
  int _selectedIndex = 0;

  final List<String> _pageTitles = [
    'Overview',
    'Loan Applications',
    'Loan Approval',
  ];

  // Dummy data for demonstration — replace with actual data if needed
  final String loanId = 'defaultLoanId';
  final Map<String, dynamic>? loanData = null;

  Widget _getPage(int index) {
    switch (index) {
      case 0:
        return const OverviewPage();
      case 1:
        return LoansPage();
      case 2:
        return LoanApprovalPage(
          loanId: loanId,
          loanData: loanData ?? {},
        );
      default:
        return const Center(child: Text('Page not found'));
    }
  }

  void _onSelectPage(int index) {
    setState(() {
      _selectedIndex = index;
      Navigator.pop(context);
    });
  }

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
  }

  void _onLogoutPressed() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _logout();
            },
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'SmartLoan SACCO - ${_pageTitles[_selectedIndex]}',
        ),
        backgroundColor: const Color(0xFF007C91),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: _onLogoutPressed,
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(
                color: Color(0xFF007C91),
              ),
              child: Text(
                'Admin Menu',
                style: TextStyle(color: Colors.white, fontSize: 24),
              ),
            ),
            _buildDrawerItem(0, Icons.dashboard),
            _buildDrawerItem(1, Icons.credit_card),
            _buildDrawerItem(2, Icons.check_circle),
          ],
        ),
      ),
      body: _getPage(_selectedIndex),
    );
  }

  Widget _buildDrawerItem(int index, IconData icon) {
    return ListTile(
      leading: Icon(icon),
      title: Text(_pageTitles[index]),
      selected: _selectedIndex == index,
      onTap: () => _onSelectPage(index),
    );
  }
}
