import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../models/bill_model.dart';

/// Wraps flutter_local_notifications to schedule bill-due reminders.
/// Each bill's notification id is derived deterministically from its
/// Firestore document id so reschedule/cancel calls are idempotent.
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    tz_data.initializeTimeZones();

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );
    await _plugin.initialize(settings);
    _initialized = true;
  }

  Future<void> requestPermissions() async {
    final androidImpl = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await androidImpl?.requestNotificationsPermission();

    final iosImpl = _plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    await iosImpl?.requestPermissions(alert: true, badge: true, sound: true);
  }

  Future<void> scheduleBillReminder(BillModel bill) async {
    await cancelBillReminder(bill);
    if (!bill.isActive) return;

    final scheduledDate = bill.reminderDate;
    if (scheduledDate.isBefore(DateTime.now())) return;

    try {
      await _plugin.zonedSchedule(
        bill.notificationId,
        'Upcoming bill: ${bill.name}',
        'Due ${_formatDate(bill.nextDueDate)} · Amount ${bill.amount.toStringAsFixed(2)}',
        tz.TZDateTime.from(scheduledDate, tz.local),
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'bill_reminders',
            'Bill Reminders',
            channelDescription: 'Reminders for upcoming recurring bills',
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: null,
      );
    } catch (e) {
      // Scheduling can fail if exact-alarm permission was revoked; the bill
      // still shows up in-app so this is non-fatal.
      debugPrint('Failed to schedule bill reminder: $e');
    }
  }

  Future<void> cancelBillReminder(BillModel bill) {
    return _plugin.cancel(bill.notificationId);
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
