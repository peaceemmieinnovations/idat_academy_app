// ─── Notifications ───────────────────────────────────────────────────────────
import 'package:flutter/material.dart';
import '../../models/models.dart';
import '../../services/api_service.dart';
import '../../widgets/shared_widgets.dart';

class StudentNotificationsScreen extends StatefulWidget {
  const StudentNotificationsScreen({super.key});

  @override
  State<StudentNotificationsScreen> createState() =>
      _StudentNotificationsScreenState();
}

class _StudentNotificationsScreenState
    extends State<StudentNotificationsScreen> {
  List<AppNotification> _notifications = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    final res = await ApiService.getStudentNotifications();
    if (mounted) {
      if (res['error'] != null) {
        setState(() { _error = res['error']; _loading = false; });
      } else {
        final data = res['data'] as List? ?? [];
        setState(() {
          _notifications =
              data.map((n) => AppNotification.fromJson(n)).toList();
          _loading = false;
        });
      }
    }
  }

  Future<void> _markRead(AppNotification n) async {
    if (n.isRead) return;
    await ApiService.markNotificationRead(n.id);
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          if (_notifications.any((n) => !n.isRead))
            TextButton(
              onPressed: () async {
                for (final n in _notifications.where((n) => !n.isRead)) {
                  await ApiService.markNotificationRead(n.id);
                }
                _load();
              },
              child: const Text('Mark all read',
                  style: TextStyle(color: Colors.white, fontSize: 12)),
            ),
        ],
      ),
      body: _loading
          ? const Padding(padding: EdgeInsets.all(16), child: ShimmerList(count: 6, itemHeight: 80))
          : _error != null
              ? ErrorState(message: _error!, onRetry: _load)
              : _notifications.isEmpty
                  ? const EmptyState(
                      icon: Icons.notifications_none_rounded,
                      title: 'No notifications',
                      subtitle: 'You are all caught up!',
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                      itemCount: _notifications.length,
                      itemBuilder: (_, i) => NotificationTile(
                        notification: _notifications[i],
                        onTap: () => _markRead(_notifications[i]),
                      ),
                    ),
    );
  }
}
