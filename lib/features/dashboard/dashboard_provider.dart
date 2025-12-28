import 'package:flutter_riverpod/flutter_riverpod.dart';

class DashboardController extends Notifier<int> {
  @override
  int build() {
    return 0; // Default to first tab (New Order)
  }

  void setIndex(int index) {
    state = index;
  }
}

final dashboardControllerProvider = NotifierProvider<DashboardController, int>(
  DashboardController.new,
);
