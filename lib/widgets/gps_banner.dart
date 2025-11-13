import 'package:flutter/material.dart';

class GpsBanner extends StatelessWidget {
  const GpsBanner({super.key, required this.message});
  final String message;

  @override
  Widget build(BuildContext context) => SafeArea(
        child: Container(
          width: double.infinity,
          margin: const EdgeInsets.only(top: 16),
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          color: const Color.fromRGBO(255, 0, 0, 0.8),
          child: Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
      );
}