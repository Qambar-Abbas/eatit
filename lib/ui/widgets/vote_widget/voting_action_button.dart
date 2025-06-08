import 'package:flutter/material.dart';

class VotingActionButton extends StatelessWidget {
  final VoidCallback onPressed;

  const VotingActionButton({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) => Center(
    child: ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      ),
      child: const Text('Send Vote'),
    ),
  );
}
