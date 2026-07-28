import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../widgets/shared_widgets.dart';

class TutorStudentProfileScreen extends StatelessWidget {
  final Map<String, dynamic> student;

  const TutorStudentProfileScreen({super.key, required this.student});

  @override
  Widget build(BuildContext context) {
    final name = '${student['first_name'] ?? ''} ${student['last_name'] ?? ''}';
    final email = student['email'] ?? '';
    final phone = student['phone'] ?? 'N/A';
    final status = student['enrollment_status'] ?? 'active';
    final photo = student['photo'];
    final address = student['address'] ?? 'N/A';
    final enrolledAt = student['enrolled_at'] ?? '';
    final initial = name.trim().isNotEmpty ? name[0].toUpperCase() : '?';

    return Scaffold(
      appBar: AppBar(title: Text(name.trim().isNotEmpty ? name : 'Student Profile')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            CircleAvatar(
              radius: 50,
              backgroundColor: AppColors.secondary.withValues(alpha: 0.15),
              backgroundImage: (photo != null && photo.toString().startsWith('http'))
                  ? NetworkImage(photo.toString())
                  : null,
              child: photo == null || !photo.toString().startsWith('http')
                  ? Text(initial,
                      style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: AppColors.secondary))
                  : null,
            ),
            const SizedBox(height: 16),
            Text(name, style: AppTextStyles.h2, textAlign: TextAlign.center),
            const SizedBox(height: 4),
            StatusChip.fromStatus(status),
            const SizedBox(height: 24),
            _InfoTile(icon: Icons.email_outlined, label: 'Email', value: email),
            _InfoTile(icon: Icons.phone_outlined, label: 'Phone', value: phone),
            _InfoTile(icon: Icons.location_on_outlined, label: 'Address', value: address),
            if (enrolledAt.isNotEmpty)
              _InfoTile(icon: Icons.calendar_today_rounded, label: 'Enrolled', value: enrolledAt),
          ],
        ),
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoTile({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 2))
          ],
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.secondary, size: 22),
            const SizedBox(width: 14),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textGrey, fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(value, style: AppTextStyles.body),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
