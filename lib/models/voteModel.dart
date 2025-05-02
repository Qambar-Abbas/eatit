import 'package:cloud_firestore/cloud_firestore.dart';

class VoteSession {
  final String id;
  final List<String> choices;
  final DateTime startedAt;
  final DateTime endsAt;

  VoteSession({
    required this.id,
    required this.choices,
    required this.startedAt,
    required this.endsAt,
  });

  factory VoteSession.fromMap(String id, Map<String, dynamic> map) =>
      VoteSession(
        id: id,
        choices: List<String>.from(map['choices'] ?? const []),
        startedAt: (map['startedAt'] as Timestamp).toDate(),
        endsAt: (map['endsAt'] as Timestamp).toDate(),
      );
}

class Vote {
  final String voterEmail;
  final String choice;

  Vote({required this.voterEmail, required this.choice});

  factory Vote.fromMap(Map<String, dynamic> map) => Vote(
        voterEmail: map['voterEmail'],
        choice: map['choice'],
      );

  Map<String, dynamic> toMap() => {
        'voterEmail': voterEmail,
        'choice': choice,
      };
}
