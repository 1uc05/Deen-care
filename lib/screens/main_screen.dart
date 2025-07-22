import 'package:flutter/material.dart';
import 'package:caunvo/screens/home_screen.dart';
import 'package:caunvo/screens/calendar_screen.dart';
import 'package:caunvo/screens/salon_screen.dart';
import 'package:caunvo/core/constants/app_colors.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});
  
  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  
  final List<Widget> _pages = [
    const HomeScreen(),
    const CalendarScreen(), 
    const SalonScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppColors.highLight,
        unselectedItemColor: AppColors.textGrey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Accueil'),
          BottomNavigationBarItem(icon: Icon(Icons.calendar_today), label: 'Réservation'),
          BottomNavigationBarItem(icon: Icon(Icons.chat), label: 'Salon'),
        ],
      ),
    );
  }
}
