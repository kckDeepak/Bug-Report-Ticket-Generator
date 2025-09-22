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
        primarySwatch: Colors.blue,
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
        title: const Text('Bug Ticket App'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SubmitBugScreen()),
                );
              },
              child: const Text('Submit Bug Report'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ViewTicketsScreen()),
                );
              },
              child: const Text('View Tickets'),
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

  Future<void> _createTicket() async {
    final String baseUrl = dotenv.env['BASE_URL'] ?? 'http://localhost:5000';  // Use .env or default to localhost
    final String bugText = _bugController.text;

    if (bugText.isEmpty) {
      setState(() {
        _responseMessage = 'Please enter a bug description.';
      });
      return;
    }

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/create_ticket'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'bug': bugText}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _responseMessage = data['message'];
          _createdTicket = data['ticket'];
        });
      } else {
        setState(() {
          _responseMessage = 'Error: ${response.body}';
        });
      }
    } catch (e) {
      setState(() {
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
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _bugController,
              decoration: const InputDecoration(
                labelText: 'Enter messy bug description',
                border: OutlineInputBorder(),
              ),
              maxLines: 5,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _createTicket,
              child: const Text('Create Ticket'),
            ),
            const SizedBox(height: 20),
            Text(_responseMessage),
            if (_createdTicket != null) ...[
              const SizedBox(height: 20),
              const Text('Created Ticket:'),
              Text('Title: ${_createdTicket!['title']}'),
              Text('Description: ${_createdTicket!['description']}'),
              Text('Steps: ${_createdTicket!['steps']}'),
            ],
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
    final String baseUrl = dotenv.env['BASE_URL'] ?? 'http://localhost:5000';  // Use .env or default to localhost

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
        _errorMessage = 'Failed to connect to backend: $e';
        _isLoading = false;
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
        title: const Text('View Tickets'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage.isNotEmpty
              ? Center(child: Text(_errorMessage))
              : ListView.builder(
                  itemCount: _tickets.length,
                  itemBuilder: (context, index) {
                    final ticket = _tickets[index];
                    return ListTile(
                      title: Text(ticket['title']),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Description: ${ticket['description']}'),
                          Text('Steps: ${ticket['steps']}'),
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}