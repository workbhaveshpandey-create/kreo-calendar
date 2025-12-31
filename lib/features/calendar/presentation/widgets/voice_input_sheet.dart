import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:uuid/uuid.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/constants/app_config.dart';
import '../../../../shared/services/ai_service.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../domain/event_model.dart';
import '../bloc/calendar_bloc.dart';
import '../bloc/calendar_event.dart';
import '../bloc/calendar_state.dart';

/// Voice Input Sheet for AI Commands
/// Allows users to speak to create events and reminders
class VoiceInputSheet extends StatefulWidget {
  const VoiceInputSheet({super.key});

  @override
  State<VoiceInputSheet> createState() => _VoiceInputSheetState();
}

class _VoiceInputSheetState extends State<VoiceInputSheet>
    with SingleTickerProviderStateMixin {
  final TextEditingController _textController = TextEditingController();
  final AIService _aiService = AIService(apiKey: AppConfig.openRouterApiKey);
  final _uuid = const Uuid();

  bool _isListening = false;
  bool _isProcessing = false;
  String _statusText = 'Tap mic to speak or type below';
  String? _resultText;
  bool _eventCreated = false;

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.7,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(top: 12),
            decoration: BoxDecoration(
              color: AppColors.divider,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Icon(Icons.auto_awesome, color: AppColors.primary, size: 24),
                const SizedBox(width: 12),
                Text(
                  'AI Assistant',
                  style: AppTextStyles.headlineMedium(
                    color: AppColors.onSurface,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(
                    Icons.close_rounded,
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),

          const Divider(color: AppColors.divider),

          // Status / Result
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: _buildStatusSection(),
          ),

          // Mic Button
          if (!_eventCreated) ...[
            GestureDetector(
              onTap: _isListening ? _stopListening : _startListening,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: _isListening ? AppColors.accent : AppColors.primary,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color:
                          (_isListening ? AppColors.accent : AppColors.primary)
                              .withValues(alpha: 0.4),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Icon(
                  _isListening ? Icons.stop_rounded : Icons.mic_rounded,
                  color: Colors.white,
                  size: 36,
                ),
              ),
            ).animate(
              onPlay: (controller) => _isListening ? controller.repeat() : null,
            ),
          ],

          const SizedBox(height: 24),

          // Text Input (alternative to voice)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _textController,
                    style: AppTextStyles.bodyLarge(color: AppColors.onSurface),
                    decoration: InputDecoration(
                      hintText: 'Or type: "Meeting tomorrow at 3pm"',
                      hintStyle: AppTextStyles.bodyMedium(
                        color: AppColors.onSurfaceVariant.withValues(
                          alpha: 0.6,
                        ),
                      ),
                      filled: true,
                      fillColor: AppColors.surfaceVariant,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                    ),
                    onSubmitted: (_) => _processTextInput(),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: IconButton(
                    onPressed: _isProcessing ? null : _processTextInput,
                    icon: _isProcessing
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.send_rounded, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Quick Commands
          _buildQuickCommands(),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildStatusSection() {
    if (_eventCreated && _resultText != null) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.success.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Icon(
              Icons.check_circle_rounded,
              color: AppColors.success,
              size: 32,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Event Created!',
                    style: AppTextStyles.titleMedium(color: AppColors.success),
                  ),
                  Text(
                    _resultText!,
                    style: AppTextStyles.bodySmall(
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ).animate().fadeIn().scale(begin: const Offset(0.9, 0.9));
    }

    if (_isProcessing) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            'Understanding...',
            style: AppTextStyles.bodyMedium(color: AppColors.onSurfaceVariant),
          ),
        ],
      );
    }

    if (_isListening) {
      return Column(
        children: [
          Text(
            'Listening...',
            style: AppTextStyles.titleMedium(color: AppColors.accent),
          ),
          const SizedBox(height: 8),
          Text(
            'Say something like "Set a reminder for tomorrow at 3pm"',
            style: AppTextStyles.bodySmall(color: AppColors.onSurfaceVariant),
            textAlign: TextAlign.center,
          ),
        ],
      );
    }

    return Text(
      _statusText,
      style: AppTextStyles.bodyMedium(color: AppColors.onSurfaceVariant),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildQuickCommands() {
    final commands = [
      '📅 "Meeting tomorrow at 2pm"',
      '⏰ "Reminder: Call mom at 5"',
      '🎂 "Birthday party Saturday"',
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Try saying:',
            style: AppTextStyles.labelMedium(color: AppColors.onSurfaceVariant),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: commands.map((cmd) {
              return GestureDetector(
                onTap: () {
                  _textController.text = cmd
                      .replaceAll(RegExp(r'[📅⏰🎂] "'), '')
                      .replaceAll('"', '');
                  _processTextInput();
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    cmd,
                    style: AppTextStyles.bodySmall(
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  final SpeechToText _speechToText = SpeechToText();
  bool _speechEnabled = false;

  @override
  void initState() {
    super.initState();
    _initSpeech();
  }

  void _initSpeech() async {
    _speechEnabled = await _speechToText.initialize();
    setState(() {});
  }

  void _startListening() async {
    if (!_speechEnabled) {
      _initSpeech();
      return;
    }

    setState(() {
      _isListening = true;
      _statusText = 'Listening...';
    });

    await _speechToText.listen(
      onResult: (result) {
        setState(() {
          _textController.text = result.recognizedWords;
        });

        if (result.finalResult) {
          _stopListening();
          // Auto-process if we have text
          if (_textController.text.isNotEmpty) {
            _processTextInput();
          }
        }
      },
    );
  }

  void _stopListening() async {
    await _speechToText.stop();
    setState(() {
      _isListening = false;
      _statusText = 'Processing command...';
    });
  }

  Future<void> _processTextInput() async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _isProcessing = true;
      _statusText = 'Processing...';
    });

    try {
      final parsedEvent = await _aiService.parseEventFromText(text);

      if (parsedEvent == null) {
        setState(() {
          _isProcessing = false;
          _statusText = "Couldn't understand. Try: 'Meeting tomorrow at 3pm'";
        });
        return;
      }

      // Get user and calendar info
      final authState = context.read<AuthBloc>().state;
      if (authState is! AuthAuthenticated) {
        setState(() {
          _isProcessing = false;
          _statusText = 'Please sign in first';
        });
        return;
      }

      final calendarState = context.read<CalendarBloc>().state;
      if (calendarState is! CalendarLoaded ||
          calendarState.defaultCalendar == null) {
        setState(() {
          _isProcessing = false;
          _statusText = 'Calendar not ready';
        });
        return;
      }

      final defaultCalendar = calendarState.defaultCalendar!;

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
        color: AppColors.eventColors[0],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // ignore: use_build_context_synchronously
      context.read<CalendarBloc>().add(CalendarEventCreated(event));

      setState(() {
        _isProcessing = false;
        _eventCreated = true;
        _resultText = '${parsedEvent.title}';
        _textController.clear();
      });

      // Auto close after success
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) Navigator.pop(context);
      });
    } catch (e) {
      setState(() {
        _isProcessing = false;
        _statusText = 'Error: Please try again';
      });
    }
  }
}
