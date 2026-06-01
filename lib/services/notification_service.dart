import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;

import '../models/alert.dart';
import '../utils/date_helpers.dart';

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static const String _channelId = 'maple_alerts_channel';
  static const String _channelName = 'MapleAlerts Reminders';
  static const String _channelDesc =
      'Canadian financial deadline reminders from MapleAlerts';

  Future<void> initialize() async {
    tz_data.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('America/Toronto'));

    // Local notifications are not supported on web; skip native setup so the
    // app still boots. (dart:io Platform is also unavailable on web.)
    if (kIsWeb) return;

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwinSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: darwinSettings,
      macOS: darwinSettings,
    );

    await _plugin.initialize(initSettings);

    if (Platform.isAndroid) {
      await _plugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(
            const AndroidNotificationChannel(
              _channelId,
              _channelName,
              description: _channelDesc,
              importance: Importance.high,
            ),
          );
    }
  }

  Future<bool> requestPermissions() async {
    if (kIsWeb) return true;
    if (Platform.isIOS) {
      final result = await _plugin
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(alert: true, badge: true, sound: true);
      return result ?? false;
    }
    if (Platform.isAndroid) {
      final result = await _plugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
      return result ?? false;
    }
    return true;
  }

  NotificationDetails _buildDetails() {
    const androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDesc,
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );
    const darwinDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    return const NotificationDetails(
      android: androidDetails,
      iOS: darwinDetails,
      macOS: darwinDetails,
    );
  }

  Future<void> scheduleAlert(Alert alert) async {
    if (kIsWeb) return;
    final reminderDate = alert.deadline.subtract(const Duration(days: 7));
    final now = DateTime.now();

    if (reminderDate.isBefore(now)) return;

    final torontoTz = tz.getLocation('America/Toronto');
    final scheduledTime = tz.TZDateTime(
      torontoTz,
      reminderDate.year,
      reminderDate.month,
      reminderDate.day,
      9,
      0,
    );

    await _plugin.zonedSchedule(
      alert.id.hashCode,
      alert.title,
      '${alert.description} — due ${formatDateShort(alert.deadline)}',
      scheduledTime,
      _buildDetails(),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  Future<void> cancelAlert(String alertId) async {
    if (kIsWeb) return;
    await _plugin.cancel(alertId.hashCode);
  }

  Future<void> cancelAll() async {
    if (kIsWeb) return;
    await _plugin.cancelAll();
  }

  Future<void> scheduleAnnualReminders() async {
    if (kIsWeb) return;
    final year = DateTime.now().year;

    // RRSP reminder — Feb 20 at 9am Toronto
    final rrspReminderDate = DateTime(year, 2, 20);
    final now = DateTime.now();
    final torontoTz = tz.getLocation('America/Toronto');

    if (rrspReminderDate.isAfter(now)) {
      final rrspScheduled = tz.TZDateTime(
        torontoTz,
        rrspReminderDate.year,
        rrspReminderDate.month,
        rrspReminderDate.day,
        9,
        0,
      );
      await _plugin.zonedSchedule(
        'rrsp_annual_$year'.hashCode,
        'RRSP Deadline Approaching',
        'The RRSP contribution deadline for the $year tax year is March 1. Maximize your contribution!',
        rrspScheduled,
        _buildDetails(),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    }

    // CCB payment reminders — 19th of each month
    final ccbMonths = [2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12];
    for (final month in ccbMonths) {
      final ccbDate = DateTime(year, month, 19);
      if (ccbDate.isAfter(now)) {
        final ccbScheduled = tz.TZDateTime(
          torontoTz,
          ccbDate.year,
          ccbDate.month,
          ccbDate.day,
          9,
          0,
        );
        await _plugin.zonedSchedule(
          'ccb_${year}_$month'.hashCode,
          'CCB Payment Tomorrow',
          'Your Canada Child Benefit payment arrives tomorrow (the 20th).',
          ccbScheduled,
          _buildDetails(),
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
        );
      }
    }

    // BoC announcement reminders — schedule for 2025 dates
    final bocDates = bocAnnouncementDates(year);
    for (int i = 0; i < bocDates.length; i++) {
      final bocDate = bocDates[i];
      final reminderDate = bocDate.subtract(const Duration(days: 1));
      if (reminderDate.isAfter(now)) {
        final bocScheduled = tz.TZDateTime(
          torontoTz,
          reminderDate.year,
          reminderDate.month,
          reminderDate.day,
          9,
          0,
        );
        await _plugin.zonedSchedule(
          'boc_${year}_$i'.hashCode,
          'Bank of Canada Decision Tomorrow',
          'The Bank of Canada announces its interest rate decision on ${formatDateShort(bocDate)}.',
          bocScheduled,
          _buildDetails(),
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
        );
      }
    }
  }
}
