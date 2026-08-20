import 'package:flutter/material.dart';

import '../../models/app_models.dart';
import '../../services/notification_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/list_tiles.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  List<AppNotificationItem> _notifications = const [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final items = await NotificationService.instance.fetchHistory();
    if (mounted) {
      setState(() {
        _notifications = items;
        _loading = false;
      });
    }
  }

  Future<void> _clearAll() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear notification history?'),
        content: const Text(
            'All notifications in this list will be permanently removed.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text(
              'Clear',
              style: TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    await NotificationService.instance.clearHistory();
    if (mounted) {
      setState(() => _notifications = const []);
    }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Notification history cleared')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.mintBackground,
      appBar: AppBar(
        title: Text(
          'Notifications',
          style: TextStyle(
              fontWeight: FontWeight.bold, color: AppColors.textPrimary),
        ),
        centerTitle: true,
        actions: [
          if (_notifications.isNotEmpty)
            IconButton(
              tooltip: 'Clear all',
              icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
              onPressed: _clearAll,
            ),
        ],
      ),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _load,
                child: _notifications.isEmpty
                    ? ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: [
                          const SizedBox(height: 160),
                          Icon(Icons.notifications_off_outlined,
                              size: 56, color: AppColors.textSecondary),
                          const SizedBox(height: 12),
                          Center(
                            child: Text(
                              'No notifications yet',
                              style: TextStyle(
                                  color: AppColors.textSecondary, fontSize: 15),
                            ),
                          ),
                        ],
                      )
                    : ListView.builder(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(20),
                        itemCount: _notifications.length,
                        itemBuilder: (context, index) {
                          final notification = _notifications[index];
                          return NotificationCard(
                            notification: notification,
                            onTap: notification.route == null
                                ? null
                                : () => NotificationService.instance
                                    .openRoute(notification.route),
                          );
                        },
                      ),
              ),
      ),
    );
  }
}
