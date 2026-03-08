import 'package:flutter/material.dart';
import 'package:mobile_app/widgets/foodItem_card.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:mobile_app/services/auth_service.dart';

class IngredientList extends StatefulWidget {
  final Function(List<String>) onFindMenu;
  final TextEditingController nameController = TextEditingController();
  final TextEditingController qtyController = TextEditingController();
  final TextEditingController expireController = TextEditingController();
  final TextEditingController unitController = TextEditingController();

  IngredientList({super.key, required this.onFindMenu});
  @override
  State<IngredientList> createState() => _IngredientList();
}

class _IngredientList extends State<IngredientList> {
  DateTime? _selectedDate;
  List<Map<String, dynamic>> _foodItems = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchFridgeItems(); // เรียกดึงข้อมูลทันที
  }

  Future<void> _fetchFridgeItems() async {
    String? userId = await AuthService.getUserId();
    if (userId == null) return;

    try {
      final response = await http.get(
        Uri.parse('${AuthService.baseUrl}/fridge/$userId'),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);

        if (responseData['status'] == 'success') {
          List<dynamic> data = responseData['data']; // ข้อมูลดิบจาก Azure

          setState(() {
            // ✅ นำ Logic ที่ผมให้ไปใส่ตรงนี้เพื่อแปลงข้อมูลก่อนแสดงผล
            _foodItems = data.map((item) {
              DateTime expiryRaw = DateTime.parse(item['expiry_date']);
              DateTime now = DateTime.now();
              DateTime today = DateTime(now.year, now.month, now.day);
              DateTime expiry = DateTime(
                expiryRaw.year,
                expiryRaw.month,
                expiryRaw.day,
              );
              int daysLeft = expiry.difference(today).inDays;
              return {
                "fridge_id": item['fridge_id'],
                "title": item['ingredient_name'],
                "subtitle": 'Remaining: ${item['quantity']} ${item['unit']}',
                "expiryDate": expiry,
                "daysLeft": daysLeft,
                // ✅ ใช้ Logic สีเดียวกันกับตอนกดปุ่ม OK
                "color": daysLeft == 1
                    ? Colors.red
                    : (daysLeft <= 3 ? Colors.orange : Colors.green),
                "isSelected": false,
                "isNearExpiry": daysLeft <= 3,
              };
            }).toList();

            // ✅ สั่งเรียงลำดับตามวันหมดอายุ (น้อยไปมาก)
            _foodItems.sort(
              (a, b) => (a['expiryDate'] as DateTime).compareTo(
                b['expiryDate'] as DateTime,
              ),
            );

            _isLoading = false;
          });
        }
      }
    } catch (e) {
      print("Error fetching fridge: $e");
      setState(() => _isLoading = false);
    }
  }

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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _fetchFridgeItems,
              child: SingleChildScrollView(
                key: const PageStorageKey<String>('ingredientList'),
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  children: [
                    if (_foodItems.isNotEmpty && _foodItems.first['daysLeft'] <= 3)
                      ExpiryAlertCard(
                        title: _foodItems.first['title'],
                        daysLeft: _foodItems.first['daysLeft'],
                      ),
                    ..._foodItems.asMap().entries.map((entry) {
                      int index = entry.key;
                      var item = entry.value;
                      int daysLeft = item['daysLeft'];

                      return Dismissible(
                        key: ValueKey(item['fridge_id']),
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
                        onDismissed: (direction) async {
                          final deletedItem = item;
                          final int fridgeId = item['fridge_id'];
                          setState(() {
                            _foodItems.removeAt(index); // ลบข้อมูลออกจาก List
                          });
                          try {
                            final response = await http.delete(
                              Uri.parse(
                                '${AuthService.baseUrl}/fridge/remove/$fridgeId',
                              ),
                            );

                            if (response.statusCode == 200) {
                              // ลบสำเร็จ
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      "${deletedItem['title']} removed from fridge",
                                    ),
                                  ),
                                );
                              }
                            } else {
                              // หากลบใน Server ไม่สำเร็จ ให้ดึงข้อมูลใหม่เพื่อคืนค่า
                              _fetchFridgeItems();
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
                            print("Error deleting: $e");
                            _fetchFridgeItems(); // คืนค่าหากเกิด Error การเชื่อมต่อ
                          }
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
            ),
      floatingActionButton: SizedBox(
        width:
            MediaQuery.of(context).size.width * 0.9, // ขยายให้กว้างเกือบเต็มจอ
        height: 55,
        child: FloatingActionButton.extended(
          onPressed: () {
            // กรองเอาเฉพาะชื่อวัตถุดิบที่เลือก
            List<String> selectedNames = _foodItems
                .where((item) => item['isSelected'] == true)
                .map((item) => item['title'].toString())
                .toList();

            if (selectedNames.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("Please select ingredients first!"),
                ),
              );
              return;
            }

            // ✅ ส่งรายชื่อวัตถุดิบกลับไปยัง HomeSubNavigator ผ่าน callback
            widget.onFindMenu(selectedNames);
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
    _selectedDate = null;
    widget.nameController.clear();
    widget.qtyController.clear();
    widget.expireController.clear();
    widget.unitController.clear();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
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
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildModalTextField(
                      hintText: "Cheese",
                      controller: widget.nameController,
                      onChanged: (val) =>
                          setModalState(() {}), // รีเฟรชสถานะปุ่มเวลาพิมพ์
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
                                onChanged: (val) => setModalState(() {}),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "Exp Date",
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 8),
                              InkWell(
                                onTap: () async {
                                  DateTime? pickedDate = await showDatePicker(
                                    context: context,
                                    initialDate: DateTime.now(),
                                    firstDate: DateTime.now(),
                                    lastDate: DateTime(2100),
                                  );
                                  if (pickedDate != null) {
                                    // ✅ ใช้ setModalState เพื่อให้ปุ่ม OK เปลี่ยนจากเทาเป็นเขียวทันที
                                    setModalState(() {
                                      _selectedDate = pickedDate;
                                      widget.expireController.text =
                                          "${pickedDate.toLocal()}".split(
                                            ' ',
                                          )[0];
                                    });
                                  }
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                    horizontal: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: Colors.grey.shade300,
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          widget.expireController.text.isEmpty
                                              ? "Select"
                                              : widget.expireController.text,
                                          style: const TextStyle(fontSize: 12),
                                        ),
                                      ),
                                      const Icon(
                                        Icons.calendar_today,
                                        size: 16,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      "Unit",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildModalTextField(
                      hintText: "sheets",
                      controller: widget.unitController,
                      onChanged: (val) => setModalState(() {}),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            // ✅ ปุ่มจะกดไม่ได้จนกว่าจะกรอกชื่อและเลือกวันที่
                            onPressed:
                                (widget.nameController.text.isEmpty ||
                                    _selectedDate == null)
                                ? null
                                : () async {
                                    String? userId =
                                        await AuthService.getUserId();
                                    if (userId == null) return;

                                    try {
                                      String formattedDate =
                                          "${_selectedDate!.toLocal()}".split(
                                            ' ',
                                          )[0];
                                      final response = await http.post(
                                        Uri.parse(
                                          '${AuthService.baseUrl}/fridge/add',
                                        ),
                                        headers: {
                                          'Content-Type': 'application/json',
                                        },
                                        body: jsonEncode({
                                          "user_id": int.parse(userId),
                                          "ingredient_name":
                                              widget.nameController.text,
                                          "quantity":
                                              double.tryParse(
                                                widget.qtyController.text,
                                              ) ??
                                              1.0,
                                          "unit": widget.unitController.text,
                                          "expiry_date": formattedDate,
                                        }),
                                      );

                                      if (response.statusCode == 200) {
                                        final Map<String, dynamic>
                                        responseData = jsonDecode(
                                          response.body,
                                        );

                                        DateTime now = DateTime.now();
                                        DateTime today = DateTime(
                                          now.year,
                                          now.month,
                                          now.day,
                                        );
                                        DateTime expiry = DateTime(
                                          _selectedDate!.year,
                                          _selectedDate!.month,
                                          _selectedDate!.day,
                                        );
                                        int daysLeft = expiry
                                            .difference(today)
                                            .inDays;

                                        setState(() {
                                          // 1. เพิ่มข้อมูลเข้าไปใน List ก่อน
                                          _foodItems.add({
                                            "fridge_id":
                                                responseData['fridge_id'],
                                            "title": widget.nameController.text,
                                            "subtitle":
                                                'Remaining: ${widget.qtyController.text} ${widget.unitController.text}',
                                            "expiryDate": _selectedDate,
                                            // ✅ ปรับเงื่อนไขสีให้ตรงกับ Logic หลังรีเฟรช
                                            "color": daysLeft == 1
                                                ? Colors.red
                                                : (daysLeft <= 3
                                                      ? Colors.orange
                                                      : Colors.green),
                                            "isSelected": false,
                                            "isNearExpiry": daysLeft <= 3,
                                            "daysLeft": daysLeft,
                                          });

                                          // 2. ✅ สั่งเรียงลำดับใหม่ทันทีตามวันหมดอายุ (น้อยไปมาก)
                                          _foodItems.sort(
                                            (a, b) =>
                                                (a['expiryDate'] as DateTime)
                                                    .compareTo(
                                                      b['expiryDate']
                                                          as DateTime,
                                                    ),
                                          );
                                        });

                                        if (context.mounted)
                                          Navigator.pop(context);
                                      }
                                    } catch (e) {
                                      print("Error adding ingredient: $e");
                                    }
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF28B446),
                              disabledBackgroundColor: Colors.grey.shade300,
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
                              backgroundColor: const Color(0xFFF41F11),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text(
                              "Cancel",
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
      },
    );
  }

  // แก้ไข Helper Widget ให้รับค่า onChanged เพื่อความลื่นไหลของสถานะปุ่ม
  Widget _buildModalTextField({
    required String hintText,
    TextEditingController? controller,
    Function(String)? onChanged,
  }) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: const TextStyle(color: Colors.grey),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 10,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF28B446)),
        ),
      ),
    );
  }
}

class ExpiryAlertCard extends StatelessWidget {
  final String title;
  final int daysLeft;

  const ExpiryAlertCard({
    super.key,
    required this.title,
    required this.daysLeft,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        height: 85, // ปรับความสูงเล็กน้อยเผื่อข้อความยาว
        margin: const EdgeInsets.only(top: 16),
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 20),
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
              padding: const EdgeInsets.all(4),
              margin: const EdgeInsets.only(right: 16),
              child: Icon(Icons.alarm, size: 40, color: Colors.orange[800]),
            ),
            Expanded(
              // ใช้ Expanded กันข้อความล้นจอ
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    "Expired notification",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  Text(
                    "$title will expire in $daysLeft days!!",
                    style: const TextStyle(fontSize: 14),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
