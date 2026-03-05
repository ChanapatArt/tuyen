import 'package:flutter/material.dart';
import 'home.dart';
import 'dart:async';

class Splash extends StatefulWidget {
  const Splash({super.key});

  @override
  State<Splash> createState() => _SplashState();
}

class _SplashState extends State<Splash>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);

    _animation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    // 3. โหลดข้อมูลเบื้องหลัง (แทนการใช้ Timer เฉยๆ)
    loadDataAndNavigate();
  }

  void loadDataAndNavigate() async {
    await Future.delayed(const Duration(seconds: 3)); // จำลองการโหลดข้อมูลจริงๆ 3 วินาที

    // เมื่อโหลดเสร็จ ค่อยย้ายไปหน้า Home
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const Home()),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ScaleTransition(
              scale: _animation,
              child: Image.asset(
                'assets/images/logo.png',
                width: 150,
              ),
            ),
            Text("TuYen",
            style: 
              TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold
            ),
            ),
          ],
        ),
      ),
    );
  }
}
