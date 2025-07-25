import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class MembersPage extends StatefulWidget {
  const MembersPage({super.key});

  @override
  State<MembersPage> createState() => _MembersPageState();
}

class _MembersPageState extends State<MembersPage> {
  late Future<List<Map<String, dynamic>>> _membersFuture;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadMembers();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadMembers() async {
    _membersFuture = _fetchMembers();
  }

  Future<List<Map<String, dynamic>>> _fetchMembers() async {
    final usersSnapshot = await FirebaseFirestore.instance.collection('users').get();
    final loansSnapshot = await FirebaseFirestore.instance.collection('loans').get();

    final Map<String, double> totalApprovedLoans = {};
    final Map<String, int> loanCounts = {};

    for (var loanDoc in loansSnapshot.docs) {
      final data = loanDoc.data();
      final userId = data['userId'];
      final status = data['status']?.toString().toLowerCase() ?? '';
      final remaining = (data['remainingBalance'] is num) 
          ? data['remainingBalance'].toDouble() 
          : 0.0;

      if (status == 'approved' && remaining > 0) {
        totalApprovedLoans[userId] = (totalApprovedLoans[userId] ?? 0) + remaining;
        loanCounts[userId] = (loanCounts[userId] ?? 0) + 1;
      }
    }

    return usersSnapshot.docs.map((doc) {
      final data = doc.data();
      final id = doc.id;

      return {
        'id': id,
        'fullName': data['fullName'] ?? 'No Name',
        'email': data['email'] ?? 'No Email',
        'phone': data['phone'] ?? 'N/A',
        'joinDate': data['joinDate']?.toDate(),
        'totalLoan': totalApprovedLoans[id] ?? 0.0,
        'loanCount': loanCounts[id] ?? 0,
        'profileImage': data['profileImage'],
      };
    }).toList();
  }

  Widget _buildMemberCard(Map<String, dynamic> member) {
    final hasLoans = (member['totalLoan'] ?? 0) > 0;
    final joinDate = member['joinDate'] as DateTime?;
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _navigateToMemberDetails(member['id']),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: Colors.blue.shade100,
                    backgroundImage: member['profileImage'] != null 
                        ? NetworkImage(member['profileImage']) 
                        : null,
                    child: member['profileImage'] == null
                        ? Text(member['fullName'][0].toUpperCase())
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          member['fullName'],
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          member['email'],
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (hasLoans) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${member['loanCount']} loan${member['loanCount'] > 1 ? 's' : ''}',
                        style: TextStyle(
                          color: Colors.orange.shade800,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 12),
              _buildDetailRow('', member['phone']),
              if (joinDate != null)
                _buildDetailRow('Member since', DateFormat.yMMMd().format(joinDate)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToMemberDetails(String userId) {
    Navigator.pushNamed(
      context,
      '/member_details',
      arguments: {'userId': userId},
    );
  }

  Future<void> _refreshData() async {
    setState(() {
      _membersFuture = _fetchMembers();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SACCO Members'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshData,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Search members',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: _membersFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                
                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, size: 48, color: Colors.red),
                        const SizedBox(height: 16),
                        const Text(
                          'Failed to load members',
                          style: TextStyle(fontSize: 18),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          snapshot.error.toString(),
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _refreshData,
                          child: const Text('Try Again'),
                        ),
                      ],
                    ),
                  );
                }
                
                final members = snapshot.data!;
                final filteredMembers = members.where((member) {
                  return member['fullName'].toString().toLowerCase().contains(_searchQuery) ||
                      member['email'].toString().toLowerCase().contains(_searchQuery) ||
                      member['phone'].toString().toLowerCase().contains(_searchQuery);
                }).toList();
                
                if (filteredMembers.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.people_alt_outlined, size: 48, color: Colors.grey),
                        const SizedBox(height: 16),
                        Text(
                          _searchQuery.isEmpty
                              ? 'No members registered'
                              : 'No matching members found',
                          style: const TextStyle(fontSize: 18),
                        ),
                      ],
                    ),
                  );
                }
                
                return RefreshIndicator(
                  onRefresh: _refreshData,
                  child: ListView.builder(
                    padding: const EdgeInsets.only(bottom: 16),
                    itemCount: filteredMembers.length,
                    itemBuilder: (context, index) => 
                        _buildMemberCard(filteredMembers[index]),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}