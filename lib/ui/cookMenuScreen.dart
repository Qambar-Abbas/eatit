import 'package:eatit/services/familyService.dart';
import 'package:eatit/services/riverpods/familyRiverpod.dart';
import 'package:eatit/ui/voteWidget.dart';

import 'package:flutter/material.dart';
import 'package:eatit/models/familyModel.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

//
class CookMenuScreen extends ConsumerStatefulWidget {
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
  ConsumerState<CookMenuScreen> createState() => _CookMenuScreenState();
}

class _CookMenuScreenState extends ConsumerState<CookMenuScreen> {
  Future<List<String>>? _menuItems;
  late Future<bool> _votingStatusFuture;

  final List<String> _weekDays = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  String? _currentSelection;
  String? _confirmedSelection;
  String _currentTime = '';
  String _mealTimeText = 'Lunch Time';
  final FamilyService _familyService = FamilyService();

  @override
  void initState() {
    super.initState();
    _updateTime();
    _loadMenuItems();
    _votingStatusFuture =
        _familyService.getVotingStatus(widget.selectedFamilyCode);
  }

  Future<void> _loadMenuItems() async {
    if (widget.selectedFamilyCode.isNotEmpty) {
      final menuFuture =
          _familyService.getFoodMenuByTime(widget.selectedFamilyCode);
      setState(() {
        _menuItems = menuFuture;
      });
    }
  }

  Future<void> _updateTime() async {
    final now = DateTime.now();
    final formattedTime = DateFormat('HH:mm:ss').format(now);
    final hour = now.hour;
    final newMealTimeText = hour >= 17 ? 'Dinner Time' : 'Lunch Time';

    setState(() {
      _currentTime = formattedTime;
      _mealTimeText = newMealTimeText;
    });

    Future.delayed(const Duration(seconds: 1), _updateTime);
  }

  // --- Header Section ---
  Widget _buildHeader(String selectedMeal) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _currentTime,
          style: const TextStyle(fontSize: 16, color: Colors.black54),
        ),
        const SizedBox(height: 4),
        Text(
          _mealTimeText,
          style: const TextStyle(fontSize: 14, color: Colors.black45),
        ),
        const SizedBox(height: 4),
        if (selectedMeal.isNotEmpty)
          Text(
            'Decided Meal: $selectedMeal',
            style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.blueAccent),
          ),
        const SizedBox(height: 8),
        const Text(
          "You're the cook",
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        const Text(
          "Decide what everyone's gonna eat:",
          style: TextStyle(fontSize: 16, color: Colors.black54),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  // --- Menu Selection Section ---

  Widget _buildFoodSelectionMenu(List<String> foodItems) {
    final filteredItems =
        foodItems.where((item) => item.trim().isNotEmpty).toList();

    if (filteredItems.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24.0),
        child: Center(
          child: Text(
            'Food menu needs to be updated.',
            style: TextStyle(fontSize: 16, color: Colors.redAccent),
          ),
        ),
      );
    }

    return SizedBox(
      height: 160,
      child: ListView.builder(
        itemCount: filteredItems.length,
        itemBuilder: (context, index) {
          final item = filteredItems[index];
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
        onPressed: (_currentSelection == null)
            ? null
            : () async {
                setState(() {
                  _confirmedSelection = _currentSelection;
                });

                try {
                  final result = await _familyService.updateSelectedMeal(
                    familyCode: widget.selectedFamilyCode,
                    selectedMeal: _confirmedSelection!,
                  );

                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(result)),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('❌ Error: $e')),
                    );
                  }
                }
              },
        child: const Text('Update'),
      ),
    );
  }

  Widget _buildActionButton({
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      onPressed: onPressed,
      child: Text(label),
    );
  }

  void _handleVote(String selectedFood) async {
    try {
      await FamilyService().submitVote(
        familyCode: widget.selectedFamilyCode,
        selectedItem: selectedFood,
      );
      setState(() => _confirmedSelection = selectedFood);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Your vote for $selectedFood is recorded!')),
      );
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Failed to submit vote. Please try again.')),
      );
    }
  }

  Widget _buildVotingArea() {
    if (_menuItems == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        VotingStatusBuilder(
          votingStatusFuture: _votingStatusFuture,
          menuItemsFuture: _menuItems!,
          onVote: _handleVote,
        ),
        Row(
          children: [
            _buildActionButton(
              label: 'Ask for Vote',
              color: Theme.of(context).colorScheme.primary,
              onPressed: () async {
                _setVotingStatus(true);
                await FamilyService()
                    .syncVotingStatusWithGlobal(widget.selectedFamilyCode);
                // once opened, refresh the status
                setState(() {
                  _votingStatusFuture =
                      _familyService.getVotingStatus(widget.selectedFamilyCode);
                });
              },
            ),
            const SizedBox(width: 16),
            _buildActionButton(
              label: 'Stop Voting',
              color: Theme.of(context).colorScheme.error,
              onPressed: () async {
                await _setVotingStatus(false);
                // and refresh status again
                setState(() {
                  _votingStatusFuture =
                      _familyService.getVotingStatus(widget.selectedFamilyCode);
                });
              },
            ),
          ],
        ),
      ],
    );
  }

  @override
  void didUpdateWidget(covariant CookMenuScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedFamilyCode != widget.selectedFamilyCode) {
      // re-load menu items
      setState(() {
        _menuItems =
            _familyService.getFoodMenuByTime(widget.selectedFamilyCode);
      });
      // re-load voting status
      setState(() {
        _votingStatusFuture =
            _familyService.getVotingStatus(widget.selectedFamilyCode);
      });
    }
  }

  // --- Weekly Menu Section ---
  Widget _buildFoodMenuTitle() {
    return const Text(
      "Update Food Menu:",
      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
    );
  }

  Widget _buildWeeklyMenuList(
      AsyncValue<Map<String, dynamic>> weeklyMenuAsync) {
    return weeklyMenuAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Text('Error loading menu: $e'),
      data: (weeklyMenu) {
        return ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _weekDays.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final day = _weekDays[index];
            final lunchItems =
                List<String>.from(weeklyMenu[day]?['lunch'] ?? []);
            final dinnerItems =
                List<String>.from(weeklyMenu[day]?['dinner'] ?? []);

            return Card(
              child: InkWell(
                onTap: () => _showEditMenuDialog(day),
                borderRadius: BorderRadius.circular(12.5),
                child: ListTile(
                  leading: const Icon(Icons.calendar_today_outlined),
                  title: Text(day),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text('Lunch: ${lunchItems.join(', ')}',
                          style: const TextStyle(fontSize: 12)),
                      Text('Dinner: ${dinnerItems.join(', ')}',
                          style: const TextStyle(fontSize: 12)),
                    ],
                  ),
                  trailing: const Icon(Icons.restaurant_menu_outlined),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _setVotingStatus(bool isOpen) async {
    final action = isOpen ? 'opened' : 'closed';
    try {
      await _familyService.setVotingStatus(
        familyCode: widget.selectedFamilyCode,
        isOpen: isOpen,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Voting has been $action successfully.')),
      );
    } catch (error, stack) {
      // consider using a logging package instead of print in production
      debugPrint('Error setting voting status: $error\n$stack');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to update voting status.')),
      );
    }
  }

  void _showEditMenuDialog(String day) {
    // Initialize controllers to store values for lunch and dinner
    final lunchControllers = List.generate(3, (_) => TextEditingController());
    final dinnerControllers = List.generate(3, (_) => TextEditingController());

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit $day Menu'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Lunch:',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              ...lunchControllers.map((c) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: TextFormField(
                      controller: c,
                      decoration: InputDecoration(
                        hintText: 'Lunch item',
                        border: const OutlineInputBorder(),
                      ),
                    ),
                  )),
              const SizedBox(height: 16),
              const Text('Dinner:',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              ...dinnerControllers.map((c) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: TextFormField(
                      controller: c,
                      decoration: InputDecoration(
                        hintText: 'Dinner item',
                        border: const OutlineInputBorder(),
                      ),
                    ),
                  )),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              // 1) gather new values
              final updatedLunch =
                  lunchControllers.map((c) => c.text.trim()).toList();
              final updatedDinner =
                  dinnerControllers.map((c) => c.text.trim()).toList();

              try {
                // 2) update Firestore
                await _familyService.updateDailyMenu(
                  familyCode: widget.selectedFamilyCode,
                  day: day,
                  lunchItems: updatedLunch,
                  dinnerItems: updatedDinner,
                );

                // 3) close dialog
                if (context.mounted) Navigator.pop(context);

                // 4) invalidate weekly menu stream
                ref.invalidate(weeklyMenuProvider(widget.selectedFamilyCode));

                // 5) reload today's menu for the selection list
                await _loadMenuItems();

                // 6) show success
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('$day menu updated successfully!')),
                  );
                }
              } catch (e) {
                // on error, close dialog and show error
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error updating $day menu: $e')),
                  );
                }
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  @override
  Widget build(BuildContext context) {
    // final votingAsync =
    //     ref.watch(votingStatusProvider(widget.selectedFamilyCode));

    final weeklyMenuAsyncValue =
        ref.watch(weeklyMenuProvider(widget.selectedFamilyCode));

    final selectedMealAsyncValue =
        ref.watch(selectedMealProvider(widget.selectedFamilyCode));

    // final double screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                selectedMealAsyncValue.when(
                  loading: () => _buildHeader(''),
                  error: (e, _) => _buildHeader('Error'),
                  data: (selectedMeal) => _buildHeader(selectedMeal),
                ),
                // if (_menuItems != null) _buildMenuSelection(),
                // if (_menuItems == null) const CircularProgressIndicator(),
                if (_menuItems != null)
                  FutureBuilder<List<String>>(
                    future: _menuItems,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      } else if (snapshot.hasError) {
                        return Text('Error loading menu: ${snapshot.error}');
                      } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return const Text('No menu items found.');
                      } else {
                        return _buildFoodSelectionMenu(snapshot.data!);
                      }
                    },
                  ),

                const SizedBox(height: 16),
                _buildUpdateButton(),
                const SizedBox(height: 24),
                _buildVotingArea(),
                const SizedBox(height: 24),
                _buildFoodMenuTitle(),
                const SizedBox(height: 8),
                _buildWeeklyMenuList(weeklyMenuAsyncValue),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
