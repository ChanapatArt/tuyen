import 'package:flutter/material.dart';
import 'package:mobile_app/widgets/bottom_nav.dart';
import 'package:mobile_app/widgets/ingredientList.dart';
import 'package:mobile_app/screens/menuResults.dart';


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
  int _currentPage = 0;
  void _goToResults() {
    _pageController.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _goBack() {
    _pageController.previousPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _currentPage == 0, // ถ้าอยู่หน้าแรกให้กดออกแอปได้ตามปกติ
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return; // ถ้าออกไปแล้วไม่ต้องทำอะไร


        if (_currentPage > 0) { // ถ้าหน้าปัจจุบันไม่ใช่หน้าแรก
          _goBack(); // สั่งให้ย้อนกลับไปหน้าวัตถุดิบ
        }
      },
      child: Scaffold(
        body: PageView(
          controller: _pageController,
          physics: const NeverScrollableScrollPhysics(),
          onPageChanged: (index) => setState(() => _currentPage = index),
          children: [
            // รายการวัตถุดิบ
            IngredientList(
              onFindMenu: _goToResults,
              foodItems: _foodItems,
              onToggleSelection: (index) {
                setState(() {
                  _foodItems[index]['isSelected'] =
                      !_foodItems[index]['isSelected'];
                });
              },
            ),

            // หน้าที่ 2: ผลลัพธ์เมนู (สร้าง Widget ใหม่)
            MenuResultsScreen(onBack: _goBack),
          ],
        ),

        bottomNavigationBar: const BottomNav(),
      ),
    );
  }
}