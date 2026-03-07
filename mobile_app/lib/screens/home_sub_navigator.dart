import 'package:flutter/material.dart';
import 'package:mobile_app/widgets/ingredient_list.dart';
import 'package:mobile_app/screens/menu_results.dart';

class HomeSubNavigator extends StatefulWidget {
  const HomeSubNavigator({super.key});

  @override
  State<HomeSubNavigator> createState() => _HomeSubNavigatorState();
}

class _HomeSubNavigatorState extends State<HomeSubNavigator> {
  final PageController _subPageController = PageController();
  int _currentPage = 0; // เก็บ index ของ หน้ารายการ กับผลลัพธ์
  void _goToResults() {
    _subPageController.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.fastOutSlowIn,
    );
  }

  void _goBack() {
    _subPageController.previousPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.fastOutSlowIn,
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _currentPage == 0, // ถ้าอยู่หน้าแรกให้กดออกแอปได้ตามปกติ
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return; // ถ้าออกไปแล้วไม่ต้องทำอะไร

        if (_currentPage > 0) {
          // ถ้าหน้าปัจจุบันไม่ใช่หน้าแรก
          _goBack();
        }
      },
      child: PageView(
        controller: _subPageController,
        physics: const NeverScrollableScrollPhysics(),
        onPageChanged: (index) => setState(() => _currentPage = index),
        children: [
          IngredientList(onFindMenu: _goToResults),
          MenuResultsScreen(
            onBack: () => _subPageController.previousPage(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
            ),
          ),
        ],
      ),
    );
  }
}
