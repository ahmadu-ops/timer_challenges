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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: <Widget>[
            _ModeSelector(
              selectedMode: _selectedMode,
              onModeChanged: _handleModeChange,
            ),
            const SizedBox(height: 24),
            const _TimerContent(),
          ],
        ),
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
    return SegmentedButton<TimerMode>(
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
    );
  }
}

class _TimerContent extends ConsumerWidget {
  const _TimerContent();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final TimerNotifierState timerState = ref.watch(timerProvider);

    return Column(
      children: <Widget>[
        _TimerDisplay(timerState: timerState),
        const SizedBox(height: 24),
        if (timerState.mode == TimerMode.countdown && timerState.state == TimerState.idle)
          const _CountdownConfig()
        else
          const SizedBox(height: 120),
        const SizedBox(height: 24),
        _TimerControls(timerState: timerState),
        const SizedBox(height: 16),
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

    final int displayMs = timerState.mode == TimerMode.countdown
        ? (timerState.targetMs - timerState.elapsedMs).clamp(0, timerState.targetMs)
        : timerState.elapsedMs;

    return Card(
      color: isFinished ? colors.errorContainer : colors.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: <Widget>[
            FittedBox(  // ← AJOUT pour adapter la taille
              fit: BoxFit.scaleDown,
              child: Text(
                TimerService.formatTime(displayMs),
                style: Theme.of(context).textTheme.displayLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 56,  // ← Réduction de la taille
                      color: isFinished ? colors.onErrorContainer : colors.onPrimaryContainer,
                      fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
                    ),
              ),
            ),
            if (timerState.mode == TimerMode.countdown && timerState.targetMs > 0) ...<Widget>[
              const SizedBox(height: 16),
              LinearProgressIndicator(
                value: timerState.elapsedMs / timerState.targetMs,
                backgroundColor: Colors.white24,
                minHeight: 8,
                borderRadius: BorderRadius.circular(4),
              ),
            ],
          ],
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
    final int totalSeconds = timerState.targetMs ~/ 1000;
    final int hours = totalSeconds ~/ 3600;
    final int minutes = (totalSeconds % 3600) ~/ 60;
    final int seconds = totalSeconds % 60;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: <Widget>[
            Text(
              'Définir la durée',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: <Widget>[
                _TimeColumn(
                  label: 'H',
                  value: hours,
                  onIncrement: () => ref.read(timerProvider.notifier).setTargetMs(timerState.targetMs + 3600000),
                  onDecrement: hours > 0 ? () => ref.read(timerProvider.notifier).setTargetMs(timerState.targetMs - 3600000) : null,
                ),
                _TimeColumn(
                  label: 'M',
                  value: minutes,
                  onIncrement: () => ref.read(timerProvider.notifier).setTargetMs(timerState.targetMs + 60000),
                  onDecrement: minutes > 0 || hours > 0 ? () => ref.read(timerProvider.notifier).setTargetMs(timerState.targetMs - 60000) : null,
                ),
                _TimeColumn(
                  label: 'S',
                  value: seconds,
                  onIncrement: () => ref.read(timerProvider.notifier).setTargetMs(timerState.targetMs + 1000),
                  onDecrement: seconds > 0 || minutes > 0 || hours > 0 ? () => ref.read(timerProvider.notifier).setTargetMs(timerState.targetMs - 1000) : null,
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Wrap(
              spacing: 8,
              children: <Widget>[
                _QuickChip(label: '30s', seconds: 30),
                _QuickChip(label: '1m', seconds: 60),
                _QuickChip(label: '5m', seconds: 300),
                _QuickChip(label: '10m', seconds: 600),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TimeColumn extends StatelessWidget {
  const _TimeColumn({
    required this.label,
    required this.value,
    required this.onIncrement,
    required this.onDecrement,
  });

  final String label;
  final int value;
  final VoidCallback onIncrement;
  final VoidCallback? onDecrement;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Text(label, style: Theme.of(context).textTheme.bodySmall),
        IconButton(
          onPressed: onIncrement,
          icon: const Icon(Icons.arrow_drop_up, size: 32),
        ),
        Container(
          width: 50,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            value.toString().padLeft(2, '0'),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
        ),
        IconButton(
          onPressed: onDecrement,
          icon: const Icon(Icons.arrow_drop_down, size: 32),
        ),
      ],
    );
  }
}

class _QuickChip extends ConsumerWidget {
  const _QuickChip({required this.label, required this.seconds});

  final String label;
  final int seconds;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ActionChip(
      label: Text(label),
      onPressed: () => ref.read(timerProvider.notifier).setTargetMs(seconds * 1000),
    );
  }
}

class _TimerControls extends ConsumerWidget {
  const _TimerControls({required this.timerState});

  final TimerNotifierState timerState;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      children: <Widget>[
        if (timerState.state == TimerState.idle || timerState.state == TimerState.paused)
          FilledButton.icon(
            onPressed: () => ref.read(timerProvider.notifier).start(),
            icon: const Icon(Icons.play_arrow),
            label: const Text('Démarrer'),
          ),
        if (timerState.state == TimerState.running)
          FilledButton.icon(
            onPressed: () => ref.read(timerProvider.notifier).pause(),
            icon: const Icon(Icons.pause),
            label: const Text('Pause'),
          ),
        if (timerState.state != TimerState.idle)
          OutlinedButton.icon(
            onPressed: () => ref.read(timerProvider.notifier).reset(),
            icon: const Icon(Icons.stop),
            label: const Text('Reset'),
          ),
        if (timerState.state == TimerState.paused || timerState.state == TimerState.finished)
          FilledButton.tonalIcon(
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
          const SnackBar(content: Text('Session enregistrée ✓')),
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
    
    final List<Challenge> activeChallenges = challenges.where((Challenge c) => !c.isCompleted).toList();

    if (activeChallenges.isEmpty) {
      return const SizedBox.shrink();
    }

    return DropdownButtonFormField<String?>(
      decoration: const InputDecoration(
        labelText: 'Lier à un défi',
        prefixIcon: Icon(Icons.emoji_events),
      ),
      initialValue: timerState.linkedChallengeId,  // ← CORRECTION ICI (value → initialValue)
      items: <DropdownMenuItem<String?>>[
        const DropdownMenuItem<String?>(
          value: null,
          child: Text('Aucun'),
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
    );
  }
}