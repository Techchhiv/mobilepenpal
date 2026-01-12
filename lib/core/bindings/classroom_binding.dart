import 'package:get/get.dart';
import 'package:mobilepenpal/data/controllers/classroom/classroom_controller.dart';

class ClassroomBinding implements Bindings {
  @override
  void dependencies() {
    final idStr = Get.parameters['classroomId'];
    final id = int.tryParse(idStr ?? '');

    if (id == null) {
      Get.lazyPut<ClassroomController>(() => ClassroomController(classroomId: 0));
      return;
    }

    Get.lazyPut<ClassroomController>(() => ClassroomController(classroomId: id));
  }
}
