import 'package:flutter/material.dart';

class FoodItemCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String remainingDays;
  final Color statusColor;
  final bool isNearExpiry;
  final bool isSelected; 
  final VoidCallback onTap;

  const FoodItemCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.remainingDays,
    required this.statusColor,
    required this.isSelected,
    required this.onTap,
    this.isNearExpiry = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation:  3,
        color: isSelected ? Colors.green.shade50 : Colors.white, // สีพื้นหลัง
        shadowColor: const Color.fromARGB(110, 0, 0, 0),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: IntrinsicHeight(
            child: Row(
              children: [
                // 1. แถบสีด้านซ้าย
                Container(
                  width: 6,
                  margin: EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: statusColor,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
      
                const SizedBox(width: 12),
      
                // 2. ข้อมูลชื่อและจำนวน
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          subtitle,
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
      
                // 3. ป้ายบอกวัน (Badge)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isNearExpiry
                        ? Colors.red.shade100
                        : isSelected ? Colors.green.shade200 : Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    remainingDays,
                    style: TextStyle(
                      color: isNearExpiry ? Colors.red : Colors.black87,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
      
                // 4. Checkbox (วงกลมด้านขวา)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Icon(
                    isSelected ? Icons.check_circle : Icons.circle_outlined,
                    color: Colors.grey.shade500,
                    size: 28,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
