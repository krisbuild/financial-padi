import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class MoreHubScreen extends StatelessWidget {
  const MoreHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('More')),
      body: ListView(
        children: [
          _MoreTile(
            icon: Icons.bar_chart_outlined,
            title: 'Reports',
            subtitle: 'Spending breakdowns and trends',
            onTap: () => context.push('/reports'),
          ),
          _MoreTile(
            icon: Icons.event_note_outlined,
            title: 'Recurring Bills',
            subtitle: 'Subscriptions and bill reminders',
            onTap: () => context.push('/bills'),
          ),
          _MoreTile(
            icon: Icons.category_outlined,
            title: 'Categories',
            subtitle: 'Add, edit, or remove categories',
            onTap: () => context.push('/categories'),
          ),
          const Divider(height: 24),
          _MoreTile(
            icon: Icons.settings_outlined,
            title: 'Settings',
            subtitle: 'Currency, theme, and account',
            onTap: () => context.push('/settings'),
          ),
        ],
      ),
    );
  }
}

class _MoreTile extends StatelessWidget {
  const _MoreTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
        child: Icon(icon),
      ),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}
