import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/goal_provider.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({Key? key}) : super(key: key);

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => 
      Provider.of<GoalProvider>(context, listen: false).fetchNotifications()
    );
  }

  @override
  Widget build(BuildContext context) {
    final notifications = Provider.of<GoalProvider>(context).notifications;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Notifications'),
        centerTitle: true,
        elevation: 0,
      ),
      body: notifications.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                   Icon(Icons.notifications_off_outlined, size: 60, color: Colors.grey[400]),
                   const SizedBox(height: 16),
                   Text(
                     'No notifications yet',
                     style: TextStyle(color: Colors.grey[600]),
                   ),
                ],
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: notifications.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final item = notifications[index];
                return Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 5,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    leading: CircleAvatar(
                      backgroundColor: item['type'] == 'deposit' 
                          ? Colors.green.shade50 
                          : Colors.orange.shade50,
                      child: Icon(
                        item['type'] == 'deposit' 
                            ? Icons.arrow_downward 
                            : Icons.arrow_upward,
                        color: item['type'] == 'deposit' 
                            ? Colors.green 
                            : Colors.orange,
                        size: 20,
                      ),
                    ),
                    title: Text(
                      item['title'] ?? 'Notification',
                      style: TextStyle(
                        fontWeight: (item['is_read'] == true) ? FontWeight.normal : FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text(
                          item['message'] ?? '',
                          style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                        ),
                        const SizedBox(height: 8),
                         Text(
                          item['created_at'] ?? '',
                          style: TextStyle(fontSize: 11, color: Colors.grey[400]),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
