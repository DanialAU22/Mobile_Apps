import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/study_session.dart';
import '../providers/study_session_provider.dart';
import '../providers/subject_provider.dart';
import '../utils/helpers.dart';

/// Pomodoro-style study timer: 25 min focus, 5 min break, auto cycle.
class StudyTimerScreen extends StatefulWidget {
  const StudyTimerScreen({super.key});

  @override
  State<StudyTimerScreen> createState() => _StudyTimerScreenState();
}

class _StudyTimerScreenState extends State<StudyTimerScreen>
    with TickerProviderStateMixin {
  static const int _focusMinutes = 25;
  static const int _breakMinutes = 5;

  Timer? _timer;
  int _remainingSeconds = _focusMinutes * 60;
  bool _isFocusPhase = true;
  bool _isRunning = false;
  String? _selectedSubjectId;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    Future.microtask(() {
      context.read<SubjectProvider>().loadSubjects();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  void _startTimer() {
    if (_isRunning) return;
    setState(() => _isRunning = true);
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() {
        if (_remainingSeconds <= 0) {
          _onPhaseComplete();
        } else {
          _remainingSeconds--;
        }
      });
    });
  }

  void _pauseTimer() {
    _timer?.cancel();
    _timer = null;
    setState(() => _isRunning = false);
  }

  void _resetTimer() {
    _timer?.cancel();
    _timer = null;
    setState(() {
      _isRunning = false;
      _remainingSeconds = _isFocusPhase ? _focusMinutes * 60 : _breakMinutes * 60;
    });
  }

  void _onPhaseComplete() {
    _timer?.cancel();
    _timer = null;
    if (_isFocusPhase) {
      _saveSession();
      setState(() {
        _isFocusPhase = false;
        _remainingSeconds = _breakMinutes * 60;
        _isRunning = true;
      });
      _showPhaseSnackbar('Break time! Rest for $_breakMinutes minutes.');
      _startTimer();
    } else {
      setState(() {
        _isFocusPhase = true;
        _remainingSeconds = _focusMinutes * 60;
        _isRunning = false;
      });
      _showPhaseSnackbar('Focus session ready. Start when you\'re ready!');
    }
  }

  Future<void> _saveSession() async {
    try {
      final session = StudySession(
        id: generateId(),
        subjectId: _selectedSubjectId,
        durationMinutes: _focusMinutes,
        date: DateTime.now(),
      );
      await context.read<StudySessionProvider>().addSession(session);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Session saved!'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not save session: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _showPhaseSnackbar(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  String _formatTime(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final subjects = context.watch<SubjectProvider>().subjects;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Study Timer'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 16),
              DropdownButtonFormField<String?>(
                value: _selectedSubjectId,
                decoration: const InputDecoration(
                  labelText: 'Link to subject (optional)',
                  border: OutlineInputBorder(),
                ),
                items: [
                  const DropdownMenuItem(
                    value: null,
                    child: Text('No subject'),
                  ),
                  for (final s in subjects)
                    DropdownMenuItem(
                      value: s.id,
                      child: Row(
                        children: [
                          Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: s.color,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(s.name),
                        ],
                      ),
                    ),
                ],
                onChanged: _isRunning
                    ? null
                    : (v) => setState(() => _selectedSubjectId = v),
              ),
              const SizedBox(height: 32),
              AnimatedBuilder(
                animation: _pulseController,
                builder: (context, child) {
                  return Container(
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: (_isFocusPhase
                              ? theme.colorScheme.primary
                              : theme.colorScheme.tertiary)
                          .withOpacity(0.1 + _pulseController.value * 0.05),
                      border: Border.all(
                        color: _isFocusPhase
                            ? theme.colorScheme.primary
                            : theme.colorScheme.tertiary,
                        width: 4,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        _formatTime(_remainingSeconds),
                        style: theme.textTheme.displayMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          fontFeatures: [const FontFeature.tabularFigures()],
                        ),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
              Text(
                _isFocusPhase ? 'Focus' : 'Break',
                style: theme.textTheme.titleLarge?.copyWith(
                  color: _isFocusPhase
                      ? theme.colorScheme.primary
                      : theme.colorScheme.tertiary,
                ),
              ),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  FilledButton.icon(
                    onPressed: _isRunning ? _pauseTimer : _startTimer,
                    icon: Icon(_isRunning ? Icons.pause : Icons.play_arrow),
                    label: Text(_isRunning ? 'Pause' : 'Start'),
                  ),
                  const SizedBox(width: 16),
                  OutlinedButton(
                    onPressed: _resetTimer,
                    child: const Text('Reset'),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text(
                '${_focusMinutes} min focus · ${_breakMinutes} min break',
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
