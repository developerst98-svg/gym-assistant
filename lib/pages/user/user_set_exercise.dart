import 'package:flutter/material.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../firebase/firebase_api.dart';
import 'user_create_set.dart';
// Removed to avoid circular import

class UserSetExercisePage extends StatefulWidget {
  final String workoutId;
  const UserSetExercisePage({super.key, required this.workoutId});

  @override
  State<UserSetExercisePage> createState() => _UserSetExercisePageState();
}

class _UserSetExercisePageState extends State<UserSetExercisePage> {
  final DataBaseService _db = DataBaseService();
  List<String> _exerciseGroupIds = [];
  String? _selectedExerciseGroupId;
  List<String> _muscleIds = [];
  String? _selectedMuscleId;
  List<String> _exerciseIds = [];
  String? _selectedExerciseId;
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  bool _isLoading = true;
  List<Map<String, dynamic>> _workoutExercises = [];
  bool _isLoadingExercises = true;
  Set<String> _expandedCards = {}; // Track which cards are expanded

  @override
  void initState() {
    super.initState();
    _loadExerciseGroupIds();
    _loadWorkoutExercises();
    print('workoutId: ${widget.workoutId}');
  }

  void _checkLoadingComplete() {
    if (!_isLoadingExercises) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadExerciseGroupIds() async {
    try {
      final ids = await _db.loadGymExerciseGroupIds();
      setState(() {
        _exerciseGroupIds = ids;
      });
      print('Exercise Group IDs: $ids');
    } catch (e) {
      print('Error loading exercise group IDs: $e');
    } finally {
      _checkLoadingComplete();
    }
  }

  Future<void> _loadWorkoutExercises() async {
    try {
      final exercises = await _db.loadExercisesForWorkout(widget.workoutId);
      setState(() {
        _workoutExercises = exercises;
        _isLoadingExercises = false;
      });
      print('Workout Exercises: $exercises');
    } catch (e) {
      setState(() {
        _isLoadingExercises = false;
      });
      print('Error loading workout exercises: $e');
    } finally {
      _checkLoadingComplete();
    }
  }

  Future<void> _deleteExercise(String exerciseId, String exerciseName) async {
    try {
      await _db.deleteExerciseForWorkout(
        workoutId: widget.workoutId,
        exerciseId: exerciseId,
      );
      
      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(
                    Icons.delete_sweep,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Exercise "$exerciseName" deleted successfully! ✨',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.orange,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.all(16),
            duration: const Duration(seconds: 3),
            elevation: 8,
          ),
        );
      }
      
      // Refresh the exercise list
      _loadWorkoutExercises();
    } catch (e) {
      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(
                    Icons.error_outline,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Failed to delete exercise. Please try again.',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.all(16),
            duration: const Duration(seconds: 4),
            elevation: 8,
          ),
        );
      }
    }
  }

  void _showDeleteExerciseConfirmationDialog(String exerciseId, String exerciseName) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Exercise'),
          content: Text('Are you sure you want to delete "$exerciseName"? This will also delete all sets for this exercise. This action cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _deleteExercise(exerciseId, exerciseName);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  void _toggleCardExpansion(String exerciseId) {
    setState(() {
      if (_expandedCards.contains(exerciseId)) {
        _expandedCards.remove(exerciseId);
      } else {
        _expandedCards.add(exerciseId);
      }
    });
  }


  void _showCreateExerciseDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Create Exercise'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    value: _selectedExerciseGroupId,
                    decoration: const InputDecoration(
                      labelText: 'Exercise Group',
                      border: OutlineInputBorder(),
                    ),
                    items: _exerciseGroupIds.map((String id) {
                      return DropdownMenuItem<String>(
                        value: id,
                        child: Text(id),
                      );
                    }).toList(),
                    onChanged: (String? newValue) async {
                      setDialogState(() {
                        _selectedExerciseGroupId = newValue;
                        _muscleIds = []; // Clear muscle list while loading
                        _selectedMuscleId = null;
                        _exerciseIds = []; // Clear exercise list
                        _selectedExerciseId = null;
                      });
                      
                      if (newValue != null) {
                        // Load muscle IDs for the selected group
                        final muscleIds = await _db.getMuscleDocIdsForGroup(newValue);
                        setDialogState(() {
                          _muscleIds = muscleIds;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: _selectedMuscleId,
                    decoration: const InputDecoration(
                      labelText: 'Muscle',
                      border: OutlineInputBorder(),
                    ),
                    items: _muscleIds.map((String id) {
                      return DropdownMenuItem<String>(
                        value: id,
                        child: Text(id),
                      );
                    }).toList(),
                    onChanged: _muscleIds.isNotEmpty
                        ? (String? newValue) async {
                            setDialogState(() {
                              _selectedMuscleId = newValue;
                              _exerciseIds = []; // Clear exercise list while loading
                              _selectedExerciseId = null;
                            });
                            
                            if (newValue != null && _selectedExerciseGroupId != null) {
                              // Load exercise IDs for the selected muscle and group
                              final exerciseIds = await _db.getExercisesForMuscle(_selectedExerciseGroupId!, newValue);
                              setDialogState(() {
                                _exerciseIds = exerciseIds;
                              });
                            }
                          }
                        : null,
                    hint: _muscleIds.isEmpty && _selectedExerciseGroupId != null
                        ? const Text('Loading muscles...')
                        : _muscleIds.isEmpty
                            ? const Text('Select exercise group first')
                            : const Text('Select muscle'),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: _selectedExerciseId,
                    decoration: const InputDecoration(
                      labelText: 'Exercise',
                      border: OutlineInputBorder(),
                    ),
                    items: _exerciseIds.map((String id) {
                      return DropdownMenuItem<String>(
                        value: id,
                        child: Text(id),
                      );
                    }).toList(),
                    onChanged: _exerciseIds.isNotEmpty
                        ? (String? newValue) {
                            setDialogState(() {
                              _selectedExerciseId = newValue;
                            });
                          }
                        : null,
                    hint: _exerciseIds.isEmpty && _selectedMuscleId != null
                        ? const Text('Loading exercises...')
                        : _exerciseIds.isEmpty
                            ? const Text('Select muscle first')
                            : const Text('Select exercise'),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () async {
                            final DateTime? picked = await showDatePicker(
                              context: context,
                              initialDate: _selectedDate,
                              firstDate: DateTime(2000),
                              lastDate: DateTime(2100),
                            );
                            if (picked != null && picked != _selectedDate) {
                              setDialogState(() {
                                _selectedDate = picked;
                              });
                            }
                          },
                          child: InputDecorator(
                            decoration: const InputDecoration(
                              labelText: 'Date',
                              border: OutlineInputBorder(),
                              suffixIcon: Icon(Icons.calendar_today),
                            ),
                            child: Text(
                              '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: InkWell(
                          onTap: () async {
                            final TimeOfDay? picked = await showTimePicker(
                              context: context,
                              initialTime: _selectedTime,
                            );
                            if (picked != null && picked != _selectedTime) {
                              setDialogState(() {
                                _selectedTime = picked;
                              });
                            }
                          },
                          child: InputDecorator(
                            decoration: const InputDecoration(
                              labelText: 'Time',
                              border: OutlineInputBorder(),
                              suffixIcon: Icon(Icons.access_time),
                            ),
                            child: Text(
                              _selectedTime.format(context),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: _selectedExerciseGroupId != null && _selectedMuscleId != null && _selectedExerciseId != null
                      ? () async {
                          try {
                            // Convert TimeOfDay to String format
                            final timeString = '${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}';
                            
                            // Call the Firebase function to create the exercise
                            await _db.createUserWorkoutExercise(
                              workoutId: widget.workoutId,
                              group: _selectedExerciseGroupId!,
                              muscle: _selectedMuscleId!,
                              exercise: _selectedExerciseId!,
                              date: _selectedDate,
                              time: timeString,
                            );
                            
                            // Show success message
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.2),
                                          borderRadius: BorderRadius.circular(20),
                                        ),
                                        child: const Icon(
                                          Icons.check_circle,
                                          color: Colors.white,
                                          size: 20,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      const Expanded(
                                        child: Text(
                                          'Exercise created successfully! 🎉',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  backgroundColor: Colors.green,
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  margin: const EdgeInsets.all(16),
                                  duration: const Duration(seconds: 3),
                                  elevation: 8,
                                ),
                              );
                            }
                            
                            // Refresh the exercise list
                            _loadWorkoutExercises();
                            
                            Navigator.of(context).pop();
                          } catch (e) {
                            // Show error message
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.2),
                                          borderRadius: BorderRadius.circular(20),
                                        ),
                                        child: const Icon(
                                          Icons.error_outline,
                                          color: Colors.white,
                                          size: 20,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      const Expanded(
                                        child: Text(
                                          'Failed to create exercise. Please try again.',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  backgroundColor: Colors.red,
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  margin: const EdgeInsets.all(16),
                                  duration: const Duration(seconds: 4),
                                  elevation: 8,
                                ),
                              );
                            }
                          }
                        }
                      : null,
                  child: const Text('Create'),
                ),
              ],
            );
          },
        );
      },
    );
  }


  Widget _buildEnhancedInfoChip({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(
                  icon,
                  size: 14,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: color.withOpacity(0.8),
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color.withOpacity(0.9),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  String _formatDate(dynamic date) {
    if (date == null) return 'Unknown';
    
    try {
      if (date is Timestamp) {
        final dateTime = date.toDate();
        return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
      } else if (date is DateTime) {
        return '${date.day}/${date.month}/${date.year}';
      }
      return date.toString();
    } catch (e) {
      return 'Unknown';
    }
  }

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
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showCreateExerciseDialog,
            tooltip: 'Create Exercise',
          ),
        ],
      ),
      body: _isLoading
          ? Center(
              child: LoadingAnimationWidget.dotsTriangle(
                color: Theme.of(context).colorScheme.secondary,
                size: 64,
              ),
            )
          : Column(
              children: [
                // Exercise cards section
                Expanded(
                  child: _isLoadingExercises
                      ? const Center(
                          child: CircularProgressIndicator(),
                        )
                      : _workoutExercises.isEmpty
                          ? Center(
                              child: Container(
                                padding: const EdgeInsets.all(32),
                                margin: const EdgeInsets.all(24),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(20),
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      Theme.of(context).colorScheme.primary.withOpacity(0.1),
                                      Theme.of(context).colorScheme.secondary.withOpacity(0.1),
                                    ],
                                  ),
                                  border: Border.all(
                                    color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                                    width: 1,
                                  ),
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(20),
                                      decoration: BoxDecoration(
                                        color: Theme.of(context).colorScheme.primary,
                                        borderRadius: BorderRadius.circular(20),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                                            blurRadius: 15,
                                            offset: const Offset(0, 5),
                                          ),
                                        ],
                                      ),
                                      child: Icon(
                                        Icons.fitness_center,
                                        size: 48,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(height: 24),
                                    Text(
                                      'Ready to Start Your Workout?',
                                      style: TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold,
                                        color: Theme.of(context).colorScheme.onSurface,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      'No exercises added yet.\nTap the + button to add your first exercise and begin tracking your fitness journey!',
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                                        height: 1.5,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                    const SizedBox(height: 24),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                      decoration: BoxDecoration(
                                        color: Theme.of(context).colorScheme.secondary.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.add_circle_outline,
                                            color: Theme.of(context).colorScheme.secondary,
                                            size: 20,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            'Add Exercise',
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                              color: Theme.of(context).colorScheme.secondary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: _workoutExercises.length,
                              itemBuilder: (context, index) {
                                final exercise = _workoutExercises[index];
                                return GestureDetector(
                                  onTap: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (context) => UserCreateSetPage(
                                          exerciseData: exercise,
                                          workoutId: widget.workoutId,
                                          exerciseId: exercise['id'],
                                        ),
                                      ),
                                    );
                                  },
                                  child: Container(
                                    margin: const EdgeInsets.only(bottom: 16),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(16),
                                      gradient: LinearGradient(
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                        colors: [
                                          Theme.of(context).colorScheme.primary.withOpacity(0.1),
                                          Theme.of(context).colorScheme.secondary.withOpacity(0.1),
                                        ],
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.1),
                                          blurRadius: 10,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: Card(
                                    margin: EdgeInsets.zero,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.all(16),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          // Header with exercise name and icon
                                          Row(
                                            children: [
                                              Container(
                                                padding: const EdgeInsets.all(10),
                                                decoration: BoxDecoration(
                                                  color: Theme.of(context).colorScheme.primary,
                                                  borderRadius: BorderRadius.circular(10),
                                                  boxShadow: [
                                                    BoxShadow(
                                                      color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                                                      blurRadius: 6,
                                                      offset: const Offset(0, 2),
                                                    ),
                                                  ],
                                                ),
                                                child: Icon(
                                                  Icons.fitness_center,
                                                  color: Colors.white,
                                                  size: 20,
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      exercise['exercise'] ?? 'Unknown Exercise',
                                                      style: TextStyle(
                                                        fontSize: 18,
                                                        fontWeight: FontWeight.bold,
                                                        color: Theme.of(context).colorScheme.onSurface,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 2),
                                                    Container(
                                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                      decoration: BoxDecoration(
                                                        color: Theme.of(context).colorScheme.secondary.withOpacity(0.2),
                                                        borderRadius: BorderRadius.circular(10),
                                                      ),
                                                      child: Text(
                                                        'Exercise #${index + 1}',
                                                        style: TextStyle(
                                                          fontSize: 11,
                                                          fontWeight: FontWeight.w500,
                                                          color: Theme.of(context).colorScheme.secondary,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              
                                              // Delete button
                                              IconButton(
                                                onPressed: () {
                                                  _showDeleteExerciseConfirmationDialog(
                                                    exercise['id'],
                                                    exercise['exercise'] ?? 'Unknown Exercise',
                                                  );
                                                },
                                                icon: const Icon(
                                                  Icons.delete,
                                                  color: Colors.red,
                                                  size: 24,
                                                ),
                                                tooltip: 'Delete Exercise',
                                                style: IconButton.styleFrom(
                                                  backgroundColor: Colors.red.withOpacity(0.1),
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius: BorderRadius.circular(8),
                                                  ),
                                                  padding: const EdgeInsets.all(8),
                                                ),
                                              ),
                                              
                                              // Fold/Unfold button
                                              IconButton(
                                                onPressed: () {
                                                  _toggleCardExpansion(exercise['id']);
                                                },
                                                icon: Icon(
                                                  _expandedCards.contains(exercise['id'])
                                                      ? Icons.expand_less
                                                      : Icons.expand_more,
                                                  color: Colors.grey[600],
                                                  size: 24,
                                                ),
                                                tooltip: _expandedCards.contains(exercise['id'])
                                                    ? 'Collapse Details'
                                                    : 'Expand Details',
                                                style: IconButton.styleFrom(
                                                  backgroundColor: Colors.grey.withOpacity(0.1),
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius: BorderRadius.circular(8),
                                                  ),
                                                  padding: const EdgeInsets.all(8),
                                                ),
                                              ),
                                            ],
                                          ),
                                          // Exercise details (only show when expanded)
                                          if (_expandedCards.contains(exercise['id'])) ...[
                                            const SizedBox(height: 12),
                                            
                                            // Exercise details in a grid
                                            Row(
                                              children: [
                                                Expanded(
                                                  child: _buildEnhancedInfoChip(
                                                    icon: Icons.category,
                                                    label: 'Group',
                                                    value: exercise['group'] ?? 'Unknown',
                                                    color: Colors.blue,
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                Expanded(
                                                  child: _buildEnhancedInfoChip(
                                                    icon: Icons.accessibility,
                                                    label: 'Muscle',
                                                    value: exercise['muscle'] ?? 'Unknown',
                                                    color: Colors.green,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 8),
                                            Row(
                                              children: [
                                                Expanded(
                                                  child: _buildEnhancedInfoChip(
                                                    icon: Icons.calendar_today,
                                                    label: 'Date',
                                                    value: _formatDate(exercise['date']),
                                                    color: Colors.orange,
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                Expanded(
                                                  child: _buildEnhancedInfoChip(
                                                    icon: Icons.access_time,
                                                    label: 'Time',
                                                    value: exercise['time'] ?? 'Unknown',
                                                    color: Colors.purple,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            
                                            // Divider with decorative element
                                            const SizedBox(height: 16),
                                            Row(
                                              children: [
                                                Expanded(
                                                  child: Divider(
                                                    color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
                                                    thickness: 1,
                                                  ),
                                                ),
                                                Padding(
                                                  padding: const EdgeInsets.symmetric(horizontal: 16),
                                                  child: Icon(
                                                    Icons.sports_gymnastics,
                                                    color: Theme.of(context).colorScheme.primary.withOpacity(0.6),
                                                    size: 20,
                                                  ),
                                                ),
                                                Expanded(
                                                  child: Divider(
                                                    color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
                                                    thickness: 1,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                );
                              },
                            ),
                ),
              ],
            ),
    );
  }
}
