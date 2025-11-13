import 'package:flutter/material.dart';

class ShutterButton extends StatelessWidget {
  const ShutterButton({super.key, required this.busy});
  final bool busy;

  @override
  Widget build(BuildContext context) => Container(
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          color: busy ? Colors.white54 : Colors.white,
          shape: BoxShape.circle,
        ),
        child: busy
            ? const Center(child: CircularProgressIndicator())
            : const Icon(Icons.camera, color: Colors.black),
      );
}
