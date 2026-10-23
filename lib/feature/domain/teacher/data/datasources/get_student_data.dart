import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:test_nest/feature/domain/teacher/data/models/teacher_data_model.dart';

class GetStudentData {
  static final firestore = FirebaseFirestore.instance;

  static Stream<QuerySnapshot<Map<String, dynamic>>> getAllStudent() {
    final teacher = teacherData;

    if (teacher == null || teacher.id.trim().isEmpty) {
      return const Stream.empty();
    }

    return firestore
        .collection("user")
        .doc(teacher.id.trim())
        .collection("students")
        .snapshots();
  }
}
