import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:wizard_xi_app/models/models.dart';
import 'package:wizard_xi_app/widgets/match_tile.dart';

void main() {
  testWidgets('match tile renders match and button', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MatchTile(
            match: FantasyMatch(
              id: 'match-1',
              teamA: 'India',
              teamB: 'Australia',
              startTime: DateTime(2026, 4, 1, 18),
              venue: 'Wankhede Stadium',
              tournament: 'ODI Series',
            ),
            subtitle: 'Wed, 1 Apr - 06:00 PM',
            onGenerateTeams: () {},
          ),
        ),
      ),
    );

    expect(find.text('India vs Australia'), findsOneWidget);
    expect(find.text('Generate Teams'), findsOneWidget);
  });
}
