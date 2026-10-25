import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:test_nest/feature/domain/student/data/models/student_data_model.dart';

class StudentLoginFeature {
  static final firestore = FirebaseFirestore.instance;
  static final auth = FirebaseAuth.instance;

  /// Signs in a student using Firebase Authentication (email & password).
  /// Resolves the student's status:
  /// - 'approved': active student relationship found -> returns 200, state: 'approved'.
  /// - 'pending': request pending approval -> returns 200, state: 'pending'.
  /// - 'needs_join': no teacher relationship -> returns 200, state: 'needs_join'.
  static Future<Map<String, dynamic>> studentEmailLogin(
    String email,
    String password,
  ) async {
    try {
      final trimmedEmail = email.trim().toLowerCase();
      final trimmedPassword = password.trim();

      if (trimmedEmail.isEmpty || trimmedPassword.isEmpty) {
        return {
          'status': 404,
          'message': 'Please enter both email and password.',
        };
      }

      final credential = await auth.signInWithEmailAndPassword(
        email: trimmedEmail,
        password: trimmedPassword,
      );
      final uid = credential.user!.uid;

      return await resolveStudentState(uid);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'wrong-password' ||
          e.code == 'user-not-found' ||
          e.code == 'invalid-credential' ||
          e.code == 'invalid-email') {
        return {'status': 404, 'message': 'Invalid email or password.'};
      }
      return {
        'status': 400,
        'message': e.message ?? 'Authentication error occurred.',
      };
    } catch (e) {
      return {'status': 500, 'message': 'Login failed: $e'};
    }
  }

  /// Determines the onboarding/access state of an authenticated student.
  static Future<Map<String, dynamic>> resolveStudentState(String uid) async {
    try {
      // 1. Check if user document exists in users collection
      final userDoc = await firestore.collection('users').doc(uid).get();
      final userName =
          userDoc.data()?['name'] ?? auth.currentUser?.displayName ?? 'Student';

      // 2. Check if student has an approved teacher relationship in user/{teacherId}/students
      final teachers = await firestore.collection('user').get();
      for (final tDoc in teachers.docs) {
        final stdQuery = await tDoc.reference
            .collection('students')
            .where('auth_uid', isEqualTo: uid)
            .limit(1)
            .get();
        if (stdQuery.docs.isNotEmpty) {
          final sData = stdQuery.docs.first.data();
          studentData = StudentData(
            id: sData['id']?.toString() ?? stdQuery.docs.first.id,
            name: sData['name']?.toString() ?? userName,
            teacherId: tDoc.id,
            batch: sData['batch']?.toString() ?? '',
            teacherName: tDoc.data()['name']?.toString() ?? '',
          );
          await StudentData.updateStudentLocalData();
          return {
            'status': 200,
            'state': 'approved',
            'studentData': studentData,
          };
        }
      }

      // 3. Check for any pending join requests
      final reqSnap = await firestore
          .collection('joinRequests')
          .where('student_uid', isEqualTo: uid)
          .where('status', isEqualTo: 'pending')
          .limit(1)
          .get();

      if (reqSnap.docs.isNotEmpty) {
        final reqData = reqSnap.docs.first.data();
        return {
          'status': 200,
          'state': 'pending',
          'batchName': reqData['batch_name'] ?? 'Batch',
          'teacherName': reqData['teacher_name'] ?? 'Teacher',
        };
      }

      // 4. No relationship and no pending request -> needs to enter joining code
      return {
        'status': 200,
        'state': 'needs_join',
      };
    } catch (e) {
      log('Error resolving student state: $e');
      return {
        'status': 200,
        'state': 'needs_join',
      };
    }
  }

  static Future<String?> resolveTeacherDocumentId(String input) async {
    final value = input.trim();
    if (value.isEmpty) return null;
    final direct = await firestore.collection('user').doc(value).get();
    if (direct.exists) return direct.id;
    final users = await firestore.collection('user').get();
    for (final doc in users.docs) {
      final d = doc.data();
      final candidates = [
        doc.id,
        d['id'],
        d['teacher_id'],
        d['email'],
      ].map((e) => e?.toString().trim().toLowerCase()).toList();
      if (candidates.contains(value.toLowerCase())) return doc.id;
    }
    return null;
  }

  /// Logs in a student using Teacher ID + Student ID only.
  /// No password is required. The student's existence in the teacher's
  /// collection is sufficient proof of identity.
  static Future<int> studentlogin(
    String teacherIdInput,
    String studentIdInput,
  ) async {
    try {
      final trimmedTeacherId = teacherIdInput.trim();
      final trimmedStudentId = studentIdInput.trim();

      if (trimmedTeacherId.isEmpty || trimmedStudentId.isEmpty) {
        return 404;
      }

      String? resolvedTeacherDocId;
      String teacherDocName = '';

      // 1. Check if trimmedTeacherId is directly a document ID in collection('user')
      final directDoc = await firestore
          .collection("user")
          .doc(trimmedTeacherId)
          .get();
      if (directDoc.exists && directDoc.data() != null) {
        resolvedTeacherDocId = directDoc.id;
        teacherDocName = (directDoc.data()!["name"] ?? "").toString().trim();
      } else {
        // 2. Search collection('user') by teacher_id, id, email or doc.id
        final usersSnapshot = await firestore.collection("user").get();
        for (final doc in usersSnapshot.docs) {
          final data = doc.data();
          final tid = (data["teacher_id"] ?? "").toString().trim();
          final id = (data["id"] ?? "").toString().trim();
          final email = (data["email"] ?? "").toString().trim();
          if (doc.id.toLowerCase() == trimmedTeacherId.toLowerCase() ||
              tid.toLowerCase() == trimmedTeacherId.toLowerCase() ||
              id.toLowerCase() == trimmedTeacherId.toLowerCase() ||
              email.toLowerCase() == trimmedTeacherId.toLowerCase()) {
            resolvedTeacherDocId = doc.id;
            teacherDocName = (data["name"] ?? "").toString().trim();
            break;
          }
        }
      }

      if (resolvedTeacherDocId == null) {
        log("Teacher not found: $trimmedTeacherId");
        return 404;
      }

      // 3. Query user/{teacherDocumentId}/students — no password check
      final studentsSnapshot = await firestore
          .collection("user")
          .doc(resolvedTeacherDocId)
          .collection("students")
          .get();

      for (final doc in studentsSnapshot.docs) {
        final data = doc.data();
        final sid = (data["id"] ?? data["student_id"] ?? doc.id)
            .toString()
            .trim();

        if (sid.toLowerCase() == trimmedStudentId.toLowerCase()) {
          studentData = StudentData.fromJson(data, docId: doc.id);
          studentData!.teacherId = resolvedTeacherDocId;
          if (studentData!.teacherName.isEmpty && teacherDocName.isNotEmpty) {
            studentData!.teacherName = teacherDocName;
          }
          await StudentData.updateStudentLocalData();
          return 200;
        }
      }
    } catch (e) {
      log("Student login error: $e", name: "login error");
      return 400;
    }

    return 404;
  }
}
