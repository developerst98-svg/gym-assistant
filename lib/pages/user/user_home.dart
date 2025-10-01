import 'package:flutter/material.dart';

class UserHomePage extends StatelessWidget {
  const UserHomePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('User Home'),
      ),
      body: const Center(
        child: Text(
          'Welcome to the User Home Page!',
          style: TextStyle(fontSize: 20),
        ),
      ),
    );
  }
}
