import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:mobilepenpal/data/models/report/monthly_summary.dart';
import 'package:mobilepenpal/data/services/home_service.dart';
import 'package:mobilepenpal/core/utils/report_format.dart';

class ReportController extends GetxController {
  final HomeService _homeService = HomeService();

  final isLoading = false.obs;
  final selectedMonth = DateTime.now().obs;

  final monthly = Rxn<MonthlySummary>();

  final sortAccuracyDesc = false.obs;
  void toggleAccuracySort() => sortAccuracyDesc.value = !sortAccuracyDesc.value;

  String get monthKey => DateFormat('yyyy-MM').format(selectedMonth.value);
  String get monthLabel => selectedMonth.value.toShortMonthLabel();

  @override
  void onInit() {
    super.onInit();
    fetchMonthly();
  }

  Future<void> fetchMonthly() async {
    if (isLoading.value) return;

    isLoading.value = true;
    try {
      final res = await _homeService.getMonthlySummary(month: monthKey);

      if (res.code == 200 && res.data != null) {
        monthly.value = res.data!;
      }
    } finally {
      isLoading.value = false;
    }
  }

  void prevMonth() {
    final d = selectedMonth.value;
    selectedMonth.value = DateTime(d.year, d.month - 1, 1);
    fetchMonthly();
  }

  void nextMonth() {
    final d = selectedMonth.value;
    selectedMonth.value = DateTime(d.year, d.month + 1, 1);
    fetchMonthly();
  }
}
