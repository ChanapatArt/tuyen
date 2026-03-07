import 'package:flutter/material.dart';
import 'package:mobile_app/screens/histories.dart';
import 'package:mobile_app/screens/personal_inform.dart';
import 'package:mobile_app/screens/search.dart';
import 'package:mobile_app/screens/shopping_list.dart';
import 'package:mobile_app/widgets/bottom_nav.dart';
import 'package:mobile_app/screens/home_sub_navigator.dart';

class Home extends StatefulWidget {
  const Home({super.key});
  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
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
          HomeSubNavigator(),
          Search(),
          Histories(),
          ShoppingList(),
          PersonalInfoPage(),
        ],
      ),

      bottomNavigationBar: BottomNav(
        currentIndex: _selectedIndexPage,
        onTap: _onItemTapped,
      ),
    );
  }
}
