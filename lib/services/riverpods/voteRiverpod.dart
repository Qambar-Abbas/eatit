// services/riverpods/vote_providers.dart
import 'package:eatit/models/voteModel.dart';
import 'package:eatit/services/voteService.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tuple/tuple.dart';

final voteServiceProvider = Provider((_) => VoteService());

/// Active vote sessions for a family
final activeSessionsProvider = StreamProvider.family
    .autoDispose<List<VoteSession>, String>((ref, familyCode) {
  return ref.read(voteServiceProvider).watchActiveSessions(familyCode);
});

/// All individual votes in a session
final sessionVotesProvider = StreamProvider.family
    .autoDispose<List<Vote>, Tuple2<String, String>>((ref, data) {
  final family = data.item1, session = data.item2;
  return ref.read(voteServiceProvider).watchVotes(family, session);
});
