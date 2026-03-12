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

  List<int> _favoriteIds = [];
  List<dynamic> _favoriteMenus = [];

  bool _isLoading = false;
  // ✅ 2. ปรับฟังก์ชันโหลดข้อมูลให้จัดการสถานะ Loading
  Future<void> _fetchFavorites() async {
    setState(() => _isLoading = true); // เริ่มหมุน

    String? userId = await AuthService.getUserId();
    if (userId == null) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      final response = await http.get(
        Uri.parse('${AuthService.baseUrl}/favorites/$userId'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'success') {
          setState(() {
            _favoriteMenus = data['data'];
            _favoriteIds = _favoriteMenus
                .map<int>((m) => m['recipe_id'] as int)
                .toList();
          });
        }
      }
    } catch (e) {
      debugPrint("Fetch Error: $e");
    } finally {
      setState(() => _isLoading = false); // หยุดหมุน
    }
  }

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
  void initState() {
    super.initState();
    _fetchFavorites();

    _searchController.addListener(() {
      if (_searchController.text.isEmpty) {
        setState(() {});
      }
    });
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
                  _buildTag("pork steaks", () {
                    _searchController.text = "pork steaks";
                    _searchRecipes("pork steaks");
                  }),
                  _buildTag("ravioli lasagna", () {
                    _searchController.text = "ravioli lasagna";
                    _searchRecipes("ravioli lasagna");
                  }),
                  _buildTag("chocolate smoothie", () {
                    _searchController.text = "chocolate smoothie";
                    _searchRecipes("chocolate smoothie");
                  }),
                  _buildTag("carolina bbq", () {
                    _searchController.text = "carolina bbq";
                    _searchRecipes("carolina bbq");
                  }),
                ],
              ),
              const SizedBox(height: 24),

              // 4. ส่วน Popular menu
              // const Text(
              //   "Menu",
              //   style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              // ),
              // const SizedBox(height: 16),
              // _isLoading
              //     ? const Center(child: CircularProgressIndicator())
              //     : _searchResults.isEmpty
              //     ? _buildInitialView()
              //     :
              //       // 5. รายการเมนูแบบ Grid
              //       GridView.builder(
              //         shrinkWrap: true,
              //         physics: const NeverScrollableScrollPhysics(),
              //         gridDelegate:
              //             const SliverGridDelegateWithFixedCrossAxisCount(
              //               crossAxisCount: 2, // แบ่ง 2 คอลัมน์
              //               crossAxisSpacing: 12,
              //               mainAxisSpacing: 12,
              //               childAspectRatio:
              //                   0.85, // ปรับสัดส่วนความสูงของการ์ด
              //             ),
              //         itemCount: _searchResults.length,
              //         itemBuilder: (context, index) {
              //           final item = _searchResults[index];
              //           return _buildPopularCard(
              //             context,
              //             item['title'] ?? "Unknown",
              //             "${item['calories'] ?? 0} kcal",
              //             Colors.grey.shade200,
              //             item['recipe_id'],
              //             item['image_url'],
              //           );
              //         },
              //       ),
              Text(
                _searchController.text.isEmpty
                    ? "My Favorites"
                    : "Search Results", // ✅ เปลี่ยนหัวข้อตามสถานะ
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : (_searchController.text.isEmpty &&
                        _favoriteMenus
                            .isEmpty) // ✅ กรณีไม่มีทั้งคำค้นและไม่มีเมนูโปรด
                  ? _buildInitialView()
                  : GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio: 0.85,
                          ),
                      // ✅ เลือกจำนวนข้อมูลตามสถานะช่องค้นหา
                      itemCount: _searchController.text.isEmpty
                          ? _favoriteMenus.length
                          : _searchResults.length,
                      itemBuilder: (context, index) {
                        final item = _searchController.text.isEmpty
                            ? _favoriteMenus[index]
                            : _searchResults[index];

                        return _buildPopularCard(
                          context,
                          item['title'] ?? "Unknown",
                          // ✅ ปรับการแสดงผลแคลอรี่ให้ยืดหยุ่น
                          "${item['calories'] ?? 0} Cal.",
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
    bool isFav = _favoriteIds.contains(recipeId);
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
            Expanded(
              child: Stack(
                // ✅ ใช้ Stack เพื่อวางหัวใจทับรูป
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(12),
                    ),
                    child: imageUrl != null && imageUrl.isNotEmpty
                        ? Image.network(
                            imageUrl,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                _buildCardPlaceholder(),
                          )
                        : _buildCardPlaceholder(),
                  ),

                  // ✅ ปุ่มหัวใจมุมขวาบน
                  Positioned(
                    top: 8,
                    right: 8,
                    child: GestureDetector(
                      onTap: () => _toggleFavorite(
                        recipeId,
                        title,
                        kcal,
                        imageUrl,
                      ), // ฟังก์ชันสลับสถานะ
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isFav ? Icons.favorite : Icons.favorite_border,
                          color: isFav ? Colors.red : Colors.grey,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ],
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

  Future<void> _toggleFavorite(int recipeId, String title, String kcal, String? url) async {
  String? userId = await AuthService.getUserId();
  if (userId == null) return;

  // --- ส่วนที่ 1: อัปเดต UI ทันที (Optimistic Update) ---
  bool isAdding = !_favoriteIds.contains(recipeId);
  
  setState(() {
    if (isAdding) {
      _favoriteIds.add(recipeId);
      // เพิ่มข้อมูลจำลองเข้าไปใน List ก่อน เพื่อให้หน้า Favorites โชว์ทันที
      _favoriteMenus.add({
        'recipe_id': recipeId,
        'title': title,
        'calories': kcal.replaceAll(" kcal", ""),
        'image_url': url,
      });
    } else {
      _favoriteIds.remove(recipeId);
      _favoriteMenus.removeWhere((m) => m['recipe_id'] == recipeId);
    }
  });

  // --- ส่วนที่ 2: ทำงานกับ Backend ลับหลัง ---
  try {
    http.Response response;
    if (isAdding) {
      response = await http.post(
        Uri.parse('${AuthService.baseUrl}/favorite/add'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({"user_id": int.parse(userId), "recipe_id": recipeId}),
      );
    } else {
      response = await http.delete(
        Uri.parse('${AuthService.baseUrl}/favorite/remove/$userId/$recipeId'),
      );
    }

    // ถ้า Backend ตอบกลับว่า Error (ไม่ใช่ 200) ให้ดีดสถานะกลับ
    if (response.statusCode != 200) {
      _rollbackFavorite(recipeId, isAdding);
      ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text("Failed to update server. Please try again.")));
    }
  } catch (e) {
    // กรณีเน็ตหลุด หรือเชื่อมต่อไม่ได้ ให้ดีดสถานะกลับเช่นกัน
    _rollbackFavorite(recipeId, isAdding);
    ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text("Network error. Please check your connection.")));
  }
}

// ✅ ฟังก์ชันสำหรับดีดสถานะ UI กลับกรณีทำงานไม่สำเร็จ
void _rollbackFavorite(int recipeId, bool wasAdding) {
  setState(() {
    if (wasAdding) {
      _favoriteIds.remove(recipeId);
      _favoriteMenus.removeWhere((m) => m['recipe_id'] == recipeId);
    } else {
      _fetchFavorites(); // วิธีที่ง่ายที่สุดคือโหลดจาก DB ใหม่เพื่อความชัวร์
    }
  });
}
}

Widget _buildCardPlaceholder() {
  return Container(
    width: double.infinity,
    height: double.infinity,
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
