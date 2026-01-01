import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../app/theme/theme_cubit.dart';
import '../../../../shared/services/notification_service.dart';
import '../../../../shared/services/update_service.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_event.dart';
import '../../../auth/presentation/bloc/auth_state.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;
  final UpdateService _updateService = UpdateService();
  bool _isCheckingUpdate = false;
  bool _isDownloading = false;
  double _downloadProgress = 0.0;
  String? _currentVersion;

  @override
  void initState() {
    super.initState();
    _loadCurrentVersion();
  }

  Future<void> _loadCurrentVersion() async {
    final version = await _updateService.getCurrentVersion();
    if (mounted) {
      setState(() => _currentVersion = version);
    }
  }

  Future<void> _checkForUpdates() async {
    setState(() => _isCheckingUpdate = true);

    final result = await _updateService.checkForUpdates();

    if (!mounted) return;
    setState(() => _isCheckingUpdate = false);

    if (result.error != null) {
      _showUpdateDialog(
        title: 'UPDATE CHECK FAILED',
        content: result.error!,
        isError: true,
      );
    } else if (result.hasUpdate) {
      _showUpdateAvailableDialog(result);
    } else {
      _showUpdateDialog(
        title: 'UP TO DATE',
        content:
            'You are running the latest version (${result.currentVersion}).',
      );
    }
  }

  void _showUpdateAvailableDialog(UpdateCheckResult result) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(
              Icons.system_update,
              color: Colors.greenAccent,
              size: 24,
            ),
            const SizedBox(width: 12),
            Text(
              'UPDATE AVAILABLE',
              style: GoogleFonts.outfit(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildVersionRow('Current', result.currentVersion ?? ''),
            const SizedBox(height: 8),
            _buildVersionRow('Latest', result.latestVersion ?? ''),
            if (result.releaseNotes != null &&
                result.releaseNotes!.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                'RELEASE NOTES',
                style: GoogleFonts.outfit(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: Colors.white54,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                constraints: const BoxConstraints(maxHeight: 100),
                child: SingleChildScrollView(
                  child: Text(
                    result.releaseNotes!,
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      color: Colors.white70,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'LATER',
              style: GoogleFonts.outfit(
                fontSize: 12,
                color: Colors.white54,
                letterSpacing: 1,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              if (result.downloadUrl != null) {
                _startDownload(result.downloadUrl!);
              }
            },
            child: Text(
              'UPDATE NOW',
              style: GoogleFonts.outfit(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.greenAccent,
                letterSpacing: 1,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVersionRow(String label, String version) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.outfit(fontSize: 12, color: Colors.white54),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.white24),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            'v$version',
            style: GoogleFonts.outfit(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  void _startDownload(String url) {
    setState(() {
      _isDownloading = true;
      _downloadProgress = 0.0;
    });

    _updateService.downloadAndInstall(
      url: url,
      onProgress: (progress) {
        if (mounted) {
          setState(() => _downloadProgress = progress);
        }
      },
      onError: (error) {
        if (mounted) {
          setState(() => _isDownloading = false);
          _showUpdateDialog(
            title: 'DOWNLOAD FAILED',
            content: error,
            isError: true,
          );
        }
      },
      onComplete: () {
        if (mounted) {
          setState(() => _isDownloading = false);
        }
      },
    );
  }

  void _showUpdateDialog({
    required String title,
    required String content,
    bool isError = false,
  }) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          title,
          style: GoogleFonts.outfit(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isError ? AppColors.minimalError : Colors.white,
            letterSpacing: 1,
          ),
        ),
        content: Text(
          content,
          style: GoogleFonts.outfit(fontSize: 12, color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'OK',
              style: GoogleFonts.outfit(
                fontSize: 12,
                color: Colors.white,
                letterSpacing: 1,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: theme.colorScheme.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'SETTINGS',
          style: AppTextStyles.headlineMedium(
            color: theme.colorScheme.onSurface,
          ).copyWith(letterSpacing: 2),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            _buildProfileSection(),
            const SizedBox(height: 48),
            _buildSectionHeader('PREFERENCES'),
            const SizedBox(height: 24),
            BlocBuilder<ThemeCubit, ThemeMode>(
              builder: (context, themeMode) {
                final isDark = themeMode == ThemeMode.dark;
                return _buildSettingTile(
                  icon: isDark
                      ? Icons.dark_mode_outlined
                      : Icons.light_mode_outlined,
                  title: 'THEME MODE',
                  subtitle: isDark ? 'Dark Mode' : 'Light Mode',
                  trailing: Switch(
                    value: isDark,
                    onChanged: (value) =>
                        context.read<ThemeCubit>().toggleTheme(value),
                    activeColor: theme.colorScheme.onSurface,
                    activeTrackColor: theme.colorScheme.surface,
                    inactiveThumbColor: Colors.grey,
                    inactiveTrackColor: Colors.grey[900],
                  ),
                );
              },
            ),
            const SizedBox(height: 8),
            _buildSettingTile(
              icon: Icons.notifications_none_rounded,
              title: 'NOTIFICATIONS',
              subtitle: 'Event reminders 5 min before',
              trailing: Switch(
                value: _notificationsEnabled,
                onChanged: (value) =>
                    setState(() => _notificationsEnabled = value),
                activeColor: theme.colorScheme.onSurface,
                activeTrackColor: theme.colorScheme.surface,
                inactiveThumbColor: Colors.grey,
                inactiveTrackColor: Colors.grey[900],
              ),
            ),
            const SizedBox(height: 8),
            _buildSettingTile(
              icon: Icons.notifications_active_outlined,
              title: 'TEST NOTIFICATION',
              subtitle: 'Send a test to verify notifications work',
              trailing: const Icon(Icons.chevron_right, color: Colors.white24),
              onTap: () async {
                final notificationService = NotificationService();
                await notificationService.requestPermissions();
                await notificationService.showTestNotification();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'TEST NOTIFICATION SENT',
                        style: GoogleFonts.outfit(letterSpacing: 1),
                      ),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              },
            ),

            const SizedBox(height: 48),
            _buildSectionHeader('APP'),
            const SizedBox(height: 24),

            // Update Check Option
            _isDownloading
                ? _buildDownloadProgress()
                : _buildSettingTile(
                    icon: Icons.system_update_outlined,
                    title: 'CHECK FOR UPDATES',
                    subtitle: _isCheckingUpdate
                        ? 'Checking...'
                        : 'Current: v${_currentVersion ?? '...'}',
                    trailing: _isCheckingUpdate
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(
                            Icons.chevron_right,
                            color: Colors.white24,
                          ),
                    onTap: _isCheckingUpdate ? null : _checkForUpdates,
                  ),

            const SizedBox(height: 48),
            _buildSectionHeader('ACCOUNT'),
            const SizedBox(height: 24),
            _buildSettingTile(
              icon: Icons.logout,
              title: 'SIGN OUT',
              subtitle: 'Disconnect account',
              textColor: AppColors.minimalError,
              iconColor: AppColors.minimalError,
              onTap: () {
                context.read<AuthBloc>().add(AuthSignOutRequested());
                Navigator.pop(context);
              },
            ),
            const SizedBox(height: 48),
            Text(
              'VERSION ${_currentVersion ?? '1.0.0'}',
              style: AppTextStyles.bodySmall(
                color: Colors.grey,
              ).copyWith(letterSpacing: 2),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDownloadProgress() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.white12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.download, color: Colors.greenAccent, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'DOWNLOADING UPDATE...',
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                    letterSpacing: 1,
                  ),
                ),
              ),
              Text(
                '${(_downloadProgress * 100).toInt()}%',
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.greenAccent,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: _downloadProgress,
            backgroundColor: Colors.white12,
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.greenAccent),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileSection() {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        if (state is AuthAuthenticated) {
          return Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.transparent,
              border: Border.all(color: Colors.white),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.grey[900],
                  backgroundImage: state.user.photoUrl != null
                      ? NetworkImage(state.user.photoUrl!)
                      : null,
                  child: state.user.photoUrl == null
                      ? Text(
                          state.user.displayName?.isNotEmpty == true
                              ? state.user.displayName![0].toUpperCase()
                              : state.user.email[0].toUpperCase(),
                          style: AppTextStyles.headlineMedium(
                            color: Colors.white,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        (state.user.displayName ?? 'User').toUpperCase(),
                        style: AppTextStyles.titleMedium(
                          color: Colors.white,
                        ).copyWith(letterSpacing: 1),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        state.user.email,
                        style: AppTextStyles.bodySmall(color: Colors.grey),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildSectionHeader(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: AppTextStyles.labelMedium(
          color: Colors.grey,
        ).copyWith(letterSpacing: 2),
      ),
    );
  }

  Widget _buildSettingTile({
    required IconData icon,
    required String title,
    required String subtitle,
    Widget? trailing,
    VoidCallback? onTap,
    Color? textColor,
    Color? iconColor,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: Colors.white.withOpacity(0.1)),
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: iconColor ?? Colors.white, size: 24),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.titleSmall(
                      color: textColor ?? Colors.white,
                    ).copyWith(letterSpacing: 1),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: AppTextStyles.bodySmall(color: Colors.grey),
                  ),
                ],
              ),
            ),
            if (trailing != null) trailing,
          ],
        ),
      ),
    );
  }
}
