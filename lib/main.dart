import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/constants/app_constants.dart';
import 'core/services/app_lock_service.dart';
import 'core/theme/app_theme.dart';
import 'di/service_locator.dart';
import 'firebase_options.dart';
import 'presentation/blocs/auth/auth_bloc.dart';
import 'presentation/blocs/client/client_bloc.dart';
import 'presentation/blocs/dashboard/dashboard_bloc.dart';
import 'presentation/blocs/invoice/invoice_bloc.dart';
import 'presentation/blocs/task/task_bloc.dart';
import 'presentation/blocs/timer/timer_bloc.dart';
import 'core/services/notification_service.dart';
import 'core/services/recurring_invoice_service.dart';
import 'data/repositories/invoice_repository.dart';
import 'presentation/screens/auth/login_screen.dart';
import 'presentation/screens/main_shell.dart';
import 'presentation/screens/onboarding/onboarding_screen.dart';
import 'presentation/screens/paywall/paywall_screen.dart';
import 'presentation/screens/profile/profile_screen.dart';
import 'presentation/screens/settings/settings_screen.dart';
import 'presentation/screens/splash/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
  ));

  await setupServiceLocator();

  // Process recurring invoices and schedule overdue notifications
  unawaited(_runBackgroundTasks());

  runApp(const HustleApp());
}

Future<void> _runBackgroundTasks() async {
  try {
    await sl<RecurringInvoiceService>().processRecurring();
    final invoices = await sl<InvoiceRepository>().getAll();
    await sl<NotificationService>().scheduleOverdueReminders(invoices);
  } catch (_) {
    // Non-fatal — don't crash on notification/recurring errors
  }
}

class HustleApp extends StatefulWidget {
  const HustleApp({super.key});

  @override
  State<HustleApp> createState() => _HustleAppState();
}

class _HustleAppState extends State<HustleApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.hidden) {
      sl<AppLockService>().lockIfEnabled();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>(
          create: (_) => sl<AuthBloc>()..add(AuthStarted()),
        ),
        BlocProvider<ClientBloc>(create: (_) => sl<ClientBloc>()),
        BlocProvider<TaskBloc>(create: (_) => sl<TaskBloc>()),
        BlocProvider<TimerBloc>(create: (_) => sl<TimerBloc>()),
        BlocProvider<InvoiceBloc>(create: (_) => sl<InvoiceBloc>()),
        BlocProvider<DashboardBloc>(create: (_) => sl<DashboardBloc>()),
      ],
      child: ValueListenableBuilder<ThemeMode>(
        valueListenable: sl<ValueNotifier<ThemeMode>>(),
        builder: (context, themeMode, _) => MaterialApp(
          title: AppConstants.appName,
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme(),
          darkTheme: AppTheme.darkTheme(),
          themeMode: themeMode,
          home: const _LockGate(child: AuthGate()),
          routes: {
            '/login': (_) => const LoginScreen(),
            '/home': (_) => const MainShell(),
            '/onboarding': (_) => const OnboardingScreen(),
            '/paywall': (_) => const PaywallScreen(),
            '/profile': (_) => const ProfileScreen(),
            '/settings': (_) => const SettingsScreen(),
          },
        ),
      ),
    );
  }
}

/// Shows a biometric lock screen overlay whenever
/// `AppLockService.locked` is true. Prompts for auth automatically.
class _LockGate extends StatefulWidget {
  final Widget child;
  const _LockGate({required this.child});

  @override
  State<_LockGate> createState() => _LockGateState();
}

class _LockGateState extends State<_LockGate> {
  bool _prompting = false;

  Future<void> _authenticate() async {
    if (_prompting) return;
    _prompting = true;
    try {
      await sl<AppLockService>().authenticate();
    } finally {
      _prompting = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: sl<AppLockService>().locked,
      builder: (context, isLocked, _) {
        if (isLocked) {
          WidgetsBinding.instance.addPostFrameCallback((_) => _authenticate());
        }
        return Stack(
          children: [
            widget.child,
            if (isLocked)
              Positioned.fill(
                child: Container(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.lock_rounded,
                          size: 72,
                          color: AppTheme.primaryColor,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Hustle is locked',
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Authenticate to continue',
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(color: AppTheme.onSurfaceMutedLight),
                        ),
                        const SizedBox(height: 32),
                        FilledButton.icon(
                          onPressed: _authenticate,
                          icon: const Icon(Icons.fingerprint),
                          label: const Text('Unlock'),
                          style: FilledButton.styleFrom(
                            minimumSize: const Size(200, 48),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        final Widget child;
        final String key;

        if (state is AuthInitial) {
          // Only show splash on cold start while we check auth status.
          child = const SplashScreen();
          key = 'splash';
        } else if (state is AuthAuthenticated) {
          child = _OnboardingGate();
          key = 'home';
        } else {
          // AuthLoading, AuthUnauthenticated, AuthError — all stay on
          // LoginScreen so the inline spinner works and BlocListener
          // can fire the error snackbar without the screen being torn down.
          child = const LoginScreen();
          key = 'login';
        }

        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 400),
          transitionBuilder: (child, animation) {
            return FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.04),
                  end: Offset.zero,
                ).animate(CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeOutCubic,
                )),
                child: child,
              ),
            );
          },
          child: KeyedSubtree(key: ValueKey(key), child: child),
        );
      },
    );
  }
}

class _OnboardingGate extends StatefulWidget {
  @override
  State<_OnboardingGate> createState() => _OnboardingGateState();
}

class _OnboardingGateState extends State<_OnboardingGate> {
  late final Future<bool> _onboardedFuture;

  @override
  void initState() {
    super.initState();
    _onboardedFuture = _loadOnboarded();
  }

  Future<bool> _loadOnboarded() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(AppConstants.keyOnboarded) ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _onboardedFuture,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final hasOnboarded = snapshot.data!;
        return hasOnboarded ? const MainShell() : const OnboardingScreen();
      },
    );
  }
}
