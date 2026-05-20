import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/session.dart';
import '../models/challenge.dart';
import '../providers/providers.dart';
import '../services/timer_service.dart';

class RecordsScreen extends ConsumerWidget {
  const RecordsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final RecordsState records = ref.watch(recordsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Records'),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.read(recordsProvider.notifier).loadRecords();
        },
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: <Widget>[
            _StatsCards(records: records),
            const SizedBox(height: 24),
            _HistorySection(history: records.history),
          ],
        ),
      ),
    );
  }
}

class _StatsCards extends StatelessWidget {
  const _StatsCards({required this.records});

  final RecordsState records;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(
          child: _StatCard(
            icon: Icons.trending_up,
            label: 'Meilleur temps',
            value: records.bestTimeMs != null
                ? TimerService.formatTime(records.bestTimeMs!)
                : '--:--:--',
            color: Colors.blue,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _StatCard(
            icon: Icons.local_fire_department,
            label: 'Streak',
            value: '${records.currentStreak} jours',
            color: Colors.orange,
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: <Widget>[
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HistorySection extends StatelessWidget {
  const _HistorySection({required this.history});

  final List<Session> history;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          'Historique (${history.length}/20)',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 16),
        if (history.isEmpty)
          const _EmptyHistory()
        else
          ...history.map((Session session) => _HistoryItem(session: session)),
      ],
    );
  }
}

class _EmptyHistory extends StatelessWidget {
  const _EmptyHistory();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32.0),
        child: Text('Aucune session enregistrée'),
      ),
    );
  }
}

class _HistoryItem extends ConsumerWidget {
  const _HistoryItem({required this.session});

  final Session session;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final List<Challenge> challenges = ref.watch(challengesProvider);
    final Challenge? linkedChallenge = session.challengeId != null
        ? challenges.cast<Challenge?>().firstWhere(
              (Challenge? c) => c?.id == session.challengeId,
              orElse: () => null,
            )
        : null;

    return Card(
      child: ListTile(
        leading: Icon(
          session.type == TimerMode.stopwatch ? Icons.timer : Icons.hourglass_bottom,
        ),
        title: Text(TimerService.formatTime(session.durationMs)),
        subtitle: _buildSubtitle(linkedChallenge),
        trailing: Text(
          _formatDate(session.date),
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ),
    );
  }

  Widget _buildSubtitle(Challenge? linkedChallenge) {
    final String typeLabel = session.type == TimerMode.stopwatch
        ? 'Chronomètre'
        : 'Compte à rebours';

    if (linkedChallenge != null) {
      return Text('$typeLabel • ${linkedChallenge.title}');
    }

    return Text(typeLabel);
  }

  String _formatDate(DateTime date) {
    final DateTime now = DateTime.now();
    final DateTime today = DateTime(now.year, now.month, now.day);
    final DateTime sessionDay = DateTime(date.year, date.month, date.day);

    if (sessionDay == today) {
      return 'Aujourd\'hui';
    } else if (sessionDay == today.subtract(const Duration(days: 1))) {
      return 'Hier';
    } else {
      return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
    }
  }
}