import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../firebase/firebase_api.dart';
import 'main_scaffold.dart';

class RoleWrapper extends StatelessWidget {
  const RoleWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser!.uid;

    return FutureBuilder<String?>(
      future: DataBaseService().getUserRole(userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        final role = snapshot.data;
        if (role == null) {
          return const Scaffold(body: Center(child: Text('User not found or role missing')));
        }
        return MainScaffold(role: role);
      },
    );
  }
}
