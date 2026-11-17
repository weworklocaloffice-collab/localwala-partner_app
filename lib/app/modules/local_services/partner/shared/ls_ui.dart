import 'package:flutter/material.dart';

/// Enterprise UI primitives shared across the Local Services partner screens.
/// Keep these dumb and stateless so every screen can compose them.

class LsStatusBadge extends StatelessWidget {
  const LsStatusBadge({super.key, required this.status});

  final String status;

  Color _color(BuildContext context) {
    switch (status.toUpperCase()) {
      case 'ACTIVE':
      case 'APPROVED':
      case 'COMPLETED':
      case 'SETTLED':
      case 'VERIFIED':
        return const Color(0xFF16A34A);
      case 'PENDING_PROVIDER':
      case 'PENDING':
      case 'ACCEPTED':
      case 'PROCESSING':
      case 'IN_PROGRESS':
        return const Color(0xFFD97706);
      case 'CANCELLED':
      case 'REJECTED':
      case 'FAILED':
      case 'NO_SHOW':
        return const Color(0xFFDC2626);
      case 'CONFIRMED':
      case 'REQUESTED':
        return const Color(0xFF2563EB);
      default:
        return const Color(0xFF64748B);
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color c = _color(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        status.replaceAll('_', ' '),
        style: TextStyle(color: c, fontSize: 11, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class LsKpiCard extends StatelessWidget {
  const LsKpiCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    this.color = const Color(0xFF2563EB),
    this.subtitle,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).textTheme.bodySmall?.color,
            ),
          ),
          if (subtitle != null) ...<Widget>[
            const SizedBox(height: 2),
            Text(
              subtitle!,
              style: TextStyle(
                fontSize: 11,
                color: Theme.of(context).textTheme.bodySmall?.color,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class LsEmptyState extends StatelessWidget {
  const LsEmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 36, color: Theme.of(context).colorScheme.primary),
            ),
            const SizedBox(height: 16),
            Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            if (subtitle != null) ...<Widget>[
              const SizedBox(height: 6),
              Text(
                subtitle!,
                textAlign: TextAlign.center,
                style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color),
              ),
            ],
            if (actionLabel != null && onAction != null) ...<Widget>[
              const SizedBox(height: 16),
              FilledButton(onPressed: onAction, child: Text(actionLabel!)),
            ],
          ],
        ),
      ),
    );
  }
}

class LsErrorState extends StatelessWidget {
  const LsErrorState({super.key, required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Icon(Icons.error_outline, size: 40, color: Color(0xFFDC2626)),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            FilledButton.tonal(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}

class LsSectionHeader extends StatelessWidget {
  const LsSectionHeader({super.key, required this.title, this.action, this.onAction});

  final String title;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 16, 4, 8),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          ),
          if (action != null && onAction != null)
            TextButton(onPressed: onAction, child: Text(action!)),
        ],
      ),
    );
  }
}

class LsLoadingSkeleton extends StatelessWidget {
  const LsLoadingSkeleton({super.key, this.lines = 3});

  final int lines;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: List<Widget>.generate(
          lines,
          (int i) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Container(
              height: 16,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
