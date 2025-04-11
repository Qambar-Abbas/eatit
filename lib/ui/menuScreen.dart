import 'package:eatit/models/familyModel.dart';
import 'package:eatit/riverpods/familyriverpod.dart';
import 'package:eatit/services/userService.dart';
import 'package:eatit/ui/cookMenuScreen.dart';
import 'package:eatit/ui/userMenuScreen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class MenuScreenWrapper extends StatefulWidget {
  const MenuScreenWrapper({super.key});

  @override
  State<MenuScreenWrapper> createState() => _MenuScreenWrapperState();
}

class _MenuScreenWrapperState extends State<MenuScreenWrapper> {
  int _selectedScreenIndex = 0;

  void _navigateToScreen(int index) {
    setState(() => _selectedScreenIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    switch (_selectedScreenIndex) {
      case 1:
        return UserMenuScreen(onSwitchScreen: _navigateToScreen);
      case 2:
        return CookMenuScreen(onSwitchScreen: _navigateToScreen);
      default:
        return MenuSelectorScreen(onSelectMenu: _navigateToScreen);
    }
  }
}

class MenuSelectorScreen extends ConsumerStatefulWidget {
  final Function(int) onSelectMenu;

  const MenuSelectorScreen({super.key, required this.onSelectMenu});

  @override
  ConsumerState<MenuSelectorScreen> createState() => _MenuSelectorScreenState();
}

class _MenuSelectorScreenState extends ConsumerState<MenuSelectorScreen> {
  String? _selectedFamilyCode;
  late Future<String?> _userEmailFuture;

  @override
  void initState() {
    super.initState();
    _userEmailFuture = UserService().loadCachedUserEmail();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: _userEmailFuture,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final userEmail = snapshot.data!;
        final familyAsyncValue = ref.watch(userFamiliesProvider(userEmail));

        return Scaffold(
          appBar: AppBar(
            title: familyAsyncValue.when(
              loading: () => const Text("Loading families..."),
              error: (error, _) => Text("Error: $error"),
              data: (families) {
                return DropdownButton<String>(
                  value: _selectedFamilyCode,
                  hint: const Text('Select Family'),
                  items: families.map((family) {
                    return DropdownMenuItem(
                      value: family.familyCode,
                      child: Text(family.familyName),
                    );
                  }).toList(),
                  onChanged: (String? selectedCode) {
                    setState(() => _selectedFamilyCode = selectedCode);

                    // Example logic for routing — you can adjust
                    if (families.any((f) =>
                        f.familyCode == selectedCode &&
                        f.adminEmail == userEmail)) {
                      widget.onSelectMenu(2); // Cook Menu
                    } else {
                      widget.onSelectMenu(1); // User Menu
                    }
                  },
                );
              },
            ),
            centerTitle: true,
          ),
          body: const SizedBox(),
        );
      },
    );
  }
}
