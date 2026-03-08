import 'package:flutter/material.dart';
import 'package:mobile_app/widgets/ingredient_list.dart';
import 'package:mobile_app/screens/menu_results.dart';

class HomeSubNavigator extends StatefulWidget {
  const HomeSubNavigator({super.key});

  @override
  State<HomeSubNavigator> createState() => _HomeSubNavigatorState();
}

class _HomeSubNavigatorState extends State<HomeSubNavigator> {
  List<String> _selectedIngredients = [];
  final PageController _subPageController = PageController();
  int _currentPage = 0; // เก็บ index ของ หน้ารายการ กับผลลัพธ์
  void _goToResults(List<String> ingredients) {
    setState(() {
      _selectedIngredients = ingredients;
    });
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

  Widget build(BuildContext context) {
    return PopScope(

      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (_currentPage > 0) {
          _goBack();
        } else {
          Navigator.of(context).maybePop();
        }
      },
      child: PageView(
        controller: _subPageController,
        physics: const NeverScrollableScrollPhysics(),
        onPageChanged: (index) => setState(() => _currentPage = index),
        children: [
          // ✅ 3. ส่งฟังก์ชันที่รับค่าได้ไปให้ IngredientList
          IngredientList(onFindMenu: (list) => _goToResults(list)),

          // ✅ 4. ส่งข้อมูลที่เลือกไปให้ MenuResultsScreen
          MenuResultsScreen(
            ingredients: _selectedIngredients, // ส่งตัวแปรที่เก็บไว้ไป
            onBack: _goBack,
          ),
        ],
      ),
    );
  }
}
