import 'package:flutter/material.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';

class UserHomePage extends StatelessWidget {
  const UserHomePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('User Home'),
      ),
      body: Center(
        child: LoadingAnimationWidget.dotsTriangle(
          color: Theme.of(context).colorScheme.secondary,
          size: 64,
        ),
      ),
    );
  }
}
