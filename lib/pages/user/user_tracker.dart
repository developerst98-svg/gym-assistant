import 'package:flutter/material.dart';
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import '../../firebase/firebase_api.dart';
import 'user_set_exercise.dart';
class UserTrackerPage extends StatefulWidget {
  const UserTrackerPage({super.key});

  @override
  State<UserTrackerPage> createState() => _UserTrackerPageState();
}

class _UserTrackerPageState extends State<UserTrackerPage> {
  late Future<List<Map<String, dynamic>>> _workoutsFuture;
  bool _selectionMode = false;
  final Set<String> _selectedIds = <String>{};
  Timer? _longPressTimer;
  final DataBaseService _db = DataBaseService();

  void _showSuccessSnackBar({
    required BuildContext context,
    required String title,
    String? subtitle,
    IconData icon = Icons.check_circle,
  }) {
    final snackBar = SnackBar(
      behavior: SnackBarBehavior.floating,
      elevation: 0,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      backgroundColor: Colors.transparent,
      duration: const Duration(seconds: 2),
      content: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
          border: Border.all(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    Theme.of(context).colorScheme.primary.withOpacity(0.2),
                    Theme.of(context).colorScheme.primary.withOpacity(0.05),
                  ],
                ),
              ),
              child: Center(
                child: Icon(
                  icon,
                  size: 22,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  if (subtitle != null && subtitle.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        subtitle,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.8),
                            ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(snackBar);
  }

  @override
  void initState() {
    super.initState();
    _workoutsFuture = _db.getWorkouts();
  }

  @override
  void dispose() {
    _longPressTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Workout Tracker'),
        actions: [
          if (_selectionMode) ...[
            IconButton(
              tooltip: 'Exit delete mode',
              icon: const Icon(Icons.close),
              onPressed: () {
                setState(() {
                  _selectionMode = false;
                  _selectedIds.clear();
                });
              },
            ),
            IconButton(
              tooltip: 'Delete selected',
              icon: const Icon(Icons.delete, color: Colors.redAccent),
              onPressed: _selectedIds.isEmpty
                  ? null
                  : () async {
                      final bool? confirm = await showDialog<bool>(
                        context: context,
                        builder: (dCtx) => AlertDialog(
                          title: const Text('Delete selected workouts?'),
                          content: Text('Are you sure you want to delete ${_selectedIds.length} selected workout(s)?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(dCtx).pop(false),
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.of(dCtx).pop(true),
                              child: const Text('Delete', style: TextStyle(color: Colors.red)),
                            ),
                          ],
                        ),
                      );
                      if (confirm == true) {
                        try {
                          await _db.deleteManyWorkouts(_selectedIds.toList());
                          if (context.mounted) {
                            setState(() {
                              _selectionMode = false;
                              _selectedIds.clear();
                              _workoutsFuture = _db.getWorkouts();
                            });
                            _showSuccessSnackBar(
                              context: context,
                              title: 'Deleted successfully',
                              subtitle: 'Selected workouts have been removed.',
                              icon: Icons.delete_sweep,
                            );
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Failed to delete selected: $e')),
                            );
                          }
                        }
                      }
                    },
            ),
          ]
          else
            PopupMenuButton<String>(
              tooltip: 'More',
              onSelected: (value) {
                if (value == 'delete') {
                  setState(() {
                    _selectionMode = true;
                    _selectedIds.clear();
                  });
                } else if (value == 'create') {
                  _openCreateWorkoutDialog(context);
                }
              },
              itemBuilder: (ctx) => const [
                PopupMenuItem<String>(
                  value: 'create',
                  child: Text('Create workout'),
                ),
                PopupMenuItem<String>(
                  value: 'delete',
                  child: Text('Delete'),
                ),
              ],
              icon: const Icon(Icons.more_vert),
            ),
        ],
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _workoutsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: LoadingAnimationWidget.dotsTriangle(
                color: Theme.of(context).colorScheme.secondary,
                size: 64,
              ),
            );
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
            cacheExtent: 800,
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
                final String? id = w['id'] as String?;
                final bool isSelected = id != null && _selectedIds.contains(id);
                return SizedBox(
                  width: 150,
                  height: 120,
                  child: Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: BorderSide(color: Theme.of(context).dividerColor, width: 1),
                    ),
                    child: GestureDetector(
                      onTapDown: (_) {
                        if (!_selectionMode) {
                          _longPressTimer?.cancel();
                          _longPressTimer = Timer(const Duration(seconds: 1), () {
                            if (!mounted) return;
                            if (id == null) return;
                            setState(() {
                              _selectionMode = true;
                              _selectedIds.add(id);
                            });
                          });
                        }
                      },
                      onTapUp: (_) {
                        _longPressTimer?.cancel();
                      },
                      onTapCancel: () {
                        _longPressTimer?.cancel();
                      },
                      child: InkWell(
                        onTap: () {
                          if (!_selectionMode) {
                            if (id == null || id.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Missing workout ID')),
                              );
                              return;
                            }
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (ctx) => UserSetExercisePage(workoutId: id),
                              ),
                            );
                          } else {
                            if (id == null) return;
                            setState(() {
                              if (_selectedIds.contains(id)) {
                                _selectedIds.remove(id);
                              } else {
                                _selectedIds.add(id);
                              }
                            });
                          }
                        },
                        child: Stack(
                        children: [
                          Align(
                            alignment: Alignment.center,
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
                          if (_selectionMode)
                            Positioned(
                              top: 4,
                              right: 4,
                              child: Container(
                                width: 22,
                                height: 22,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: isSelected ? Theme.of(context).colorScheme.primary : Theme.of(context).dividerColor,
                                    width: 2,
                                  ),
                                  color: isSelected ? Theme.of(context).colorScheme.primary.withOpacity(0.15) : Colors.transparent,
                                ),
                                child: isSelected
                                    ? Icon(Icons.check, size: 16, color: Theme.of(context).colorScheme.primary)
                                    : null,
                              ),
                            ),
                        ],
                        ),
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
                          children: [for (final w in dayWorkouts) KeyedSubtree(key: ValueKey(w['id'] ?? w.hashCode), child: buildCard(w))],
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
    // Options for quick-select workout names
    const List<String> nameOptions = [
      'Chest day',
      'Back day',
      'Leg day',
      'Push day',
      'Pull day',
      'Arms day',
      'Shoulders day',
      'Full body',
      'Other',
    ];
    String? selectedNameOption;

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
                    DropdownButtonFormField<String>(
                      value: selectedNameOption,
                      items: nameOptions
                          .map((opt) => DropdownMenuItem(
                                value: opt,
                                child: Text(opt),
                              ))
                          .toList(),
                      onChanged: (value) {
                        setStateDialog(() {
                          selectedNameOption = value;
                          if (selectedNameOption != 'Other') {
                            // Clear custom input when preset is chosen
                            nameController.clear();
                          }
                        });
                      },
                      decoration: const InputDecoration(
                        labelText: 'Workout name',
                        hintText: 'Select a preset or choose Other',
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (selectedNameOption == 'Other')
                      TextField(
                        controller: nameController,
                        decoration: const InputDecoration(labelText: 'Custom name'),
                        textInputAction: TextInputAction.next,
                      ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: notesController,
                      decoration: const InputDecoration(labelText: 'Notes'),
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
                    final bool usingOther = selectedNameOption == 'Other';
                    final String name = usingOther
                        ? nameController.text.trim()
                        : (selectedNameOption ?? '').trim();
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
                          _workoutsFuture = _db.getWorkouts();
                        });
                        _showSuccessSnackBar(
                          context: context,
                          title: 'Workout created',
                          subtitle: 'Your workout has been added successfully.',
                          icon: Icons.fitness_center,
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