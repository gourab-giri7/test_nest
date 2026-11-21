abstract class AppRoutes {
  // Common / Auth
  static const splash = '/';
  static const roleSelection = '/role-selection';
  static const login = '/login';
  static const aboutApp = '/about-app';
  static const privacyPolicy = '/privacy-policy';

  // Student Auth & Onboarding
  static const studentSignup = '/student/signup';
  static const studentJoinTeacher = '/student/join-teacher';
  static const studentScanQr = '/student/scan-qr';
  static const studentRequestSent = '/student/request-sent';

  // Student Main
  static const studentDashboard = '/student/dashboard';
  static const studentProfile = '/student/profile';
  static const studentExamHistory = '/student/exam-history';
  static const studentExamDetails = '/student/exam-details';
  static const studentTakeExam = '/student/take-exam';
  static const studentExamSubmitted = '/student/exam-submitted';
  static const studentExamResult = '/student/exam-result';

  // Teacher Auth
  static const teacherSignup = '/teacher/signup';

  // Teacher Main
  static const teacherDashboard = '/teacher/dashboard';
  static const teacherProfile = '/teacher/profile';
  static const teacherAllStudents = '/teacher/students';
  static const teacherAddStudent = '/teacher/add-student';
  static const teacherStudentDetails = '/teacher/student-details';
  static const teacherStudentExamDetails = '/teacher/student-exam-details';
  static const teacherExams = '/teacher/exams';
  static const teacherCreateExam = '/teacher/create-exam';
  static const teacherQuestionMethodChoice = '/teacher/question-method-choice';
  static const teacherManualQuestions = '/teacher/manual-questions';
  static const teacherFileUpload = '/teacher/file-upload';
  static const teacherReviewPublish = '/teacher/review-publish';
  static const teacherExamDetails = '/teacher/exam-details';
  static const teacherFeeManagement = '/teacher/fees';
  static const teacherBatches = '/teacher/batches';
  static const teacherCreateBatch = '/teacher/create-batch';
  static const teacherJoinRequests = '/teacher/join-requests';
  static const teacherPromoteStudents = '/teacher/promote-students';

  // Organization / Workspace (Phase 1 & Phase 2)
  static const createOrganization = '/organization/create';
  static const organizationSwitcher = '/organization/switcher';
  static const joinOrganization = '/organization/join';
  static const manageInvitations = '/organization/invitations';
  static const instituteAdminDashboard = '/organization/admin-dashboard';
  static const instituteTeacherDashboard = '/organization/teacher-dashboard';
  static const instituteTeachers = '/organization/teachers';
  static const batchTeacherAssignment = '/organization/batch-assignment';

  // Attendance Management (Phase 3)
  static const batchAttendance = '/attendance/mark';
  static const attendanceOverview = '/attendance/overview';
  static const studentAttendanceHistory = '/attendance/student-history';

  // Notice System (Phase 4)
  static const noticeList = '/notices';
  static const noticeEditor = '/notices/editor';
  static const noticeDetail = '/notices/detail';
  static const studentNoticeInbox = '/student/notices';
  static const studentNoticeDetail = '/student/notices/detail';

  // Performance Intelligence (Phase 5)
  static const performanceAnalytics = '/performance-analytics';
}
