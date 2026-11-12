import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:test_nest/core/utils/theme/theme.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => Get.back(),
        ),
        title: const Text(
          'Privacy Policy',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: AppColors.text,
          ),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 620),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.primarySoft,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppColors.primary.withOpacity(0.2),
                      ),
                    ),
                    child: const Row(
                      children: [
                        Icon(
                          Icons.verified_user_outlined,
                          color: AppColors.primary,
                          size: 24,
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Last updated: November 2026\nApp Version: Test Nest 1.0.0',
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  _section(
                    title: '1. Introduction',
                    content:
                        'Test Nest is an academic assessment and batch-management software developed by Gourab Giri. This Privacy Policy details how we collect, store, and process information from teachers and students who use the application.',
                  ),

                  _section(
                    title: '2. Personal Information Collected',
                    content:
                        '• Student Accounts: Full name, login email address, contact phone number (optional), assigned batch name, student ID, and authentication identifier (UID).\n'
                        '• Teacher Accounts: Full name, educator email address, institute name, phone number, and unique teacher identifier.\n'
                        '• Academic & Exam Data: Exam questions, answer keys, submitted student responses, timestamps, scores, and anti-cheating focus loss occurrences during active exam attempts.\n'
                        '• Fee Tracking: Monthly payment statuses, amounts due, transaction dates, and remarks recorded by authorized teachers.',
                  ),

                  _section(
                    title: '3. Authentication & Cloud Storage',
                    content:
                        'We use Google Firebase Authentication for secure account credential validation and Cloud Firestore for database storage. Passwords are never stored in plaintext within Firestore documents; they are handled securely by Firebase Authentication with industry-standard cryptographic encryption.',
                  ),

                  _section(
                    title: '4. How Information Is Used',
                    content:
                        'The data collected is used solely to:\n'
                        '• Authenticate teachers and students and manage active role sessions.\n'
                        '• Facilitate joining batches using teacher-issued joining codes.\n'
                        '• Administer scheduled examinations and enforce anti-cheating window parameters.\n'
                        '• Calculate student test results and display historical scorecards.\n'
                        '• Enable teachers to track and manage tuition fees for active students.',
                  ),

                  _section(
                    title: '5. Information Sharing & Third Parties',
                    content:
                        'We do not sell, rent, or trade your personal information. Data is shared strictly within the context of educational workflows:\n'
                        '• Teachers can view details, exam submissions, and fee records for students enrolled in their batches.\n'
                        '• Students can only view exams and coaching information belonging to teachers whose batches they have actively joined.\n'
                        '• Backend services are provided via Google Cloud / Firebase infrastructure in accordance with Google Cloud Privacy commitments.',
                  ),

                  _section(
                    title: '6. Data Retention & Student Removal',
                    content:
                        '• When a teacher removes a student from a batch or archives a batch, the student loses immediate access to that batch\'s current exams and live materials.\n'
                        '• Historical examination submissions and published results are retained for academic transcript and accounting accuracy unless deleted by an authorized administrator.\n'
                        '• Users may request complete deletion of their authentication account by contacting their institute educator or the application administrator.',
                  ),

                  _section(
                    title: '7. Student & Minor Privacy',
                    content:
                        'Because Test Nest is used by educational institutes and students of various age groups, student registration is protected via teacher-controlled batch joining codes. Students cannot arbitrarily join batches or view assessments without teacher authorization.',
                  ),

                  _section(
                    title: '8. Security Measures',
                    content:
                        'We implement Firebase Security Rules to restrict document read and write permissions to authenticated and authorized participants. Answer keys are strictly shielded from student access, and cross-teacher data tampering is disallowed.',
                  ),

                  _section(
                    title: '9. Developer & Support Inquiries',
                    content:
                        'Test Nest was developed by Gourab Giri. For technical questions or data privacy inquiries regarding this application, please reach out through your institution administrator or verified support channels [Contact details require institute developer confirmation].',
                  ),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _section({required String title, required String content}) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: AppColors.text,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
              height: 1.55,
            ),
          ),
        ],
      ),
    );
  }
}
