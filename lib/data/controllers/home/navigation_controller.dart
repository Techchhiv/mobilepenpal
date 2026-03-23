import 'package:get/get.dart';

class NavigationController extends GetxController {
  NavigationController({int initialIndex = 0})
    : currentIndex = initialIndex.obs;

  final RxInt currentIndex;

  void changePage(int index) {
    currentIndex.value = index;
  }
}
