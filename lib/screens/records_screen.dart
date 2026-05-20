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

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Records'),
          bottom: const TabBar(
            tabs: <Tab>[
              Tab(text: 'Global', icon: Icon(Icons.public)),
              Tab(text: 'Par défi', icon: Icon(Icons.emoji_events)),
            ],
          ),
        ),
        body: TabBarView(
          children: <Widget>[
            _GlobalRecords(records: records),
            _ChallengeRecords(records: records),
          ],
        ),
      ),
    );
  }
}

class _GlobalRecords extends StatelessWidget {
  const _GlobalRecords({required this.records});

  final RecordsState records;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async {
        // Refresh handled by provider
      },
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          _StatsCards(records: records),
          const SizedBox(height: 24),
          _HistorySection(history: records.history),
        ],
      ),
    );
  }
}

class _ChallengeRecords extends ConsumerWidget {
  const _ChallengeRecords({required this.records});

  final RecordsState records;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final List<Challenge> challenges = ref.watch(challengesProvider);

    if (challenges.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(Icons.emoji_events_outlined, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('Aucun défi créé'),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: challenges.length,
      itemBuilder: (BuildContext context, int index) {
        final Challenge challenge = challenges[index];
        final int? bestTime = records.bestTimePerChallenge[challenge.id];
        final int sessionCount = records.sessionsPerChallenge[challenge.id] ?? 0;

        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Icon(
                      challenge.isCompleted ? Icons.check_circle : Icons.emoji_events,
                      color: challenge.isCompleted ? Colors.green : Colors.orange,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        challenge.title,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _ChallengeStatRow(
                  icon: Icons.timer,
                  label: 'Meilleur temps',
                  value: bestTime != null ? TimerService.formatTime(bestTime) : '--:--:--',
                ),
                _ChallengeStatRow(
                  icon: Icons.play_circle,
                  label: 'Sessions',
                  value: sessionCount.toString(),
                ),
                _ChallengeStatRow(
                  icon: Icons.tablet,
                  label: 'Objectif',
                  value: '${challenge.targetMinutes} min',
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ChallengeStatRow extends StatelessWidget {
  const _ChallengeStatRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: <Widget>[
          Icon(icon, size: 20, color: Colors.grey),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
        ],
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
        padding: const EdgeInsets.all(16),
        child: Column(
          children: <Widget>[
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            FittedBox(
              child: Text(
                value,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
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
        padding: EdgeInsets.all(32),
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