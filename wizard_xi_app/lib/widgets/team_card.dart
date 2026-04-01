import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../core/constants.dart';
import '../models/models.dart';

class TeamCard extends StatelessWidget {
  const TeamCard({
    super.key,
    required this.team,
    required this.onCopy,
    required this.onCreateInDream11,
  });

  final GeneratedTeam team;
  final VoidCallback onCopy;
  final VoidCallback onCreateInDream11;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              runSpacing: 10,
              spacing: 12,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Team ${team.teamNumber}',
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${team.totalCredits.toStringAsFixed(1)} credits - ${team.totalProjection.toStringAsFixed(1)} projected score',
                      style: const TextStyle(color: AppColors.textSecondary),
                    ),
                  ],
                ),
                Wrap(
                  spacing: 10,
                  children: [
                    OutlinedButton(
                      onPressed: onCopy,
                      child: const Text('Copy Team'),
                    ),
                    FilledButton.tonal(
                      onPressed: onCreateInDream11,
                      child: const Text('Create in Dream11'),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 18),
            for (final role in AppConstants.roleOrder) ...[
              _RoleSection(
                title: role,
                players: team.playersForRole(role),
                captainId: team.captainId,
                viceCaptainId: team.viceCaptainId,
              ),
              if (role != AppConstants.roleOrder.last) const SizedBox(height: 14),
            ],
          ],
        ),
      ),
    );
  }
}

class _RoleSection extends StatelessWidget {
  const _RoleSection({
    required this.title,
    required this.players,
    required this.captainId,
    required this.viceCaptainId,
  });

  final String title;
  final List<FantasyPlayer> players;
  final String captainId;
  final String viceCaptainId;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: AppColors.secondaryAccent,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.6,
          ),
        ),
        const SizedBox(height: 8),
        ...players.map(
          (player) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.cardMuted,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          player.name,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${player.team} - ${player.credit.toStringAsFixed(1)} cr',
                          style: const TextStyle(color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  Wrap(
                    spacing: 8,
                    children: [
                      if (player.id == captainId)
                        _Badge(label: 'C', color: AppColors.captain),
                      if (player.id == viceCaptainId)
                        _Badge(label: 'VC', color: AppColors.viceCaptain),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({
    required this.label,
    required this.color,
  });

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.16),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
