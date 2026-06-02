import 'package:flutter/material.dart';

import '../models/notification.dart';

class NotificationTile extends StatelessWidget {
  const NotificationTile({
    super.key,
    required this.notification,
    required this.onTap,
    this.onMarkAsRead,
  });

  final NotificationModel notification;
  final VoidCallback onTap;
  final VoidCallback? onMarkAsRead;

  String _formatDate(BuildContext context, DateTime value) {
    final local = value.toLocal();
    final now = DateTime.now();
    final diff = now.difference(local);

    if (diff.inMinutes < 1) return 'Ara mateix';
    if (diff.inHours < 1) return 'Fa ${diff.inMinutes} min';
    if (diff.inDays < 1) return 'Fa ${diff.inHours} h';

    return '${local.day.toString().padLeft(2, '0')}/${local.month.toString().padLeft(2, '0')}/${local.year}';
  }

  @override
  Widget build(BuildContext context) {
    final unread = !notification.isRead;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: unread ? const Color(0xFFFFF7EF) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: unread ? const Color(0xFFFFB36B) : const Color(0xFFE2E8F0),
          ),
        ),
        child: ListTile(
          leading: Stack(
            alignment: Alignment.topRight,
            children: [
              CircleAvatar(
                backgroundColor: const Color(0xFFFF7A1A).withOpacity(0.12),
                child: Icon(notification.type.icon, color: const Color(0xFFFF7A1A)),
              ),
              if (unread)
                Container(
                  width: 10,
                  height: 10,
                  decoration: const BoxDecoration(
                    color: Color(0xFFEF4444),
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
          title: Text(
            notification.title,
            style: TextStyle(
              fontWeight: unread ? FontWeight.w800 : FontWeight.w600,
              color: const Color(0xFF0F172A),
            ),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              notification.message,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Color(0xFF475569)),
            ),
          ),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _formatDate(context, notification.createdAt),
                style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
              ),
              if (onMarkAsRead != null)
                TextButton(
                  onPressed: onMarkAsRead,
                  child: const Text('Llegida'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}