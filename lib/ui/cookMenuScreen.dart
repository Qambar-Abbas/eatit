import 'package:flutter/material.dart';

class CookMenuScreen extends StatefulWidget {
  final Function(int) onSwitchScreen;

  const CookMenuScreen({super.key, required this.onSwitchScreen});

  @override
  _CookMenuScreenState createState() => _CookMenuScreenState();
}

class _CookMenuScreenState extends State<CookMenuScreen> {
  List<String> menuItems = ['Burger', 'Pizza', 'Pasta'];
  String? currentSelection;
  String? confirmedSelection;
  String dropdownValue = 'Cook Menu';

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
            return DropdownMenuItem(
              value: value,
              child: Text(value, style: const TextStyle(color: Colors.black)),
            );
          }).toList(),
          onChanged: (String? newValue) {
            if (newValue == null) return;
            setState(() => dropdownValue = newValue);
            if (newValue == 'User Menu') {
              widget.onSwitchScreen(1);
            }
          },
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: SingleChildScrollView(
          child: Column(
            children: [
              Column(
                children: const [
                  Text('You\'re the cook'),
                  Text('Decide what everyone\'s gonna eat:'),
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
                child: Text('UPDATE'),
              ),
              SizedBox(height: 5),
              Text(
                'OR',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Text('ask other family members to vote:'),
              Container(
                height: screenHeight * 0.4,
                width: screenHeight * 0.4,
                decoration: BoxDecoration(
                  color: Colors.black,
                ),
              ),
              SizedBox(height: 5),
              ElevatedButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content:
                          const Text("Voting Request Sent! Polls are open"),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                },
                child: Text('ASK'),
              ),
              Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Update Food Menu :",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  )),
              ListView(
                physics: NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                padding: EdgeInsets.all(16),
                children: [
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
                  ListTile(
                    title: Text('Tuesday'),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Lunch: Tacos, Rice Bowl, Churros'),
                        Text('Dinner: Curry, Naan, Lassi'),
                      ],
                    ),
                    trailing: Icon(Icons.restaurant_menu),
                  ),
                  ListTile(
                    title: Text('Wednesday'),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Lunch: Burgers, Fries, Milkshake'),
                        Text('Dinner: Spaghetti, Garlic Bread, Salad'),
                      ],
                    ),
                    trailing: Icon(Icons.restaurant_menu),
                  ),
                  ListTile(
                    title: Text('Thursday'),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Lunch: Pizza, Caesar Salad, Minestrone'),
                        Text('Dinner: Chicken Alfredo, Broccoli, Breadsticks'),
                      ],
                    ),
                    trailing: Icon(Icons.restaurant_menu),
                  ),
                  ListTile(
                    title: Text('Friday'),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Lunch: Fish & Chips, Coleslaw, Pudding'),
                        Text('Dinner: Sushi, Miso Soup, Tempura'),
                      ],
                    ),
                    trailing: Icon(Icons.restaurant_menu),
                  ),
                  ListTile(
                    title: Text('Saturday'),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Lunch: Steak, Mashed Potatoes, Grilled Veggies'),
                        Text('Dinner: BBQ Ribs, Cornbread, Slaw'),
                      ],
                    ),
                    trailing: Icon(Icons.restaurant_menu),
                  ),
                  ListTile(
                    title: Text('Sunday'),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Lunch: Roast Chicken, Cornbread, Apple Pie'),
                        Text('Dinner: Lasagna, Caesar Salad, Ice Cream'),
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
