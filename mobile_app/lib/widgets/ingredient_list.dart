import 'package:flutter/material.dart';
import 'package:mobile_app/widgets/foodItem_card.dart';

class IngredientList extends StatefulWidget {
  final VoidCallback onFindMenu;

  final TextEditingController nameController = TextEditingController();
  final TextEditingController qtyController = TextEditingController();
  final TextEditingController expireController = TextEditingController();

  IngredientList({super.key, required this.onFindMenu});
  @override
  State<IngredientList> createState() => _IngredientList();
}

class _IngredientList extends State<IngredientList> {
  DateTime? _selectedDate;
  final List<Map<String, dynamic>> _foodItems = [
    {
      'title': 'Egg',
      'subtitle': 'Remaining: 4 eggs',
      'expiryDate': DateTime(2026, 3, 15),
      'color': Colors.green,
      'isSelected': false,
    },
    {
      'title': 'Minced pork',
      'subtitle': 'Remaining: 300g',
      'expiryDate': DateTime(2026, 3, 15),
      'color': Colors.orange,
      'isSelected': false,
      'isNearExpiry': true,
    },
    {
      'title': 'Spring onion',
      'subtitle': '2 plants',
      'expiryDate': DateTime(2026, 3, 15),
      'color': Colors.red,
      'isSelected': false,
      'isNearExpiry': true,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "My TuYen",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            Text(
              "TuYen",
              style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
            ),
          ],
        ),
        centerTitle: false,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(
              Icons.add_circle_outline,
              color: Colors.green,
              size: 30,
            ),
            onPressed: () {
              _showAddIngredientDialog(context);
            },
          ),
        ],
        toolbarHeight: 65,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              color: Colors.grey.withAlpha(76), // 0.3 * 255
              height: 1,
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        key: const PageStorageKey<String>('ingredientList'),
        child: Column(
          children: [
            const ExpiryAlertCard(),
            ..._foodItems.asMap().entries.map((entry) {
              int index = entry.key;
              var item = entry.value;
              int daysLeft = _calculateRemainingDays(item['expiryDate']);

              return Dismissible(
                key: UniqueKey(),
                direction: DismissDirection.endToStart,
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
                onDismissed: (direction) {
                  setState(() {
                    _foodItems.removeAt(index); // ลบข้อมูลออกจาก List
                  });

                  // แจ้งเตือนสั้นๆ ด้านล่าง (Optional)
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("${item['title']} removed")),
                  );
                },

                child: FoodItemCard(
                  title: item['title'],
                  subtitle: item['subtitle'],
                  remainingDays: '$daysLeft Day',
                  statusColor: item['color'],
                  isSelected: item['isSelected'],
                  isNearExpiry: item['isNearExpiry'] ?? false,
                  onTap: () => {
                    setState(() {
                      _foodItems[index]['isSelected'] =
                          !_foodItems[index]['isSelected'];
                    }),
                  },
                ),
              );
            }),
            SizedBox(height: 75),
          ],
        ),
      ),
      floatingActionButton: SizedBox(
        width:
            MediaQuery.of(context).size.width * 0.9, // ขยายให้กว้างเกือบเต็มจอ
        height: 55,
        child: FloatingActionButton.extended(
          onPressed: () {
            // เมื่อกดเอาเฉพาะไอเทมที่ isSelected เป็น true
            widget.onFindMenu();
            final selectedItems = _foodItems
                .where((item) => item['isSelected'] == true)
                .toList();
            print(
              "เมนูแนะนำสำหรับ: ${selectedItems.map((e) => e['title']).toList()}",
            );
          },
          backgroundColor: Colors.green,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 4,
          // ใส่ Icon และ Text ตามรูป
          icon: const Icon(Icons.restaurant_menu, color: Colors.white),
          label: const Text(
            "Find the menu from the available items.",
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
        ),
      ),

      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  void _showAddIngredientDialog(BuildContext context) {
    widget.nameController.clear();
    widget.qtyController.clear();
    widget.expireController.clear();

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
                const Text(
                  "Ingredient name",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                // ส่ง Controller เข้าไปเพื่อให้ดึงค่าได้
                _buildModalTextField(
                  hintText: "Cheese",
                  controller: widget.nameController,
                ),
                const SizedBox(height: 16),

                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Quantity",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          _buildModalTextField(
                            hintText: "3",
                            controller: widget.qtyController,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ListTile(
                            title: Text(
                              "Exp Date: ${widget.expireController.text}",
                            ),
                            trailing: Icon(Icons.calendar_today),
                            onTap: () async {
                              DateTime? pickedDate = await showDatePicker(
                                context: context,
                                initialDate: DateTime.now(),
                                firstDate: DateTime.now(), // ห้ามเลือกย้อนหลัง
                                lastDate: DateTime(2100),
                              );
                              if (pickedDate != null) {
                                setState(() {
                                  widget.expireController.text =
                                      "${pickedDate.toLocal()}".split(' ')[0];
                                  _selectedDate = pickedDate;
                                });
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text(
                  "Unit",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                // ส่ง Controller เข้าไปเพื่อให้ดึงค่าได้
                _buildModalTextField(
                  hintText: "sheets",
                  controller: widget.nameController,
                ),

                const SizedBox(height: 24),

                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          if (widget.nameController.text.isNotEmpty &&
                              _selectedDate != null) {
                            setState(() {
                              _foodItems.add({
                                'title': widget.nameController.text,
                                'subtitle':
                                    'Remaining: ${widget.qtyController.text}',
                                'expiryDate': _selectedDate,
                                'color': Colors.green, // ตั้งค่าสีเริ่มต้น
                                'isSelected': false,
                              });
                            });
                            Navigator.pop(context);
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF28B446),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          "OK",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFF41F11),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          "Cancle",
                          style: TextStyle(fontWeight: FontWeight.bold),
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

class ExpiryAlertCard extends StatelessWidget {
  const ExpiryAlertCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        height: 82,
        margin: EdgeInsets.only(top: 16),
        padding: EdgeInsets.symmetric(vertical: 8, horizontal: 20),
        decoration: BoxDecoration(
          color: const Color.fromARGB(255, 255, 241, 229),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(width: 2, color: Colors.orange),
        ),
        child: Row(
          children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.orange[200],
                borderRadius: BorderRadius.circular(8),
              ),
              padding: EdgeInsets.all(4),
              margin: EdgeInsets.only(right: 16),
              child: Icon(Icons.alarm, size: 40, color: Colors.orange[800]),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "Expired notification",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                ),
                Text(
                  "Green onions will expire in ? days!!",
                  style: TextStyle(fontSize: 16),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

Widget _buildModalTextField({
  required String hintText,
  TextEditingController? controller,
}) {
  return TextField(
    controller: controller,
    decoration: InputDecoration(
      hintText: hintText,
      hintStyle: const TextStyle(color: Colors.grey),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Colors.grey),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
    ),
  );
}

int _calculateRemainingDays(DateTime expiryDate) {
  final now = DateTime.now();
  // คำนวณส่วนต่างของเวลา
  final difference = expiryDate.difference(now).inDays;
  return difference;
}
