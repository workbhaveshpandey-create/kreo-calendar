import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/text_styles.dart';
import '../../../../core/constants/app_config.dart';
import '../../../../shared/services/ai_service.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../domain/event_model.dart';
import '../bloc/calendar_bloc.dart';
import '../bloc/calendar_event.dart';
import '../bloc/calendar_state.dart';
import 'package:uuid/uuid.dart';

/// AI Quick Add Widget
/// Allows users to create events using natural language
class AIQuickAddWidget extends StatefulWidget {
  final VoidCallback? onEventCreated;

  const AIQuickAddWidget({super.key, this.onEventCreated});

  @override
  State<AIQuickAddWidget> createState() => _AIQuickAddWidgetState();
}

class _AIQuickAddWidgetState extends State<AIQuickAddWidget> {
  final TextEditingController _controller = TextEditingController();
  final AIService _aiService = AIService();
  final Uuid _uuid = const Uuid();

  bool _isLoading = false;
  String? _errorMessage;
  String? _successMessage;

  @override
  void dispose() {
    _controller.dispose();
    _aiService.dispose();
    super.dispose();
  }

  Future<void> _parseAndCreateEvent() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      final parsedEvent = await _aiService.parseEventFromText(text);

      if (parsedEvent == null) {
        setState(() {
          _errorMessage =
              "Couldn't understand that. Try something like 'Meeting tomorrow at 3pm'";
          _isLoading = false;
        });
        return;
      }

      // Get user and calendar info
      final authState = context.read<AuthBloc>().state;
      if (authState is! AuthAuthenticated) {
        setState(() {
          _errorMessage = 'Please sign in first';
          _isLoading = false;
        });
        return;
      }

      final calendarState = context.read<CalendarBloc>().state;
      if (calendarState is! CalendarLoaded) {
        setState(() {
          _errorMessage = 'Calendar not loaded';
          _isLoading = false;
        });
        return;
      }

      final defaultCalendar = calendarState.defaultCalendar;
      if (defaultCalendar == null) {
        setState(() {
          _errorMessage = 'No calendar available';
          _isLoading = false;
        });
        return;
      }

      // Create the event
      final event = EventModel(
        id: _uuid.v4(),
        calendarId: defaultCalendar.id,
        userId: authState.user.uid,
        title: parsedEvent.title,
        description: parsedEvent.description,
        startTime: parsedEvent.startTime ?? parsedEvent.date,
        endTime:
            parsedEvent.endTime ??
            (parsedEvent.isAllDay
                ? DateTime(
                    parsedEvent.date.year,
                    parsedEvent.date.month,
                    parsedEvent.date.day,
                    23,
                    59,
                  )
                : parsedEvent.date.add(const Duration(hours: 1))),
        isAllDay: parsedEvent.isAllDay,
        location: parsedEvent.location,
        color: defaultCalendar.color,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      context.read<CalendarBloc>().add(CalendarEventCreated(event));

      setState(() {
        _successMessage = '✨ Created: ${parsedEvent.title}';
        _isLoading = false;
      });

      _controller.clear();
      widget.onEventCreated?.call();

      // Clear success message after 3 seconds
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) {
          setState(() => _successMessage = null);
        }
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withValues(alpha: 0.1),
            AppColors.secondary.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Input Row
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // AI Icon
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.auto_awesome,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),

                // Text Input
                Expanded(
                  child: TextField(
                    controller: _controller,
                    style: AppTextStyles.bodyLarge(
                      color: isDark
                          ? AppColors.darkOnSurface
                          : AppColors.lightOnSurface,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Try "Meeting tomorrow at 3pm"',
                      hintStyle: AppTextStyles.bodyMedium(
                        color: isDark
                            ? AppColors.darkOnSurfaceVariant
                            : AppColors.lightOnSurfaceVariant,
                      ),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                    ),
                    onSubmitted: (_) => _parseAndCreateEvent(),
                  ),
                ),

                // Submit Button
                if (_isLoading)
                  const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.primary,
                    ),
                  )
                else
                  IconButton(
                    onPressed: _parseAndCreateEvent,
                    icon: const Icon(
                      Icons.send_rounded,
                      color: AppColors.primary,
                    ),
                    tooltip: 'Create event with AI',
                  ),
              ],
            ),
          ),

          // Messages
          if (_errorMessage != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(16),
                ),
              ),
              child: Text(
                _errorMessage!,
                style: AppTextStyles.bodySmall(color: AppColors.error),
              ),
            ).animate().fadeIn().slideY(begin: -0.2),

          if (_successMessage != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.1),
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(16),
                ),
              ),
              child: Text(
                _successMessage!,
                style: AppTextStyles.bodySmall(color: AppColors.success),
              ),
            ).animate().fadeIn().slideY(begin: -0.2),
        ],
      ),
    );
  }
}

/// AI Assistant Chat Panel
/// Full AI chat interface for calendar assistance
class AIAssistantPanel extends StatefulWidget {
  const AIAssistantPanel({super.key});

  @override
  State<AIAssistantPanel> createState() => _AIAssistantPanelState();
}

class _AIAssistantPanelState extends State<AIAssistantPanel> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final AIService _aiService = AIService();

  final List<ChatMessage> _messages = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Add welcome message
    _messages.add(
      ChatMessage(
        role: ChatRole.assistant,
        content:
            "Hi! I'm Kreo, your AI calendar assistant. I can help you:\n\n"
            "• Create events: \"Schedule meeting tomorrow at 2pm\"\n"
            "• Get summaries: \"What's my day look like?\"\n"
            "• Find events: \"When did I last have a team meeting?\"\n\n"
            "How can I help you today?",
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    _aiService.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _isLoading) return;

    setState(() {
      _messages.add(ChatMessage(role: ChatRole.user, content: text));
      _isLoading = true;
    });

    _controller.clear();
    _scrollToBottom();

    try {
      // Check if it's an event creation request
      if (_isEventCreationRequest(text)) {
        await _handleEventCreation(text);
      } else {
        // General assistant query
        final calendarState = context.read<CalendarBloc>().state;
        List<Map<String, dynamic>> events = [];

        if (calendarState is CalendarLoaded) {
          events = calendarState.events
              .map(
                (e) => {
                  'title': e.title,
                  'date': e.startTime.toIso8601String(),
                  'isAllDay': e.isAllDay,
                },
              )
              .toList();
        }

        final response = await _aiService.askAssistant(text, events);

        setState(() {
          _messages.add(
            ChatMessage(role: ChatRole.assistant, content: response),
          );
        });
      }
    } catch (e) {
      setState(() {
        _messages.add(
          ChatMessage(
            role: ChatRole.assistant,
            content: "Sorry, I encountered an error. Please try again.",
          ),
        );
      });
    } finally {
      setState(() => _isLoading = false);
      _scrollToBottom();
    }
  }

  bool _isEventCreationRequest(String text) {
    final keywords = [
      'schedule',
      'create',
      'add',
      'new event',
      'meeting',
      'appointment',
      'remind',
    ];
    final lowerText = text.toLowerCase();
    return keywords.any((k) => lowerText.contains(k)) &&
        (lowerText.contains('at') ||
            lowerText.contains('on') ||
            lowerText.contains('tomorrow'));
  }

  Future<void> _handleEventCreation(String text) async {
    final parsed = await _aiService.parseEventFromText(text);

    if (parsed != null) {
      // Show what we parsed and ask for confirmation
      setState(() {
        _messages.add(
          ChatMessage(
            role: ChatRole.assistant,
            content:
                "I'll create this event for you:\n\n"
                "📅 **${parsed.title}**\n"
                "📆 ${_formatDate(parsed.date)}\n"
                "${parsed.isAllDay ? '🌅 All day' : '⏰ ${_formatTime(parsed.startTime)} - ${_formatTime(parsed.endTime)}'}\n"
                "${parsed.location != null ? '📍 ${parsed.location}\n' : ''}\n"
                "Creating event...",
          ),
        );
      });

      // Create the event
      final authState = context.read<AuthBloc>().state;
      final calendarState = context.read<CalendarBloc>().state;

      if (authState is AuthAuthenticated && calendarState is CalendarLoaded) {
        final defaultCalendar = calendarState.defaultCalendar;
        if (defaultCalendar != null) {
          final event = EventModel(
            id: const Uuid().v4(),
            calendarId: defaultCalendar.id,
            userId: authState.user.uid,
            title: parsed.title,
            description: parsed.description,
            startTime: parsed.startTime ?? parsed.date,
            endTime:
                parsed.endTime ??
                (parsed.isAllDay
                    ? DateTime(
                        parsed.date.year,
                        parsed.date.month,
                        parsed.date.day,
                        23,
                        59,
                      )
                    : parsed.date.add(const Duration(hours: 1))),
            isAllDay: parsed.isAllDay,
            location: parsed.location,
            color: defaultCalendar.color,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );

          context.read<CalendarBloc>().add(CalendarEventCreated(event));

          setState(() {
            _messages.add(
              ChatMessage(
                role: ChatRole.assistant,
                content:
                    "✅ Done! I've added \"${parsed.title}\" to your calendar.",
              ),
            );
          });
          return;
        }
      }

      setState(() {
        _messages.add(
          ChatMessage(
            role: ChatRole.assistant,
            content:
                "❌ Couldn't create the event. Please make sure you're signed in.",
          ),
        );
      });
    } else {
      setState(() {
        _messages.add(
          ChatMessage(
            role: ChatRole.assistant,
            content:
                "I couldn't understand that event. Try being more specific, like:\n"
                "\"Meeting with John tomorrow at 3pm\"",
          ),
        );
      });
    }
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return '${days[date.weekday - 1]}, ${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  String _formatTime(DateTime? time) {
    if (time == null) return '';
    final hour = time.hour > 12
        ? time.hour - 12
        : (time.hour == 0 ? 12 : time.hour);
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.auto_awesome,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Kreo AI Assistant',
                  style: AppTextStyles.titleMedium(color: Colors.white),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, color: Colors.white),
                ),
              ],
            ),
          ),

          // Messages
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length + (_isLoading ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _messages.length && _isLoading) {
                  return const _TypingIndicator();
                }
                return _ChatBubble(message: _messages[index]);
              },
            ),
          ),

          // Input
          Container(
            padding: EdgeInsets.fromLTRB(
              16,
              8,
              16,
              8 + MediaQuery.of(context).viewInsets.bottom,
            ),
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.darkSurfaceVariant
                  : AppColors.lightSurfaceVariant,
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    style: AppTextStyles.bodyLarge(
                      color: isDark
                          ? AppColors.darkOnSurface
                          : AppColors.lightOnSurface,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Ask Kreo anything...',
                      hintStyle: AppTextStyles.bodyMedium(
                        color: isDark
                            ? AppColors.darkOnSurfaceVariant
                            : AppColors.lightOnSurfaceVariant,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: isDark
                          ? AppColors.darkSurface
                          : AppColors.lightSurface,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                FloatingActionButton.small(
                  onPressed: _sendMessage,
                  backgroundColor: AppColors.primary,
                  child: const Icon(Icons.send_rounded, color: Colors.white),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Chat message model
enum ChatRole { user, assistant }

class ChatMessage {
  final ChatRole role;
  final String content;

  ChatMessage({required this.role, required this.content});
}

/// Chat bubble widget
class _ChatBubble extends StatelessWidget {
  final ChatMessage message;

  const _ChatBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isUser = message.role == ChatRole.user;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color: isUser
              ? AppColors.primary
              : (isDark
                    ? AppColors.darkSurfaceVariant
                    : AppColors.lightSurfaceVariant),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isUser ? 16 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 16),
          ),
        ),
        child: Text(
          message.content,
          style: AppTextStyles.bodyMedium(
            color: isUser
                ? Colors.white
                : (isDark ? AppColors.darkOnSurface : AppColors.lightOnSurface),
          ),
        ),
      ),
    ).animate().fadeIn().slideX(begin: isUser ? 0.1 : -0.1);
  }
}

/// Typing indicator
class _TypingIndicator extends StatelessWidget {
  const _TypingIndicator();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isDark
              ? AppColors.darkSurfaceVariant
              : AppColors.lightSurfaceVariant,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildDot(0),
            const SizedBox(width: 4),
            _buildDot(1),
            const SizedBox(width: 4),
            _buildDot(2),
          ],
        ),
      ),
    );
  }

  Widget _buildDot(int index) {
    return Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.6),
            shape: BoxShape.circle,
          ),
        )
        .animate(onPlay: (controller) => controller.repeat())
        .scaleXY(
          begin: 0.5,
          end: 1.0,
          duration: 600.ms,
          delay: (index * 200).ms,
          curve: Curves.easeInOut,
        )
        .then()
        .scaleXY(begin: 1.0, end: 0.5, duration: 600.ms);
  }
}
