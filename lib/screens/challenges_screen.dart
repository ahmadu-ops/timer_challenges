import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../models/challenge.dart';
import '../providers/providers.dart';

class ChallengesScreen extends ConsumerWidget {
  const ChallengesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final List<Challenge> challenges = ref.watch(challengesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Défis'),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => context.push('/create-challenge'),
          ),
        ],
      ),
      body: challenges.isEmpty
          ? const _EmptyState()
          : ListView.builder(
              itemCount: challenges.length,
              itemBuilder: (BuildContext context, int index) {
                return _ChallengeCard(challenge: challenges[index]);
              },
            ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Icon(
            Icons.emoji_events_outlined,
            size: 64,
            color: Theme.of(context).colorScheme.secondary,
          ),
          const SizedBox(height: 16),
          Text(
            'Aucun défi pour le moment',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          const Text('Appuyez sur + pour créer votre premier défi'),
        ],
      ),
    );
  }
}

class _ChallengeCard extends ConsumerWidget {
  const _ChallengeCard({required this.challenge});

  final Challenge challenge;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ColorScheme colors = Theme.of(context).colorScheme;

    return Card(
      child: ListTile(
        leading: Icon(
          challenge.isCompleted ? Icons.check_circle : Icons.radio_button_unchecked,
          color: challenge.isCompleted ? colors.primary : null,
        ),
        title: Text(
          challenge.title,
          style: TextStyle(
            decoration: challenge.isCompleted ? TextDecoration.lineThrough : null,
          ),
        ),
        subtitle: _buildSubtitle(context),
        trailing: _buildActions(context, ref),
      ),
    );
  }

  Widget _buildSubtitle(BuildContext context) {
    final List<String> parts = <String>[
      '${challenge.targetMinutes} min',
    ];

    if (challenge.description != null && challenge.description!.isNotEmpty) {
      parts.add(challenge.description!);
    }

    return Text(parts.join(' • '));
  }

  Widget _buildActions(BuildContext context, WidgetRef ref) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        IconButton(
          icon: const Icon(Icons.check),
          onPressed: () => _handleToggle(context, ref),
        ),
        IconButton(
          icon: const Icon(Icons.delete),
          onPressed: () => _handleDelete(context, ref),
        ),
      ],
    );
  }

  Future<void> _handleToggle(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(challengesProvider.notifier).toggleComplete(challenge.id);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    }
  }

  Future<void> _handleDelete(BuildContext context, WidgetRef ref) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: const Text('Voulez-vous vraiment supprimer ce défi ?'),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await ref.read(challengesProvider.notifier).deleteChallenge(challenge.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Défi supprimé')),
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