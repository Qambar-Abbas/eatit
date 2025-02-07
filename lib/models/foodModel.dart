class FoodItem {
  final String name;
  final double price;
  final String description;

  FoodItem({
    required this.name,
    required this.price,
    required this.description,
  });
}

class DayMenu {
  final List<FoodItem> lunchItems;
  final List<FoodItem> dinnerItems;

  DayMenu({
    required this.lunchItems,
    required this.dinnerItems,
  });
}

class WeeklyMenu {
  final Map<String, DayMenu> weeklyMenu;

  WeeklyMenu({
    required this.weeklyMenu,
  });

  // Factory constructor to initialize with empty data
  factory WeeklyMenu.emptyMenu() {
    return WeeklyMenu(
      weeklyMenu: {
        'Monday': DayMenu(lunchItems: [], dinnerItems: []),
        'Tuesday': DayMenu(lunchItems: [], dinnerItems: []),
        'Wednesday': DayMenu(lunchItems: [], dinnerItems: []),
        'Thursday': DayMenu(lunchItems: [], dinnerItems: []),
        'Friday': DayMenu(lunchItems: [], dinnerItems: []),
        'Saturday': DayMenu(lunchItems: [], dinnerItems: []),
        'Sunday': DayMenu(lunchItems: [], dinnerItems: []),
      },
    );
  }
}
