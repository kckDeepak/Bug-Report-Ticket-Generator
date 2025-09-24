// lib/main.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';  // Optional, for loading API URL from .env

void main() async {
  // Load .env if using dotenv (add .env file with BASE_URL=http://localhost:5000)
  await dotenv.load(fileName: ".env");
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bug Ticket Generator',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          primary: Colors.deepPurple,
          secondary: Colors.teal,
          background: Colors.grey[100],
        ),
        useMaterial3: true,
        scaffoldBackgroundColor: Colors.grey[50],
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.deepPurple,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.deepPurple,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        cardTheme: CardThemeData( // Changed from CardTheme to CardThemeData
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 4,
          color: Colors.white,
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.deepPurple, width: 2),
          ),
          labelStyle: const TextStyle(color: Colors.deepPurple),
        ),
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bug Report Ticket Generator'),
        centerTitle: true,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.bug_report, size: 100, color: Colors.deepPurple),
            const SizedBox(height: 40),
            ElevatedButton.icon(
              icon: const Icon(Icons.add),
              label: const Text('Submit New Bug Report'),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SubmitBugScreen()),
                );
              },
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              icon: const Icon(Icons.list),
              label: const Text('View All Tickets'),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ViewTicketsScreen()),
                );
              },
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              icon: const Icon(Icons.dashboard),
              label: const Text('Dashboard'),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const DashboardScreen()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class SubmitBugScreen extends StatefulWidget {
  const SubmitBugScreen({super.key});

  @override
  _SubmitBugScreenState createState() => _SubmitBugScreenState();
}

class _SubmitBugScreenState extends State<SubmitBugScreen> {
  final TextEditingController _bugController = TextEditingController();
  String _responseMessage = '';
  Map<String, dynamic>? _createdTicket;
  bool _isLoading = false;

  Future<void> _createTicket() async {
    final String baseUrl = dotenv.env['BASE_URL'] ?? 'http://localhost:5000';
    final String bugText = _bugController.text;

    if (bugText.isEmpty) {
      setState(() {
        _responseMessage = 'Please enter a bug description.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _responseMessage = '';
      _createdTicket = null;
    });

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/create_ticket'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'bug': bugText}),
      );

      setState(() {
        _isLoading = false;
      });

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _responseMessage = data['message'];
          _createdTicket = data['ticket'];
        });
        // Navigate to ticket detail screen after creation
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TicketDetailScreen(ticket: _createdTicket!),
          ),
        );
      } else {
        setState(() {
          _responseMessage = 'Error: ${response.body}';
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _responseMessage = 'Failed to connect to backend: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Submit Bug Report'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Describe the Bug',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.deepPurple),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _bugController,
              decoration: const InputDecoration(
                labelText: 'Enter messy bug description',
                hintText: 'Describe the issue in detail...',
              ),
              maxLines: 8,
            ),
            const SizedBox(height: 24),
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else
              ElevatedButton(
                onPressed: _createTicket,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                ),
                child: const Text('Create Ticket'),
              ),
            const SizedBox(height: 16),
            if (_responseMessage.isNotEmpty)
              Text(
                _responseMessage,
                style: TextStyle(color: _createdTicket != null ? Colors.green : Colors.red),
              ),
          ],
        ),
      ),
    );
  }
}

class ViewTicketsScreen extends StatefulWidget {
  const ViewTicketsScreen({super.key});

  @override
  _ViewTicketsScreenState createState() => _ViewTicketsScreenState();
}

class _ViewTicketsScreenState extends State<ViewTicketsScreen> {
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
      final response = await http.get(Uri.parse('$baseUrl/tickets'));

      if (response.statusCode == 200) {
        setState(() {
          _tickets = jsonDecode(response.body);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('All Tickets'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchTickets,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage.isNotEmpty
              ? Center(child: Text(_errorMessage, style: const TextStyle(color: Colors.red)))
              : RefreshIndicator(
                  onRefresh: _fetchTickets,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _tickets.length,
                    itemBuilder: (context, index) {
                      final ticket = _tickets[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 16),
                        child: ListTile(
                          leading: const Icon(Icons.bug_report, color: Colors.deepPurple),
                          title: Text(
                            ticket['title'],
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            ticket['description'].toString().substring(0, 100) + '...',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          trailing: const Icon(Icons.arrow_forward_ios),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => TicketDetailScreen(ticket: ticket),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}

class TicketDetailScreen extends StatelessWidget {
  final Map<String, dynamic> ticket;

  const TicketDetailScreen({super.key, required this.ticket});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ticket Details'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Title:',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.deepPurple),
                ),
                const SizedBox(height: 8),
                Text(ticket['title']),
                const SizedBox(height: 24),
                const Text(
                  'Description:',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.deepPurple),
                ),
                const SizedBox(height: 8),
                Text(ticket['description']),
                const SizedBox(height: 24),
                const Text(
                  'Steps to Reproduce:',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.deepPurple),
                ),
                const SizedBox(height: 8),
                Text(ticket['steps']),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // For demo, showing placeholder stats. In real app, fetch from backend.
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
      ),
      body: Padding(
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
                _buildStatCard('Total Tickets', '42', Colors.teal),
                _buildStatCard('Open Bugs', '15', Colors.orange),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildStatCard('Resolved', '27', Colors.green),
                _buildStatCard('High Priority', '5', Colors.red),
              ],
            ),
            const SizedBox(height: 32),
            const Text(
              'Recent Activity',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.deepPurple),
            ),
            const SizedBox(height: 16),
            // Placeholder for recent tickets
            const ListTile(
              leading: Icon(Icons.history, color: Colors.deepPurple),
              title: Text('Bug #42 resolved'),
              subtitle: Text('2 hours ago'),
            ),
            const ListTile(
              leading: Icon(Icons.history, color: Colors.deepPurple),
              title: Text('New ticket created'),
              subtitle: Text('1 day ago'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, Color color) {
    return Card(
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
    );
  }
}