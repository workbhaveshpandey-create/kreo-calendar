import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_event.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../bloc/calendar_bloc.dart';
import '../bloc/calendar_state.dart';

/// Calendar Navigation Drawer
/// Shows calendars list, user info, and settings
class CalendarDrawer extends StatelessWidget {
  const CalendarDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.black,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      child: SafeArea(
        child: Column(
          children: [
            // User Header
            _buildUserHeader(context),

            const Divider(color: Colors.white24, height: 1),

            // Calendars List
            Expanded(child: _buildCalendarsList(context)),

            const Divider(color: Colors.white24, height: 1),

            // Bottom Actions
            _buildBottomActions(context),
          ],
        ),
      ),
    );
  }

  Widget _buildUserHeader(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        if (state is! AuthAuthenticated) {
          return const SizedBox.shrink();
        }

        final user = state.user;

        return Container(
          padding: const EdgeInsets.all(24),
          child: Row(
            children: [
              // Avatar
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                ),
                child: user.photoUrl != null
                    ? ClipOval(
                        child: Image.network(
                          user.photoUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              _buildAvatarPlaceholder(user.displayName),
                        ),
                      )
                    : _buildAvatarPlaceholder(user.displayName),
              ),

              const SizedBox(width: 16),

              // User Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.displayName?.toUpperCase() ?? 'USER',
                      style: AppTextStyles.titleMedium(
                        color: Colors.white,
                      ).copyWith(letterSpacing: 1),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      user.email.toUpperCase(),
                      style: AppTextStyles.bodySmall(
                        color: Colors.grey,
                      ).copyWith(letterSpacing: 1),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAvatarPlaceholder(String? name) {
    final initial = (name?.isNotEmpty == true) ? name![0].toUpperCase() : 'U';
    return Center(
      child: Text(
        initial,
        style: AppTextStyles.headlineMedium(color: Colors.black),
      ),
    );
  }

  Widget _buildCalendarsList(BuildContext context) {
    return BlocBuilder<CalendarBloc, CalendarState>(
      builder: (context, state) {
        if (state is! CalendarLoaded) {
          return const Center(
            child: CircularProgressIndicator(color: Colors.white),
          );
        }

        final calendars = state.calendars;

        return ListView(
          padding: const EdgeInsets.symmetric(vertical: 8),
          children: [
            // Section Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Row(
                children: [
                  Text(
                    'CALENDARS',
                    style: AppTextStyles.labelSmall(
                      color: Colors.grey,
                    ).copyWith(letterSpacing: 2),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => _showCreateCalendarDialog(context),
                    icon: const Icon(Icons.add, size: 20, color: Colors.white),
                    tooltip: 'Add Calendar',
                  ),
                ],
              ),
            ),

            // Calendar Items
            ...calendars.map((calendar) {
              return ListTile(
                leading: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: calendar.color,
                    shape: BoxShape
                        .circle, // Keep circles for distinction or make squares
                  ),
                ),
                title: Text(
                  calendar.name,
                  style: AppTextStyles.bodyLarge(color: Colors.white),
                ),
                trailing: Icon(Icons.cloud_done, size: 18, color: Colors.grey),
                onTap: () {
                  Navigator.pop(context);
                },
              );
            }),

            const SizedBox(height: 16),

            // Data Storage Info
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: Text(
                'SYNC STATUS',
                style: AppTextStyles.labelSmall(
                  color: Colors.grey,
                ).copyWith(letterSpacing: 2),
              ),
            ),

            ListTile(
              leading: Icon(Icons.cloud_done, color: Colors.green),
              title: Text(
                'FIREBASE CLOUD',
                style: AppTextStyles.bodyLarge(color: Colors.white),
              ),
              subtitle: Text(
                'All events synced',
                style: AppTextStyles.bodySmall(color: Colors.grey),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildBottomActions(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Settings
          ListTile(
            leading: const Icon(Icons.settings_outlined, color: Colors.grey),
            title: Text(
              'SETTINGS',
              style: AppTextStyles.bodyLarge(
                color: Colors.white,
              ).copyWith(letterSpacing: 1),
            ),
            onTap: () {
              Navigator.pop(context);
            },
          ),

          // Sign Out
          ListTile(
            leading: Icon(Icons.logout, color: AppColors.minimalError),
            title: Text(
              'SIGN OUT',
              style: AppTextStyles.bodyLarge(
                color: AppColors.minimalError,
              ).copyWith(letterSpacing: 1),
            ),
            onTap: () => _showSignOutDialog(context),
          ),
        ],
      ),
    );
  }

  void _showCreateCalendarDialog(BuildContext context) {
    final nameController = TextEditingController();
    Color selectedColor = AppColors.eventColors[0];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: Colors.black,
          shape: Border.all(color: Colors.white),
          title: Text(
            'NEW CALENDAR',
            style: TextStyle(color: Colors.white, letterSpacing: 2),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                style: TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'NAME',
                  labelStyle: TextStyle(color: Colors.grey),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey),
                  ),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.white),
                  ),
                ),
                autofocus: true,
              ),
              const SizedBox(height: 24),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: AppColors.eventColors.map((color) {
                  final isSelected =
                      color.toARGB32() == selectedColor.toARGB32();
                  return GestureDetector(
                    onTap: () => setState(() => selectedColor = color),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: isSelected
                            ? Border.all(color: Colors.white, width: 2)
                            : null,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'CANCEL',
                style: TextStyle(color: Colors.grey, letterSpacing: 2),
              ),
            ),
            TextButton(
              onPressed: () {
                final name = nameController.text.trim();
                if (name.isNotEmpty) {
                  Navigator.pop(context);
                }
              },
              child: const Text(
                'CREATE',
                style: TextStyle(
                  color: Colors.white,
                  letterSpacing: 2,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSignOutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.black,
        shape: Border.all(color: Colors.white),
        title: Text(
          'SIGN OUT',
          style: TextStyle(color: Colors.white, letterSpacing: 2),
        ),
        content: Text(
          'Disconnect account?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'CANCEL',
              style: TextStyle(color: Colors.grey, letterSpacing: 2),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Close drawer
              context.read<AuthBloc>().add(const AuthSignOutRequested());
            },
            child: const Text(
              'LOGOUT',
              style: TextStyle(
                color: Colors.red,
                letterSpacing: 2,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
