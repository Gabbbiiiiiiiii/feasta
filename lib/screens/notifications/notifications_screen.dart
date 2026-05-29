import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../core/constants/firestore_collections.dart';
import '../../core/constants/status_constants.dart';
import '../../models/feasta_models.dart';
import '../../repositories/feasta_repository.dart';
import '../customer/booking_details_screen.dart';
import '../customer/chat_screen.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final FeastaRepository repository = FeastaRepository();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Notifications',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              try {
                await repository.markAllNotificationsAsRead();

                if (!context.mounted) return;

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('All notifications marked as read.'),
                  ),
                );
              } catch (e) {
                if (!context.mounted) return;

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      e.toString().replaceAll('Exception: ', ''),
                    ),
                  ),
                );
              }
            },
            child: const Text(
              'Mark all',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: repository.myNotifications(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}'),
            );
          }

          final docs = snapshot.data?.docs ?? [];

          if (docs.isEmpty) {
            return const Center(
              child: Text(
                'No notifications yet.',
                style: TextStyle(color: Colors.grey),
              ),
            );
          }

          final notifications = [...docs];

          notifications.sort((a, b) {
            final aDate = a.data()['createdAt'];
            final bDate = b.data()['createdAt'];

            if (aDate is Timestamp && bDate is Timestamp) {
              return bDate.compareTo(aDate);
            }

            return 0;
          });

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: notifications.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final doc = notifications[index];
              final data = doc.data();

              return NotificationCard(
                notificationId: doc.id,
                data: data,
                repository: repository,
              );
            },
          );
        },
      ),
    );
  }
}

class NotificationCard extends StatelessWidget {
  final String notificationId;
  final Map<String, dynamic> data;
  final FeastaRepository repository;

  const NotificationCard({
    super.key,
    required this.notificationId,
    required this.data,
    required this.repository,
  });

  String get title => data['title'] ?? 'Notification';
  String get message => data['message'] ?? '';
  String get type => data['type'] ?? 'system';
  bool get isRead => data['isRead'] ?? false;

  String get formattedDate {
    final createdAt = data['createdAt'];

    if (createdAt is Timestamp) {
      final date = createdAt.toDate();
      final hour = date.hour % 12 == 0 ? 12 : date.hour % 12;
      final minute = date.minute.toString().padLeft(2, '0');
      final period = date.hour >= 12 ? 'PM' : 'AM';

      return '${date.month}/${date.day}/${date.year} $hour:$minute $period';
    }

    return '';
  }

  IconData get icon {
    switch (type) {
      case 'booking':
        return Icons.event_available;
      case 'payment':
        return Icons.payment;
      case 'chat':
        return Icons.chat_bubble_outline;
      case 'review':
        return Icons.star_outline;
      case 'verification':
        return Icons.verified_user_outlined;
      case 'system':
      default:
        return Icons.notifications_outlined;
    }
  }

  Color get color {
    switch (type) {
      case 'booking':
        return const Color(0xFFFF6333);
      case 'payment':
        return Colors.green;
      case 'chat':
        return Colors.blue;
      case 'review':
        return Colors.amber;
      case 'verification':
        return Colors.purple;
      case 'system':
      default:
        return Colors.grey;
    }
  }

  Future<void> _markAsRead(BuildContext context) async {
    if (isRead) return;

    try {
      await repository.markNotificationAsRead(notificationId);
    } catch (e) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
        ),
      );
    }
  }

  Future<BookingModel?> _getBookingFromChatRoom(String chatRoomId) async {
  final chatRoomDoc = await FirebaseFirestore.instance
      .collection(FirestoreCollections.chatRooms)
      .doc(chatRoomId)
      .get();

  if (!chatRoomDoc.exists) return null;

  final data = chatRoomDoc.data();

  final bookingId = data?['bookingId'];

  if (bookingId == null || bookingId.toString().isEmpty) {
    return null;
  }

  final bookingDoc = await FirebaseFirestore.instance
      .collection(FirestoreCollections.bookings)
      .doc(bookingId)
      .get();

  if (!bookingDoc.exists) return null;

  return BookingModel.fromDoc(bookingDoc);
}

Future<void> _openNotification(BuildContext context) async {
  await _markAsRead(context);

  if (!context.mounted) return;

  final relatedId = data['relatedId']?.toString() ?? '';
  final relatedCollection = data['relatedCollection']?.toString() ?? '';

  if (relatedId.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('No related item found.')),
    );
    return;
  }

  if (relatedCollection == FirestoreCollections.bookings) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BookingDetailsScreen(
          bookingId: relatedId,
        ),
      ),
    );
    return;
  }

  if (relatedCollection == FirestoreCollections.chatRooms) {
    final booking = await _getBookingFromChatRoom(relatedId);

    if (!context.mounted) return;

    if (booking == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Chat booking not found.')),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatScreen(
          booking: booking,
          currentRole: booking.customerId == repository.currentUid
              ? UserRoles.customer
              : UserRoles.provider,
        ),
      ),
    );
    return;
  }

  if (relatedCollection == FirestoreCollections.addonRequests) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Add-on request details screen will be connected next.'),
      ),
    );
    return;
  }

  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text('This notification type is not connected yet.'),
    ),
  );
}

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () => _openNotification(context),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isRead ? Colors.white : color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isRead ? const Color(0xFFE5E7EB) : color.withOpacity(0.35),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              backgroundColor: color.withOpacity(0.12),
              child: Icon(
                icon,
                color: color,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight:
                                isRead ? FontWeight.w700 : FontWeight.w900,
                          ),
                        ),
                      ),
                      if (!isRead)
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    message,
                    style: const TextStyle(
                      color: Colors.grey,
                      height: 1.35,
                    ),
                  ),
                  if (formattedDate.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      formattedDate,
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 12,
                      ),
                    ),
                  ],
                  if (!isRead) ...[
                    const SizedBox(height: 10),
                    TextButton(
                      onPressed: () => _markAsRead(context),
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(0, 0),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Text(
                        'Mark as read',
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}