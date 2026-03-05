import 'dart:ui'; // สำหรับ DashedRectPainter
import 'package:flutter/material.dart';

class ShoppingList extends StatefulWidget {
  const ShoppingList({super.key});

  @override
  State<ShoppingList> createState() => _ShoppingListState();
}

class _ShoppingListState extends State<ShoppingList> {
  // 1. สร้างรายการข้อมูล (Data List) สำหรับเก็บสถานะ
  final List<Map<String, dynamic>> _shoppingItems = [
    {"title": "Chicken eggs", "amount": "10 units", "isChecked": true},
    {"title": "Minced pork", "amount": "500 g", "isChecked": false},
    {"title": "Fish sauce", "amount": "1 bottle", "isChecked": false},
  ];

  // 2. ฟังก์ชันสำหรับสลับสถานะติ๊กถูก
  void _toggleItem(int index) {
    setState(() {
      _shoppingItems[index]['isChecked'] = !_shoppingItems[index]['isChecked'];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Text(
                    "Shopping list",
                    style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(width: 8),
                  Icon(Icons.shopping_basket, size: 30),
                ],
              ),
              const SizedBox(height: 20),

              // 3. ใช้ Column.builder หรือ List.generate เพื่อสร้างรายการจากข้อมูลจริง
              ...List.generate(_shoppingItems.length, (index) {
                final item = _shoppingItems[index];
                return _buildShoppingItem(
                  index,
                  item['title'],
                  item['amount'],
                  isChecked: item['isChecked'],
                );
              }),

              const SizedBox(height: 24),

              // ปุ่ม Add item (Dashed Border)
              CustomPaint(
                painter: DashedRectPainter(color: Colors.grey.shade400),
                child: SizedBox(
                  width: double.infinity,
                  height: 60,
                  child: TextButton.icon(
                    onPressed: () {
                      // อนาคต: ใส่ Logic สำหรับเพิ่มของใหม่เข้า List
                    },
                    icon: const Icon(Icons.add, color: Colors.grey),
                    label: const Text(
                      "Add item",
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: TextButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 4. ปรับปรุง Widget รายการให้กดได้ (ใส่ GestureDetector)
  Widget _buildShoppingItem(
    int index,
    String title,
    String amount, {
    required bool isChecked,
  }) {
    return GestureDetector(
      onTap: () => _toggleItem(index), // เมื่อกดทั้งแถว ให้สลับสถานะ
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isChecked
                ? const Color(0xFF28B446).withOpacity(0.3)
                : Colors.grey.shade200,
          ),
        ),
        child: Row(
          children: [
            // Custom Circle Checkbox
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isChecked
                      ? const Color(0xFF28B446)
                      : Colors.grey.shade300,
                  width: 2,
                ),
                color: isChecked ? const Color(0xFF28B446) : Colors.transparent,
              ),
              child: isChecked
                  ? const Icon(Icons.check, color: Colors.white, size: 16)
                  : null,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      decoration: isChecked ? TextDecoration.lineThrough : null,
                      color: isChecked ? Colors.grey : Colors.black,
                    ),
                  ),
                  Text(
                    amount,
                    style: const TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                ],
              ),
            ),
            const Icon(Icons.more_horiz, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}

class DashedRectPainter extends CustomPainter {
  final Color color;
  DashedRectPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    double dashWidth = 5, dashSpace = 3;
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    final RRect rrect = RRect.fromLTRBR(
      0,
      0,
      size.width,
      size.height,
      const Radius.circular(12),
    );
    final Path path = Path()..addRRect(rrect);

    // ต้อง import 'dart:ui'; เพื่อใช้งาน PathMetric
    for (var pathMetric in path.computeMetrics()) {
      double distance = 0;
      while (distance < pathMetric.length) {
        canvas.drawPath(
          pathMetric.extractPath(distance, distance + dashWidth),
          paint,
        );
        distance += dashWidth + dashSpace;
      }
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
