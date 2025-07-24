import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';

// Import your pages
import 'enhanced_dashboard_page.dart';
import 'loans_page.dart';
import 'member_page.dart';
import 'adminBalance.dart';
import 'active_loan_page.dart';
import 'pending_loan_page.dart';
import 'overview.dart';

class AdminMainPage extends StatefulWidget {
  const AdminMainPage({super.key});

  @override
  AdminMainPageState createState() => AdminMainPageState();
}

class AdminMainPageState extends State<AdminMainPage> {
  int _selectedIndex = 0;

  final List<AdminMenuItem> _menuItems = [
    AdminMenuItem(
      title: 'Dashboard',
      icon: Icons.dashboard,
      pageIndex: 0,
      description: 'Overview and analytics',
    ),
    AdminMenuItem(
      title: 'Loan Applications',
      icon: Icons.credit_card,
      pageIndex: 1,
      description: 'Manage loan requests',
    ),
    AdminMenuItem(
      title: 'Active Loans',
      icon: Icons.check_circle,
      pageIndex: 2,
      description: 'View active loans',
    ),
    AdminMenuItem(
      title: 'Pending Loans',
      icon: Icons.pending_actions,
      pageIndex: 3,
      description: 'Review pending applications',
    ),
    AdminMenuItem(
      title: 'Overview',
      icon: Icons.analytics,
      pageIndex: 4,
      description: 'System overview and reports',
    ),
    AdminMenuItem(
      title: 'Members',
      icon: Icons.people,
      pageIndex: 5,
      description: 'Member management',
    ),
    AdminMenuItem(
      title: 'Admin Balance',
      icon: Icons.account_balance,
      pageIndex: 6,
      description: 'Financial overview',
    ),
  ];

  Widget _getPage(int index) {
    switch (index) {
      case 0:
        return const EnhancedAdminDashboard();
      case 1:
        return const LoanPage();
      case 2:
        return const ActiveLoansPage();
      case 3:
        return const PendingLoansPage();
      case 4:
        return const OverviewPage();
      case 5:
        return const MembersPage();
      case 6:
        return const AdminBalancePage();
      default:
        return const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text(
                'Page not found',
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
            ],
          ),
        );
    }
  }

  void _onSelectPage(int index) {
    setState(() {
      _selectedIndex = index;
    });
    Navigator.pop(context); // Close the drawer after selection
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
          'SmartSacco Admin - ${_menuItems[_selectedIndex].title}',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF007C91),
        foregroundColor: Colors.white,
        elevation: 2,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications),
            tooltip: 'Notifications',
            onPressed: () {
              // TODO: Implement notifications
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Notifications coming soon!')),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Settings',
            onPressed: () {
              // TODO: Implement settings
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Settings coming soon!')),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: _onLogoutPressed,
          ),
        ],
      ),
      drawer: _buildDrawer(),
      body: _getPage(_selectedIndex),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      child: Column(
        children: [
          _buildDrawerHeader(),
          Expanded(child: _buildDrawerBody()),
          _buildDrawerFooter(),
        ],
      ),
    );
  }

  Widget _buildDrawerHeader() {
    return DrawerHeader(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF007C91), Color(0xFF005A6B)],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.admin_panel_settings,
              color: Colors.white,
              size: 32,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Admin Panel',
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'SmartSacco Management',
            style: GoogleFonts.poppins(
              color: Colors.white.withOpacity(0.9),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerBody() {
    return ListView.builder(
          padding: EdgeInsets.zero,
      itemCount: _menuItems.length,
      itemBuilder: (context, index) {
        final item = _menuItems[index];
        final isSelected = _selectedIndex == index;

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: isSelected
                ? const Color(0xFF007C91).withOpacity(0.1)
                : Colors.transparent,
          ),
          child: ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFF007C91)
                    : Colors.grey.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                item.icon,
                color: isSelected ? Colors.white : Colors.grey[600],
                size: 20,
              ),
            ),
            title: Text(
              item.title,
              style: GoogleFonts.poppins(
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? const Color(0xFF007C91) : Colors.grey[800],
              ),
            ),
            subtitle: Text(
              item.description,
              style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600]),
            ),
            selected: isSelected,
            onTap: () => _onSelectPage(item.pageIndex),
            trailing: isSelected
                ? const Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: Color(0xFF007C91),
                  )
                : null,
          ),
        );
      },
    );
  }

  Widget _buildDrawerFooter() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        border: Border(top: BorderSide(color: Colors.grey[300]!)),
      ),
      child: Column(
        children: [
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.logout, color: Colors.red, size: 20),
            ),
            title: Text(
              'Logout',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w500,
                color: Colors.red,
              ),
            ),
            subtitle: Text(
              'Sign out of admin panel',
              style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600]),
            ),
            onTap: _onLogoutPressed,
          ),
          const SizedBox(height: 8),
          Text(
            'SmartSacco Admin v1.0',
            style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }
}

class AdminMenuItem {
  final String title;
  final IconData icon;
  final int pageIndex;
  final String description;

  AdminMenuItem({
    required this.title,
    required this.icon,
    required this.pageIndex,
    required this.description,
  });
}
