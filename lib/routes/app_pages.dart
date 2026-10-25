import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:test_nest/feature/domain/common/presentation/screen/login/login_screen.dart';
import 'package:test_nest/feature/domain/common/presentation/screen/roleSelection/role_selection_screen.dart';
import 'package:test_nest/feature/domain/common/presentation/screen/splash/splash_screen.dart';
import 'package:test_nest/feature/domain/student/data/models/student_data_model.dart';
import 'package:test_nest/feature/domain/student/presentation/screens/dashboard/students_dashboard_screen.dart';
import 'package:test_nest/feature/domain/student/presentation/screens/examDetails/exam_details_screen.dart';
import 'package:test_nest/feature/domain/student/presentation/screens/examHistory/exam_history_screen.dart';
import 'package:test_nest/feature/domain/student/presentation/screens/examResult/exam_result_review_screen.dart';
import 'package:test_nest/feature/domain/student/presentation/screens/examSubmited/exam_submited_screen.dart';
import 'package:test_nest/feature/domain/student/presentation/screens/joinTeacher/join_teacher_screen.dart';
import 'package:test_nest/feature/domain/student/presentation/screens/joinTeacher/request_sent_screen.dart';
import 'package:test_nest/feature/domain/student/presentation/screens/signup/student_signup_screen.dart';
import 'package:test_nest/feature/domain/student/presentation/screens/takeExam/take_exam_screen.dart';
import 'package:test_nest/feature/domain/teacher/data/models/student_model.dart';
import 'package:test_nest/feature/domain/teacher/data/models/teacher_data_model.dart';
import 'package:test_nest/feature/domain/teacher/presentation/screens/CreateExam/create_exam_screen.dart';
import 'package:test_nest/feature/domain/teacher/presentation/screens/CreateExam/question_method_choice_screen.dart';
import 'package:test_nest/feature/domain/teacher/presentation/screens/addStudents/add_students_screen.dart';
import 'package:test_nest/feature/domain/teacher/presentation/screens/allStudents/all_students_screen.dart';
import 'package:test_nest/feature/domain/teacher/presentation/screens/batches/create_batch_screen.dart';
import 'package:test_nest/feature/domain/teacher/presentation/screens/batches/join_requests_screen.dart';
import 'package:test_nest/feature/domain/teacher/presentation/screens/batches/my_batches_screen.dart';
import 'package:test_nest/feature/domain/teacher/presentation/screens/batches/promote_students_screen.dart';
import 'package:test_nest/feature/domain/teacher/presentation/screens/dashboard/teacher_dashboard_screen.dart';
import 'package:test_nest/feature/domain/teacher/presentation/screens/examDetails/teacher_exam_details_screen.dart';
import 'package:test_nest/feature/domain/teacher/presentation/screens/exams/teacher_exam_screen.dart';
import 'package:test_nest/feature/domain/teacher/presentation/screens/feeManagement/controller/fee_management_controller.dart';
import 'package:test_nest/feature/domain/teacher/presentation/screens/feeManagement/fee_management_screen.dart';
import 'package:test_nest/feature/domain/teacher/presentation/screens/fileUpload/file_upload_screen.dart';
import 'package:test_nest/feature/domain/teacher/presentation/screens/manualQuestions/controller/question_controller.dart';
import 'package:test_nest/feature/domain/teacher/presentation/screens/manualQuestions/manual_questions_screen.dart';
import 'package:test_nest/feature/domain/teacher/presentation/screens/reviewPublishExam/review_publish_screen.dart';
import 'package:test_nest/feature/domain/teacher/presentation/screens/signup/teacher_signup_screen.dart';
import 'package:test_nest/feature/domain/teacher/presentation/screens/studentDetails/model/student_exam_submission_summary.dart';
import 'package:test_nest/feature/domain/teacher/presentation/screens/studentDetails/student_details_screen.dart';
import 'package:test_nest/feature/domain/teacher/presentation/screens/studentDetails/student_exam_details_screen.dart';
import 'package:test_nest/model/batch_model.dart';
import 'package:test_nest/model/exam_model.dart';
import 'package:test_nest/routes/app_routes.dart';

class AppPages {
  static const initial = AppRoutes.splash;

  static final List<GetPage> routes = [
    // Common / Auth
    GetPage(
      name: AppRoutes.splash,
      page: () => const SplashScreen(),
    ),
    GetPage(
      name: AppRoutes.roleSelection,
      page: () => const RoleSelectionScreen(),
    ),
    GetPage(
      name: AppRoutes.login,
      page: () => const LoginScreen(),
    ),

    // Student Auth & Onboarding
    GetPage(
      name: AppRoutes.studentSignup,
      page: () => const StudentSignupScreen(),
    ),
    GetPage(
      name: AppRoutes.studentJoinTeacher,
      page: () => const JoinTeacherScreen(),
    ),
    GetPage(
      name: AppRoutes.studentRequestSent,
      page: () {
        final args = Get.arguments;
        String batchName = 'Your Batch';
        String teacherName = 'Your Teacher';
        if (args is Map<String, dynamic>) {
          batchName = args['batchName']?.toString() ?? batchName;
          teacherName = args['teacherName']?.toString() ?? teacherName;
        }
        return RequestSentScreen(
          batchName: batchName,
          teacherName: teacherName,
        );
      },
    ),

    // Student Main
    GetPage(
      name: AppRoutes.studentDashboard,
      page: () => const StudentDashboardScreen(),
    ),
    GetPage(
      name: AppRoutes.studentExamHistory,
      page: () {
        final args = Get.arguments;
        StudentData? student;
        Stream<QuerySnapshot<Map<String, dynamic>>>? stream;
        int tab = 0;

        if (args is Map<String, dynamic>) {
          student = args['initialStudentData'] as StudentData?;
          stream = args['examStream']
              as Stream<QuerySnapshot<Map<String, dynamic>>>?;
          tab = args['initialTab'] as int? ?? 0;
        } else if (args is StudentData) {
          student = args;
        } else if (args is int) {
          tab = args;
        }

        return ExamHistoryScreen(
          initialStudentData: student,
          examStream: stream,
          initialTab: tab,
        );
      },
    ),
    GetPage(
      name: AppRoutes.studentExamDetails,
      page: () {
        final args = Get.arguments;
        ExamModel? exam;
        if (args is ExamModel) {
          exam = args;
        } else if (args is Map<String, dynamic>) {
          exam = args['exam'] as ExamModel?;
        }
        if (exam == null) {
          throw ArgumentError('ExamModel is required for studentExamDetails');
        }
        return ExamDetailsScreen(exam: exam);
      },
    ),
    GetPage(
      name: AppRoutes.studentTakeExam,
      page: () {
        final args = Get.arguments;
        ExamModel? exam;
        if (args is ExamModel) {
          exam = args;
        } else if (args is Map<String, dynamic>) {
          exam = args['exam'] as ExamModel?;
        }
        if (exam == null) {
          throw ArgumentError('ExamModel is required for studentTakeExam');
        }
        return TakeExamScreen(exam: exam);
      },
    ),
    GetPage(
      name: AppRoutes.studentExamSubmitted,
      page: () {
        final args = Get.arguments;
        String examTitle = 'Exam';
        int totalQuestions = 0;
        int attemptedQuestions = 0;
        String fullMarks = '0';

        if (args is Map<String, dynamic>) {
          examTitle = args['examTitle']?.toString() ?? examTitle;
          totalQuestions = (args['totalQuestions'] as num?)?.toInt() ?? 0;
          attemptedQuestions =
              (args['attemptedQuestions'] as num?)?.toInt() ?? 0;
          fullMarks = args['fullMarks']?.toString() ?? fullMarks;
        }

        return SubmissionScreen(
          examTitle: examTitle,
          totalQuestions: totalQuestions,
          attemptedQuestions: attemptedQuestions,
          fullMarks: fullMarks,
        );
      },
    ),
    GetPage(
      name: AppRoutes.studentExamResult,
      page: () {
        final args = Get.arguments;
        ExamModel? exam;
        Map<String, dynamic> submission = {};

        if (args is Map<String, dynamic>) {
          exam = args['exam'] as ExamModel?;
          submission = (args['submission'] as Map<String, dynamic>?) ?? {};
        }

        if (exam == null) {
          throw ArgumentError('ExamModel is required for studentExamResult');
        }

        return ExamResultReviewScreen(
          exam: exam,
          submission: submission,
        );
      },
    ),

    // Teacher Auth
    GetPage(
      name: AppRoutes.teacherSignup,
      page: () => const TeacherSignupScreen(),
    ),

    // Teacher Main
    GetPage(
      name: AppRoutes.teacherDashboard,
      page: () => const TeacherDashboardScreen(),
    ),
    GetPage(
      name: AppRoutes.teacherAllStudents,
      page: () => const AllStudentsScreen(),
    ),
    GetPage(
      name: AppRoutes.teacherAddStudent,
      page: () => const AddStudentScreen(),
    ),
    GetPage(
      name: AppRoutes.teacherStudentDetails,
      page: () {
        final args = Get.arguments;
        StudentModel? student;
        String? teacherId;

        if (args is StudentModel) {
          student = args;
        } else if (args is Map<String, dynamic>) {
          student = args['student'] as StudentModel?;
          teacherId = args['teacherId']?.toString();
        }

        if (student == null) {
          throw ArgumentError('StudentModel is required for studentDetails');
        }

        return StudentDetailsScreen(
          student: student,
          teacherId: teacherId,
        );
      },
    ),
    GetPage(
      name: AppRoutes.teacherStudentExamDetails,
      page: () {
        final args = Get.arguments;
        StudentModel? student;
        StudentExamSubmissionSummary? summary;
        String? teacherId;

        if (args is Map<String, dynamic>) {
          student = args['student'] as StudentModel?;
          summary = args['summary'] as StudentExamSubmissionSummary?;
          teacherId = args['teacherId']?.toString();
        }

        if (student == null || summary == null) {
          throw ArgumentError(
            'StudentModel and StudentExamSubmissionSummary are required for studentExamDetailsTeacher',
          );
        }

        return StudentExamDetailsScreen(
          student: student,
          summary: summary,
          teacherId: teacherId,
        );
      },
    ),
    GetPage(
      name: AppRoutes.teacherExams,
      page: () => const TeacherExamsScreen(),
    ),
    GetPage(
      name: AppRoutes.teacherCreateExam,
      page: () => const CreateExamScreen(),
    ),
    GetPage(
      name: AppRoutes.teacherQuestionMethodChoice,
      page: () {
        final args = Get.arguments;
        QuestionController? qc;
        if (args is QuestionController) {
          qc = args;
        } else if (args is Map<String, dynamic>) {
          qc = args['qc'] as QuestionController?;
        }
        if (qc == null) {
          throw ArgumentError(
            'QuestionController is required for questionMethodChoice',
          );
        }
        return QuestionMethodChoiceScreen(qc: qc);
      },
    ),
    GetPage(
      name: AppRoutes.teacherManualQuestions,
      page: () {
        final args = Get.arguments;
        QuestionController? qc;
        if (args is QuestionController) {
          qc = args;
        } else if (args is Map<String, dynamic>) {
          qc = args['qc'] as QuestionController?;
        }
        if (qc != null) {
          return ChangeNotifierProvider<QuestionController>.value(
            value: qc,
            child: const ManualQuestionsScreen(),
          );
        }
        return const ManualQuestionsScreen();
      },
    ),
    GetPage(
      name: AppRoutes.teacherFileUpload,
      page: () {
        final args = Get.arguments;
        QuestionController? qc;
        if (args is QuestionController) {
          qc = args;
        } else if (args is Map<String, dynamic>) {
          qc = args['qc'] as QuestionController?;
        }
        if (qc != null) {
          return ChangeNotifierProvider<QuestionController>.value(
            value: qc,
            child: const FileUploadScreen(),
          );
        }
        return const FileUploadScreen();
      },
    ),
    GetPage(
      name: AppRoutes.teacherReviewPublish,
      page: () {
        final args = Get.arguments;
        QuestionController? qc;
        if (args is QuestionController) {
          qc = args;
        } else if (args is Map<String, dynamic>) {
          qc = args['qc'] as QuestionController?;
        }
        if (qc != null) {
          return ChangeNotifierProvider<QuestionController>.value(
            value: qc,
            child: const ReviewPublishScreen(),
          );
        }
        return const ReviewPublishScreen();
      },
    ),
    GetPage(
      name: AppRoutes.teacherExamDetails,
      page: () {
        final args = Get.arguments;
        ExamModel? exam;
        if (args is ExamModel) {
          exam = args;
        } else if (args is Map<String, dynamic>) {
          exam = args['exam'] as ExamModel?;
        }
        if (exam == null) {
          throw ArgumentError('ExamModel is required for teacherExamDetails');
        }
        return TeacherExamDetailsScreen(exam: exam);
      },
    ),
    GetPage(
      name: AppRoutes.teacherFeeManagement,
      page: () {
        final t = teacherData;
        final teacherId = t?.id ?? '';
        final teacherName = t?.name ?? '';
        return ChangeNotifierProvider(
          create: (_) => FeeManagementController(
            teacherId: teacherId,
            teacherName: teacherName,
          ),
          child: const FeeManagementScreen(),
        );
      },
    ),
    GetPage(
      name: AppRoutes.teacherBatches,
      page: () => const MyBatchesScreen(),
    ),
    GetPage(
      name: AppRoutes.teacherCreateBatch,
      page: () => const CreateBatchScreen(),
    ),
    GetPage(
      name: AppRoutes.teacherJoinRequests,
      page: () => const JoinRequestsScreen(),
    ),
    GetPage(
      name: AppRoutes.teacherPromoteStudents,
      page: () {
        final args = Get.arguments;
        BatchModel? batch;
        if (args is BatchModel) {
          batch = args;
        } else if (args is Map<String, dynamic>) {
          batch = args['sourceBatch'] as BatchModel?;
        }
        if (batch == null) {
          throw ArgumentError('BatchModel is required for promoteStudents');
        }
        return PromoteStudentsScreen(sourceBatch: batch);
      },
    ),
  ];
}
