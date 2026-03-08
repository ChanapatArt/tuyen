import 'package:flutter/material.dart';
import 'package:mobile_app/screens/recipe_details.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:mobile_app/services/auth_service.dart';

class Search extends StatefulWidget {
  const Search({super.key});

  @override
  State<Search> createState() => _SearchState();
}

class _SearchState extends State<Search> {
  final TextEditingController _searchController = TextEditingController();
  List<dynamic> _searchResults = [];
  bool _isLoading = false;

  Future<void> _searchRecipes(String query) async {
    if (query.isEmpty) return;

    setState(() => _isLoading = true);

    try {
      final uri = Uri.parse(
        '${AuthService.baseUrl}/recipes/search',
      ).replace(queryParameters: {'q': query, 'limit': '20'});

      final response = await http.get(
        uri,
        headers: {'accept': 'application/json'},
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        setState(() {
          _searchResults = responseData['data'];
          _isLoading = false;
        });
      }
    } catch (e) {
      print("Search Error: $e");
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. หัวข้อ Search menu
              const Row(
                children: [
                  Text(
                    "Search menu",
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(width: 8),
                  Icon(Icons.search, size: 28),
                ],
              ),
              const SizedBox(height: 16),

              // 2. ช่อง Search Bar
              TextField(
                controller: _searchController,
                onSubmitted: (value) => _searchRecipes(value),
                decoration: InputDecoration(
                  hintText: "Type the name of the menu item...",
                  hintStyle: TextStyle(
                    color: Colors.grey.shade400,
                    fontSize: 14,
                  ),
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade200),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // 3. หมวดหมู่ (Tags)
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildTag("Omelet", () {
                    _searchController.text = "Omelet";
                    _searchRecipes("Omelet");
                  }),
                  _buildTag("Chicken", () {
                    _searchController.text = "Chicken";
                    _searchRecipes("Chicken");
                  }),
                  _buildTag("Fried Rice", () {
                    _searchController.text = "Fried Rice";
                    _searchRecipes("Fried Rice");
                  }),
                ],
              ),
              const SizedBox(height: 24),

              // 4. ส่วน Popular menu
              const Text(
                "Menu",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _searchResults
                        .isEmpty 
                  ? _buildInitialView() 
                  :
                    // 5. รายการเมนูแบบ Grid
                    GridView.builder(
                      shrinkWrap: true, 
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2, // แบ่ง 2 คอลัมน์
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio:
                                0.85, // ปรับสัดส่วนความสูงของการ์ด
                          ),
                      itemCount: _searchResults.length,
                      itemBuilder: (context, index) {
                        final item = _searchResults[index];
                        return _buildPopularCard(
                          context,
                          item['title'] ?? "Unknown",
                          "${item['calories'] ?? 0} kcal",
                          Colors.grey.shade200,
                          item['recipe_id'],
                          item['image_url'],
                        );
                      },
                    ),
            ],
          ),
        ),
      ),
    );
  }

  // ฟังก์ชันสร้าง Tag หมวดหมู่
  Widget _buildTag(String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Text(
          label,
          style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
        ),
      ),
    );
  }

  // ฟังก์ชันสร้างการ์ดเมนูยอดนิยม
  Widget _buildPopularCard(
    BuildContext context,
    String title,
    String kcal,
    Color color,
    int recipeId,
    String? imageUrl,
  ) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => RecipeDetails(title: title)),
        );
      },
      child: Card(
        color: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ส่วนรูปภาพสมมติ
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
                child: imageUrl != null && imageUrl.isNotEmpty
                    ? Image.network(
                        imageUrl,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        // ✅ กรณีลิงก์เสียให้โชว์สีพื้นหลังเทา
                        errorBuilder: (context, error, stackTrace) =>
                            _buildCardPlaceholder(),
                      )
                    : _buildCardPlaceholder(), // ✅ กรณีไม่มี URL
              ),
            ),
            // ส่วนรายละเอียด
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    kcal,
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
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

Widget _buildCardPlaceholder() {
  return Container(
    width: double.infinity,
    color: Colors.grey.shade100,
    child: Icon(Icons.restaurant_menu, color: Colors.grey.shade300, size: 40),
  );
}

Widget _buildInitialView() {
  return Center(
    child: Padding(
      padding: const EdgeInsets.only(top: 50),
      child: Column(
        children: [
          // ใส่ไอคอนน่ารักๆ หรือภาพประกอบ
          Icon(Icons.restaurant_menu, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            "What do you want to cook today?",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Try searching for menu like 'Omelet' or 'Fried Rice'",
            style: TextStyle(color: Colors.grey.shade400, fontSize: 14),
          ),
        ],
      ),
    ),
  );
}
