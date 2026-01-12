import 'package:get/get.dart';
import 'package:mobilepenpal/data/models/classroom/classroom_detail.dart';
import 'package:mobilepenpal/data/services/classroom_service.dart';

class ClassroomController extends GetxController {
  final int classroomId;
  ClassroomController({required this.classroomId});

  final ClassroomService _service = ClassroomService();

  var isLoading = false.obs;
  var detail = Rxn<ClassroomDetail>();
  var errorText = ''.obs;

  @override
  void onInit() {
    super.onInit();
    fetchDetail();
  }

  Future<void> fetchDetail() async {
    if (isLoading.value) return;

    isLoading.value = true;
    errorText.value = '';
    try {
      final res = await _service.getClassroomDetail(classroomId);

      if (res.code == 200 && res.data != null) {
        detail.value = res.data!;
      } else {
        detail.value = null;
        errorText.value = res.message;
      }
    } catch (e) {
      detail.value = null;
      errorText.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }
}
