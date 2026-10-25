import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:test_nest/feature/domain/common/presentation/widget/custom_Snackbar.dart';
import 'package:get/get.dart';
import 'package:test_nest/routes/app_routes.dart';

class StudentSignupController extends ChangeNotifier {
  final formKey = GlobalKey<FormState>();
  final name = TextEditingController();
  final email = TextEditingController();
  final mobile = TextEditingController();
  final password = TextEditingController();
  final confirm = TextEditingController();

  bool loading = false;
  bool obscure = true;
  bool obscureConfirm = true;

  String? requiredField(String? v) =>
      v == null || v.trim().isEmpty ? 'This field is required' : null;

  String? emailValidator(String? v) {
    if (v == null || v.trim().isEmpty) return 'Email is required';
    if (!v.contains('@') || !v.contains('.')) return 'Enter a valid email';
    return null;
  }

  String? passwordValidator(String? v) {
    if (v == null || v.trim().isEmpty) return 'Password is required';
    if (v.length < 6) return 'Minimum 6 characters required';
    return null;
  }

  String? confirmPasswordValidator(String? v) {
    if (v != password.text) return 'Passwords do not match';
    return null;
  }

  void toggleObscure() {
    obscure = !obscure;
    notifyListeners();
  }

  void toggleObscureConfirm() {
    obscureConfirm = !obscureConfirm;
    notifyListeners();
  }

  Future<void> signup(BuildContext context) async {
    if (!formKey.currentState!.validate() || loading) return;
    loading = true;
    notifyListeners();

    try {
      final cleanEmail = email.text.trim().toLowerCase();
      final cleanName = name.text.trim();

      // Create Firebase Auth user
      UserCredential userCredential;
      try {
        userCredential = await FirebaseAuth.instance
            .createUserWithEmailAndPassword(
              email: cleanEmail,
              password: password.text,
            );
      } on FirebaseAuthException catch (authErr) {
        if (authErr.code == 'email-already-in-use') {
          // Attempt sign in if previously interrupted
          try {
            userCredential = await FirebaseAuth.instance
                .signInWithEmailAndPassword(
                  email: cleanEmail,
                  password: password.text,
                );
          } catch (_) {
            rethrow;
          }
        } else {
          rethrow;
        }
      }

      final uid = userCredential.user!.uid;

      // Create root user record in users/{uid}
      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'uid': uid,
        'name': cleanName,
        'email': cleanEmail,
        'phone': mobile.text.trim(),
        'role': 'student',
        'created_at': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (context.mounted) {
        customSnackbar(
          context: context,
          message: 'Account created! Now join your teacher.',
          color: Colors.green,
          ico: Icons.check_circle,
        );
        Get.offAllNamed(AppRoutes.studentJoinTeacher);
      }
    } on FirebaseAuthException catch (e) {
      if (!context.mounted) return;
      String message;
      if (e.code == 'email-already-in-use') {
        message = 'An account with this email already exists. Please log in.';
      } else if (e.code == 'weak-password') {
        message = 'Password must be at least 6 characters.';
      } else if (e.code == 'invalid-email') {
        message = 'The email address is invalid.';
      } else {
        message = 'Registration failed: ${e.message ?? e.code}';
      }
      customSnackbar(
        context: context,
        message: message,
        color: Colors.red,
        ico: Icons.error,
      );
    } catch (e) {
      if (context.mounted) {
        customSnackbar(
          context: context,
          message: 'Registration failed. Please try again.',
          color: Colors.red,
          ico: Icons.error,
        );
      }
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    name.dispose();
    email.dispose();
    mobile.dispose();
    password.dispose();
    confirm.dispose();
    super.dispose();
  }
}
