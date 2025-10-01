import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../pages/coach/coach_home.dart';
import '../pages/user/user_home.dart';
import '../pages/user/user_profile.dart';
import '../pages/coach/coach_profile.dart';
import '../pages/user/user_tracker.dart';
class MainScaffold extends StatefulWidget {
  final String role;
  const MainScaffold({super.key, required this.role});

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  int _selectedIndex = 1;

  @override
  Widget build(BuildContext context) {
    // Different nav items depending on role
    final pages = widget.role == 'coach'
        ? [CoachHomePage(), CoachProfilePage()]
        : [UserHomePage(),  UserTrackerPage(),UserProfilePage()];

    final navItems = widget.role == 'coach'
        ? const [
            BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
            BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
          ]
        : const [
            BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
            BottomNavigationBarItem(icon: Icon(Icons.track_changes), label: "Tracker"),
            BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
          ];

    return Scaffold(
      body: pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        items: navItems,
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
      ),
    );
  }
}
