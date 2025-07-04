import 'package:flutter/material.dart';
import '../widgets/dashboard_card.dart';
import 'home_page.dart';
import 'loans_plan.dart';
import 'users_page.dart';
import 'payment_page.dart';
import 'browsers_page.dart';

class DashboardPage extends StatelessWidget {
  final List<Map<String, String>> payments = const [
    {
      "refNo": "S001023",
      "payee": "Nikhil",
      "amount": "\$600.00",
      "penalty": "\$0.00"
    },
    {
      "refNo": "S001024",
      "payee": "Ajay",
      "amount": "\$600.00",
      "penalty": "\$0.00"
    },
  ];

  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: _buildDrawer(context),
      appBar: AppBar(
        title: const Text("SACCO SHIELD Dashboard"),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            _buildDashboardCards(),
            const SizedBox(height: 20),
            const Text(
              "Payment List",
              style: TextStyle(
                fontSize: 18, 
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            _buildPaymentsTable(),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          const DrawerHeader(
            decoration: BoxDecoration(
              color: Colors.blue,
            ),
            child: Text(
              "SACCO SHIELD", 
              style: TextStyle(
                fontSize: 20,
                color: Colors.white,
              ),
            ),
          ),
          _buildDrawerItem(
            context: context,
            icon: Icons.dashboard,
            title: "Home",
            page: const HomePage(),
          ),
          _buildDrawerItem(
            context: context,
            icon: Icons.credit_card,
            title: "Loans",
            page: LoansPage(),
          ),
          _buildDrawerItem(
            context: context,
            icon: Icons.payment,
            title: "Payments",
            page: const PaymentsPage(),
          ),
          _buildDrawerItem(
            context: context,
            icon: Icons.people,
            title: "Borrowers",
            page: BrowsersPage(),
          ),
          _buildDrawerItem(
            context: context,
            icon: Icons.supervised_user_circle,
            title: "Users",
            page: const UsersPage(),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text("Logout"),
            onTap: () {
              Navigator.of(context)
                  .pushNamedAndRemoveUntil('/home', (route) => false);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem({
    required BuildContext context,
    required IconData icon,
    required String title,
    required Widget page,
  }) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      onTap: () {
        Navigator.pop(context); // Close drawer
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => page),
        );
      },
    );
  }

  Widget _buildDashboardCards() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.5,
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      children: const [
        DashboardCard(
          title: "Payments Today",
          value: "0.00",
          color: Colors.blue,
          icon: Icons.payment,
        ),
        DashboardCard(
          title: "Borrowers",
          value: "2",
          color: Colors.green,
          icon: Icons.people,
        ),
        DashboardCard(
          title: "Active Loans",
          value: "2",
          color: Colors.amber,
          icon: Icons.assignment,
        ),
        DashboardCard(
          title: "Total Receivable",
          value: "6,289,600.00",
          color: Colors.purple,
          icon: Icons.attach_money,
        ),
      ],
    );
  }

  Widget _buildPaymentsTable() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columnSpacing: 12,
        // ignore: deprecated_member_use
        dataRowHeight: 48,
        headingRowHeight: 40,
        columns: const [
          DataColumn(label: _TableHeader("#")),
          DataColumn(label: _TableHeader("Loan Ref No")),
          DataColumn(label: _TableHeader("Payee", minWidth: 100)),
          DataColumn(label: _TableHeader("Amount")),
          DataColumn(label: _TableHeader("Penalty")),
          DataColumn(label: _TableHeader("Action")),
        ],
        rows: payments.map((p) => DataRow(
          cells: [
            DataCell(Text('${payments.indexOf(p) + 1}')),
            DataCell(_TableCell(p["refNo"]!)),
            DataCell(_TableCell(p["payee"]!)),
            DataCell(_TableCell(p["amount"]!)),
            DataCell(_TableCell(p["penalty"]!)),
            DataCell(
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit, color: Colors.blue, size: 20),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () {},
                  ),
                  const SizedBox(width: 4),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () {},
                  ),
                ],
              ),
            ),
          ],
        )).toList(),
      ),
    );
  }
}

class _TableHeader extends StatelessWidget {
  final String text;
  final double minWidth;

  const _TableHeader(this.text, {this.minWidth = 60});

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(minWidth: minWidth),
      child: Text(
        text,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _TableCell extends StatelessWidget {
  final String text;

  const _TableCell(this.text);

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: text,
      child: Text(
        text,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}