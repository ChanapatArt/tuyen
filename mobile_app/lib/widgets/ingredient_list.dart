import 'package:flutter/material.dart';
import 'package:mobile_app/widgets/foodItem_card.dart';

class IngredientList extends StatelessWidget {
  final List<Map<String, dynamic>> foodItems;
  final Function(int) onToggleSelection;
  final VoidCallback onFindMenu;
  const IngredientList({
    super.key,
    required this.onFindMenu,
    required this.foodItems,
    required this.onToggleSelection,
  });

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
            onPressed: () {},
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
            ...foodItems.asMap().entries.map((entry) {
              int index = entry.key;
              var item = entry.value;

              return FoodItemCard(
                title: item['title'],
                subtitle: item['subtitle'],
                remainingDays: item['days'],
                statusColor: item['color'],
                isSelected: item['isSelected'],
                isNearExpiry: item['isNearExpiry'] ?? false,
                onTap: () => {onToggleSelection(index)},
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
            onFindMenu();
            final selectedItems = foodItems
                .where((item) => item['isSelected'] == true)
                .toList();
            print(
              "เมนูแนะนำสำหรับ: ${selectedItems.map((e) => e['title']).toList()}",
            );
          },
          backgroundColor: const Color(0xFF00C853),
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