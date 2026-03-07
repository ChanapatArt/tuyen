import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  // พิกัดเริ่มต้น (ระหว่างรอโหลดตำแหน่งเครื่อง)
  LatLng _currentPosition = const LatLng(13.7563, 100.5018);
  GoogleMapController? _mapController;
  String _currentSearchTitle = "Market near me";
  final Set<Marker> _markers = {};

  @override
  void initState() {
    super.initState();
    _determinePosition(); // ✅ เรียกฟังก์ชันดึงตำแหน่งทันทีที่เปิดหน้า
  }

  // ฟังก์ชันขออนุญาตเข้าถึงตำแหน่งและดึงพิกัดปัจจุบัน
  Future<void> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    // ตรวจสอบว่าเปิด Service GPS หรือไม่
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    // ตรวจสอบการขออนุญาต (Permission)
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }

    if (permission == LocationPermission.deniedForever) return;

    Position position =
        await Geolocator.getCurrentPosition(); // ดึงตำแหน่งปัจจุบัน
    if (mounted) {
      setState(() {
        // เช็กว่า Widget ยังอยู่บนหน้าจอไหม
        _currentPosition = LatLng(position.latitude, position.longitude);
      });
      _loadStoreMarkers(
        _currentSearchTitle,
      ); // โหลดหมุดทันทีที่ได้ตำแหน่งเครื่อง

      _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(_currentPosition, 15),
      );
    }

    setState(() {
      _currentPosition = LatLng(position.latitude, position.longitude);
    });

    // เลื่อนกล้องแผนที่ไปที่พิกัดที่ดึงมาได้
    _mapController?.animateCamera(
      CameraUpdate.newLatLngZoom(_currentPosition, 15),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          _currentSearchTitle,
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _currentPosition,
              zoom: 14,
            ),
            onMapCreated: (controller) {
              _mapController =
                  controller; // เก็บตัวควบคุมแผนที่ไว้ใช้เลื่อนกล้อง
            },
            myLocationEnabled: true, // ✅ แสดงจุดสีฟ้าที่ตำแหน่งเรา
            myLocationButtonEnabled:
                true, // ✅ เพิ่มปุ่มกดกลับมาที่ตำแหน่งตัวเอง
            zoomControlsEnabled: false,
            markers: _markers,
          ),

          // Chips สำหรับเลือกประเภท (โค้ดเดิมของคุณ)
          Positioned(
            top: 10,
            left: 0,
            right: 0,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  _buildSearchChip("Market near me", Icons.storefront),
                  _buildSearchChip("Big C near me", Icons.shopping_bag),
                  _buildSearchChip("Makro near me", Icons.local_shipping),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchChip(String label, IconData icon) {
    bool isSelected = _currentSearchTitle == label;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ActionChip(
        avatar: Icon(
          icon,
          size: 18,
          color: isSelected ? Colors.white : Colors.green,
        ),
        label: Text(label),
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : Colors.black,
          fontWeight: FontWeight.bold,
        ),
        backgroundColor: isSelected ? Colors.green : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        onPressed: () {
          setState(() {
            _currentSearchTitle = label;
          });
          _loadStoreMarkers(label);

          // ✅ 1. ย้ายกล้องไปยังตำแหน่งปัจจุบันของเราก่อนค้นหา
          _mapController?.animateCamera(
            CameraUpdate.newLatLngZoom(_currentPosition, 15),
          );

          // ✅ 2. ตัวอย่าง Logic สำหรับการค้นหา (ในที่นี้คือการแสดงข้อความแจ้งเตือน)
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("กำลังค้นหา $label..."),
              duration: const Duration(seconds: 2),
              backgroundColor: Colors.green,
            ),
          );
        },
      ),
    );
  }

  Future<void> _loadStoreMarkers(String type) async {
    try {
      final String response = await rootBundle.loadString(
        'assets/map_data.json',
      );
      final List<dynamic> data = json.decode(response);

      // ✅ ปรับการดึง Key: ถ้าเป็น Big C ให้ยุบเหลือ BigC เพื่อให้ตรงกับ JSON
      String filterKey = type.split(' ')[0]; // ได้ "Big", "Makro", "Market"
      if (filterKey == "Big") filterKey = "BigC";

      setState(() {
        _markers.clear();
        for (var item in data) {
          // 1. คำนวณระยะทาง
          double distanceInMeters = Geolocator.distanceBetween(
            _currentPosition.latitude,
            _currentPosition.longitude,
            item['lat'],
            item['lng'],
          );

          // 2. เงื่อนไข: เช็กประเภทให้ตรงกับ filterKey
          if (item['type'].toString().contains(filterKey) &&
              distanceInMeters < 10000) { // ปรับระยะเป็น 10 กม.
            _markers.add(
              Marker(
                markerId: MarkerId(item['name']),
                position: LatLng(item['lat'], item['lng']),
                infoWindow: InfoWindow(
                  title: item['name'],
                  snippet:
                      'ห่างจากคุณ ${(distanceInMeters / 1000).toStringAsFixed(1)} กม. (${item['province']})',
                ),
                icon: BitmapDescriptor.defaultMarkerWithHue(
                  BitmapDescriptor.hueGreen,
                ),
              ),
            );
          }
        }
      });
    } catch (e) {
      print("Error loading JSON: $e");
    }
  }
}
