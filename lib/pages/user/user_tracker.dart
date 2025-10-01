import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../firebase/firebase_api.dart';

class UserTrackerPage extends StatefulWidget {
  const UserTrackerPage({super.key});

  @override
  State<UserTrackerPage> createState() => _UserTrackerPageState();
}

class _UserTrackerPageState extends State<UserTrackerPage> {
  late Future<List<Map<String, dynamic>>> _workoutsFuture;

  @override
  void initState() {
    super.initState();
    _workoutsFuture = DataBaseService().getWorkouts();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Workout Tracker'),
        actions: [
          TextButton.icon(
            onPressed: () => _openCreateWorkoutDialog(context),
            icon: const Icon(Icons.add, color: Colors.white),
            label: const Text('Create workout', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _workoutsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          final workouts = snapshot.data ?? [];
          if (workouts.isEmpty) {
            return const Center(child: Text('No workouts yet'));
          }
          // Group workouts by date (yyyy-MM-dd), latest date first
          final Map<String, List<Map<String, dynamic>>> grouped = {};
          for (final w in workouts) {
            final dynamic rawDate = w['date'];
            DateTime? date;
            if (rawDate is Timestamp) {
              date = rawDate.toDate();
            } else if (rawDate is DateTime) {
              date = rawDate;
            }
            final DateTime d = date != null
                ? DateTime(date.year, date.month, date.day)
                : DateTime(1970, 1, 1);
            final String key = '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
            grouped.putIfAbsent(key, () => []).add(w);
          }
          final List<String> dateKeys = grouped.keys.toList()
            ..sort((a, b) => b.compareTo(a));

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: dateKeys.length,
            itemBuilder: (context, index) {
              final String key = dateKeys[index];
              // Build a friendly display with weekday name
              String displayDate = key;
              try {
                final parts = key.split('-');
                if (parts.length == 3) {
                  final d = DateTime(
                    int.parse(parts[0]),
                    int.parse(parts[1]),
                    int.parse(parts[2]),
                  );
                  const weekdayNames = [
                    'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'
                  ];
                  final weekday = weekdayNames[d.weekday - 1];
                  displayDate = '$key ($weekday)';
                }
              } catch (_) {}
              final bool isLast = index == dateKeys.length - 1;
              final List<Map<String, dynamic>> dayWorkouts = grouped[key]!;

              Widget buildCard(Map<String, dynamic> w) {
                final String name = (w['name'] ?? '') as String;
                final String note = (w['note'] ?? '') as String;
                return SizedBox(
                  width: 150,
                  height: 120,
                  child: Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: BorderSide(color: Theme.of(context).dividerColor, width: 1),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            name.isEmpty ? 'Unnamed' : name,
                            style: Theme.of(context).textTheme.titleMedium,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            note,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodySmall,
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Timeline gutter
                  SizedBox(
                    width: 28,
                    child: Column(
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                        if (!isLast)
                          Container(
                            margin: const EdgeInsets.only(top: 4),
                            width: 2,
                            height: 120, // approximate connector; grows per section content
                            color: Theme.of(context).dividerColor,
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Content: date header + cards
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          displayDate,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: dayWorkouts.map(buildCard).toList(),
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  void _openCreateWorkoutDialog(BuildContext context) {
    final TextEditingController nameController = TextEditingController();
    final TextEditingController notesController = TextEditingController();
    DateTime selectedDate = DateTime.now();

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setStateDialog) {
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
                        Text('${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}'),
                        const Spacer(),
                        TextButton.icon(
                          onPressed: () async {
                            final DateTime now = DateTime.now();
                            final DateTime firstDate = DateTime(now.year - 5);
                            final DateTime lastDate = DateTime(now.year + 5);
                            final DateTime? picked = await showDatePicker(
                              context: ctx,
                              initialDate: selectedDate,
                              firstDate: firstDate,
                              lastDate: lastDate,
                            );
                            if (picked != null) {
                              setStateDialog(() {
                                selectedDate = picked;
                              });
                            }
                          },
                          icon: const Icon(Icons.event),
                          label: const Text('Change'),
                        ),
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
                        date: selectedDate,
                      );
                      if (context.mounted) {
                        Navigator.of(ctx).pop();
                        setState(() {
                          _workoutsFuture = DataBaseService().getWorkouts();
                        });
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
      },
    );
  }
}