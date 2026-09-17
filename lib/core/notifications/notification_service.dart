import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

const String kNovaSyncChannelId = 'nova_sync';
const String kNovaSyncChannelName = 'Queue Sync';

final notificationServiceProvider = Provider<NotificationService>(
  (ref) => NotificationService(),
);

class NotificationService {
  NotificationService({FlutterLocalNotificationsPlugin? plugin})
      : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    await _plugin.initialize(
      const InitializationSettings(android: android, iOS: ios),
    );

    final iosPlugin = _plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    await iosPlugin?.requestPermissions(alert: true, badge: true, sound: true);

    final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.createNotificationChannel(
      const AndroidNotificationChannel(
        kNovaSyncChannelId,
        kNovaSyncChannelName,
        importance: Importance.high,
      ),
    );

    _initialized = true;
  }

  Future<void> showSyncSuccess(String title, String body) async {
    if (!_initialized) return;
    const androidDetails = AndroidNotificationDetails(
      kNovaSyncChannelId,
      kNovaSyncChannelName,
      importance: Importance.high,
      priority: Priority.high,
    );
    const details = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(),
    );
    await _plugin.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      details,
    );
  }
}

/// No-op for widget/unit tests (avoids platform channels).
class NoOpNotificationService extends NotificationService {
  NoOpNotificationService() : super(plugin: FlutterLocalNotificationsPlugin());

  @override
  Future<void> init() async {}

  @override
  Future<void> showSyncSuccess(String title, String body) async {}
}
