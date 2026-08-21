import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:test_nest/feature/domain/common/presentation/screen/login/controller/login_controller.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blueGrey[50],
      body: SafeArea(
        child: Consumer<LoginController>(
          builder: (context, controller, child) => Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24.0,
                    vertical: 40.0,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(32),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blueGrey,
                        // color: controller.isStudentLogin
                        //     ? const Color(0xFF6B48D9)
                        //     : const Color(0xFF2962FF),
                        blurRadius: 24,
                        offset: const Offset(0, 0),
                      ),
                    ],
                  ),
                  child: Form(
                    key: controller.loginKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Logo and Title
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.school,
                              size: 48,
                              color: controller.isStudentLogin
                                  ? const Color(0xFF6B48D9)
                                  : const Color(0xFF2962FF),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'XYZ',
                                  style: TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.indigo[900],
                                  ),
                                ),
                                Text(
                                  controller.isStudentLogin
                                      ? 'Online Examination'
                                      : 'Exam Management System',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 32),

                        // ===================Toggle Switch=====================
                        Container(
                          height: 50,
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: GestureDetector(
                                  onTap: () => controller.toggeFields(),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: !controller.isStudentLogin
                                          ? controller.isStudentLogin
                                                ? const Color(0xFF6B48D9)
                                                : const Color(0xFF2962FF)
                                          : Colors.transparent,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    alignment: Alignment.center,
                                    child: Text(
                                      'Teacher / Admin',
                                      style: TextStyle(
                                        color: !controller.isStudentLogin
                                            ? Colors.white
                                            : Colors.grey[600],
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              Expanded(
                                child: GestureDetector(
                                  onTap: () =>
                                      controller.changeLoginToStudent(),

                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: controller.isStudentLogin
                                          ? controller.isStudentLogin
                                                ? const Color(0xFF6B48D9)
                                                : const Color(0xFF2962FF)
                                          : Colors.transparent,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    alignment: Alignment.center,
                                    child: Text(
                                      'Student',
                                      style: TextStyle(
                                        color: controller.isStudentLogin
                                            ? Colors.white
                                            : Colors.grey[600],
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        // teacher id
                        controller.isStudentLogin
                            ? TextFormField(
                                controller: controller.teacherId,
                                validator: controller.fieldeValidation,
                                onTapOutside: (event) => FocusManager
                                    .instance
                                    .primaryFocus!
                                    .unfocus(),
                                decoration: InputDecoration(
                                  hintText: 'Teacher ID',
                                  hintStyle: TextStyle(color: Colors.grey[400]),
                                  prefixIcon: Icon(
                                    Icons.person_outline,
                                    color: Colors.grey[700],
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(color: Colors.grey),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(color: Colors.grey),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(
                                      color: const Color(0xFF6B48D9),
                                    ),
                                  ),
                                ),
                              )
                            : SizedBox.shrink(),
                        const SizedBox(height: 16),

                        // User ID Field
                        TextFormField(
                          controller: controller.id,
                          validator: controller.fieldeValidation,
                          onTapOutside: (event) =>
                              FocusManager.instance.primaryFocus!.unfocus(),
                          decoration: InputDecoration(
                            hintText: controller.isStudentLogin
                                ? 'Student ID'
                                : 'Email / Teacher ID',
                            hintStyle: TextStyle(color: Colors.grey[400]),
                            prefixIcon: Icon(
                              Icons.person_outline,
                              color: Colors.grey[700],
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 16,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.grey),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.grey),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: controller.isStudentLogin
                                    ? const Color(0xFF6B48D9)
                                    : const Color(0xFF2962FF),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Password Field
                        TextFormField(
                          // textInputAction: .,
                          keyboardType: TextInputType.visiblePassword,
                          controller: controller.password,
                          validator: controller.fieldeValidation,
                          onTapOutside: (event) =>
                              FocusManager.instance.primaryFocus!.unfocus(),
                          obscureText: controller.obscurePassword,
                          decoration: InputDecoration(
                            hintText: 'Password',
                            hintStyle: TextStyle(color: Colors.grey[400]),
                            prefixIcon: Icon(
                              Icons.lock_outline,
                              color: Colors.grey[700],
                            ),
                            suffixIcon: IconButton(
                              icon: Icon(
                                controller.obscurePassword
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                                color: Colors.grey[500],
                              ),
                              onPressed: () {
                                controller.toggelObscurePassword();
                              },
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 16,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: Colors.grey.shade300,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: Colors.grey.shade500,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: controller.isStudentLogin
                                    ? const Color(0xFF6B48D9)
                                    : const Color(0xFF2962FF),
                              ),
                            ),
                          ),
                        ),

                        // Forgot Password
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () {},
                            child: Text(
                              'Forgot Password?',
                              style: TextStyle(
                                color: controller.isStudentLogin
                                    ? const Color(0xFF6B48D9)
                                    : const Color(0xFF2962FF),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),

                        // Login Button
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: controller.isStudentLogin
                                  ? const Color(0xFF6B48D9)
                                  : const Color(0xFF2962FF),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 0,
                            ),
                            onPressed: () {
                              !controller.ispressed
                                  ? controller.login(context)
                                  : null;
                            },
                            child: controller.ispressed
                                ? Center(
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text(
                                    'Login',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                          ),
                        ),
                        // const SizedBox(height: 24),

                        // // Divider
                        // Row(
                        //   children: [
                        //     Expanded(
                        //       child: Divider(
                        //         color: Colors.grey[200],
                        //         thickness: 1,
                        //       ),
                        //     ),
                        //     Padding(
                        //       padding: const EdgeInsets.symmetric(
                        //         horizontal: 16,
                        //       ),
                        //       child: Text(
                        //         'or continue with',
                        //         style: TextStyle(
                        //           color: Colors.grey[500],
                        //           fontSize: 12,
                        //         ),
                        //       ),
                        //     ),
                        //     Expanded(
                        //       child: Divider(
                        //         color: Colors.grey[200],
                        //         thickness: 1,
                        //       ),
                        //     ),
                        //   ],
                        // ),

                        // const SizedBox(height: 24),

                        // // Social Buttons
                        // Row(
                        //   mainAxisAlignment: MainAxisAlignment.center,
                        //   children: [
                        //     _buildSocialButton(
                        //       color: Colors.red,
                        //       text: 'G',
                        //       label: 'Google',
                        //     ),
                        //     const SizedBox(width: 20),
                        //     _buildSocialButton(
                        //       color: Colors.orange[800]!,
                        //       text: 'O',
                        //       label: 'Office',
                        //     ),
                        //   ],
                        // ),
                        // const SizedBox(height: 32),

                        // // Footer
                        // Row(
                        //   mainAxisAlignment: MainAxisAlignment.center,
                        //   children: [
                        //     Text(
                        //       "Don't have an account?",
                        //       style: TextStyle(color: Colors.grey[600]),
                        //     ),
                        //     const SizedBox(width: 4),
                        //     GestureDetector(
                        //       onTap: () {},
                        //       child: Text(
                        //         footerAction,
                        //         style: TextStyle(
                        //           color: activeColor,
                        //           fontWeight: FontWeight.bold,
                        //         ),
                        //       ),
                        //     ),
                        //   ],
                        // ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Helper for placeholder social buttons (Use flutter_svg for real icons in production)
  Widget _buildSocialButton({
    required Color color,
    required String text,
    required String label,
  }) {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      alignment: Alignment.center,
      child: Text(
        text,
        style: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }
}
