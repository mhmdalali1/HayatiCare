class NotificationModel {
  final int notificationId;
  final int userId;
  final String? type;
  final String title;
  final String message;
  final bool isRead;
  final String? createdAt;

  const NotificationModel({
    required this.notificationId,
    required this.userId,
    this.type,
    required this.title,
    required this.message,
    required this.isRead,
    this.createdAt,
  })
  ;

  factory NotificationModel.fromJson(Map<String, dynamic> j) => NotificationModel(
        notificationId: j['notification_id'] as int,
        userId: j['user_id'] as int,
        type: j['type'] as String?,
        title: j['title'] as String? ?? '',
        message: j['message'] as String? ?? '',
        isRead: j['is_read'] as bool? ?? false,
        createdAt: j['created_at'] as String?,
      );
}
