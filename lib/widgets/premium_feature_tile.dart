import 'package:flutter/material.dart';

class PremiumFeatureTile extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;

  const PremiumFeatureTile({
    required this.title,
    required this.description,
    required this.icon,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(
          icon,
          color: Theme.of(context).colorScheme.primary,
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Text(
          description,
          style: const TextStyle(fontSize: 14),
        ),
      ),
    );
  }
}
