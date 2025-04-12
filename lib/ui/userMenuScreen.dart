import 'package:eatit/models/familyModel.dart';
import 'package:flutter/material.dart';

class UserMenuScreen extends StatefulWidget {
  final Function(int) onSwitchScreen;
  final List<FamilyModel> families;
  final String selectedFamilyCode;
  final Function(String) onFamilyChange;

  const UserMenuScreen({
    super.key,
    required this.onSwitchScreen,
    required this.families,
    required this.selectedFamilyCode,
    required this.onFamilyChange,
  });

  @override
  _UserMenuScreenState createState() => _UserMenuScreenState();
}

class _UserMenuScreenState extends State<UserMenuScreen> {
  List<String> menuItems = ['Burger', 'Pizza', 'Pasta'];
  var confirmedSelection = '404';
  String? selectedItem;

  @override
  Widget build(BuildContext context) {
    double screenHeight = MediaQuery.of(context).size.height;
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('It\'s Lunch time'),
              ],
            ),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 160),
              child: ListView.builder(
                itemCount: menuItems.length,
                itemBuilder: (context, index) {
                  return InkWell(
                    onTap: () {
                      setState(() {
                        selectedItem = menuItems[index];
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      color: selectedItem == menuItems[index]
                          ? Colors.blue.shade100
                          : null,
                      child: Center(child: Text(menuItems[index])),
                    ),
                  );
                },
              ),
            ),
            Container(
              height: screenHeight * 0.4,
              width: screenHeight * 0.4,
              decoration: BoxDecoration(color: Colors.green),
            ),
            ElevatedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Button Pressed!"),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
              child: const Text('VOTE'),
            ),
            const SizedBox(height: 10),
            const Text('You are going to eat:'),
            Text(
              confirmedSelection,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
