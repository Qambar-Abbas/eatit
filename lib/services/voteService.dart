// services/vote_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:eatit/models/voteModel.dart';

class VoteService {
  final _db = FirebaseFirestore.instance;
  CollectionReference<Map<String, dynamic>> _votes(String familyCode) =>
      _db.collection('families_collection').doc(familyCode).collection('votes');

  Future<void> startVote({
    required String familyCode,
    required List<String> choices,
  }) async {
    final now = DateTime.now();
    final doc = _votes(familyCode).doc();
    await doc.set({
      'choices': choices,
      'startedAt': Timestamp.fromDate(now),
      'endsAt': Timestamp.fromDate(now.add(const Duration(minutes: 15))),
    });
  }

  Stream<List<VoteSession>> watchActiveSessions(String familyCode) {
    final now = Timestamp.fromDate(DateTime.now());
    return _votes(familyCode)
        .where('endsAt', isGreaterThan: now)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => VoteSession.fromMap(d.id, d.data())).toList());
  }

  Stream<List<Vote>> watchVotes(String familyCode, String sessionId) {
    return _votes(familyCode)
        .doc(sessionId)
        .collection('votes')
        .snapshots()
        .map((snap) => snap.docs.map((d) => Vote.fromMap(d.data())).toList());
  }

  Future<void> castVote({
    required String familyCode,
    required String sessionId,
    required Vote vote,
  }) =>
      _votes(familyCode)
          .doc(sessionId)
          .collection('votes')
          .doc(vote.voterEmail)
          .set(vote.toMap());
}
