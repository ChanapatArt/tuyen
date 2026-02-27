import 'package:flutter/material.dart';

class BottomNav extends StatefulWidget {
  const BottomNav({super.key});

  @override
  State<BottomNav> createState() => _BottomNavState();
}

class _BottomNavState extends State<BottomNav> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: Colors.grey.withValues(alpha: 0.3),
            width: 1
          )
        )
      ),
      child: BottomNavigationBar(
        type: BottomNavigationBarType.fixed, // เพื่อให้แสดง label ทุกตัว
        currentIndex: _currentIndex,         // บอกว่าตอนนี้เลือกอันไหนอยู่
        selectedItemColor: const Color(0xFF28B446), // สีเขียวตามรูป
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
        
        onTap: (index) { // ฟังก์ชันเมื่อมีการกดเปลี่ยนเมนู
          setState(() {
            _currentIndex = index;
          });
        },
      
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.kitchen_outlined),
            label: 'TuYen',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.search_rounded),
            label: 'Search',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_month_outlined),
            label: 'Plan',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_cart_outlined),
            label: 'Shopping List',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: 'Personal',
          ),
        ],
      ),
    );
  }
}