import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:mobilepenpal/core/theme/app_colors.dart';
import 'package:mobilepenpal/data/controllers/auth/auth_controller.dart';
import 'package:mobilepenpal/data/controllers/home/home_controller.dart';
import 'package:mobilepenpal/data/models/student/student.dart';

class HomePage extends StatelessWidget {
  HomePage({super.key});

  final HomeController homeController = Get.find<HomeController>();
  final AuthController authController = Get.find<AuthController>();
  final box = GetStorage();

  Student? get student {
    final studentData = box.read('student');
    if (studentData != null && studentData is Map<String, dynamic>) {
      return Student.fromJson(studentData);
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async => homeController.refreshCourses(),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Obx(
              () => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 34,
                            backgroundColor: Colors.grey[200],
                            child: Icon(Icons.person, color: Colors.grey[600]),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "welcome".tr,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                              Text(
                                homeController.currentMode.value == 'student'
                                    ? homeController.fullName
                                    : homeController.parentName,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.1),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: IconButton(
                          onPressed: () {},
                          icon: Stack(
                            children: [
                              const Icon(
                                Icons.notifications_outlined,
                                size: 24,
                              ),
                              Positioned(
                                right: 0,
                                top: 0,
                                child: Container(
                                  width: 8,
                                  height: 8,
                                  decoration: const BoxDecoration(
                                    color: Colors.red,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Simple text mode switcher with moving background
                  Container(
                    padding: const EdgeInsets.all(4),
                    height: 47,
                    decoration: BoxDecoration(
                      color: const Color(0x056E6D66).withOpacity(0.4),
                      borderRadius: const BorderRadius.all(Radius.circular(18)),
                    ),
                    child: Stack(
                      children: [
                        // Moving background
                        AnimatedPositioned(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                          left: homeController.currentMode.value == 'student'
                              ? 0
                              : MediaQuery.of(context).size.width * 0.5 - 32,
                          child: Container(
                            width: MediaQuery.of(context).size.width * 0.5 - 32,
                            height: 39,
                            decoration: BoxDecoration(
                              color: AppColors
                                  .primary, // Use your app's primary color
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                        // Text buttons in row
                        Row(
                          children: [
                            Expanded(
                              child: GestureDetector(
                                onTap: () =>
                                    homeController.setCurrentMode('student'),
                                child: Container(
                                  height: 39,
                                  child: Center(
                                    child: Text(
                                      'Student',
                                      style: TextStyle(
                                        color:
                                            homeController.currentMode.value ==
                                                'student'
                                            ? Colors.white
                                            : Colors.grey[600],
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                              child: GestureDetector(
                                onTap: () =>
                                    homeController.setCurrentMode('parent'),
                                child: Container(
                                  height: 39,
                                  child: Center(
                                    child: Text(
                                      'Parent',
                                      style: TextStyle(
                                        color:
                                            homeController.currentMode.value ==
                                                'parent'
                                            ? Colors.white
                                            : Colors.grey[600],
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Content based on selected mode
                  Obx(() {
                    if (homeController.currentMode.value == 'student') {
                      return _buildStudentContent();
                    } else {
                      return _buildParentContent();
                    }
                  }),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStudentContent() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Student Dashboard',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Welcome to your student dashboard! Here you can access your courses, track your progress, and continue learning.',
            style: TextStyle(color: Colors.grey[600]),
          ),
          // Add more student-specific content here
        ],
      ),
    );
  }

  Widget _buildParentContent() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Parent Dashboard',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Welcome to the parent dashboard! Here you can monitor your child\'s progress, view reports, and manage settings.',
            style: TextStyle(color: Colors.grey[600]),
          ),
          // Add more parent-specific content here
        ],
      ),
    );
  }
}
