// import 'package:flutter/material.dart';
// import 'package:go_router/go_router.dart';

// Future<dynamic> coustomDialog(
//   String title,
//   context,
//   VoidCallback fun,
//   String positive,
//   String negative,
// ) {
//   return showDialog(
//     context: context,
//     builder: (context) {
//       return AlertDialog(
//         backgroundColor: Colors.white,
//         title: Text(
//           title,
//           style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
//           textAlign: TextAlign.center,
//         ),
//         content: Row(
//           spacing: 10,
//           children: [
//             Expanded(
//               child: ElevatedButton(
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: Colors.red[100],
//                   foregroundColor: const Color(0xFF972820),
//                   elevation: 0,
//                   shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(15),
//                   ),
//                 ),
//                 onPressed: () => context.pop(),
//                 child: Text(negative),
//               ),
//             ),
//             Expanded(
//               child: ElevatedButton(
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: Colors.green[100],
//                   foregroundColor: const Color(0xFF357937),
//                   elevation: 0,
//                   shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(15),
//                   ),
//                 ),
//                 onPressed: fun,
//                 child: Text(positive),
//               ),
//             ),
//           ],
//         ),
//       );
//     },
//   );
// }
