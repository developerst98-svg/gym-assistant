import 'package:flutter/material.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
// Removed to avoid circular import

class UserSetExercisePage extends StatelessWidget {
  final String workoutId;
  const UserSetExercisePage({super.key, required this.workoutId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Set Exercise'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            // Option 1: Just pop (if navigated from UserTrackerPage)
            Navigator.of(context).pop();
            // Option 2: If you want to always go to UserTrackerPage, use below:
            // Navigator.of(context).pushReplacement(
            //   MaterialPageRoute(builder: (context) => const UserTrackerPage()),
            // );
          },
        ),
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
