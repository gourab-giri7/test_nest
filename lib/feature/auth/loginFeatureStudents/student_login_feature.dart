import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:test_nest/feature/domain/student/data/models/student_data_model.dart';

/// Student login does NOT require a password.
/// Students authenticate by providing a valid Teacher ID + Student ID combination.
/// The teacher ID + student ID pair is verified against Firestore.
///
/// SECURITY NOTE: Without Firebase Auth for students, Firestore security rules
/// cannot properly restrict student read/write access by identity.
/// The proper fix is to implement Firebase Auth for students as well.
/// This is documented as a known limitation — teacher-side security rules
/// protect teacher data, but student submissions rely on server-side validation
/// or backend enforcement for full security.
class StudentLoginFeature {
  static final firestore = FirebaseFirestore.instance;

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
        teacherDocName =
            (directDoc.data()!["name"] ?? "").toString().trim();
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
        final sid =
            (data["id"] ?? data["student_id"] ?? doc.id).toString().trim();

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
