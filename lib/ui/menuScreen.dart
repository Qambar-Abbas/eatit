import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:eatit/services/userService.dart';
import 'package:eatit/ui/cookMenuScreen.dart';
import 'package:eatit/ui/userMenuScreen.dart';

import '../models/familyModel.dart';
import '../services/riverpods/familyRiverpod.dart';

class MenuScreen extends ConsumerStatefulWidget {
  const MenuScreen({super.key});

  @override
  _MenuScreenState createState() => _MenuScreenState();
}

class _MenuScreenState extends ConsumerState<MenuScreen> {
  String? _userEmail;
  String? _selectedFamilyCode;
  late Future<List<FamilyModel>> _familiesFuture;

  @override
  void initState() {
    super.initState();
    _initUserAndFamilies();
  }

  Future<void> _initUserAndFamilies() async {
    final email = await UserService().loadCachedUserEmail();
    if (!mounted) return;
    setState(() {
      _userEmail = email;
      _familiesFuture = ref.read(userFamiliesProvider(email!).future);
    });
  }

  void _onFamilyChanged(String? newCode) {
    if (newCode == null) return;
    setState(() {
      _selectedFamilyCode = newCode;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_userEmail == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return FutureBuilder<List<FamilyModel>>(
      future: _familiesFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        } else if (snapshot.hasError) {
          return Scaffold(
            body: Center(
                child: Text('Error loading families: ${snapshot.error}')),
          );
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Scaffold(
            appBar: AppBar(centerTitle: true, title: const Text("No Family")),
            body: const Center(
              child: Text("You have not joined or created any family yet."),
            ),
          );
        }

        final families = snapshot.data!;
        if (_selectedFamilyCode == null ||
            !families.any((f) => f.familyCode == _selectedFamilyCode)) {
          _selectedFamilyCode = families.first.familyCode;
        }

        final selectedFamily = families.firstWhere(
          (f) => f.familyCode == _selectedFamilyCode,
          orElse: () => families.first,
        );

        final bool isCook = selectedFamily.cook == _userEmail;

        return Scaffold(
          appBar: AppBar(
            centerTitle: true,
            title: DropdownButton<String>(
              value: _selectedFamilyCode,
              items: families.map((family) {
                return DropdownMenuItem(
                  value: family.familyCode,
                  child: Text(family.familyName),
                );
              }).toList(),
              onChanged: _onFamilyChanged,
            ),
          ),
          body: isCook
              ? CookMenuScreen(
                  onSwitchScreen: (int index) {},
                  families: families,
                  selectedFamilyCode: _selectedFamilyCode!,
                  onFamilyChange: _onFamilyChanged,
                )
              : UserMenuScreen(
                  onSwitchScreen: (int index) {},
                  families: families,
                  selectedFamilyCode: _selectedFamilyCode!,
                  onFamilyChange: _onFamilyChanged,
                ),
        );
      },
    );
  }
}
