import 'package:flutter/material.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import '../../firebase/firebase_api.dart';

class UserCreateSetPage extends StatefulWidget {
  final Map<String, dynamic> exerciseData;
  final String workoutId;
  final String exerciseId;
  
  const UserCreateSetPage({
    super.key,
    required this.exerciseData,
    required this.workoutId,
    required this.exerciseId,
  });

  @override
  State<UserCreateSetPage> createState() => _UserCreateSetPageState();
}

class _UserCreateSetPageState extends State<UserCreateSetPage> {
  bool _isLoading = true;
  final DataBaseService _db = DataBaseService();
  List<Map<String, dynamic>> _exerciseSets = [];
  bool _isLoadingSets = true;
  
  // Dialog form fields
  int _setNumber = 1;
  String _weightUnit = 'kg';
  double _weight = 0.0;
  int _reps = 0;
  String _note = '';

  @override
  void initState() {
    super.initState();
    _loadPageData();
    _loadExerciseSets();
  }

  Future<void> _loadPageData() async {
    // Simulate loading time - you can replace this with actual data loading
    await Future.delayed(const Duration(seconds: 0));
    
    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _loadExerciseSets() async {
    try {
      final sets = await _db.loadSetsForExercise(
        workoutId: widget.workoutId,
        exerciseId: widget.exerciseId,
      );
      setState(() {
        _exerciseSets = sets;
        _isLoadingSets = false;
      });
      print('Exercise Sets: $sets');
    } catch (e) {
      setState(() {
        _isLoadingSets = false;
      });
      print('Error loading exercise sets: $e');
    }
  }

  Future<void> _deleteSet(String setId) async {
    try {
      await _db.deleteSetForExercise(
        workoutId: widget.workoutId,
        exerciseId: widget.exerciseId,
        setId: setId,
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
                const Expanded(
                  child: Text(
                    'Set deleted successfully! ✨',
                    style: TextStyle(
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
      
      // Refresh the sets list
      _loadExerciseSets();
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
                    'Failed to delete set. Please try again.',
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

  void _showDeleteConfirmationDialog(String setId, int setNumber) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Set'),
          content: Text('Are you sure you want to delete Set #$setNumber? This action cannot be undone.'),
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
                _deleteSet(setId);
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

  void _showCreateSetDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Create Set'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Set Number
                    TextFormField(
                      initialValue: _setNumber.toString(),
                      decoration: const InputDecoration(
                        labelText: 'Set Number',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: (value) {
                        setDialogState(() {
                          _setNumber = int.tryParse(value) ?? 1;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    // Weight Unit Radio Buttons
                    Row(
                      children: [
                        const Text('Weight Unit:', style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(width: 16),
                        Radio<String>(
                          value: 'kg',
                          groupValue: _weightUnit,
                          onChanged: (value) {
                            setDialogState(() {
                              _weightUnit = value!;
                            });
                          },
                        ),
                        const Text('kg'),
                        const SizedBox(width: 20),
                        Radio<String>(
                          value: 'lbs',
                          groupValue: _weightUnit,
                          onChanged: (value) {
                            setDialogState(() {
                              _weightUnit = value!;
                            });
                          },
                        ),
                        const Text('lbs'),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    // Weight
                    TextFormField(
                      initialValue: _weight.toString(),
                      decoration: InputDecoration(
                        labelText: 'Weight ($_weightUnit)',
                        border: const OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: (value) {
                        setDialogState(() {
                          _weight = double.tryParse(value) ?? 0.0;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    // Reps
                    TextFormField(
                      initialValue: _reps.toString(),
                      decoration: const InputDecoration(
                        labelText: 'Number of Reps',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: (value) {
                        setDialogState(() {
                          _reps = int.tryParse(value) ?? 0;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    // Note
                    TextFormField(
                      initialValue: _note,
                      decoration: const InputDecoration(
                        labelText: 'Note (Optional)',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                      onChanged: (value) {
                        setDialogState(() {
                          _note = value;
                        });
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    try {
                      // Call the Firebase function to create the set
                      await _db.createUserSetExercise(
                        workoutId: widget.workoutId,
                        exerciseId: widget.exerciseId,
                        setNumber: _setNumber,
                        weightUnit: _weightUnit,
                        weight: _weight,
                        reps: _reps,
                        note: _note,
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
                    'Set created successfully! 🎉',
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
                      
                      // Refresh the sets list
                      _loadExerciseSets();
                      
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
                    'Failed to create set. Please try again.',
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
                  },
                  child: const Text('Create Set'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildInfoChip({
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Create Set - ${widget.exerciseData['exercise'] ?? 'Exercise'}'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.of(context).pop();
          },
          tooltip: 'Return',
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showCreateSetDialog,
            tooltip: 'Create Set',
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
                // Exercise info header
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  margin: const EdgeInsets.all(16),
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.fitness_center,
                            color: Theme.of(context).colorScheme.primary,
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              widget.exerciseData['exercise'] ?? 'Unknown Exercise',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _buildInfoChip(
                              icon: Icons.category,
                              label: 'Group',
                              value: widget.exerciseData['group'] ?? 'Unknown',
                              color: Colors.blue,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildInfoChip(
                              icon: Icons.accessibility,
                              label: 'Muscle',
                              value: widget.exerciseData['muscle'] ?? 'Unknown',
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                // Sets section
                Expanded(
                  child: _isLoadingSets
                      ? const Center(
                          child: CircularProgressIndicator(),
                        )
                      : _exerciseSets.isEmpty
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
                                      'No Sets Added Yet',
                                      style: TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold,
                                        color: Theme.of(context).colorScheme.onSurface,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      'Start tracking your progress!\nTap the + button to add your first set.',
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                                        height: 1.5,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              itemCount: _exerciseSets.length,
                              itemBuilder: (context, index) {
                                final set = _exerciseSets[index];
                                return Container(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12),
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
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Card(
                                    margin: EdgeInsets.zero,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.all(16),
                                      child: Row(
                                        children: [
                                          // Set number badge
                                          Container(
                                            width: 40,
                                            height: 40,
                                            decoration: BoxDecoration(
                                              color: Theme.of(context).colorScheme.primary,
                                              borderRadius: BorderRadius.circular(20),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                                                  blurRadius: 6,
                                                  offset: const Offset(0, 2),
                                                ),
                                              ],
                                            ),
                                            child: Center(
        child: Text(
                                                '${set['setNumber'] ?? index + 1}',
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 16,
                                                ),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 16),
                                          
                                          // Set details
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  children: [
                                                    Icon(
                                                      Icons.fitness_center,
                                                      size: 16,
                                                      color: Colors.grey[600],
                                                    ),
                                                    const SizedBox(width: 4),
                                                    Text(
                                                      '${set['weight'] ?? 0} ${set['weightUnit'] ?? 'kg'}',
                                                      style: const TextStyle(
                                                        fontSize: 16,
                                                        fontWeight: FontWeight.bold,
                                                      ),
                                                    ),
                                                    const SizedBox(width: 16),
                                                    Icon(
                                                      Icons.repeat,
                                                      size: 16,
                                                      color: Colors.grey[600],
                                                    ),
                                                    const SizedBox(width: 4),
                                                    Text(
                                                      '${set['reps'] ?? 0} reps',
                                                      style: const TextStyle(
                                                        fontSize: 16,
                                                        fontWeight: FontWeight.bold,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                if (set['note'] != null && set['note'].toString().isNotEmpty) ...[
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    set['note'],
                                                    style: TextStyle(
                                                      fontSize: 14,
                                                      color: Colors.grey[600],
                                                      fontStyle: FontStyle.italic,
                                                    ),
                                                    maxLines: 2,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ],
                                              ],
                                            ),
                                          ),
                                          
                                          // Delete button
                                          IconButton(
                                            onPressed: () {
                                              _showDeleteConfirmationDialog(
                                                set['id'],
                                                set['setNumber'] ?? index + 1,
                                              );
                                            },
                                            icon: const Icon(
                                              Icons.delete,
                                              color: Colors.red,
                                              size: 24,
                                            ),
                                            tooltip: 'Delete Set',
                                            style: IconButton.styleFrom(
                                              backgroundColor: Colors.red.withOpacity(0.1),
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              padding: const EdgeInsets.all(8),
                                            ),
                                          ),
                                        ],
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
