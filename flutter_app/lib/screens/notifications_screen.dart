import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/theme.dart';
import '../providers/notifications_provider.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_text_styles.dart';

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() =>
      _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(
        () => ref.read(notificationsProvider.notifier).load());
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(notificationsProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundGrey,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('Notifications', style: AppTextStyles.titleLarge),
        centerTitle: false,
        actions: [
          if (state.notifications.isNotEmpty)
            TextButton(
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    title: Text('Clear All', style: AppTextStyles.titleMedium),
                    content: const Text('Delete all notifications?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: Text(
                          'Cancel',
                          style: GoogleFonts.poppins(color: AppColors.textGrey),
                        ),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        child: Text(
                          'Clear',
                          style: GoogleFonts.poppins(
                            color: AppColors.errorRed,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
                if (confirm == true) {
                  await ref.read(notificationsProvider.notifier).deleteAll();
                }
              },
              child: Text(
                'Clear all',
                style: GoogleFonts.poppins(
                  color: AppColors.errorRed,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
        ],
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : state.notifications.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: () =>
                      ref.read(notificationsProvider.notifier).load(),
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: state.notifications.length,
                    itemBuilder: (_, i) {
                      final n = state.notifications[i];
                      return TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0, end: 1),
                        duration:
                            Duration(milliseconds: 200 + (i * 50)),
                        curve: Curves.easeOut,
                        builder: (context, v, child) {
                          return Opacity(
                            opacity: v,
                            child: Transform.translate(
                              offset: Offset(30 * (1 - v), 0),
                              child: child,
                            ),
                          );
                        },
                        child: Dismissible(
                          key: Key('notif_${n.notificationId}'),
                          direction: DismissDirection.endToStart,
                          background: Container(
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 24),
                            margin: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.errorRed,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Icon(Icons.delete,
                                color: Colors.white),
                          ),
                          onDismissed: (_) => ref
                              .read(notificationsProvider.notifier)
                              .delete(n.notificationId),
                          child: Container(
                            margin: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.cardWhite,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: AppTheme.cardShadow,
                              border: n.isRead
                                  ? null
                                  : Border.all(
                                      color: AppColors.primaryBlue
                                          .withValues(alpha: 0.2),
                                      width: 1,
                                    ),
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.all(14),
                              leading: Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: n.isRead
                                      ? AppColors.backgroundGrey
                                      : AppColors.primaryBlue
                                          .withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  _iconFor(n.type),
                                  color: n.isRead
                                      ? AppColors.textGrey
                                      : AppColors.primaryBlue,
                                  size: 20,
                                ),
                              ),
                              title: Text(
                                n.title,
                                style: GoogleFonts.poppins(
                                  fontWeight: n.isRead
                                      ? FontWeight.w500
                                      : FontWeight.w600,
                                  fontSize: 14,
                                  color: AppColors.textDark,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 4),
                                  Text(
                                    n.message,
                                    style: GoogleFonts.poppins(
                                      fontSize: 13,
                                      color: AppColors.textGrey,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    n.createdAt ?? '',
                                    style: GoogleFonts.poppins(
                                      fontSize: 11,
                                      color: AppColors.textHint,
                                    ),
                                  ),
                                ],
                              ),
                              trailing: !n.isRead
                                  ? Container(
                                      width: 8,
                                      height: 8,
                                      decoration: const BoxDecoration(
                                        color: AppColors.primaryBlue,
                                        shape: BoxShape.circle,
                                      ),
                                    )
                                  : null,
                              onTap: () {
                                if (!n.isRead) {
                                  ref
                                      .read(notificationsProvider.notifier)
                                      .markRead(n.notificationId);
                                }
                              },
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.cardWhite,
              shape: BoxShape.circle,
              boxShadow: AppTheme.cardShadow,
            ),
            child: Icon(Icons.notifications_none,
                size: 40, color: AppColors.textHint),
          ),
          const SizedBox(height: 20),
          Text(
            'No notifications yet',
            style: AppTextStyles.titleMedium,
          ),
          const SizedBox(height: 4),
          Text(
            'You\'re all caught up!',
            style: AppTextStyles.caption,
          ),
        ],
      ),
    );
  }

  IconData _iconFor(String? type) {
    switch (type) {
      case 'appointment':
        return Icons.calendar_today;
      case 'test_result':
        return Icons.science;
      case 'alert':
        return Icons.warning_amber;
      default:
        return Icons.notifications_outlined;
    }
  }
}
