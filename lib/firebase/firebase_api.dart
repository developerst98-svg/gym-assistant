import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';

class DataBaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  static Future<void> initializeFirebase() async {
    WidgetsFlutterBinding.ensureInitialized();
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }

  /// Gets the role of the user from Firestore.
  /// Returns "user", "coach", or null if not found.
  Future<String?> getUserRole(String userId) async {
    try {
      final doc = await _firestore.collection('Users').doc(userId).get();
      if (doc.exists && doc.data() != null) {
        return doc.data()!['role'] as String?;
      }
      return null;
    } catch (e) {
      return null;
    }
  }


  //& Workout
  /// Creates a new workout document in the "workout" subcollection for the given user.
  /// The workout document contains: name, note, date.
  Future<void> createWorkout({
    required String name,
    required String? note,
    required DateTime date,
  }) async {
    try {
      final userId = _firebaseAuth.currentUser!.uid;
      await _firestore
          .collection('Users')
          .doc(userId)
          .collection('workout')
          .add({
        'name': name,
        'note': note ?? '',
        'date': date,
      });
    } catch (e) {
      // Optionally handle/log error
      rethrow;
    }
  }


  /// Gets all workouts for the given user.
  Future<List<Map<String, dynamic>>> getWorkouts() async {
    final userId = _firebaseAuth.currentUser!.uid;
    final workouts = await _firestore
        .collection('Users')
        .doc(userId)
        .collection('workout')
        .get();
    return workouts.docs
        .map((doc) => {
              ...doc.data(),
              'id': doc.id,
            })
        .toList();
  }


  // delete workout
  Future<void> deleteWorkout(String workoutId) async {
    final userId = _firebaseAuth.currentUser!.uid;
    await _firestore.collection('Users').doc(userId).collection('workout').doc(workoutId).delete();
  }

  // delete many workouts
  Future<void> deleteManyWorkouts(List<String> workoutIds) async {
    final String userId = _firebaseAuth.currentUser!.uid;
    final WriteBatch batch = _firestore.batch();
    for (final String workoutId in workoutIds) {
      final DocumentReference docRef = _firestore
          .collection('Users')
          .doc(userId)
          .collection('workout')
          .doc(workoutId);
      batch.delete(docRef);
    }
    await batch.commit();
  }



  //& Gym Exercises
  Future<Map<String, Map<String, List<String>>>> loadGymExercisesHierarchy() async {
    final Map<String, Map<String, List<String>>> result = {};

    final gymExercisesSnapshot = await _firestore.collection('gym_exercises').get();
    print('am here');
    for (final groupDoc in gymExercisesSnapshot.docs) {
      final String groupName = groupDoc.data()['name'] ?? groupDoc.id;
      final Map<String, List<String>> musclesMap = {};

      final musclesSnapshot = await _firestore
          .collection('gym_exercises')
          .doc(groupDoc.id)
          .collection('muscles')
          .get();

      for (final muscleDoc in musclesSnapshot.docs) {
        final String muscleName = muscleDoc.data()['name'] ?? muscleDoc.id;
        final List<String> exercisesList = [];

        final exercisesSnapshot = await _firestore
            .collection('gym_exercises')
            .doc(groupDoc.id)
            .collection('muscles')
            .doc(muscleDoc.id)
            .collection('exercises')
            .get();

        for (final exerciseDoc in exercisesSnapshot.docs) {
          final String exerciseName = exerciseDoc.data()['name'] ?? exerciseDoc.id;
          exercisesList.add(exerciseName);
        }

        musclesMap[muscleName] = exercisesList;
      }

      result[groupName] = musclesMap;
    }

    print('result: $result');

    return result;
  }


  /// Loads only the names and document IDs of gym_exercises.
  /// Returns a list of maps: [{'id': docId, 'name': name}, ...]
  Future<List<String>> loadGymExerciseGroupIds() async {
    final snapshot = await _firestore.collection('gym_exercises').get();
    return snapshot.docs.map((doc) => doc.id).toList();
  }


  /// Returns a list of document IDs for the "muscles" subcollection
  /// under the specified gym_exercises document ID.
  Future<List<String>> getMuscleDocIdsForGroup(String groupDocId) async {
    final musclesSnapshot = await _firestore
        .collection('gym_exercises')
        .doc(groupDocId)
        .collection('muscles')
        .get();
    return musclesSnapshot.docs.map((doc) => doc.id).toList();
  }


  /// Returns a list of exercise names for a given groupDocId and muscleGroupId.
  Future<List<String>> getExercisesForMuscle(String groupDocId, String muscleGroupId) async {
    final exercisesSnapshot = await _firestore
        .collection('gym_exercises')
        .doc(groupDocId)
        .collection('muscles')
        .doc(muscleGroupId)
        .collection('exercises')
        .get();

    return exercisesSnapshot.docs.map((doc) => doc.id).toList();
  }


  /// Creates a new exercise entry for the current user under the specified workout.
  /// 
  /// [workoutId] - The document ID of the workout (in user's workouts subcollection).
  /// [group] - The exercise group name or ID.
  /// [muscle] - The muscle name or ID.
  /// [exercise] - The exercise name or ID.
  /// [date] - The date of the exercise (DateTime).
  /// [time] - The time of the exercise (TimeOfDay or String).
  /// 
  /// Returns the created exercise document reference.
  Future<DocumentReference> createUserWorkoutExercise({
    required String workoutId,
    required String group,
    required String muscle,
    required String exercise,
    required DateTime date,
    required String time,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('No user logged in');
    }

    final exerciseData = {
      'group': group,
      'muscle': muscle,
      'exercise': exercise,
      'date': Timestamp.fromDate(date),
      'time': time,
      'createdAt': FieldValue.serverTimestamp(),
    };

    final docRef = await _firestore
        .collection('Users')
        .doc(user.uid)
        .collection('workout')
        .doc(workoutId)
        .collection('exercises')
        .add(exerciseData);

    return docRef;
  }


  /// Loads all exercises for a specific workout ID for the current user.
  /// Returns a list of exercise documents (as Map<String, dynamic>).
  Future<List<Map<String, dynamic>>> loadExercisesForWorkout(String workoutId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('No user logged in');
    }

    final exercisesSnapshot = await _firestore
        .collection('Users')
        .doc(user.uid)
        .collection('workout')
        .doc(workoutId)
        .collection('exercises')
        .orderBy('createdAt', descending: false)
        .get();

    return exercisesSnapshot.docs
        .map((doc) => {
              ...doc.data(),
              'id': doc.id,
            })
        .toList();
  }


  /// Creates a new set entry for the current user under the specified exercise.
  Future<DocumentReference> createUserSetExercise({
    required String workoutId,
    required String exerciseId,
    required int setNumber,
    required String weightUnit,
    required double weight,
    required int reps,
    required String note,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('No user logged in');
    }
  
    final setData = {
      'setNumber': setNumber,
      'weightUnit': weightUnit,
      'weight': weight,
      'reps': reps,
      'note': note,
    };
  
    final docRef = await _firestore
        .collection('Users')
        .doc(user.uid)
        .collection('workout')
        .doc(workoutId)
        .collection('exercises')
        .doc(exerciseId)
        .collection('sets')
        .add(setData);
  
    return docRef;
  }


  /// Loads all sets for a given exercise in a workout for the current user.
  Future<List<Map<String, dynamic>>> loadSetsForExercise({
    required String workoutId,
    required String exerciseId,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('No user logged in');
    }

    final setsSnapshot = await _firestore
        .collection('Users')
        .doc(user.uid)
        .collection('workout')
        .doc(workoutId)
        .collection('exercises')
        .doc(exerciseId)
        .collection('sets')
        .orderBy('setNumber', descending: false)
        .get();

    return setsSnapshot.docs
        .map((doc) => {
              ...doc.data(),
              'id': doc.id,
            })
        .toList();
  }
  

  /// Deletes a set for a given exercise in a workout for the current user.
  Future<void> deleteSetForExercise({
    required String workoutId,
    required String exerciseId,
    required String setId,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('No user logged in');
    }

    await _firestore
        .collection('Users')
        .doc(user.uid)
        .collection('workout')
        .doc(workoutId)
        .collection('exercises')
        .doc(exerciseId)
        .collection('sets')
        .doc(setId)
        .delete();
  }


  /// Deletes an exercise (and all its sets) for a given workout for the current user.
  Future<void> deleteExerciseForWorkout({
    required String workoutId,
    required String exerciseId,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('No user logged in');
    }

    final exerciseRef = _firestore
        .collection('Users')
        .doc(user.uid)
        .collection('workout')
        .doc(workoutId)
        .collection('exercises')
        .doc(exerciseId);

    // Delete all sets subcollection first
    final setsSnapshot = await exerciseRef.collection('sets').get();
    for (final doc in setsSnapshot.docs) {
      await doc.reference.delete();
    }

    // Delete the exercise document itself
    await exerciseRef.delete();
  }




}

class AuthenticationService {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Returns the current user or null if no user is signed in
  User? get user => _firebaseAuth.currentUser;

  /// Returns true if the current user's email is verified
  bool get isUserVerified => user?.emailVerified ?? false;

  /// Stream of auth state changes
  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

  /// Signs out the current user
  Future<void> signOut() async {
    try {
      await _firebaseAuth.signOut();
    } on FirebaseAuthException catch (e) {
      throw Exception(e.message ?? 'Failed to sign out');
    }
  }

  /// Signs in a user with email and password
  Future<void> loginUser({
    required String phoneNumber,
    required String password,
  }) async {
    try {
      String cleanPhoneNumber = phoneNumber.replaceAll(' ', '');
      // print('cleanPhoneNumber: $cleanPhoneNumber');
      // print('password: $password');
      await _firebaseAuth
          .signInWithEmailAndPassword(
            email: "${cleanPhoneNumber.trim()}@phone.com",
            password: password.trim(),
          );
    } on FirebaseAuthException catch (_) {
      throw Exception('Invalid password');
    }
  }

  /// Registers a new user with phone number and password
  Future<UserCredential> registerUser({
    required String phoneNumber,
    required String password,
    required String fullName,
    String? email,
  }) async {
    // Remove all spaces from phone number
    String cleanPhoneNumber = phoneNumber.replaceAll(RegExp(r'[^\d]'), '');
    print('cleanPhoneNumber: $cleanPhoneNumber');
    print('password: $password');
    print('fullName: $fullName');
    print('email: $email');
    // Create user with email (using phone number as email)
    final UserCredential userCredential = await _firebaseAuth
        .createUserWithEmailAndPassword(
          email: "${cleanPhoneNumber.trim()}@phone.com",
          password: password.trim(),
        );

    // Save additional user data to Firestore
    if (userCredential.user != null) {
      await _firestore.collection('Users').doc(userCredential.user!.uid).set({
        'phoneNumber': "${cleanPhoneNumber.trim()}@phone.com",
        'fullName': fullName,
        'email': email,
        'password': password.trim(),
        'isActive': true,
        'createdAt': FieldValue.serverTimestamp(),
        'lastLogin': FieldValue.serverTimestamp(),
      });
    }

    return userCredential;
  }
}
