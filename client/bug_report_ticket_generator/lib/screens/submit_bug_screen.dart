import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'ticket_detail_screen.dart';

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