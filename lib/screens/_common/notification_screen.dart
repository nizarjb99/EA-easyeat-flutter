import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/notification.dart';
import '../../providers/notification_provider.dart';
import '../../widgets/notification_tile.dart';

const Color _orange = Color(0xFFFF7A1A);
const Color _dark = Color(0xFF0F172A);
const Color _grey = Color(0xFF64748B);

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);

    Future.microtask(() {
      final provider = context.read<NotificationProvider>();
      provider.refresh();
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 500) {
      final provider = context.read<NotificationProvider>();
      if (provider.hasMore && !provider.isLoading) {
        provider.loadMore();
      }
    }
  }

  Future<void> _onRefresh() async {
    final provider = context.read<NotificationProvider>();
    await provider.refresh();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFBF7),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        title: const Text(
          'Notificacions',
          style: TextStyle(
            color: _dark,
            fontSize: 22,
            fontWeight: FontWeight.w900,
          ),
        ),
        actions: [
          Consumer<NotificationProvider>(
            builder: (context, provider, _) {
              if (provider.unreadCount == 0) return const SizedBox();

              return Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Center(
                  child: TextButton(
                    onPressed: () => _showMarkAllAsReadDialog(context),
                    child: Text(
                      'Marcar tot llegit',
                      style: TextStyle(
                        color: _orange,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: Consumer<NotificationProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading && provider.notifications.isEmpty) { // Modified this line
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 50,
                    height: 50,
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(_orange),
                    ),
                  ),
                ],
              ),
            );
          }

          if (provider.notifications.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_none, size: 64, color: _grey),
                  const SizedBox(height: 16),
                  Text(
                    'No hi ha notificacions',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: _dark,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'No tindràs cap notificació pendent',
                    style: TextStyle(
                      fontSize: 14,
                      color: _grey,
                    ),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: _onRefresh,
            color: _orange,
            backgroundColor: Colors.white,
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: provider.notifications.length +
                  (provider.hasMore ? 1 : 0),
              itemBuilder: (context, index) {
                // Loading indicator at bottom
                if (index >= provider.notifications.length) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Center(
                      child: SizedBox(
                        width: 30,
                        height: 30,
                        child: CircularProgressIndicator(
                          valueColor:
                              AlwaysStoppedAnimation<Color>(_orange),
                        ),
                      ),
                    ),
                  );
                }

                final notification = provider.notifications[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: NotificationTile(
                    notification: notification,
                    onTap: () => _handleNotificationTap(context, notification),
                    onMarkAsRead: !notification.isRead
                        ? () => _markAsRead(context, notification)
                        : null,
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  void _handleNotificationTap(
      BuildContext context, NotificationModel notification) {
    final provider = context.read<NotificationProvider>();

    // Mark as read if not already
    if (!notification.isRead) {
      provider.markAsRead(notification.id);
    }

    // Navigate to appropriate screen based on type
    // This can be expanded based on your routing logic
    Navigator.pop(context);
  }

  void _markAsRead(BuildContext context, NotificationModel notification) {
    final provider = context.read<NotificationProvider>();
    provider.markAsRead(notification.id);
  }

  void _showMarkAllAsReadDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Marcar tot com llegit'),
          content: const Text(
              '¿Estàs segur que vols marcar totes les notificacions com llegides?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel·lar'),
            ),
            TextButton(
              onPressed: () {
                context.read<NotificationProvider>().markAllAsRead();
                Navigator.pop(dialogContext);
              },
              child: Text(
                'Marcar',
                style: TextStyle(color: _orange, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        );
      },
    );
  }
}