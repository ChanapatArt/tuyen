import 'package:flutter/material.dart';
import 'package:mobile_app/screens/map_page.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:mobile_app/services/auth_service.dart';

class ShoppingList extends StatefulWidget {
  const ShoppingList({super.key});

  @override
  State<ShoppingList> createState() => _ShoppingListState();
}

class _ShoppingListState extends State<ShoppingList> {
  // 1. สร้างรายการข้อมูล (Data List) สำหรับเก็บสถานะ
  List<Map<String, dynamic>> _shoppingItems = [];
  bool _isLoading = true;

  // 2. ฟังก์ชันสำหรับสลับสถานะติ๊กถูก
  void _toggleItem(int index) {
    setState(() {
      _shoppingItems[index]['isChecked'] = !_shoppingItems[index]['isChecked'];
    });
  }

  @override
  void initState() {
    super.initState();
    _fetchShoppingItems(); // 2. เรียกดึงข้อมูลทันทีที่เปิดหน้า
  }

  Future<void> _fetchShoppingItems() async {
    final String? userId = await AuthService.getUserId();
    if (userId == null) return;
    try {
      final response = await http.get(
        Uri.parse('${AuthService.baseUrl}/shopping-list/$userId'),
      );
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        if (data['status'] == 'success' && data['data'] != null) {
          final List<dynamic> itemsList = data['data'];

          setState(() {
            // 3. แปลงข้อมูลให้เข้ากับรูปแบบที่แอปเราใช้
            _shoppingItems = itemsList
                .map((item) {
                  return {
                    "list_id":
                        item['list_id'], // เก็บ ID ไว้เผื่อใช้ลบหรืออัปเดต
                    "title":
                        item['ingredient_name'], // เปลี่ยนจาก ingredient_name เป็น title
                    "amount": "${item['quantity']} ${item['unit']}"
                        .trim(), // รวมจำนวนและหน่วย
                    "isChecked":
                        item['is_bought'] ??
                        false, // ใช้ is_bought แทน isChecked
                  };
                })
                .toList();

            _isLoading = false;
          });
        }
      }
    } catch (e) {
      print("Error fetching data: $e");
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : // แสดงตัวหมุนขณะโหลด
              SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Text(
                          "Shopping list",
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(width: 8),
                        Icon(Icons.shopping_basket, size: 30),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // 3. ใช้ Column.builder หรือ List.generate เพื่อสร้างรายการจากข้อมูลจริง
                    ...List.generate(_shoppingItems.length, (index) {
                      final item = _shoppingItems[index];
                      return Dismissible(
                        key: UniqueKey(),
                        background: Container(
                          margin: const EdgeInsets.symmetric(
                            vertical: 8,
                            horizontal: 16,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.red.shade400,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          child: const Icon(Icons.delete, color: Colors.white),
                        ),

                        // 🗑️ ฟังก์ชันที่จะทำงานเมื่อสไลด์จนสุด
                        onDismissed: (direction) async {
                          final deletedItem = item;
                          final int? listId = item['list_id'];

                          setState(() {
                            _shoppingItems.remove(item); // ลบข้อมูลออกจาก List
                          });

                          // 2. ยิง API ไปลบในฐานข้อมูลจริง
                          if (listId != null) {
                            try {
                              final response = await http.delete(
                                Uri.parse(
                                  '${AuthService.baseUrl}/shopping-list/remove/$listId',
                                ),
                                headers: {'Content-Type': 'application/json'},
                              );
                              print(response.statusCode);
                              if (response.statusCode == 200) {
                                // ลบสำเร็จ
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        "${deletedItem['title']} removed",
                                      ),
                                    ),
                                  );
                                }
                              } else {
                                // ถ้าลบใน API ไม่สำเร็จ ให้เอาข้อมูลกลับคืนมาใน List
                                setState(() {
                                  _shoppingItems.insert(index, deletedItem);
                                });
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        "Failed to delete from server",
                                      ),
                                    ),
                                  );
                                }
                              }
                            } catch (e) {
                              // กรณีเกิด Error ในการเชื่อมต่อ
                              setState(() {
                                _shoppingItems.insert(index, deletedItem);
                              });
                              print("Error deleting: $e");
                            }
                          }
                        },
                        direction: DismissDirection.endToStart,
                        child: _buildShoppingItem(
                          index,
                          item['title'],
                          item['amount'],
                          isChecked: item['isChecked'],
                        ),
                      );
                    }),

                    // ปุ่ม Add item (Dashed Border)
                    CustomPaint(
                      painter: DashedRectPainter(color: Colors.grey.shade400),
                      child: SizedBox(
                        width: double.infinity,
                        height: 60,
                        child: TextButton.icon(
                          onPressed: () {
                            _showAddShoppingItemDialog(context);
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
                    SizedBox(height: 75),
                  ],
                ),
              ),
      ),

      floatingActionButton: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: SizedBox(
          width: MediaQuery.of(context).size.width, // ขยายให้กว้าง 90% ของจอ
          height: 55,
          child: FloatingActionButton.extended(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const MapPage()),
              );
            },
            backgroundColor: Colors.black,
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            label: const Text(
              "Map",
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),

      // ✅ กำหนดตำแหน่งให้อยู่กึ่งกลางด้านล่าง (ลอยเหนือ Bottom Nav)
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
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
                ? Colors.green.withValues(alpha: .3)
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
                  color: isChecked ? Colors.green : Colors.grey.shade300,
                  width: 2,
                ),
                color: isChecked ? Colors.green : Colors.transparent,
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
          ],
        ),
      ),
    );
  }

  // Controller สำหรับหน้า Shopping List
  final TextEditingController ingredientController = TextEditingController();
  final TextEditingController quantityController = TextEditingController();
  final TextEditingController unitController = TextEditingController();

  void _showAddShoppingItemDialog(BuildContext context) {
    ingredientController.clear();
    quantityController.clear();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. หัวข้อ Ingredient
                const Text(
                  "Ingredient",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: ingredientController,
                  decoration: _modalInputDecoration(hint: "Lettuce"),
                ),
                const SizedBox(height: 16),

                // 2. หัวข้อ Quantity
                Row(
                  children: [
                    // ฝั่ง Quantity
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Quantity",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: quantityController,
                            keyboardType: TextInputType
                                .number, // ให้แป้นพิมพ์ขึ้นเป็นตัวเลข
                            decoration: _modalInputDecoration(hint: "1"),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    // ฝั่ง Unit
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Unit",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: unitController,
                            decoration: _modalInputDecoration(hint: "head"),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // 3. ปุ่ม OK และ Cancle
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          FocusScope.of(context).unfocus();
                          if (ingredientController.text.isNotEmpty) {
                            String? userId = await AuthService.getUserId();

                            // 1. ยิง API ไปบันทึกในฐานข้อมูลก่อน
                            final response = await http.post(
                              Uri.parse(
                                '${AuthService.baseUrl}/shopping-list/add',
                              ),
                              headers: {'Content-Type': 'application/json'},
                              body: jsonEncode({
                                "user_id": int.parse(userId!),
                                "ingredient_name": ingredientController.text,
                                "quantity":
                                    int.tryParse(quantityController.text) ?? 1,
                                "unit": unitController.text.trim().isEmpty
                                    ? "unit"
                                    : unitController.text,
                              }),
                            );

                            if (response.statusCode == 200) {
                              // ✅ 1. แกะ JSON ที่ API ส่งกลับมา (ที่มี list_id)
                              final Map<String, dynamic> responseData =
                                  jsonDecode(response.body);
                              final int newId = responseData['list_id'];

                              setState(() {
                                // ✅ 2. ใส่ list_id ลงไปใน Map ของรายการที่เพิ่มใหม่
                                _shoppingItems.insert(0, {
                                  "list_id": newId,
                                  "title": ingredientController.text,
                                  "amount":
                                      "${int.tryParse(quantityController.text) ?? 1} ${unitController.text.trim().isEmpty ? "unit" : unitController.text}"
                                          .trim(),
                                  "isChecked": false,
                                });
                              });

                              // ล้างข้อมูลและปิดหน้าต่าง
                              ingredientController.clear();
                              quantityController.clear();
                              unitController.clear();
                              if (context.mounted) Navigator.pop(context);
                            }
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          "OK",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFF41F11), // สีแดง
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          "Cancle",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
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

InputDecoration _modalInputDecoration({String? hint}) {
  return InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(color: Colors.grey),
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(color: Colors.grey.shade300),
    ),
  );
}
