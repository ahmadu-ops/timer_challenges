import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../models/session.dart';
import '../models/challenge.dart';
import '../providers/providers.dart';
import '../services/timer_service.dart';

class TimerScreen extends ConsumerStatefulWidget {
  const TimerScreen({super.key});

  @override
  ConsumerState<TimerScreen> createState() => _TimerScreenState();
}

class _TimerScreenState extends ConsumerState<TimerScreen> {
  TimerMode _selectedMode = TimerMode.stopwatch;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Timer'),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.emoji_events),
            onPressed: () => context.push('/challenges'),
          ),
          IconButton(
            icon: const Icon(Icons.bar_chart),
            onPressed: () => context.push('/records'),
          ),
        ],
      ),
      body: Column(
        children: <Widget>[
          _ModeSelector(
            selectedMode: _selectedMode,
            onModeChanged: _handleModeChange,
          ),
          const Expanded(child: _TimerContent()),
        ],
      ),
    );
  }

  void _handleModeChange(TimerMode mode) {
    final TimerNotifierState timerState = ref.read(timerProvider);
    if (timerState.state != TimerState.idle) return;

    setState(() {
      _selectedMode = mode;
    });
    ref.read(timerProvider.notifier).setMode(mode);
  }
}

class _ModeSelector extends StatelessWidget {
  const _ModeSelector({
    required this.selectedMode,
    required this.onModeChanged,
  });

  final TimerMode selectedMode;
  final ValueChanged<TimerMode> onModeChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: SegmentedButton<TimerMode>(
        segments: const <ButtonSegment<TimerMode>>[
          ButtonSegment<TimerMode>(
            value: TimerMode.stopwatch,
            label: Text('Chronomètre'),
            icon: Icon(Icons.timer),
          ),
          ButtonSegment<TimerMode>(
            value: TimerMode.countdown,
            label: Text('Compte à rebours'),
            icon: Icon(Icons.hourglass_bottom),
          ),
        ],
        selected: <TimerMode>{selectedMode},
        onSelectionChanged: (Set<TimerMode> selection) {
          onModeChanged(selection.first);
        },
      ),
    );
  }
}

class _TimerContent extends ConsumerWidget {
  const _TimerContent();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final TimerNotifierState timerState = ref.watch(timerProvider);

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        _TimerDisplay(timerState: timerState),
        const SizedBox(height: 32),
        if (timerState.mode == TimerMode.countdown && timerState.state == TimerState.idle)
          const _CountdownConfig(),
        const SizedBox(height: 32),
        _TimerControls(timerState: timerState),
        const SizedBox(height: 24),
        const _ChallengeSelector(),
      ],
    );
  }
}

class _TimerDisplay extends StatelessWidget {
  const _TimerDisplay({required this.timerState});

  final TimerNotifierState timerState;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final bool isFinished = timerState.state == TimerState.finished;

    return Card(
      color: isFinished ? colors.errorContainer : null,
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Text(
          TimerService.formatTime(timerState.elapsedMs),
          style: Theme.of(context).textTheme.displayLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: isFinished ? colors.onErrorContainer : null,
              ),
        ),
      ),
    );
  }
}

class _CountdownConfig extends ConsumerWidget {
  const _CountdownConfig();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final TimerNotifierState timerState = ref.watch(timerProvider);
    final int currentMinutes = timerState.targetMs ~/ 60000;

    return Column(
      children: <Widget>[
        Text(
          'Durée: $currentMinutes minutes',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            IconButton.filled(
              onPressed: currentMinutes > 1
                  ? () => ref.read(timerProvider.notifier).setTargetMinutes(currentMinutes - 1)
                  : null,
              icon: const Icon(Icons.remove),
            ),
            const SizedBox(width: 16),
            IconButton.filled(
              onPressed: () => ref.read(timerProvider.notifier).setTargetMinutes(currentMinutes + 1),
              icon: const Icon(Icons.add),
            ),
          ],
        ),
      ],
    );
  }
}

class _TimerControls extends ConsumerWidget {
  const _TimerControls({required this.timerState});

  final TimerNotifierState timerState;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        if (timerState.state == TimerState.idle || timerState.state == TimerState.paused)
          ElevatedButton.icon(
            onPressed: () => ref.read(timerProvider.notifier).start(),
            icon: const Icon(Icons.play_arrow),
            label: const Text('Démarrer'),
          ),
        if (timerState.state == TimerState.running)
          ElevatedButton.icon(
            onPressed: () => ref.read(timerProvider.notifier).pause(),
            icon: const Icon(Icons.pause),
            label: const Text('Pause'),
          ),
        const SizedBox(width: 16),
        if (timerState.state != TimerState.idle)
          TextButton.icon(
            onPressed: () => ref.read(timerProvider.notifier).reset(),
            icon: const Icon(Icons.stop),
            label: const Text('Réinitialiser'),
          ),
        if (timerState.state == TimerState.paused || timerState.state == TimerState.finished)
          TextButton.icon(
            onPressed: () => _handleSave(context, ref),
            icon: const Icon(Icons.save),
            label: const Text('Enregistrer'),
          ),
      ],
    );
  }

  Future<void> _handleSave(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(timerProvider.notifier).saveSession(ref.read(recordsServiceProvider));
      ref.read(timerProvider.notifier).reset();
      ref.read(recordsProvider.notifier).loadRecords();
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Session enregistrée avec succès')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    }
  }
}

class _ChallengeSelector extends ConsumerWidget {
  const _ChallengeSelector();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final List<Challenge> challenges = ref.watch(challengesProvider);
    final TimerNotifierState timerState = ref.watch(timerProvider);
    
    final List<Challenge> activeChallenges = challenges
        .where((Challenge c) => !c.isCompleted)
        .toList();

    if (activeChallenges.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: DropdownButton<String?>(
        isExpanded: true,
        hint: const Text('Lier à un défi (optionnel)'),
        value: timerState.linkedChallengeId,
        items: <DropdownMenuItem<String?>>[
          const DropdownMenuItem<String?>(
            value: null,
            child: Text('Aucun défi'),
          ),
          ...activeChallenges.map((Challenge c) {
            return DropdownMenuItem<String?>(
              value: c.id,
              child: Text(c.title),
            );
          }),
        ],
        onChanged: (String? value) {
          ref.read(timerProvider.notifier).linkChallenge(value);
        },
      ),
    );
  }
}