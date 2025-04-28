import 'package:eatit/services/familyService.dart';
import 'package:flutter/material.dart';
import 'package:eatit/models/familyModel.dart';

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
  State<CookMenuScreen> createState() => _CookMenuScreenState();
}

class _CookMenuScreenState extends State<CookMenuScreen> {
  final List<String> _menuItems = ['Burger', 'Pizza', 'Pasta'];
  final List<String> _weekDays = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday'
  ];

  String? _currentSelection;
  String? _confirmedSelection;

  @override
  Widget build(BuildContext context) {
    final double screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                _buildMenuSelection(),
                const SizedBox(height: 16),
                _buildUpdateButton(),
                const SizedBox(height: 24),
                _buildVotingSection(screenHeight),
                const SizedBox(height: 24),
                _buildFoodMenuTitle(),
                const SizedBox(height: 8),
                _buildWeeklyMenuList(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- Header Section ---
  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        SizedBox(height: 16),
        Text(
          "You're the cook",
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 8),
        Text(
          "Decide what everyone's gonna eat:",
          style: TextStyle(fontSize: 16, color: Colors.black54),
        ),
        SizedBox(height: 16),
      ],
    );
  }

  // --- Menu Selection Section ---
  Widget _buildMenuSelection() {
    return SizedBox(
      height: 160,
      child: ListView.builder(
        itemCount: _menuItems.length,
        itemBuilder: (context, index) {
          final item = _menuItems[index];
          final isSelected = item == _currentSelection;

          return Card(
            elevation: isSelected ? 4 : 1,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
              side: isSelected
                  ? BorderSide(color: Colors.blue.shade400, width: 2)
                  : BorderSide.none,
            ),
            child: ListTile(
              title: Center(child: Text(item)),
              tileColor: isSelected ? Colors.blue.shade50 : null,
              onTap: () => setState(() => _currentSelection = item),
            ),
          );
        },
      ),
    );
  }

  Widget _buildUpdateButton() {
    return Center(
      child: ElevatedButton(
        onPressed: _currentSelection == null
            ? null
            : () {
                setState(() {
                  _confirmedSelection = _currentSelection;
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Selected: $_confirmedSelection')),
                );
              },
        child: const Text('Update'),
      ),
    );
  }

  // --- Voting Section ---
  Widget _buildVotingSection(double screenHeight) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Center(
          child: Text(
            "OR",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 8),
        const Center(child: Text('Ask family members to vote:')),
        const SizedBox(height: 16),
        Center(
          child: Container(
            height: screenHeight * 0.3,
            width: screenHeight * 0.3,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(
              child: Icon(Icons.poll, size: 60, color: Colors.black54),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Center(
          child: ElevatedButton.icon(
            onPressed: _sendVotingRequest,
            icon: const Icon(Icons.send),
            label: const Text('Ask'),
          ),
        ),
      ],
    );
  }

  void _sendVotingRequest() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Voting Request Sent! Polls are open.'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  // --- Weekly Menu Section ---
  Widget _buildFoodMenuTitle() {
    return const Text(
      "Update Food Menu:",
      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
    );
  }

  Widget _buildWeeklyMenuList() {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _weekDays.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        return Card(
          child: InkWell(
            onTap: () => _showEditMenuDialog(_weekDays[index]),
            borderRadius: BorderRadius.circular(12.5), // Match Card's rounding
            child: ListTile(
              leading: const Icon(Icons.calendar_today_outlined),
              title: Text(_weekDays[index]),
              subtitle: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 4),
                  Text('Lunch: ', style: TextStyle(fontSize: 12)),
                  Text('Dinner: ', style: TextStyle(fontSize: 12)),
                ],
              ),
              trailing: const Icon(Icons.restaurant_menu_outlined),
            ),
          ),
        );
      },
    );
  }

  void _showEditMenuDialog(String day) {
    // Initialize controllers to store values for lunch and dinner
    List<TextEditingController> lunchControllers =
        List.generate(3, (_) => TextEditingController());
    List<TextEditingController> dinnerControllers =
        List.generate(3, (_) => TextEditingController());

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit $day Menu'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Lunch:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ...List.generate(3, (index) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: TextFormField(
                    controller: lunchControllers[index],
                    decoration: InputDecoration(
                      hintText: 'Lunch item ${index + 1}',
                      border: const OutlineInputBorder(),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                    ),
                  ),
                );
              }),
              const SizedBox(height: 16),
              const Text(
                'Dinner:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ...List.generate(3, (index) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: TextFormField(
                    controller: dinnerControllers[index],
                    decoration: InputDecoration(
                      hintText: 'Dinner item ${index + 1}',
                      border: const OutlineInputBorder(),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              // Collect updated lunch and dinner items
              List<String> updatedLunch =
                  lunchControllers.map((c) => c.text).toList();
              List<String> updatedDinner =
                  dinnerControllers.map((c) => c.text).toList();

              try {
                // Call the update method to save to Firebase
                await FamilyService().updateDailyMenu(
                  familyCode: widget.selectedFamilyCode, // Pass family code
                  day: day, // Pass the specific day (e.g., 'Monday')
                  lunchItems: updatedLunch,
                  dinnerItems: updatedDinner,
                );

                // Close dialog
                Navigator.pop(context);

                // Provide success feedback to the user
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('$day menu updated successfully!')),
                );
              } catch (e) {
                // In case of error, show error message
                Navigator.pop(context);

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error updating $day menu: $e')),
                );
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
