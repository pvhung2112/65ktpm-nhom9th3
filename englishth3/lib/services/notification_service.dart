import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;

  Future<void> init() async {
    if (_isInitialized) return;

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(
      android: androidSettings,
      windows: WindowsInitializationSettings(
        appName: 'EnglishTH3',
        appUserModelId: 'EnglishTH3.App',
        guid: 'd9b7a3d3-1e9a-4c2f-b4c6-8f3b2a5e7c1d',
      ),
    );

    try {
      await _plugin.initialize(
        settings: initSettings,
        onDidReceiveNotificationResponse: (details) {
          debugPrint('[Notification] User tapped notification: ${details.payload}');
        },
      );
      _isInitialized = true;
      debugPrint('[NotificationService] Khởi tạo hệ thống thông báo thành công!');
    } catch (e) {
      debugPrint('[NotificationService] Warning: Không thể khởi tạo local notifications: $e');
    }
  }

  /// Hiển thị thông báo nhắc nhở kỷ luật
  Future<void> showStreakReminder({
    required int currentStreak,
    String title = '🔥 Đừng để đứt chuỗi Streak!',
    String? body,
  }) async {
    final message = body ?? 'Bạn đang có chuỗi $currentStreak ngày học rực lửa! Hãy dành 5 phút luyện phát âm hôm nay nhé!';

    const androidDetails = AndroidNotificationDetails(
      'streak_channel',
      'Nhắc Nhở Luyện Tập',
      channelDescription: 'Kênh thông báo nhắc nhở chuỗi ngày streak',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      windows: WindowsNotificationDetails(),
    );

    try {
      await _plugin.show(
        id: 101,
        title: title,
        body: message,
        notificationDetails: details,
      );
    } catch (e) {
      debugPrint('[Notification] Show notification fallback: $e');
    }
  }
}
