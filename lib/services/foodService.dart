
import '../models/foodModel.dart';

class FoodService {
  WeeklyMenu _weeklyMenu = WeeklyMenu.emptyMenu();

  WeeklyMenu get weeklyMenu => _weeklyMenu;

  // Get the menu for a specific day
  DayMenu getDayMenu(String day) {
    return _weeklyMenu.weeklyMenu[day]!;
  }

  // Add a food item to lunch or dinner
  void addFoodItem(String day, FoodItem item, {required bool isLunch}) {
    final currentDayMenu = getDayMenu(day);
    final updatedLunch = [...currentDayMenu.lunchItems];
    final updatedDinner = [...currentDayMenu.dinnerItems];

    if (isLunch) {
      updatedLunch.add(item);
    } else {
      updatedDinner.add(item);
    }

    _weeklyMenu.weeklyMenu[day] = DayMenu(
      lunchItems: updatedLunch,
      dinnerItems: updatedDinner,
    );
  }

  // Remove a food item by name from lunch or dinner
  void removeFoodItem(String day, String itemName, {required bool isLunch}) {
    final currentDayMenu = getDayMenu(day);

    final updatedLunch = isLunch
        ? currentDayMenu.lunchItems
        .where((item) => item.name != itemName)
        .toList()
        : currentDayMenu.lunchItems;

    final updatedDinner = !isLunch
        ? currentDayMenu.dinnerItems
        .where((item) => item.name != itemName)
        .toList()
        : currentDayMenu.dinnerItems;

    _weeklyMenu.weeklyMenu[day] = DayMenu(
      lunchItems: updatedLunch,
      dinnerItems: updatedDinner,
    );
  }

  // Update a food item (based on name)
  void updateFoodItem(String day, FoodItem updatedItem, {required bool isLunch}) {
    final currentDayMenu = getDayMenu(day);

    final updatedLunch = isLunch
        ? currentDayMenu.lunchItems
        .map((item) => item.name == updatedItem.name ? updatedItem : item)
        .toList()
        : currentDayMenu.lunchItems;

    final updatedDinner = !isLunch
        ? currentDayMenu.dinnerItems
        .map((item) => item.name == updatedItem.name ? updatedItem : item)
        .toList()
        : currentDayMenu.dinnerItems;

    _weeklyMenu.weeklyMenu[day] = DayMenu(
      lunchItems: updatedLunch,
      dinnerItems: updatedDinner,
    );
  }

  // Reset the entire weekly menu
  void clearWeeklyMenu() {
    _weeklyMenu = WeeklyMenu.emptyMenu();
  }

  // Replace the entire weekly menu
  void setWeeklyMenu(WeeklyMenu menu) {
    _weeklyMenu = menu;
  }
}
