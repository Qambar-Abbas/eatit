import 'package:flutter/material.dart';

class VotingTitles extends StatelessWidget {
  final String title;
  final String subtitle;

  const VotingTitles({super.key, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(title, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
      const SizedBox(height: 4),
      Text(subtitle, style: Theme.of(context).textTheme.titleMedium),
    ],
  );
}
