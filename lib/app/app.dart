import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'theme/app_theme.dart';
import 'theme/theme_cubit.dart';
import '../features/auth/data/auth_repository.dart';
import '../features/auth/presentation/bloc/auth_bloc.dart';
import '../features/auth/presentation/bloc/auth_event.dart';
import '../features/auth/presentation/bloc/auth_state.dart';
import '../features/auth/presentation/screens/login_screen.dart';
import '../features/calendar/data/calendar_repository.dart';
import '../features/calendar/presentation/bloc/calendar_bloc.dart';
import '../features/calendar/presentation/bloc/calendar_event.dart';
import '../features/calendar/presentation/bloc/calendar_state.dart';
import '../features/calendar/presentation/views/calendar_home_screen.dart';

/// Kreo Calendar App
/// Premium dark calendar application
class KreoCalendarApp extends StatelessWidget {
  const KreoCalendarApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider(create: (_) => AuthRepository()),
        RepositoryProvider(create: (_) => CalendarRepository()),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (context) =>
                AuthBloc(authRepository: context.read<AuthRepository>())
                  ..add(const AuthCheckRequested()),
          ),
          BlocProvider(
            create: (context) => CalendarBloc(
              calendarRepository: context.read<CalendarRepository>(),
            ),
          ),
          BlocProvider(create: (_) => ThemeCubit()),
        ],
        child: BlocBuilder<ThemeCubit, ThemeMode>(
          builder: (context, themeMode) {
            return MaterialApp(
              title: 'Kreo Calendar',
              debugShowCheckedModeBanner: false,
              theme: AppTheme.light,
              darkTheme: AppTheme.dark,
              themeMode: themeMode,
              themeAnimationDuration: const Duration(
                milliseconds: 300,
              ), // Smooth transition
              themeAnimationCurve: Curves.easeInOut,
              home: const _AuthWrapper(),
            );
          },
        ),
      ),
    );
  }
}

/// Handles authentication state and navigation
class _AuthWrapper extends StatelessWidget {
  const _AuthWrapper();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        // Handle unauthenticated state
        if (authState is AuthUnauthenticated) {
          return const LoginScreen(key: ValueKey('login'));
        }

        // Handle authenticated state - wait for calendar to load
        if (authState is AuthAuthenticated) {
          // Trigger calendar load if not started
          final calendarBloc = context.read<CalendarBloc>();
          if (calendarBloc.state is CalendarInitial) {
            calendarBloc.add(CalendarLoadRequested(authState.user.uid));
          }

          return BlocBuilder<CalendarBloc, CalendarState>(
            builder: (context, calendarState) {
              // Only show home when calendar is fully loaded
              if (calendarState is CalendarLoaded) {
                return AnimatedSwitcher(
                  duration: const Duration(milliseconds: 800),
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeInCubic,
                  transitionBuilder: (child, animation) {
                    return FadeTransition(opacity: animation, child: child);
                  },
                  child: const CalendarHomeScreen(key: ValueKey('home')),
                );
              }

              // Handle error - retry automatically
              if (calendarState is CalendarError) {
                calendarBloc.add(CalendarLoadRequested(authState.user.uid));
              }

              // Show splash for all loading states (Initial, Loading, Error)
              return const _PremiumSplashScreen(
                key: ValueKey('splash'),
                status: 'Loading calendars...',
              );
            },
          );
        }

        // Default: show splash (Auth loading states)
        return const _PremiumSplashScreen(
          key: ValueKey('splash'),
          status: 'Loading calendars...',
        );
      },
    );
  }
}

/// Premium Splash Screen with Animated Loading Bar
class _PremiumSplashScreen extends StatefulWidget {
  final String status;
  const _PremiumSplashScreen({super.key, required this.status});

  @override
  State<_PremiumSplashScreen> createState() => _PremiumSplashScreenState();
}

class _PremiumSplashScreenState extends State<_PremiumSplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _progressController;
  late Animation<double> _progressAnimation;

  @override
  void initState() {
    super.initState();
    _progressController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat();

    _progressAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _progressController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo with glow
            Container(
                  width: size.width * 0.25,
                  height: size.width * 0.25,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.white.withOpacity(0.1),
                        blurRadius: 60,
                        spreadRadius: 20,
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: Image.asset(
                      'assets/images/kreo_logo.jpg',
                      fit: BoxFit.cover,
                    ),
                  ),
                )
                .animate()
                .fadeIn(duration: 600.ms)
                .scale(
                  begin: const Offset(0.8, 0.8),
                  duration: 600.ms,
                  curve: Curves.easeOutBack,
                ),

            const SizedBox(height: 32),

            // App Name
            Text(
              'KREO',
              style: AppTextStyles.headlineLarge(
                color: Colors.white,
              ).copyWith(letterSpacing: 8, fontWeight: FontWeight.w300),
            ).animate().fadeIn(delay: 200.ms, duration: 400.ms),

            const SizedBox(height: 48),

            // Premium Progress Bar
            SizedBox(
              width: size.width * 0.5,
              child: Column(
                children: [
                  // Progress bar track
                  Container(
                    height: 2,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(1),
                    ),
                    child: AnimatedBuilder(
                      animation: _progressAnimation,
                      builder: (context, child) {
                        return Stack(
                          children: [
                            // Animated progress indicator
                            FractionallySizedBox(
                              alignment: Alignment.centerLeft,
                              widthFactor: _progressAnimation.value,
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.white.withOpacity(0.3),
                                      Colors.white,
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(1),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Status text
                  Text(
                    widget.status.toUpperCase(),
                    style: AppTextStyles.labelSmall(
                      color: Colors.white38,
                    ).copyWith(letterSpacing: 2),
                  ).animate().fadeIn(delay: 300.ms, duration: 300.ms),
                ],
              ),
            ).animate().fadeIn(delay: 400.ms, duration: 400.ms),
          ],
        ),
      ),
    );
  }
}
