import 'package:eatit/ui/cookMenuScreen.dart';
import 'package:eatit/ui/userMenuScreen.dart';
import 'package:flutter/material.dart';

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

class MenuSelectorScreen extends StatefulWidget {
  final Function(int) onSelectMenu;

  const MenuSelectorScreen({super.key, required this.onSelectMenu});

  @override
  State<MenuSelectorScreen> createState() => _MenuSelectorScreenState();
}

class _MenuSelectorScreenState extends State<MenuSelectorScreen> {
  String? _dropdownValue;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: DropdownButton<String>(
          value: _dropdownValue,
          hint: const Text(
            'Select Family',
          ),
          items: const [
            DropdownMenuItem(
              value: 'User Menu',
              child: Text('User Menu'),
            ),
            DropdownMenuItem(
              value: 'Cook Menu',
              child: Text('Cook Menu'),
            ),
          ],
          onChanged: (String? newValue) {
            if (newValue == null) return;
            setState(() => _dropdownValue = newValue);

            if (newValue == 'User Menu') {
              widget.onSelectMenu(1);
            } else if (newValue == 'Cook Menu') {
              widget.onSelectMenu(2);
            }
          },
        ),
        centerTitle: true,
      ),
      body: const SizedBox(),
    );
  }
}
