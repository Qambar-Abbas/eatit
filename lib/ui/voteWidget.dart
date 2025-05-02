import 'dart:async';

import 'package:eatit/models/voteModel.dart';
import 'package:eatit/services/riverpods/voteRiverpod.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class VoteWidget extends ConsumerStatefulWidget {
  final VoteSession session;
  final String familyCode;
  final String userEmail;

  const VoteWidget({
    Key? key,
    required this.session,
    required this.familyCode,
    required this.userEmail,
  }) : super(key: key);

  @override
  ConsumerState<VoteWidget> createState() => _VoteWidgetState();
}

class _VoteWidgetState extends ConsumerState<VoteWidget> {
  String? _selectedOption;
  Timer? _timer;
  late Duration _remaining;

  @override
  void initState() {
    super.initState();
    _remaining = widget.session.endsAt.difference(DateTime.now());
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      final now = DateTime.now();
      setState(() {
        _remaining = widget.session.endsAt.difference(now);
      });
      if (_remaining.isNegative) t.cancel();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_selectedOption == null) return;
    await ref.read(voteServiceProvider).castVote(
          familyCode: widget.familyCode,
          sessionId: widget.session.id,
          vote: Vote(voterEmail: widget.userEmail, choice: _selectedOption!),
        );
    setState(() {}); // refresh UI if needed
  }

  @override
  Widget build(BuildContext context) {
    // show closed if time’s up
    if (_remaining.isNegative) {
      return const Center(child: Text('Voting closed.'));
    }

    // countdown + choices
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Time left: '
              '${_remaining.inMinutes.remainder(60).toString().padLeft(2, '0')}'
              ':${_remaining.inSeconds.remainder(60).toString().padLeft(2, '0')}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            // radio list of choices
            ...widget.session.choices.map((choice) {
              return RadioListTile<String>(
                title: Text(choice),
                value: choice,
                groupValue: _selectedOption,
                onChanged: (v) => setState(() => _selectedOption = v),
              );
            }).toList(),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _selectedOption == null ? null : _submit,
              child: const Text('Submit Vote'),
            ),
          ],
        ),
      ),
    );
  }
}
