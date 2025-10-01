import 'package:flutter/material.dart';

class CoachHomePage extends StatelessWidget {
  const CoachHomePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Coach Home'),
      ),
      body: const Center(
        child: Text(
          'Welcome to the Coach Home Page!',
          style: TextStyle(fontSize: 20),
        ),
      ),
    );
  }
}
