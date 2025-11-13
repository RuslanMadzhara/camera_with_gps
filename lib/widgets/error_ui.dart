import 'package:flutter/material.dart';

class ErrorUi extends StatelessWidget {
  const ErrorUi({super.key, required this.msg, required this.retry});
  final String msg;
  final VoidCallback retry;

  @override
  Widget build(BuildContext context) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(msg,
                style: const TextStyle(color: Colors.white),
                textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: retry, child: const Text('Retry')),
          ],
        ),
      );
}