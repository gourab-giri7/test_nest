import '../context/active_tenant_context.dart';

/// Centralized Firestore path resolver supporting both:
/// 1. Single Teacher Mode (`user/{teacherId}/...`) — 100% backward compatible
/// 2. Coaching Institute Mode (`organizations/{orgId}/...`) — Multi-tenant
class TenantPathResolver {
  final ActiveTenantContext? _tenantContext;
  final String? _explicitOrgId;
  final bool? _explicitIsInstitute;

  TenantPathResolver({
    ActiveTenantContext? tenantContext,
    String? explicitOrgId,
    bool? explicitIsInstitute,
  }) : _tenantContext = tenantContext,
       _explicitOrgId = explicitOrgId,
       _explicitIsInstitute = explicitIsInstitute;

  String get orgId {
    final explicit = _explicitOrgId;
    if (explicit != null && explicit.isNotEmpty) {
      return explicit;
    }
    return _tenantContext?.activeOrgId ?? '';
  }

  bool get isInstitute {
    final explicit = _explicitIsInstitute;
    if (explicit != null) {
      return explicit;
    }
    return _tenantContext?.isInstitute ?? false;
  }

  /// Root base collection path for the current tenant context.
  /// If institute: `organizations/{orgId}`
  /// If independent / single teacher: `user/{teacherId}`
  String basePath([String? fallbackTeacherId]) {
    final effectiveId = orgId.isNotEmpty ? orgId : (fallbackTeacherId ?? '');
    if (isInstitute) {
      return 'organizations/$effectiveId';
    } else {
      return 'user/$effectiveId';
    }
  }

  String batchesPath([String? fallbackTeacherId]) =>
      '${basePath(fallbackTeacherId)}/batches';

  String batchDocPath(String batchId, [String? fallbackTeacherId]) =>
      '${batchesPath(fallbackTeacherId)}/$batchId';

  String batchStudentsPath(String batchId, [String? fallbackId]) =>
      '${batchDocPath(batchId, fallbackId)}/students';

  String batchStudentDocPath(
    String batchId,
    String studentUid, [
    String? fallbackId,
  ]) => '${batchStudentsPath(batchId, fallbackId)}/$studentUid';

  String joinRequestsPath([String? fallbackOrgId]) {
    final targetOrgId = orgId.isNotEmpty ? orgId : (fallbackOrgId ?? '');
    return 'organizations/$targetOrgId/joinRequests';
  }

  String joinRequestDocPath(String requestId, [String? fallbackOrgId]) =>
      '${joinRequestsPath(fallbackOrgId)}/$requestId';

  String studentsPath([String? fallbackTeacherId]) =>
      '${basePath(fallbackTeacherId)}/students';

  String studentDocPath(String studentId, [String? fallbackTeacherId]) =>
      '${studentsPath(fallbackTeacherId)}/$studentId';

  String examsPath([String? fallbackTeacherId]) =>
      '${basePath(fallbackTeacherId)}/exams';

  String examDocPath(String examId, [String? fallbackTeacherId]) =>
      '${examsPath(fallbackTeacherId)}/$examId';

  String submissionsPath(String examId, [String? fallbackTeacherId]) =>
      '${examDocPath(examId, fallbackTeacherId)}/submissions';

  String submissionDocPath(
    String examId,
    String submissionId, [
    String? fallbackTeacherId,
  ]) => '${submissionsPath(examId, fallbackTeacherId)}/$submissionId';

  String feeRecordsPath([String? fallbackTeacherId]) =>
      '${basePath(fallbackTeacherId)}/feeRecords';

  String feeRecordDocPath(String recordId, [String? fallbackTeacherId]) =>
      '${feeRecordsPath(fallbackTeacherId)}/$recordId';

  /// Resolves the collection path for a student's monthly fee records.
  /// If institute mode: `organizations/{orgId}/feeRecords/{studentUid}/months`
  /// If single-teacher mode: `user/{teacherId}/students/{studentUid}/feeRecords`
  String studentFeeMonthsPath(String studentUid, [String? fallbackId]) {
    if (isInstitute) {
      final targetOrgId = orgId.isNotEmpty ? orgId : (fallbackId ?? '');
      return 'organizations/$targetOrgId/feeRecords/$studentUid/months';
    } else {
      final targetTeacherId = orgId.isNotEmpty ? orgId : (fallbackId ?? '');
      return 'user/$targetTeacherId/students/$studentUid/feeRecords';
    }
  }

  String studentFeeMonthDocPath(
    String studentUid,
    String monthKey, [
    String? fallbackId,
  ]) => '${studentFeeMonthsPath(studentUid, fallbackId)}/$monthKey';

  String studentFeePaymentsPath(
    String studentUid,
    String monthKey, [
    String? fallbackId,
  ]) => '${studentFeeMonthDocPath(studentUid, monthKey, fallbackId)}/payments';

  String studentFeePaymentDocPath(
    String studentUid,
    String monthKey,
    String paymentId, [
    String? fallbackId,
  ]) =>
      '${studentFeePaymentsPath(studentUid, monthKey, fallbackId)}/$paymentId';

  /// Resolves the collection path for a teacher's monthly salary records (organization-scoped).
  String teacherSalaryMonthsPath(String teacherUid, [String? fallbackOrgId]) {
    final targetOrgId = orgId.isNotEmpty ? orgId : (fallbackOrgId ?? '');
    return 'organizations/$targetOrgId/teacherSalaryRecords/$teacherUid/months';
  }

  String teacherSalaryMonthDocPath(
    String teacherUid,
    String monthKey, [
    String? fallbackOrgId,
  ]) => '${teacherSalaryMonthsPath(teacherUid, fallbackOrgId)}/$monthKey';

  String teacherSalaryPaymentsPath(
    String teacherUid,
    String monthKey, [
    String? fallbackOrgId,
  ]) =>
      '${teacherSalaryMonthDocPath(teacherUid, monthKey, fallbackOrgId)}/payments';

  String teacherSalaryPaymentDocPath(
    String teacherUid,
    String monthKey,
    String paymentId, [
    String? fallbackOrgId,
  ]) =>
      '${teacherSalaryPaymentsPath(teacherUid, monthKey, fallbackOrgId)}/$paymentId';

  String attendancePath([String? fallbackTeacherId]) =>
      '${basePath(fallbackTeacherId)}/attendance';

  String attendanceDocPath(String attendanceId, [String? fallbackTeacherId]) =>
      '${attendancePath(fallbackTeacherId)}/$attendanceId';

  String noticesPath([String? fallbackTeacherId]) =>
      '${basePath(fallbackTeacherId)}/notices';

  String noticeDocPath(String noticeId, [String? fallbackTeacherId]) =>
      '${noticesPath(fallbackTeacherId)}/$noticeId';

  String salariesPath([String? fallbackOrgId]) {
    final targetOrgId = orgId.isNotEmpty ? orgId : (fallbackOrgId ?? '');
    return 'organizations/$targetOrgId/salaries';
  }

  String salaryDocPath(String salaryId, [String? fallbackOrgId]) =>
      '${salariesPath(fallbackOrgId)}/$salaryId';

  String membersPath([String? fallbackOrgId]) {
    final targetOrgId = orgId.isNotEmpty ? orgId : (fallbackOrgId ?? '');
    return 'organizations/$targetOrgId/members';
  }

  String memberDocPath(String uid, [String? fallbackOrgId]) =>
      '${membersPath(fallbackOrgId)}/$uid';

  String invitationsPath([String? fallbackOrgId]) {
    final targetOrgId = orgId.isNotEmpty ? orgId : (fallbackOrgId ?? '');
    return 'organizations/$targetOrgId/invitations';
  }

  String invitationDocPath(String code, [String? fallbackOrgId]) =>
      '${invitationsPath(fallbackOrgId)}/$code';

  static String globalInvitationsPath() => 'invitations';
  static String globalInvitationDocPath(String code) => 'invitations/$code';

  static String userMembershipsPath(String uid) => 'users/$uid/memberships';
  static String userMembershipDocPath(String uid, String orgId) =>
      'users/$uid/memberships/$orgId';
}
