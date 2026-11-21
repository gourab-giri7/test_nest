import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:test_nest/core/services/batch_and_join_code_service.dart';
import 'package:test_nest/feature/auth/loginFeatureStudents/student_login_feature.dart';
import 'package:test_nest/model/join_request_model.dart';

class JoinTeacherController extends ChangeNotifier {
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  void setLoading(bool val) {
    if (_isLoading != val) {
      _isLoading = val;
      notifyListeners();
    }
  }

  Future<JoinRequestModel?> submitCode(String rawCode) async {
    final code = rawCode.trim();
    setLoading(true);
    try {
      final codeModel = await BatchAndJoinCodeService.validateJoiningCode(code);
      if (codeModel == null) {
        throw StateError(
          'Invalid, expired, or revoked joining code. Please check and try again.',
        );
      }

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw StateError('Please log in again to continue.');
      }

      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      final studentName =
          (userDoc.data()?['name'] ?? user.displayName ?? 'Student').toString();
      final studentEmail = user.email ?? '';
      final studentPhone = userDoc.data()?['phone']?.toString();

      final request = await BatchAndJoinCodeService.submitJoinRequest(
        studentUid: user.uid,
        studentName: studentName,
        studentEmail: studentEmail,
        studentPhone: studentPhone,
        codeModel: codeModel,
      );

      return request;
    } finally {
      setLoading(false);
    }
  }
}

class RequestSentController extends ChangeNotifier {
  bool _isChecking = false;
  bool get isChecking => _isChecking;

  void setChecking(bool val) {
    if (_isChecking != val) {
      _isChecking = val;
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>> checkApprovalStatus(String uid) async {
    setChecking(true);
    try {
      return await StudentLoginFeature.resolveStudentState(uid);
    } finally {
      setChecking(false);
    }
  }
}
