import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_constants.dart';
import '../../data/models/invoice_model.dart';

class NotificationService {
  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  final SharedPreferences _prefs;

  NotificationService(this._prefs);

  bool get isEnabled =>
      _prefs.getBool(AppConstants.keyOverdueNotifications) ?? true;

  Future<void> initialize() async {
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const initSettings = InitializationSettings(
      android: androidInit,
      iOS: iosInit,
    );
    await _plugin.initialize(initSettings);
  }

  Future<bool> requestPermission() async {
    final android = _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) {
      return await android.requestNotificationsPermission() ?? false;
    }
    final ios = _plugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>();
    if (ios != null) {
      return await ios.requestPermissions(alert: true, badge: true, sound: true) ?? false;
    }
    return false;
  }

  Future<void> scheduleOverdueReminders(List<InvoiceModel> invoices) async {
    if (!isEnabled) return;
    await _plugin.cancelAll();

    final unpaid = invoices.where((i) => i.isSent || i.isOverdue).toList();
    for (var i = 0; i < unpaid.length; i++) {
      final invoice = unpaid[i];
      final isOverdue = invoice.isOverdue;

      await _plugin.show(
        AppConstants.invoiceOverdueBaseId + i,
        isOverdue ? 'Invoice Overdue' : 'Invoice Due Soon',
        isOverdue
            ? '${invoice.clientName} – Invoice #${invoice.invoiceNumber.toString().padLeft(4, '0')} is overdue'
            : '${invoice.clientName} – Invoice #${invoice.invoiceNumber.toString().padLeft(4, '0')} due ${_daysUntil(invoice.dueDate)}',
        NotificationDetails(
          android: AndroidNotificationDetails(
            AppConstants.notificationChannelId,
            AppConstants.notificationChannelName,
            channelDescription: 'Reminders for unpaid and overdue invoices',
            importance: isOverdue ? Importance.high : Importance.defaultImportance,
            priority: isOverdue ? Priority.high : Priority.defaultPriority,
            icon: '@mipmap/ic_launcher',
          ),
          iOS: const DarwinNotificationDetails(),
        ),
      );
    }
  }

  Future<void> cancelAll() => _plugin.cancelAll();

  Future<void> setEnabled(bool value) async {
    await _prefs.setBool(AppConstants.keyOverdueNotifications, value);
    if (!value) await cancelAll();
  }

  String _daysUntil(DateTime date) {
    final diff = date.difference(DateTime.now()).inDays;
    if (diff == 0) return 'today';
    if (diff == 1) return 'tomorrow';
    return 'in $diff days';
  }
}
