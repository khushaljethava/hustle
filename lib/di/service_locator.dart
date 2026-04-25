import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants/app_constants.dart';
import '../core/services/app_lock_service.dart';
import '../core/services/backup_service.dart';
import '../core/services/csv_export_service.dart';
import '../core/services/currency_service.dart';
import '../core/services/invoice_pdf_service.dart';
import '../core/services/notification_service.dart';
import '../core/services/pro_service.dart';
import '../core/services/recurring_invoice_service.dart';
import '../data/database/database_helper.dart';
import '../data/repositories/client_repository.dart';
import '../data/repositories/task_repository.dart';
import '../data/repositories/time_entry_repository.dart';
import '../data/repositories/invoice_repository.dart';
import '../presentation/blocs/auth/auth_bloc.dart';
import '../presentation/blocs/client/client_bloc.dart';
import '../presentation/blocs/task/task_bloc.dart';
import '../presentation/blocs/timer/timer_bloc.dart';
import '../presentation/blocs/invoice/invoice_bloc.dart';
import '../presentation/blocs/dashboard/dashboard_bloc.dart';

final sl = GetIt.instance;

ThemeMode _parseThemeMode(String value) => switch (value) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };

Future<void> setupServiceLocator() async {
  // SharedPreferences + theme notifier
  final prefs = await SharedPreferences.getInstance();
  sl.registerSingleton<SharedPreferences>(prefs);
  final savedTheme = prefs.getString(AppConstants.keyThemeMode) ?? 'system';
  sl.registerSingleton<ValueNotifier<ThemeMode>>(
    ValueNotifier<ThemeMode>(_parseThemeMode(savedTheme)),
  );
  final savedCurrency =
      prefs.getString(AppConstants.keyCurrency) ?? AppConstants.defaultCurrency;
  sl.registerSingleton<ValueNotifier<String>>(
    ValueNotifier<String>(savedCurrency),
  );

  // Currency service
  final currencyService = CurrencyService(prefs);
  sl.registerSingleton<CurrencyService>(currencyService);
  currencyService.fetchRates(); // background fetch, no await

  // Pro / monetization
  final proService = ProService(prefs);
  await proService.initialize();
  sl.registerSingleton<ProService>(proService);
  sl.registerSingleton<InvoicePdfService>(InvoicePdfService(prefs));

  // Notification
  final notificationService = NotificationService(prefs);
  await notificationService.initialize();
  sl.registerSingleton<NotificationService>(notificationService);

  // Database
  sl.registerSingleton<DatabaseHelper>(DatabaseHelper());

  // Repositories
  sl.registerSingleton<ClientRepository>(ClientRepository(sl()));
  sl.registerSingleton<TaskRepository>(TaskRepository(sl()));
  sl.registerSingleton<TimeEntryRepository>(TimeEntryRepository(sl()));
  sl.registerSingleton<InvoiceRepository>(InvoiceRepository(sl()));

  // CSV + Recurring (depend on repositories)
  sl.registerSingleton<CsvExportService>(CsvExportService(sl(), sl()));
  sl.registerSingleton<RecurringInvoiceService>(RecurringInvoiceService(sl()));

  // Polish / UX services
  sl.registerSingleton<AppLockService>(AppLockService(prefs));
  sl.registerSingleton<BackupService>(BackupService(prefs));

  // BLoCs (factory - new instance per use)
  sl.registerFactory<AuthBloc>(() => AuthBloc());
  sl.registerFactory<ClientBloc>(() => ClientBloc(sl()));
  sl.registerFactory<TaskBloc>(() => TaskBloc(sl()));
  sl.registerFactory<TimerBloc>(() => TimerBloc(sl()));
  sl.registerFactory<InvoiceBloc>(() => InvoiceBloc(sl()));
  sl.registerFactory<DashboardBloc>(() => DashboardBloc(sl(), sl(), sl(), sl()));
}
