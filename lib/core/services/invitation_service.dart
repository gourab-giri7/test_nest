import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../model/invitation_model.dart';
import '../../model/organization_model.dart';

class InvitationService {
  final FirebaseFirestore? _explicitFirestore;

  InvitationService({FirebaseFirestore? firestore})
    : _explicitFirestore = firestore;

  FirebaseFirestore get _firestore =>
      _explicitFirestore ?? FirebaseFirestore.instance;

  static const String _codeChars = '23456789ABCDEFGHJKLMNPQRSTUVWXYZ';

  /// Generates a cryptographically secure random invitation code.
  /// Format: TN-INV-XXXXXX (6 random characters from unambiguous alphabet)
  static String generateSecureCode([int length = 6]) {
    final random = Random.secure();
    final buffer = StringBuffer('TN-INV-');
    for (int i = 0; i < length; i++) {
      buffer.write(_codeChars[random.nextInt(_codeChars.length)]);
    }
    return buffer.toString();
  }

  /// Creates and stores a single-use, email-bound, expiring teacher invitation.
  Future<TeacherInvitationModel> createInvitation({
    required String orgId,
    required String orgName,
    required String teacherEmail,
    required String adminUid,
    Duration validity = const Duration(days: 7),
  }) async {
    final cleanEmail = teacherEmail.toLowerCase().trim();
    if (cleanEmail.isEmpty || !cleanEmail.contains('@')) {
      throw ArgumentError('A valid teacher email is required');
    }

    final code = generateSecureCode();
    final now = DateTime.now();
    final expiresAt = now.add(validity);

    final invitation = TeacherInvitationModel(
      code: code,
      orgId: orgId,
      orgName: orgName,
      teacherEmail: cleanEmail,
      createdBy: adminUid,
      createdAt: now,
      expiresAt: expiresAt,
      isUsed: false,
      status: InvitationStatus.pending,
    );

    final batch = _firestore.batch();
    final globalRef = _firestore.collection('invitations').doc(code);
    final orgRef = _firestore
        .collection('organizations')
        .doc(orgId)
        .collection('invitations')
        .doc(code);

    batch.set(globalRef, invitation.toMap());
    batch.set(orgRef, invitation.toMap());

    await batch.commit();
    return invitation;
  }

  /// Streams invitations for a specific organization (used by admins).
  Stream<List<TeacherInvitationModel>> streamOrganizationInvitations(
    String orgId,
  ) {
    return _firestore
        .collection('organizations')
        .doc(orgId)
        .collection('invitations')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => TeacherInvitationModel.fromMap(doc.data(), doc.id))
              .toList();
        });
  }

  /// Revokes a pending invitation.
  Future<void> revokeInvitation({
    required String orgId,
    required String code,
  }) async {
    final batch = _firestore.batch();
    final globalRef = _firestore.collection('invitations').doc(code);
    final orgRef = _firestore
        .collection('organizations')
        .doc(orgId)
        .collection('invitations')
        .doc(code);

    final updates = {'status': InvitationStatus.revoked};

    batch.update(globalRef, updates);
    batch.update(orgRef, updates);

    await batch.commit();
  }

  /// Fetches an invitation by code (for preview before redemption).
  Future<TeacherInvitationModel?> getInvitation(String code) async {
    final cleanCode = code.trim().toUpperCase();
    final doc = await _firestore.collection('invitations').doc(cleanCode).get();
    if (!doc.exists || doc.data() == null) return null;
    return TeacherInvitationModel.fromMap(doc.data()!, doc.id);
  }

  /// Redeems an invitation atomically inside a Firestore transaction.
  /// Enforces:
  /// 1. Exists & pending status
  /// 2. Not already used
  /// 3. Not expired
  /// 4. Email match with authenticated user
  /// 5. Atomic write of membership docs and marking invitation as used
  Future<void> redeemInvitation({
    required String code,
    required User user,
  }) async {
    final cleanCode = code.trim().toUpperCase();
    final userEmail = (user.email ?? '').toLowerCase().trim();
    final userName = (user.displayName ?? '').trim().isNotEmpty
        ? user.displayName!.trim()
        : 'Teacher';

    if (userEmail.isEmpty) {
      throw StateError('Current user does not have a valid email address.');
    }

    if (!user.emailVerified) {
      try {
        await user.sendEmailVerification();
      } catch (_) {}
      throw Exception(
        'Your email ($userEmail) is not verified. A verification link has been sent to your email. Please verify your email before accepting this invitation.',
      );
    }

    final globalRef = _firestore.collection('invitations').doc(cleanCode);

    await _firestore.runTransaction((transaction) async {
      final inviteSnapshot = await transaction.get(globalRef);
      if (!inviteSnapshot.exists || inviteSnapshot.data() == null) {
        throw Exception('Invalid invitation code. Please check and try again.');
      }

      final invite = TeacherInvitationModel.fromMap(
        inviteSnapshot.data()!,
        cleanCode,
      );

      if (invite.isUsed || invite.status == InvitationStatus.accepted) {
        throw Exception('This invitation code has already been redeemed.');
      }

      if (invite.status == InvitationStatus.revoked) {
        throw Exception(
          'This invitation has been revoked by the institute admin.',
        );
      }

      if (DateTime.now().isAfter(invite.expiresAt)) {
        throw Exception('This invitation has expired.');
      }

      if (invite.teacherEmail.toLowerCase().trim() != userEmail) {
        throw Exception(
          'This invitation was sent to ${invite.teacherEmail}. Please sign in with that email address to accept.',
        );
      }

      final orgRef = _firestore.collection('organizations').doc(invite.orgId);
      final orgSnapshot = await transaction.get(orgRef);
      if (!orgSnapshot.exists) {
        throw Exception(
          'The organization for this invitation no longer exists.',
        );
      }

      final orgData = orgSnapshot.data()!;
      final orgName = (orgData['name'] ?? invite.orgName).toString();
      final orgType = (orgData['type'] ?? OrganizationType.institute)
          .toString();

      final now = DateTime.now();

      // Mark global invitation as accepted
      transaction.update(globalRef, {
        'isUsed': true,
        'status': InvitationStatus.accepted,
        'usedBy': user.uid,
        'usedAt': FieldValue.serverTimestamp(),
      });

      // Mark org invitation doc as accepted
      final orgInviteRef = orgRef.collection('invitations').doc(cleanCode);
      transaction.set(orgInviteRef, {
        'isUsed': true,
        'status': InvitationStatus.accepted,
        'usedBy': user.uid,
        'usedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // Add user to organizations/{orgId}/members/{user.uid}
      final memberRef = orgRef.collection('members').doc(user.uid);
      final memberModel = OrganizationMemberModel(
        uid: user.uid,
        email: userEmail,
        name: userName,
        role: OrganizationRole.teacher,
        status: OrganizationStatus.active,
        joinedAt: now,
        inviteCode: cleanCode,
      );
      transaction.set(memberRef, memberModel.toMap());

      // Add indexing membership at users/{user.uid}/memberships/{orgId}
      final userMembershipRef = _firestore
          .collection('users')
          .doc(user.uid)
          .collection('memberships')
          .doc(invite.orgId);
      final userMembershipModel = UserMembershipModel(
        organizationId: invite.orgId,
        organizationName: orgName,
        organizationType: orgType,
        role: OrganizationRole.teacher,
        status: OrganizationStatus.active,
        joinedAt: now,
      );
      transaction.set(userMembershipRef, userMembershipModel.toMap());
    });
  }
}
