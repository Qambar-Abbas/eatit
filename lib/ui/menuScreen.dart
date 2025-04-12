import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:eatit/services/userService.dart';
import 'package:eatit/riverpods/familyriverpod.dart';
import 'package:eatit/ui/cookMenuScreen.dart';
import 'package:eatit/ui/userMenuScreen.dart';

class MenuScreen extends ConsumerStatefulWidget {
  const MenuScreen({Key? key}) : super(key: key);

  @override
  _MenuScreenState createState() => _MenuScreenState();
}

class _MenuScreenState extends ConsumerState<MenuScreen> {
  String? _userEmail;
  String? _selectedFamilyCode;
  bool _isUserEmailLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadUserEmail();
  }

  Future<void> _loadUserEmail() async {
    final email = await UserService().loadCachedUserEmail();
    if (mounted) {
      setState(() {
        _userEmail = email;
        _isUserEmailLoaded = true;
      });
    }
  }

  void _onFamilyChanged(String? newCode) {
    if (newCode == null) return;
    setState(() {
      _selectedFamilyCode = newCode;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_isUserEmailLoaded || _userEmail == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final familiesAsync = ref.watch(userFamiliesProvider(_userEmail!));

    return familiesAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => Scaffold(
        body: Center(child: Text('Error loading families: $error')),
      ),
      data: (families) {
        if (families.isEmpty) {
          return Scaffold(
            appBar: AppBar(centerTitle: true, title: const Text("No Family")),
            body: const Center(
              child: Text("You have not joined or created any family yet."),
            ),
          );
        }

        if (_selectedFamilyCode == null ||
            !families.any((f) => f.familyCode == _selectedFamilyCode)) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            setState(() {
              _selectedFamilyCode = families.first.familyCode;
            });
          });
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
