import 'package:flutter/services.dart';
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
    return PopScope(
      canPop: false, // ✅ บังคับว่าห้าม "ถอยกลับ" ทันที
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return; // ถ้าหน้าถูกปิดไปแล้วไม่ต้องทำอะไร

        // ✅ เรียก Modal ยืนยันการออก
        final bool shouldPop = await _showExitDialog(context);
        if (shouldPop && context.mounted) {
          // ถ้าผู้ใช้กด Exit ให้ปิดแอปหรือถอยกลับจริง
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
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
      ),
    );
  }
}

Future<bool> _showExitDialog(BuildContext context) async {
  return await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: const Text(
            "Exit App",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: const Text("Are you sure you want to exit TuYen?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text(
                "Cancel",
                style: TextStyle(color: Colors.black),
              ),
            ),
            ElevatedButton(
              onPressed: () => SystemNavigator.pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade400,
                foregroundColor: Colors.white,
              ),
              child: const Text("Exit"),
            ),
          ],
        ),
      ) ??
      false;
}
