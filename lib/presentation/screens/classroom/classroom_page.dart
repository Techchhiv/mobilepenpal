import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mobilepenpal/core/config/env.dart';
import 'package:mobilepenpal/core/theme/app_colors.dart';
import 'package:mobilepenpal/core/utils/number_format_utils.dart';
import 'package:mobilepenpal/data/controllers/classroom/classroom_controller.dart';
import 'package:mobilepenpal/data/models/classroom/classroom_detail.dart';
import 'package:shimmer/shimmer.dart';
import 'package:mobilepenpal/core/utils/report_format.dart';

class ClassroomPage extends GetView<ClassroomController> {
  final int classroomId;

  const ClassroomPage({super.key, required this.classroomId});

  static const Color _brand = Color(0xFF00897B);

  @override
  Widget build(BuildContext context) {
    final c = controller;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        title: Text('classroom'.tr),
      ),
      body: Obx(() {
        final loading = c.isLoading.value;
        final detail = c.detail.value;
        final err = c.errorText.value;

        return RefreshIndicator(
          color: _brand,
          onRefresh: () async => c.fetchDetail(),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            children: [
              if (loading && detail == null) _HeaderShimmer(),
              if (!loading && detail != null) _HeaderCard(detail: detail),

              const SizedBox(height: 14),

              _sectionTitle('classmates'.tr),
              const SizedBox(height: 10),

              if (loading && detail == null)
                ...List.generate(6, (_) => _RowShimmer()),
              if (!loading && err.isNotEmpty)
                _errorBox(err, onRetry: c.fetchDetail),
              if (!loading && detail != null)
                _ClassmateList(classmates: detail.classmates),
            ],
          ),
        );
      }),
    );
  }

  Widget _sectionTitle(String t) {
    return Text(
      t,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w900,
        color: Colors.black87,
      ),
    );
  }

  Widget _errorBox(String msg, {required Future<void> Function() onRetry}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(msg, style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          SizedBox(
            height: 40,
            child: FilledButton(
              style: FilledButton.styleFrom(backgroundColor: _brand),
              onPressed: () => onRetry(),
              child: Text('retry'.tr),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderCard extends StatelessWidget {
  final ClassroomDetail detail;
  const _HeaderCard({required this.detail});

  static const Color _brand = Color(0xFF00897B);

  @override
  Widget build(BuildContext context) {
    final t = detail.teacher?.name ?? '—';
    final enrolled = detail.enrollment?.enrolledAt;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
        border: Border.all(color: Colors.black.withValues(alpha: 0.03)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 6,
                height: 54,
                decoration: BoxDecoration(
                  color: _brand.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            detail.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        _statusBadge(detail.isActive),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${'teacher'.tr}: $t',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${'student'.tr}: ${NumberFormatUtils.intText(detail.studentsCount)}',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[700],
                      ),
                    ),
                    if (enrolled != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        '${'joined'.tr}: ${detail.enrollment?.enrolledAt?.toJoinDateLabel() ?? '—'}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statusBadge(bool active) {
    final bg = (active ? const Color(0xFF22C55E) : const Color(0xFF9CA3AF))
        .withValues(alpha: 0.14);
    final fg = active ? const Color(0xFF16A34A) : const Color(0xFF6B7280);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        active ? 'active'.tr : 'inactive'.tr,
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: fg),
      ),
    );
  }
}

class _ClassmateList extends StatelessWidget {
  final List<Classmate> classmates;
  const _ClassmateList({required this.classmates});

  @override
  Widget build(BuildContext context) {
    if (classmates.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
        ),
        child: Text(
          'no_classmates'.tr,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
      );
    }

    return Column(
      children: classmates.map((s) => _ClassmateRow(s: s)).toList(),
    );
  }
}

class _ClassmateRow extends StatelessWidget {
  final Classmate s;
  const _ClassmateRow({required this.s});

  @override
  Widget build(BuildContext context) {
    final avatar = (s.avatar ?? '').trim();

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
        border: Border.all(color: Colors.black.withValues(alpha: 0.03)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: Colors.grey[200],
            backgroundImage: avatar.isNotEmpty
                ? NetworkImage(Env.backendUrl + avatar)
                : null,
            child: avatar.isEmpty
                ? const Icon(Icons.person, color: Colors.white)
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              s.displayName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderShimmer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade200,
      highlightColor: Colors.grey.shade100,
      child: Container(
        height: 110,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
        ),
      ),
    );
  }
}

class _RowShimmer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Shimmer.fromColors(
        baseColor: Colors.grey.shade200,
        highlightColor: Colors.grey.shade100,
        child: Container(
          height: 64,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
          ),
        ),
      ),
    );
  }
}
