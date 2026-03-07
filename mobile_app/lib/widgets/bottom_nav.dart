import 'package:flutter/material.dart';

class BottomNav extends StatefulWidget {
  final int currentIndex;
  final Function(int) onTap;
  const BottomNav({super.key, required this.currentIndex, required this.onTap});

  @override
  State<BottomNav> createState() => _BottomNavState();
}

class _BottomNavState extends State<BottomNav> {

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: Colors.grey.withValues(alpha: 0.3),
            width: 1
          )
        ),
      ),
      child: BottomNavigationBar(
        type: BottomNavigationBarType.fixed, // เพื่อให้แสดง label ทุกตัว
        currentIndex: widget.currentIndex, // บอกว่าตอนนี้เลือกหน้าไหนอยู่
        selectedItemColor: const Color(0xFF28B446),
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
        
        onTap: widget.onTap,
      
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
            icon: Icon(Icons.history),
            label: 'Histories',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_cart_outlined),
            label: 'Cart',
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