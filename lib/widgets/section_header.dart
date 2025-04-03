import 'package:flutter/material.dart';

class SectionHeader extends StatelessWidget {
  final String title;
  final VoidCallback onSeeAll;
  final Widget? trailing;

  const SectionHeader({
    super.key,
    required this.title,
    required this.onSeeAll,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          Row(
            children: [
              if (trailing != null) trailing!,
              TextButton(
                onPressed: onSeeAll,
                child: const Text('See All'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}