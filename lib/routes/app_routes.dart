abstract class AppRoutes {
  // Common / Auth
  static const splash = '/';
  static const roleSelection = '/role-selection';
  static const login = '/login';

  // Student Auth & Onboarding
  static const studentSignup = '/student/signup';
  static const studentJoinTeacher = '/student/join-teacher';
  static const studentRequestSent = '/student/request-sent';

  // Student Main
  static const studentDashboard = '/student/dashboard';
  static const studentExamHistory = '/student/exam-history';
  static const studentExamDetails = '/student/exam-details';
  static const studentTakeExam = '/student/take-exam';
  static const studentExamSubmitted = '/student/exam-submitted';
  static const studentExamResult = '/student/exam-result';

  // Teacher Auth
  static const teacherSignup = '/teacher/signup';

  // Teacher Main
  static const teacherDashboard = '/teacher/dashboard';
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
}
