import 'package:flutter/material.dart';
import 'chatScreen.dart';
import 'SearchScreen.dart';
import 'ProfileScreen.dart';

class HomeNavigationBar extends StatefulWidget {
  final dynamic user;
  const HomeNavigationBar({super.key, required this.user});

  @override
  _HomeNavigationBarState createState() => _HomeNavigationBarState();
}

class _HomeNavigationBarState extends State<HomeNavigationBar>
    with AutomaticKeepAliveClientMixin {
  late PageController _pageController;
  final ValueNotifier<int> _selectedIndex = ValueNotifier<int>(1);

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _selectedIndex.value);

    // Listen to page changes and update the navigation bar index
    _pageController.addListener(() {
      int currentIndex = _pageController.page!.round();
      if (_selectedIndex.value != currentIndex) {
        _selectedIndex.value = currentIndex;
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _selectedIndex.dispose();
    super.dispose();
  }

  void _onItemTapped(int index) {
    if (_selectedIndex.value != index) {
      _selectedIndex.value = index;
      _pageController.animateToPage(
        index,
        duration: const Duration(milliseconds: 300),
        curve: Curves.ease,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    return Scaffold(
      body: PageView.builder(
        controller: _pageController,
        itemCount: _widgetOptions.length,
        itemBuilder: (context, index) {
          return _widgetOptions[index];
        },
      ),
      bottomNavigationBar: ValueListenableBuilder<int>(
        valueListenable: _selectedIndex,
        builder: (context, selectedIndex, child) {
          return BottomNavigationBar(
            type: BottomNavigationBarType.shifting,
            items: const <BottomNavigationBarItem>[
              BottomNavigationBarItem(
                icon: Icon(Icons.chat),
                label: 'Chat',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.restaurant_menu),
                label: 'Search',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person),
                label: 'Profile',
              ),
            ],
            currentIndex: selectedIndex,
            unselectedItemColor: Colors.grey,
            selectedItemColor: Colors.black,
            onTap: _onItemTapped,
          );
        },
      ),
    );
  }

  List<Widget> get _widgetOptions => <Widget>[
    const ChatScreen(),
    const SearchScreen(),
    ProfileScreen(),
  ];

  @override
  bool get wantKeepAlive => true;
}
