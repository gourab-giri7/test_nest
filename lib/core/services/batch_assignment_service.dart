import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:test_nest/model/batch_model.dart';
import 'package:test_nest/model/organization_model.dart';

class BatchAssignmentService {
  final FirebaseFirestore? _explicitFirestore;

  BatchAssignmentService({FirebaseFirestore? firestore})
    : _explicitFirestore = firestore;

  FirebaseFirestore get _firestore =>
      _explicitFirestore ?? FirebaseFirestore.instance;

  /// Assigns a teacher to an institute batch.
  /// Atomically updates:
  /// 1. `organizations/{orgId}/batches/{batchId}` -> arrayUnion `assigned_teacher_ids: [teacherUid]`
  /// 2. `organizations/{orgId}/members/{teacherUid}` -> arrayUnion `assignedBatchIds: [batchId]`
  Future<void> assignTeacherToBatch({
    required String orgId,
    required String batchId,
    required String teacherUid,
  }) async {
    final batchRef = _firestore
        .collection('organizations')
        .doc(orgId)
        .collection('batches')
        .doc(batchId);

    final memberRef = _firestore
        .collection('organizations')
        .doc(orgId)
        .collection('members')
        .doc(teacherUid);

    final writeBatch = _firestore.batch();
    writeBatch.update(batchRef, {
      'assigned_teacher_ids': FieldValue.arrayUnion([teacherUid]),
      'updated_at': FieldValue.serverTimestamp(),
    });
    writeBatch.update(memberRef, {
      'assignedBatchIds': FieldValue.arrayUnion([batchId]),
    });

    await writeBatch.commit();
  }

  /// Removes a teacher from an institute batch.
  /// Atomically updates:
  /// 1. `organizations/{orgId}/batches/{batchId}` -> arrayRemove `assigned_teacher_ids: [teacherUid]`
  /// 2. `organizations/{orgId}/members/{teacherUid}` -> arrayRemove `assignedBatchIds: [batchId]`
  Future<void> removeTeacherFromBatch({
    required String orgId,
    required String batchId,
    required String teacherUid,
  }) async {
    final batchRef = _firestore
        .collection('organizations')
        .doc(orgId)
        .collection('batches')
        .doc(batchId);

    final memberRef = _firestore
        .collection('organizations')
        .doc(orgId)
        .collection('members')
        .doc(teacherUid);

    final writeBatch = _firestore.batch();
    writeBatch.update(batchRef, {
      'assigned_teacher_ids': FieldValue.arrayRemove([teacherUid]),
      'updated_at': FieldValue.serverTimestamp(),
    });
    writeBatch.update(memberRef, {
      'assignedBatchIds': FieldValue.arrayRemove([batchId]),
    });

    await writeBatch.commit();
  }

  /// Streams all batches assigned to a specific teacher in an institute.
  Stream<List<BatchModel>> streamTeacherBatches(
    String orgId,
    String teacherUid,
  ) {
    return _firestore
        .collection('organizations')
        .doc(orgId)
        .collection('batches')
        .where('assigned_teacher_ids', arrayContains: teacherUid)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => BatchModel.fromJson(doc.data(), docId: doc.id))
              .where((b) => !b.isArchived)
              .toList();
        });
  }

  /// Streams all members of an organization (teachers and admins).
  Stream<List<OrganizationMemberModel>> streamOrganizationTeachers(
    String orgId,
  ) {
    return _firestore
        .collection('organizations')
        .doc(orgId)
        .collection('members')
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => OrganizationMemberModel.fromMap(doc.data(), doc.id))
              .where((m) => m.isTeacher || m.isAdmin)
              .toList();
        });
  }

  /// Fetches a specific batch with its assigned teachers.
  Future<BatchModel?> getBatch(String orgId, String batchId) async {
    final doc = await _firestore
        .collection('organizations')
        .doc(orgId)
        .collection('batches')
        .doc(batchId)
        .get();

    if (!doc.exists || doc.data() == null) return null;
    return BatchModel.fromJson(doc.data()!, docId: doc.id);
  }
}
