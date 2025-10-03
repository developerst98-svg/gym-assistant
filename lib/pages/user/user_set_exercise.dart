import 'package:flutter/material.dart';
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'This is the Set Exercise page.',
              style: TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 8),
            Text('Workout ID: $workoutId'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {},
              child: const Text('Add New Exercise'),
            ),
          ],
        ),
      ),
    );
  }
}
