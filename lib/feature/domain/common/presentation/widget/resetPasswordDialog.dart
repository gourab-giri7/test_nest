// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import 'package:resume_xpert/features/presentation/screens/loginScreen/controller/loginController.dart';

// Future<void> resetPasswordDialog(
//   BuildContext context, {
//   required VoidCallback onBack,
// }) {
//   return showDialog(
//     context: context,
//     barrierDismissible: false,
//     builder: (context) {
//       return Consumer<Logincontroller>(
//         builder: (context, controller, child) => Dialog(
//           backgroundColor: Colors.white,
//           insetPadding: const EdgeInsets.symmetric(horizontal: 20),
//           shape: RoundedRectangleBorder(
//             borderRadius: BorderRadius.circular(20),
//           ),

//           child: Padding(
//             padding: const EdgeInsets.all(24),

//             child: Form(
//               key: controller.resetPasswordformKey,
//               child: Column(
//                 mainAxisSize: MainAxisSize.min,
//                 children: [
//                   /// ICON
//                   Container(
//                     height: 70,
//                     width: 70,
//                     decoration: BoxDecoration(
//                       color: Colors.blueAccent.withAlpha(50),
//                       shape: BoxShape.circle,
//                     ),
//                     child: const Icon(
//                       Icons.restart_alt_rounded,
//                       color: Colors.blueAccent,
//                       size: 35,
//                     ),
//                   ),

//                   const SizedBox(height: 20),

//                   /// TITLE
//                   const Text(
//                     "Forgot Password?",
//                     style: TextStyle(
//                       fontSize: 24,
//                       fontWeight: FontWeight.bold,
//                       fontFamily: 'Georgia',
//                     ),
//                   ),

//                   const SizedBox(height: 10),

//                   /// DESCRIPTION
//                   const Text(
//                     "Enter your email address and we'll send you\ninstructions to reset your password.",
//                     textAlign: TextAlign.center,
//                     style: TextStyle(color: Colors.grey, height: 1.4),
//                   ),

//                   const SizedBox(height: 25),

//                   /// EMAIL LABEL
//                   const Align(
//                     alignment: Alignment.centerLeft,
//                     child: Text(
//                       "Email Address",
//                       style: TextStyle(fontWeight: FontWeight.bold),
//                     ),
//                   ),

//                   const SizedBox(height: 8),

//                   /// EMAIL FIELD
//                   TextFormField(
//                     keyboardType: TextInputType.emailAddress,
//                     controller: controller.resetPasswordemail,
//                     cursorColor: Colors.blueAccent,
//                     validator: (value) => controller.emailValidator(value),
//                     decoration: InputDecoration(
//                       prefixIcon: const Icon(
//                         Icons.email,
//                         color: Colors.blueAccent,
//                       ),
//                       hintText: "your@email.com",
//                       filled: true,
//                       fillColor: Colors.grey.shade100,
//                       border: OutlineInputBorder(
//                         borderRadius: BorderRadius.circular(10),
//                         borderSide: BorderSide.none,
//                       ),
//                     ),
//                   ),

//                   const SizedBox(height: 25),

//                   /// RESET BUTTON
//                   SizedBox(
//                     width: double.infinity,
//                     height: 50,
//                     child: ElevatedButton(
//                       onPressed: () {
//                         controller.resetPassword(context);
//                       },
//                       style: ElevatedButton.styleFrom(
//                         backgroundColor: Colors.blueAccent,
//                         shape: RoundedRectangleBorder(
//                           borderRadius: BorderRadius.circular(12),
//                         ),
//                       ),
//                       child: controller.isLoadReset
//                           ? CircularProgressIndicator(color: Colors.white)
//                           : Row(
//                               mainAxisAlignment: MainAxisAlignment.center,
//                               children: [
//                                 Text(
//                                   "Reset Password",
//                                   style: TextStyle(
//                                     fontSize: 16,
//                                     color: Theme.of(
//                                       context,
//                                     ).colorScheme.surface,
//                                   ),
//                                 ),
//                                 SizedBox(width: 6),
//                                 Icon(Icons.arrow_forward, color: Colors.white),
//                               ],
//                             ),
//                     ),
//                   ),

//                   const SizedBox(height: 18),

//                   /// BACK TO LOGIN
//                   TextButton(
//                     onPressed: () {
//                       onBack();
//                       // Forgotpasswordcontroller.emailController.clear();
//                     },
//                     child: const Text(
//                       "< Back to Login",
//                       style: TextStyle(
//                         color: Colors.blueAccent,
//                         fontWeight: FontWeight.w600,
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         ),
//       );
//     },
//   );
// }
