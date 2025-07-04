
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import 'statement_screen.dart'; // Make sure this path matches the actual location of StatementScreen

class MemberDashboard extends StatefulWidget {
  final String userName;
  final String email;
  final double currentSavings;
  final double outstandingLoan;
  final String? profileImageUrl;

  const MemberDashboard({
    super.key,
    required this.userName,
    required this.email,
    required this.currentSavings,
    required this.outstandingLoan,
    this.profileImageUrl,
  });

  @override
  State<MemberDashboard> createState() => _MemberDashboardState();
}

class _MemberDashboardState extends State<MemberDashboard> {
  // Color Scheme
  final Color _primaryColor = Colors.blue;
  final Color _successColor = Colors.green;
  final Color _dangerColor = Colors.red;
  final Color _warningColor = Colors.amber;
  final Color _bgColor = const Color(0xFFF5F6FA);
  final Color _textSecondary = const Color(0xFF666666);

  // Navigation state
  int _currentIndex = 0;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  // Transaction data
  final List<Map<String, dynamic>> _recentTransactions = [
    {
      'amount': 50000,
      'type': 'Deposit',
      'date': DateTime.now().subtract(const Duration(hours: 2)),
      'icon': Icons.arrow_downward
    },
    {
      'amount': -20000,
      'type': 'Withdrawal',
      'date': DateTime.now().subtract(const Duration(days: 1)),
      'icon': Icons.arrow_upward
    },
    {
      'amount': 100000,
      'type': 'Deposit',
      'date': DateTime.now().subtract(const Duration(days: 3)),
      'icon': Icons.arrow_downward
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
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
      ),
      body: _getCurrentScreen(),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _getCurrentScreen() {
    switch (_currentIndex) {
      case 0: return _buildHomeScreen();
      case 1: return _buildPlaceholderScreen('Savings');
      case 2: return _buildPlaceholderScreen('Loans');
      case 3: return _buildPlaceholderScreen('Transactions');
      default: return _buildHomeScreen();
    }
  }

  Widget _buildBottomNavigationBar() {
    return BottomNavigationBar(
      currentIndex: _currentIndex,
      onTap: (index) {
        if (index == 4) {
          // Logout tapped
          Navigator.of(context)
              .pushNamedAndRemoveUntil('/home', (route) => false);
        } else {
          setState(() => _currentIndex = index);
        }
      },
      selectedItemColor: _primaryColor,
      unselectedItemColor: _textSecondary,
      type: BottomNavigationBarType.fixed,
      items: const [
        BottomNavigationBarItem(
            icon: Icon(Icons.dashboard), label: 'Dashboard'),
        BottomNavigationBarItem(icon: Icon(Icons.savings), label: 'Savings'),
        BottomNavigationBarItem(icon: Icon(Icons.money), label: 'Loans'),
        BottomNavigationBarItem(
            icon: Icon(Icons.swap_horiz), label: 'Transactions'),
        BottomNavigationBarItem(icon: Icon(Icons.logout), label: 'Logout'),
      ],
    );
  }

  Widget _buildHomeScreen() {
    return SingleChildScrollView(
      child: Column(
        children: [
          _buildHeaderSection(),
          _buildCalendarSection(),
          _buildStatsGrid(),
          _buildRecentActivity(),
        ],
      ),
    );
  }

  Widget _buildHeaderSection() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
      decoration: BoxDecoration(
        color: _primaryColor,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Welcome ,', style: GoogleFonts.poppins(color: Colors.white)),
          Text(widget.userName, 
              style: GoogleFonts.poppins(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              )),
          const SizedBox(height: 20),
          _buildQuickStatsCard(),
        ],
      ),
    );
  }

  Widget _buildCalendarSection() {
    return Padding(
      padding: const EdgeInsets.all(15),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: TableCalendar(
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: _focusedDay,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });
            },
            headerStyle: HeaderStyle(
              formatButtonVisible: false,
              titleCentered: true,
              titleTextStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            ),
            calendarStyle: CalendarStyle(
              todayDecoration: BoxDecoration(
                color: _primaryColor.withBlue(40),
                shape: BoxShape.circle,
              ),
              selectedDecoration: BoxDecoration(
                color: _primaryColor,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickStatsCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildStatItem('Savings', widget.currentSavings, _successColor),
            _buildStatItem('Loan', widget.outstandingLoan, _dangerColor),
            _buildStatItem('Due', 15000, _warningColor),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String title, double amount, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withRed(50),
            shape: BoxShape.circle,
          ),
          child: Icon(_getStatIcon(title), size: 18, color: color),
        ),
        const SizedBox(height: 8),
        Text(title, style: GoogleFonts.poppins(fontSize: 12, color: _textSecondary)),
        const SizedBox(height: 4),
        Text(_formatCurrency(amount), 
            style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: color)),
      ],
    );
  }

  Widget _buildStatsGrid() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15),
      child: GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 2,
        childAspectRatio: 1.2,
        crossAxisSpacing: 15,
        mainAxisSpacing: 15,
        children: [
          _buildStatCard('Total Savings', widget.currentSavings, Icons.savings, _successColor),
          _buildStatCard('Outstanding Loan', widget.outstandingLoan, Icons.money_off, _dangerColor),
          _buildStatCard('Last Deposit', 20000, Icons.arrow_downward, _primaryColor),
          _buildStatCard('Next Payment', 15000, Icons.payment, _warningColor),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, double amount, IconData icon, Color color) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blueAccent,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 20, color: color),
            ),
            const SizedBox(height: 12),
            Text(title, style: GoogleFonts.poppins(fontSize: 12, color: _textSecondary)),
            const SizedBox(height: 4),
            Text(_formatCurrency(amount), 
                style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentActivity() {
    return Padding(
      padding: const EdgeInsets.all(15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Recent Activity', 
                  style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600)),
              TextButton(
                onPressed: () => _navigateToStatementScreen(context),
                child: Text('View All', style: GoogleFonts.poppins(color: _primaryColor)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ..._recentTransactions.map((t) => _buildTransactionItem((t['amount'] as num).toDouble(), t['type'], t['date'], t['icon'])),
        ],
      ),
    );
  }

  Widget _buildTransactionItem(double amount, String type, DateTime date, IconData icon) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        leading: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: amount > 0 ? _successColor.withAlpha(50) : _dangerColor.withRed(50),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 18, color: amount > 0 ? _successColor : _dangerColor),
        ),
        title: Text(type, style: GoogleFonts.poppins(fontWeight: FontWeight.w500)),
        subtitle: Text(DateFormat('MMM d, h:mm a').format(date), 
            style: GoogleFonts.poppins(fontSize: 11, color: _textSecondary)),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(_formatCurrency(amount), 
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  color: amount > 0 ? _successColor : _dangerColor,
                )),
            if (amount > 0) Text('Completed', 
                style: GoogleFonts.poppins(fontSize: 10, color: _successColor)),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholderScreen(String title) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.account_balance, size: 60, color: _primaryColor),
          const SizedBox(height: 16),
          Text('$title Feature', 
              style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Text('Coming soon', style: GoogleFonts.poppins(color: _textSecondary)),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => _navigateToStatementScreen(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: _primaryColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text('View Statements', style: GoogleFonts.poppins(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  IconData _getStatIcon(String title) {
    switch (title) {
      case 'Savings': return Icons.savings;
      case 'Loan': return Icons.money_off;
      case 'Due': return Icons.calendar_today;
      default: return Icons.info;
    }
  }

  String _getAppBarTitle() {
    switch (_currentIndex) {
      case 0: return 'Dashboard';
      case 1: return 'Savings';
      case 2: return 'Loans';
      case 3: return 'Transactions';
      default: return 'Dashboard';
    }
  }

  void _navigateToStatementScreen(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => StatementScreen(
          userName: widget.userName,
          memberId: 'MEMBER_${widget.email.hashCode}',
        ),
      ),
    );
  }


  String _formatCurrency(double amount) {
    return NumberFormat.currency(symbol: 'UGX ', decimalDigits: 0).format(amount);
  }
}

