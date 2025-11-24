import 'package:flutter/material.dart';
import 'share_page.dart';

class TokenPage extends StatefulWidget {
  const TokenPage({super.key});

  @override
  State<TokenPage> createState() => _TokenPageState();
}

class _TokenPageState extends State<TokenPage> {
  final _tokenController = TextEditingController();

  void _join() {
    final token = _tokenController.text.trim();
    if (token.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Enter your LiveKit token')));
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => SharePage(token: token)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Enter LiveKit Token')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _tokenController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'LiveKit Token',
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _join,
              icon: const Icon(Icons.login),
              label: const Text('Join Room'),
            ),
          ],
        ),
      ),
    );
  }
}
