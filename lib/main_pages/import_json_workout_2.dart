import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:cloud_firestore/cloud_firestore.dart';

/// Clean Firestore document IDs
String cleanId(String input) {
  return input
      .replaceAll("/", "-")
      .replaceAll(".", "-")
      .replaceAll("#", "-")
      .replaceAll("\$", "-")
      .replaceAll("[", "-")
      .replaceAll("]", "-")
      .trim();
}

Future<void> importGymExercises() async {
  // Load JSON from assets
  final String response = await rootBundle.loadString('assets/workout2.json');
  final Map<String, dynamic> data = json.decode(response);

  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  // Loop through main muscle groups (e.g., Chest, Back, Shoulders, etc.)
  for (var groupName in data.keys) {
    String safeGroupId = cleanId(groupName);

    final groupRef = firestore.collection("gym_exercises").doc(safeGroupId);
    await groupRef.set({"name": groupName});

    print("📂 Added Muscle Group: gym_exercises/$safeGroupId");

    final muscles = data[groupName] as Map<String, dynamic>;

    // Loop through sub-muscles (e.g., Upper Chest, Lats, etc.)
    for (var muscleName in muscles.keys) {
      String safeMuscleId = cleanId(muscleName);

      final muscleRef = groupRef.collection("muscles").doc(safeMuscleId);
      await muscleRef.set({"name": muscleName});

      print("   📂 Added Muscle: gym_exercises/$safeGroupId/muscles/$safeMuscleId");

      final exercises = muscles[muscleName] as List<dynamic>;

      // Loop through exercises under that muscle
      for (var exerciseName in exercises) {
        String safeExerciseId = cleanId(exerciseName);

        final exerciseRef = muscleRef.collection("exercises").doc(safeExerciseId);
        await exerciseRef.set({"name": exerciseName});

        print("      ✅ Added Exercise: gym_exercises/$safeGroupId/muscles/$safeMuscleId/exercises/$safeExerciseId");
      }
    }
  }

  print("🎉 Gym exercises imported successfully!");
}
