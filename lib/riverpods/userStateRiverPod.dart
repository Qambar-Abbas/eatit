import 'package:eatit/models/userModel.dart';
import 'package:eatit/services/userService.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final userStateProvider = StateNotifierProvider<UserStateNotifier, UserModel?>(
  (ref) => UserStateNotifier(),
);

class UserStateNotifier extends StateNotifier<UserModel?> {
  UserStateNotifier() : super(null);

  Future<void> loadUserData() async {
    try {
      final user = await UserService().loadCachedUserData();
      state = user;
    } catch (e) {
      state = null;
    }
  }
}
