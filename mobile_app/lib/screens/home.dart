import 'package:flutter/material.dart';
import 'package:mobile_app/screens/recipeDetails.dart';
import 'package:mobile_app/screens/search.dart';
import 'package:mobile_app/widgets/bottom_nav.dart';
import 'package:mobile_app/screens/homeSubNavigator.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final List<Map<String, dynamic>> _foodItems = [
    {
      'title': 'Egg',
      'subtitle': 'Remaining: 4 eggs',
      'days': '10 Day',
      'color': Colors.green,
      'isSelected': false,
    },
    {
      'title': 'Minced pork',
      'subtitle': 'Remaining: 300g',
      'days': '2 Day',
      'color': Colors.orange,
      'isSelected': false,
      'isNearExpiry': true,
    },
    {
      'title': 'Spring onion',
      'subtitle': '2 plants',
      'days': '2 Day',
      'color': Colors.red,
      'isSelected': false,
      'isNearExpiry': true,
    },
  ];

  final PageController _pageController = PageController();
  int _selectedIndexPage = 0; // เก็บ index ของ Tab ปัจจุบัน

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndexPage = index;
    });
    _pageController.jumpToPage(index); // สั่งให้ PageView กระโดดไปหน้านั้นๆ
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: PageView(
          controller: _pageController,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            HomeSubNavigator(
              foodItems: _foodItems,
              onToggleSelection: (index) {
                setState(() {
                  _foodItems[index]['isSelected'] =
                      !_foodItems[index]['isSelected'];
                });
              },
            ),
            Search(),
            RecipeDetails(title: 'Minced pork omelet')
          ],
        ),

        bottomNavigationBar: BottomNav(
          currentIndex: _selectedIndexPage,
          onTap: _onItemTapped,
        ),
      );
  }
}
