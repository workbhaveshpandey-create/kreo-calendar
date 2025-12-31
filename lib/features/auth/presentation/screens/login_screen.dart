import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../app/theme/app_theme.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';

/// Premium Minimal Login Screen
/// Clean, simple design matching the app's dark aesthetic
class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  state.message.toUpperCase(),
                  style: GoogleFonts.outfit(
                    letterSpacing: 1,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                backgroundColor: AppColors.minimalError,
                behavior: SnackBarBehavior.floating,
                margin: const EdgeInsets.all(24),
                shape: const RoundedRectangleBorder(),
              ),
            );
          }
        },
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Spacer(flex: 2),

                // Minimal Logo
                _buildLogo(),

                const SizedBox(height: 48),

                // App Name - Large and bold
                Text(
                  'KREO',
                  style: GoogleFonts.outfit(
                    fontSize: 56,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: 8,
                    height: 1,
                  ),
                ),

                const SizedBox(height: 8),

                Text(
                  'CALENDAR',
                  style: GoogleFonts.outfit(
                    fontSize: 20,
                    fontWeight: FontWeight.w300,
                    color: Colors.white.withOpacity(0.6),
                    letterSpacing: 12,
                  ),
                ),

                const SizedBox(height: 32),

                // Tagline
                Container(
                  padding: const EdgeInsets.only(left: 2),
                  child: Text(
                    'Your schedule,\nbeautifully organized.',
                    style: GoogleFonts.outfit(
                      fontSize: 18,
                      fontWeight: FontWeight.w300,
                      color: Colors.white.withOpacity(0.5),
                      height: 1.5,
                    ),
                  ),
                ),

                const Spacer(flex: 2),

                // Features - Minimal list
                _buildFeatureItem('CLOUD SYNC', 'Secure Firebase storage'),
                const SizedBox(height: 16),
                _buildFeatureItem('VOICE AI', 'Create events by speaking'),
                const SizedBox(height: 16),
                _buildFeatureItem('SMART REMINDERS', 'Never miss an event'),

                const Spacer(flex: 2),

                // Sign In Button - Minimal white border
                _buildSignInButton(context),

                const SizedBox(height: 24),

                // Privacy note
                Center(
                  child: Text(
                    'YOUR DATA IS STORED SECURELY',
                    style: GoogleFonts.outfit(
                      fontSize: 10,
                      fontWeight: FontWeight.w400,
                      color: Colors.white.withOpacity(0.3),
                      letterSpacing: 2,
                    ),
                  ),
                ),

                const SizedBox(height: 48),

                // Version
                Center(
                  child: Text(
                    'V1.0.0',
                    style: GoogleFonts.outfit(
                      fontSize: 10,
                      fontWeight: FontWeight.w300,
                      color: Colors.white.withOpacity(0.2),
                      letterSpacing: 3,
                    ),
                  ),
                ),

                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.white, width: 1),
      ),
      child: ClipRRect(
        child: Image.asset('assets/images/kreo_logo.jpg', fit: BoxFit.cover),
      ),
    );
  }

  Widget _buildFeatureItem(String title, String subtitle) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 4,
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                  letterSpacing: 2,
                ),
              ),
              Text(
                subtitle,
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  fontWeight: FontWeight.w300,
                  color: Colors.white.withOpacity(0.4),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSignInButton(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        final isLoading = state is AuthLoading;

        return GestureDetector(
          onTap: isLoading
              ? null
              : () {
                  context.read<AuthBloc>().add(
                    const AuthGoogleSignInRequested(),
                  );
                },
          child: Container(
            width: double.infinity,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.transparent,
              border: Border.all(color: Colors.white, width: 1),
            ),
            child: isLoading
                ? const Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 1,
                        color: Colors.white,
                      ),
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Google icon
                      Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(2),
                        ),
                        child: Center(
                          child: Text(
                            'G',
                            style: GoogleFonts.outfit(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Colors.black,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Text(
                        'CONTINUE WITH GOOGLE',
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                          letterSpacing: 2,
                        ),
                      ),
                    ],
                  ),
          ),
        );
      },
    );
  }
}
