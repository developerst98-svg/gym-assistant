import 'package:flutter/material.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';

class UserProfilePage extends StatelessWidget {
  const UserProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('User Profile')),
      body: Center(
        child: LoadingAnimationWidget.dotsTriangle(
          color: Theme.of(context).colorScheme.secondary,
          size: 64,
        ),
      ),
    );
  }
}
