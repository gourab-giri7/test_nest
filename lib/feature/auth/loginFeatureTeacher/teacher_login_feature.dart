import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:test_nest/feature/domain/teacher/data/models/teacher_data_model.dart';

class TeacherLoginFeature {
  static final firestore = FirebaseFirestore.instance;
  static final auth = FirebaseAuth.instance;

  /// Signs in a teacher using Firebase Authentication.
  /// Returns 200 on success, 404 on wrong credentials (user-not-found / wrong-password),
  /// 400 on any other error.
  static Future<int> teacherlogin(String email, String password) async {
    try {
      final trimmedEmail = email.trim();
      final trimmedPassword = password.trim();

      if (trimmedEmail.isEmpty || trimmedPassword.isEmpty) {
        return 404;
      }

      // Sign in via Firebase Auth
      final userCredential = await auth.signInWithEmailAndPassword(
        email: trimmedEmail,
        password: trimmedPassword,
      );

      final uid = userCredential.user!.uid;

      // Load teacher profile from Firestore using the Auth UID
      final directDoc = await firestore.collection('user').doc(uid).get();
      if (directDoc.exists && directDoc.data() != null) {
        teacherData = TeacherData.fromJson(directDoc.data()!, docId: uid);
        await TeacherData.updateTeacherLocalData();
        return 200;
      }

      // Backward-compat fallback: search by email field in old-format docs
      // (for accounts that existed before Firebase Auth migration)
      final usersSnapshot = await firestore.collection('user').get();
      for (final doc in usersSnapshot.docs) {
        final data = doc.data();
        final dataEmail = (data['email'] ?? '').toString().trim();
        if (dataEmail.toLowerCase() == trimmedEmail.toLowerCase()) {
          teacherData = TeacherData.fromJson(data, docId: doc.id);
          await TeacherData.updateTeacherLocalData();
          return 200;
        }
      }

      return 404;
    } on FirebaseAuthException catch (e) {
      log('Firebase Auth error: ${e.code} - ${e.message}',
          name: 'teacher_login');
      if (e.code == 'wrong-password' ||
          e.code == 'user-not-found' ||
          e.code == 'invalid-credential' ||
          e.code == 'invalid-email') {
        return 404;
      }
      return 400;
    } catch (e) {
      log('Login error: $e', name: 'teacher_login_error');
      return 400;
    }
  }
}
