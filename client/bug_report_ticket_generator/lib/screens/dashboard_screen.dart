import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'ticket_detail_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  List<dynamic> _tickets = [];
  String _errorMessage = '';
  bool _isLoading = true;

  Future<void> _fetchTickets() async {
    final String baseUrl = dotenv.env['BASE_URL'] ?? 'http://localhost:5000';

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/tickets'),
        headers: {'Content-Type': 'application/json'},
      );
      print('Fetch tickets response: ${response.statusCode} ${response.body}'); // Debug

      if (response.statusCode == 200) {
        final List<dynamic> fetchedTickets = jsonDecode(response.body);
        setState(() {
          _tickets = fetchedTickets;
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = 'Error: ${response.body}';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to connect to backend: $e';
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _fetchTickets();
  }

  String _getRelativeTime(String? createdAt) {
    if (createdAt == null || createdAt.isEmpty) {
      print('No created_at provided, returning "Just now"'); // Debug
      return 'Just now';
    }
    try {
      // Parse created_at as UTC
      DateTime ticketTime = DateTime.parse(createdAt + 'Z'); // Append 'Z' to ensure UTC
      DateTime now = DateTime.now().toUtc(); // Current time in UTC
      Duration diff = now.difference(ticketTime);
      print('Ticket time: $ticketTime (UTC), Now: $now (UTC), Diff: $diff'); // Debug

      if (diff.isNegative) {
        print('Warning: Ticket time is in the future: $ticketTime'); // Debug
        return 'Just now'; // Handle future timestamps
      }
      if (diff.inDays > 0) {
        return '${diff.inDays} day${diff.inDays > 1 ? 's' : ''} ago';
      } else if (diff.inHours > 0) {
        return '${diff.inHours} hour${diff.inHours > 1 ? 's' : ''} ago';
      } else if (diff.inMinutes > 0) {
        return '${diff.inMinutes} minute${diff.inMinutes > 1 ? 's' : ''} ago';
      } else {
        return 'Just now';
      }
    } catch (e) {
      print('Error parsing created_at "$createdAt": $e'); // Debug
      return 'Just now';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Dashboard')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_errorMessage.isNotEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Dashboard')),
        body: Center(child: Text(_errorMessage, style: const TextStyle(color: Colors.red))),
      );
    }

    // Compute stats (assuming all tickets are open; no status field yet)
    int totalTickets = _tickets.length;
    int openBugs = totalTickets; // Placeholder: assume all open
    int resolved = 0; // Placeholder: would need backend status
    int highPriority = _tickets.where((t) => (t['title'] ?? '').toLowerCase().contains('urgent')).length;

    // Recent tickets: sort by created_at (newest first)
    List<dynamic> recentTickets = List.from(_tickets)
      ..sort((a, b) => DateTime.parse(b['created_at'] + 'Z')
          .compareTo(DateTime.parse(a['created_at'] + 'Z')))
      ..take(5);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchTickets,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _fetchTickets,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Overview',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.deepPurple),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildStatCard('Total Tickets', totalTickets.toString(), Colors.teal),
                  _buildStatCard('Open Bugs', openBugs.toString(), Colors.orange),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildStatCard('Resolved', resolved.toString(), Colors.green),
                  _buildStatCard('High Priority', highPriority.toString(), Colors.red),
                ],
              ),
              const SizedBox(height: 32),
              const Text(
                'Recent Activity',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.deepPurple),
              ),
              const SizedBox(height: 16),
              if (recentTickets.isEmpty)
                const Text('No recent tickets yet.')
              else
                ...recentTickets.map((ticket) => ListTile(
                      leading: const Icon(Icons.history, color: Colors.deepPurple),
                      title: Text(ticket['title'] ?? 'Untitled'),
                      subtitle: Text(_getRelativeTime(ticket['created_at'])),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => TicketDetailScreen(ticket: ticket),
                          ),
                        );
                      },
                    )),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, Color color) {
    return Expanded(
      child: Card(
        color: color.withOpacity(0.1),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            children: [
              Text(
                value,
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: color),
              ),
              Text(title, style: TextStyle(color: color)),
            ],
          ),
        ),
      ),
    );
  }
}