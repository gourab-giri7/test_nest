import 'package:flutter/material.dart';

class DasboardController extends ChangeNotifier {
  int currentNavIndex = 0;

  void switchTab(int index) {
    if (currentNavIndex == index) return;
    currentNavIndex = index;
    notifyListeners();
  }
}
