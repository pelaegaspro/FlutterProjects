import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/models.dart';
import 'demo_data_service.dart';

abstract class FantasyRepository {
  Future<List<FantasyMatch>> getMatches();
  Future<List<FantasyPlayer>> getPlayersForMatch(String matchId);
}

class FirebaseFantasyRepository implements FantasyRepository {
  FirebaseFantasyRepository(this._firestore);

  final FirebaseFirestore _firestore;

  @override
  Future<List<FantasyMatch>> getMatches() async {
    final snapshot = await _firestore.collection('matches').get();
    final matches = snapshot.docs
        .map((doc) => FantasyMatch.fromMap(_normalizeMap(doc.id, doc.data())))
        .toList()
      ..sort((a, b) => a.startTime.compareTo(b.startTime));
    return matches;
  }

  @override
  Future<List<FantasyPlayer>> getPlayersForMatch(String matchId) async {
    final nestedPlayers = await _firestore
        .collection('matches')
        .doc(matchId)
        .collection('players')
        .get();

    if (nestedPlayers.docs.isNotEmpty) {
      return _mapPlayers(nestedPlayers.docs);
    }

    final rootPlayersByCamel = await _firestore
        .collection('players')
        .where('matchId', isEqualTo: matchId)
        .get();
    if (rootPlayersByCamel.docs.isNotEmpty) {
      return _mapPlayers(rootPlayersByCamel.docs);
    }

    final rootPlayersBySnake = await _firestore
        .collection('players')
        .where('match_id', isEqualTo: matchId)
        .get();
    return _mapPlayers(rootPlayersBySnake.docs);
  }

  List<FantasyPlayer> _mapPlayers(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) {
    final players = docs
        .map((doc) => FantasyPlayer.fromMap(_normalizeMap(doc.id, doc.data())))
        .toList()
      ..sort((a, b) => b.projectedScore.compareTo(a.projectedScore));
    return players;
  }

  Map<String, dynamic> _normalizeMap(
    String id,
    Map<String, dynamic> data,
  ) {
    final normalized = <String, dynamic>{'id': id};
    data.forEach((key, value) {
      if (value is Timestamp) {
        normalized[key] = value.toDate().toIso8601String();
      } else {
        normalized[key] = value;
      }
    });
    return normalized;
  }
}

class DemoFantasyRepository implements FantasyRepository {
  @override
  Future<List<FantasyMatch>> getMatches() async {
    return DemoDataService.matches;
  }

  @override
  Future<List<FantasyPlayer>> getPlayersForMatch(String matchId) async {
    final players = DemoDataService.playersByMatch[matchId] ?? const [];
    return [...players]..sort((a, b) => b.projectedScore.compareTo(a.projectedScore));
  }
}
