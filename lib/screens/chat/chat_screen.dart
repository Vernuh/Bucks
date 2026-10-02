import 'package:flutter/material.dart';

/// Placeholder: the Bucks AI assistant is a separate, later feature.
/// This exists so the Chat card on the Bucks tab doesn't hit an
/// unregistered route.
class ChatScreen extends StatelessWidget {
  const ChatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Chat with Bucks')),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Chatting with Bucks is not available yet.',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
