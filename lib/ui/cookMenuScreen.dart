import 'package:eatit/models/familyModel.dart';
import 'package:flutter/material.dart';

class CookMenuScreen extends StatefulWidget {
  final Function(int) onSwitchScreen;
  final List<FamilyModel> families;
  final String selectedFamilyCode;
  final Function(String) onFamilyChange;

  const CookMenuScreen({
    super.key,
    required this.onSwitchScreen,
    required this.families,
    required this.selectedFamilyCode,
    required this.onFamilyChange,
  });

  @override
  _CookMenuScreenState createState() => _CookMenuScreenState();
}

class _CookMenuScreenState extends State<CookMenuScreen> {
  List<String> menuItems = ['Burger', 'Pizza', 'Pasta'];
  String? currentSelection;
  String? confirmedSelection;

  @override
  Widget build(BuildContext context) {
    double screenHeight = MediaQuery.of(context).size.height;
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: SingleChildScrollView(
          child: Column(
            children: [
              const Column(
                children: [
                  Text('You\'re the cook'),
                  Text('Decide what everyone\'s gonna eat:'),
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
                          currentSelection = menuItems[index];
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        color: currentSelection == menuItems[index]
                            ? Colors.blue.shade100
                            : null,
                        child: Center(child: Text(menuItems[index])),
                      ),
                    );
                  },
                ),
              ),
              ElevatedButton(
                onPressed: currentSelection != null
                    ? () {
                        setState(() {
                          confirmedSelection = currentSelection;
                        });
                      }
                    : null,
                child: const Text('UPDATE'),
              ),
              const SizedBox(height: 5),
              const Text(
                'OR',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const Text('ask other family members to vote:'),
              Container(
                height: screenHeight * 0.4,
                width: screenHeight * 0.4,
                decoration: BoxDecoration(
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 5),
              ElevatedButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Voting Request Sent! Polls are open"),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
                child: const Text('ASK'),
              ),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Update Food Menu :",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              ListView(
                physics: const NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                padding: const EdgeInsets.all(16),
                children: const [
                  ListTile(
                    title: Text('Monday'),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Lunch: Pasta, Salad, Soup'),
                        Text('Dinner: Grilled Chicken, Rice, Veggies'),
                      ],
                    ),
                    trailing: Icon(Icons.restaurant_menu),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
