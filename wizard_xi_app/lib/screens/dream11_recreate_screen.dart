import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/app_theme.dart';
import '../models/models.dart';
import '../providers/fantasy_providers.dart';

class Dream11RecreateScreen extends ConsumerStatefulWidget {
  const Dream11RecreateScreen({
    super.key,
    required this.match,
    required this.team,
  });

  final FantasyMatch match;
  final GeneratedTeam team;

  @override
  ConsumerState<Dream11RecreateScreen> createState() =>
      _Dream11RecreateScreenState();
}

class _Dream11RecreateScreenState
    extends ConsumerState<Dream11RecreateScreen> {
  final Set<String> _selectedPlayers = <String>{};
  bool _launching = false;

  @override
  Widget build(BuildContext context) {
    final selectionOrder = widget.team.selectionOrder;
    final nextPlayer = selectionOrder.firstWhere(
      (player) => !_selectedPlayers.contains(player.id),
      orElse: () => selectionOrder.last,
    );
    final completed = _selectedPlayers.length == selectionOrder.length;

    return Scaffold(
      appBar: AppBar(
        title: Text('Dream11 Guide • Team ${widget.team.teamNumber}'),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.backgroundTop,
              AppColors.background,
            ],
          ),
        ),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.match.title,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        completed
                            ? '11/11 players marked. Team is ready.'
                            : 'Pick next: ${nextPlayer.name}',
                        style: TextStyle(
                          color: completed
                              ? AppColors.accent
                              : AppColors.secondaryAccent,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 12),
                      LinearProgressIndicator(
                        value: _selectedPlayers.length / selectionOrder.length,
                        minHeight: 10,
                        backgroundColor: AppColors.cardMuted,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${_selectedPlayers.length}/11 selected',
                        style: const TextStyle(color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: _launching ? null : _openDream11,
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.accent,
                            foregroundColor: AppColors.background,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: Text(
                            _launching ? 'Opening Dream11...' : 'Create in Dream11',
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              ...selectionOrder.map(
                (player) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Card(
                    child: CheckboxListTile(
                      value: _selectedPlayers.contains(player.id),
                      onChanged: (_) {
                        setState(() {
                          if (_selectedPlayers.contains(player.id)) {
                            _selectedPlayers.remove(player.id);
                          } else {
                            _selectedPlayers.add(player.id);
                          }
                        });
                      },
                      title: Text(
                        player.name,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      subtitle: Text(
                        '${player.role} • ${player.team} • ${player.credit.toStringAsFixed(1)} cr',
                        style: const TextStyle(color: AppColors.textSecondary),
                      ),
                      secondary: _BadgePair(
                        isCaptain: widget.team.captainId == player.id,
                        isViceCaptain: widget.team.viceCaptainId == player.id,
                      ),
                      controlAffinity: ListTileControlAffinity.trailing,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openDream11() async {
    setState(() {
      _launching = true;
    });

    try {
      await ref.read(dream11LauncherProvider).openDream11();
    } finally {
      if (mounted) {
        setState(() {
          _launching = false;
        });
      }
    }
  }
}

class _BadgePair extends StatelessWidget {
  const _BadgePair({
    required this.isCaptain,
    required this.isViceCaptain,
  });

  final bool isCaptain;
  final bool isViceCaptain;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6,
      children: [
        if (isCaptain) _Pill(label: 'C', color: AppColors.captain),
        if (isViceCaptain) _Pill(label: 'VC', color: AppColors.viceCaptain),
      ],
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({
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
