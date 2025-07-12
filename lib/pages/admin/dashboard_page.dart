import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

// Import your pages
import 'overview.dart';
import 'loans_page.dart';

class AdminMainPage extends StatefulWidget {
  const AdminMainPage({super.key});

  @override
  AdminMainPageState createState() => AdminMainPageState();
}

class AdminMainPageState extends State<AdminMainPage> {
  int _selectedIndex = 0;

  final List<String> _pageTitles = [
    'Overview',
    'Loan Applications',
  ];

  Widget _getPage(int index) {
    switch (index) {
      case 0:
        return const OverviewPage();
      case 1:
        return const LoanPage();  // Your loan list page
      default:
        return const Center(child: Text('Page not found'));
    }
  }

  void _onSelectPage(int index) {
    setState(() {
      _selectedIndex = index;
      Navigator.pop(context);  // Close the drawer after selection
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
