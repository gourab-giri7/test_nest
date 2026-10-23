import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:test_nest/feature/domain/student/data/models/student_data_model.dart';
import 'package:test_nest/feature/domain/teacher/data/models/teacher_data_model.dart';

class ExamFirestoreService {
  static final FirebaseFirestore db = FirebaseFirestore.instance;

  static String? get teacherDocId => teacherData?.id.trim();
  static String? get studentTeacherDocId => studentData?.teacherId.trim();

  static CollectionReference<Map<String, dynamic>> exams(String teacherId) =>
      db.collection('user').doc(teacherId.trim()).collection('exams');

  static DocumentReference<Map<String, dynamic>> exam(
    String teacherId,
    String examId,
  ) => exams(teacherId).doc(examId);

  static CollectionReference<Map<String, dynamic>> submissions(
    String teacherId,
    String examId,
  ) => exam(teacherId, examId).collection('submissions');

  static DocumentReference<Map<String, dynamic>> submission(
    String teacherId,
    String examId,
    String studentId,
  ) => submissions(teacherId, examId).doc(studentId.trim());

  static CollectionReference<Map<String, dynamic>> students(String teacherId) =>
      db.collection('user').doc(teacherId.trim()).collection('students');
}
