import 'package:flutter/material.dart';

class UserMenuScreen extends StatefulWidget {
  final Function(int) onSwitchScreen;

  const UserMenuScreen({super.key, required this.onSwitchScreen});

  @override
  _UserMenuScreenState createState() => _UserMenuScreenState();
}

class _UserMenuScreenState extends State<UserMenuScreen> {
  List<String> menuItems = ['Burger', 'Pizza', 'Pasta'];
  var confirmedSelection = '404';
  String? selectedItem;
  String dropdownValue = 'User Menu';

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;
    return Scaffold(
      appBar: AppBar(
        title: DropdownButton(
          value: dropdownValue,
          style: const TextStyle(fontSize: 18),
          items: ['User Menu', 'Cook Menu'].map((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(value, style: const TextStyle(color: Colors.black)),
            );
          }).toList(),
          onChanged: (String? newValue) {
            if (newValue == null) return;
            setState(() => dropdownValue = newValue);
            if (newValue == 'Cook Menu') {
              widget.onSwitchScreen(2);
            }
          },
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Text('It\'s Lunch time'),
              ],
            ),
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: 160,
              ),
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
              decoration: BoxDecoration(
                color: Colors.green,
              ),
            ),
            ElevatedButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text("Button Pressed!"),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                },
                child: Text('VOTE')),
            SizedBox(height: 10),
            Text('You are going to eat:'),
            Text(
              confirmedSelection,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
