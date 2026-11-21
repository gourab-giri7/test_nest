import 'package:cloud_firestore/cloud_firestore.dart';
import '../../model/organization_model.dart';

class OrganizationService {
  final FirebaseFirestore? _explicitFirestore;

  OrganizationService({FirebaseFirestore? firestore})
    : _explicitFirestore = firestore;

  FirebaseFirestore get _firestore =>
      _explicitFirestore ?? FirebaseFirestore.instance;

  /// Creates a new Organization (e.g., Coaching Institute or Personal Workspace).
  /// Atomically writes:
  /// 1. `organizations/{orgId}`
  /// 2. `organizations/{orgId}/members/{ownerId}` (role: admin)
  /// 3. `users/{ownerId}/memberships/{orgId}`
  Future<OrganizationModel> createOrganization({
    required String name,
    required String type,
    required String ownerId,
    required String ownerName,
    required String ownerEmail,
    Map<String, dynamic> metadata = const {},
  }) async {
    final cleanName = name.trim();
    if (cleanName.isEmpty) {
      throw ArgumentError('Organization name cannot be empty');
    }
    if (!OrganizationType.isValid(type)) {
      throw ArgumentError('Invalid organization type: $type');
    }

    final orgRef = _firestore.collection('organizations').doc();
    final orgId = orgRef.id;
    final now = DateTime.now();

    final orgModel = OrganizationModel(
      id: orgId,
      name: cleanName,
      type: type,
      ownerId: ownerId,
      ownerName: ownerName.trim(),
      createdAt: now,
      status: OrganizationStatus.active,
      metadata: metadata,
    );

    final memberModel = OrganizationMemberModel(
      uid: ownerId,
      email: ownerEmail.toLowerCase().trim(),
      name: ownerName.trim(),
      role: OrganizationRole.admin,
      status: OrganizationStatus.active,
      joinedAt: now,
    );

    final membershipModel = UserMembershipModel(
      organizationId: orgId,
      organizationName: cleanName,
      organizationType: type,
      role: OrganizationRole.admin,
      status: OrganizationStatus.active,
      joinedAt: now,
    );

    final batch = _firestore.batch();
    batch.set(orgRef, orgModel.toMap());
    batch.set(orgRef.collection('members').doc(ownerId), memberModel.toMap());
    batch.set(
      _firestore
          .collection('users')
          .doc(ownerId)
          .collection('memberships')
          .doc(orgId),
      membershipModel.toMap(),
    );

    await batch.commit();
    return orgModel;
  }

  /// Ensures an independent workspace is registered for legacy or newly registered teachers.
  /// Does not copy, overwrite, or mutate any existing `user/{teacherId}` data.
  Future<OrganizationModel> ensureIndependentWorkspace({
    required String teacherId,
    required String teacherName,
    required String teacherEmail,
  }) async {
    final membershipRef = _firestore
        .collection('users')
        .doc(teacherId)
        .collection('memberships')
        .doc(teacherId);

    final membershipDoc = await membershipRef.get();
    final now = DateTime.now();

    final orgModel = OrganizationModel(
      id: teacherId,
      name: teacherName.isNotEmpty ? teacherName : 'Personal Workspace',
      type: OrganizationType.independent,
      ownerId: teacherId,
      ownerName: teacherName,
      createdAt: now,
      status: OrganizationStatus.active,
    );

    if (!membershipDoc.exists) {
      final orgRef = _firestore.collection('organizations').doc(teacherId);
      final orgDoc = await orgRef.get();

      final memberModel = OrganizationMemberModel(
        uid: teacherId,
        email: teacherEmail.toLowerCase().trim(),
        name: teacherName,
        role: OrganizationRole.admin,
        status: OrganizationStatus.active,
        joinedAt: now,
      );

      final membershipModel = UserMembershipModel(
        organizationId: teacherId,
        organizationName: orgModel.name,
        organizationType: OrganizationType.independent,
        role: OrganizationRole.admin,
        status: OrganizationStatus.active,
        joinedAt: now,
      );

      final batch = _firestore.batch();
      if (!orgDoc.exists) {
        batch.set(orgRef, orgModel.toMap());
      }
      batch.set(
        orgRef.collection('members').doc(teacherId),
        memberModel.toMap(),
        SetOptions(merge: true),
      );
      batch.set(
        membershipRef,
        membershipModel.toMap(),
        SetOptions(merge: true),
      );
      await batch.commit();
    }

    return orgModel;
  }

  /// Stream of user memberships for fast workspace list and selector rendering.
  Stream<List<UserMembershipModel>> streamUserMemberships(String uid) {
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('memberships')
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => UserMembershipModel.fromMap(doc.data(), doc.id))
              .toList();
        });
  }

  /// Future fetch of user memberships.
  Future<List<UserMembershipModel>> getUserMemberships(String uid) async {
    final snapshot = await _firestore
        .collection('users')
        .doc(uid)
        .collection('memberships')
        .get();

    return snapshot.docs
        .map((doc) => UserMembershipModel.fromMap(doc.data(), doc.id))
        .toList();
  }

  /// Fetches an Organization by ID.
  Future<OrganizationModel?> getOrganization(String orgId) async {
    final doc = await _firestore.collection('organizations').doc(orgId).get();
    if (!doc.exists || doc.data() == null) return null;
    return OrganizationModel.fromMap(doc.data()!, doc.id);
  }

  /// Stream of organization members.
  Stream<List<OrganizationMemberModel>> streamOrganizationMembers(
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
              .toList();
        });
  }

  /// Updates a member's role (admin / teacher).
  Future<void> updateMemberRole({
    required String orgId,
    required String memberUid,
    required String newRole,
  }) async {
    if (!OrganizationRole.isValid(newRole)) {
      throw ArgumentError('Invalid role: $newRole');
    }

    final batch = _firestore.batch();
    final memberRef = _firestore
        .collection('organizations')
        .doc(orgId)
        .collection('members')
        .doc(memberUid);
    final userMembershipRef = _firestore
        .collection('users')
        .doc(memberUid)
        .collection('memberships')
        .doc(orgId);

    batch.update(memberRef, {'role': newRole});
    batch.update(userMembershipRef, {'role': newRole});

    await batch.commit();
  }

  /// Removes a member from an organization.
  Future<void> removeMember({
    required String orgId,
    required String memberUid,
  }) async {
    final batch = _firestore.batch();
    final memberRef = _firestore
        .collection('organizations')
        .doc(orgId)
        .collection('members')
        .doc(memberUid);
    final userMembershipRef = _firestore
        .collection('users')
        .doc(memberUid)
        .collection('memberships')
        .doc(orgId);

    batch.delete(memberRef);
    batch.delete(userMembershipRef);

    await batch.commit();
  }
}
