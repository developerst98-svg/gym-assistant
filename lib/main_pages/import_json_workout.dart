import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:cloud_firestore/cloud_firestore.dart';

/// Function to clean invalid Firestore characters from IDs
String cleanId(String input) {
  return input
      .replaceAll("/", "-")   // replace slashes
      .replaceAll(".", "-")
      .replaceAll("#", "-")
      .replaceAll("\$", "-")
      .replaceAll("[", "-")
      .replaceAll("]", "-")
      .trim();                // remove leading/trailing spaces
}

Future<void> importWorkouts() async {
  // Load JSON file from assets
  final String response = await rootBundle.loadString('assets/workouts.json');
  final Map<String, dynamic> data = json.decode(response);

  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  for (var splitName in data.keys) {
    String safeSplitId = cleanId(splitName);

    final splitRef = firestore.collection("workouts").doc(safeSplitId);
    await splitRef.set({"name": splitName}); // store original name inside

    print("📂 Added Workout Split: workouts/$safeSplitId");

    final muscles = data[splitName]["Target Muscles"] as Map<String, dynamic>;

    for (var muscleName in muscles.keys) {
      String safeMuscleId = cleanId(muscleName);

      final muscleRef = splitRef.collection("muscles").doc(safeMuscleId);
      await muscleRef.set({"name": muscleName});

      print("   📂 Added Muscle: workouts/$safeSplitId/muscles/$safeMuscleId");

      final exercises = muscles[muscleName] as List<dynamic>;

      for (var exerciseName in exercises) {
        String safeExerciseId = cleanId(exerciseName);

        final exerciseRef = muscleRef.collection("exercises").doc(safeExerciseId);
        await exerciseRef.set({"name": exerciseName});

        print("      ✅ Added Exercise: workouts/$safeSplitId/muscles/$safeMuscleId/exercises/$safeExerciseId");
      }
    }
  }

  print("🎉 Workouts imported successfully!");
}
