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
