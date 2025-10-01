import 'package:flutter/material.dart';
import '../../firebase/firebase_api.dart';

class UserTrackerPage extends StatelessWidget {
  const UserTrackerPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('User Tracker'),
        actions: [
          TextButton.icon(
            onPressed: () => _openCreateWorkoutDialog(context),
            icon: const Icon(Icons.add, color: Colors.white),
            label: const Text('Create workout', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: const Center(
        child: Text('User Tracker Page'),
      ),
    );
  }

  void _openCreateWorkoutDialog(BuildContext context) {
    final TextEditingController nameController = TextEditingController();
    final TextEditingController notesController = TextEditingController();
    final DateTime today = DateTime.now();

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Create workout'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Workout name'),
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Text('Date: '),
                    Text('${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}'),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: notesController,
                  decoration: const InputDecoration(labelText: 'Notes'),
                  maxLines: 3,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final String name = nameController.text.trim();
                final String notes = notesController.text.trim();
                if (name.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter a workout name')),
                  );
                  return;
                }
                try {
                  await DataBaseService().createWorkout(
                    name: name,
                    note: notes,
                    date: today,
                  );
                  if (context.mounted) {
                    Navigator.of(ctx).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Workout created')),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed to create workout: $e')),
                    );
                  }
                }
              },
              child: const Text('Create'),
            ),
          ],
        );
      },
    );
  }
}