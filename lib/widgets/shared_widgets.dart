import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

// ─── Shimmer replacement — pure Flutter animated skeleton ────────────────────
class ShimmerCard extends StatefulWidget {
  final double height;
  const ShimmerCard({super.key, this.height = 100});
  @override
  State<ShimmerCard> createState() => _ShimmerCardState();
}

class _ShimmerCardState extends State<ShimmerCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200))
      ..repeat(reverse: true);
    _anim = Tween(begin: 0.4, end: 1.0).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _anim,
      child: Container(
        height: widget.height,
        margin: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }
}

class ShimmerList extends StatelessWidget {
  final int count;
  final double itemHeight;
  const ShimmerList({super.key, this.count = 4, this.itemHeight = 100});

  @override
  Widget build(BuildContext context) => Column(
        children: List.generate(count, (_) => ShimmerCard(height: itemHeight)),
      );
}

// ─── Stat card ────────────────────────────────────────────────────────────────
class StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const StatCard({super.key, required this.label, required this.value,
      required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: 0.16)),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.10),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.13),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              Icon(Icons.trending_up_rounded,
                  color: color.withValues(alpha: 0.55), size: 18),
            ],
          ),
          const Spacer(),
          Text(value,
              style: TextStyle(
                  fontSize: 26,
                  height: 1,
                  fontWeight: FontWeight.w800,
                  color: color)),
          const SizedBox(height: 5),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.bodySmall.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.textDark,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Section header ───────────────────────────────────────────────────────────
class SectionHeader extends StatelessWidget {
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;
  const SectionHeader({super.key, required this.title, this.actionLabel, this.onAction});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: AppTextStyles.h3),
        if (actionLabel != null)
          TextButton(
            onPressed: onAction,
            child: Text(actionLabel!,
                style: const TextStyle(
                    color: AppColors.secondary, fontWeight: FontWeight.w600)),
          ),
      ],
    );
  }
}

// ─── Status chip ──────────────────────────────────────────────────────────────
class StatusChip extends StatelessWidget {
  final String label;
  final Color color;
  const StatusChip({super.key, required this.label, required this.color});

  factory StatusChip.fromStatus(String status) {
    Color color;
    switch (status.toLowerCase()) {
      case 'active': case 'approved': case 'completed': case 'confirmed':
        color = AppColors.success; break;
      case 'pending': case 'enrolled':
        color = AppColors.warning; break;
      case 'rejected': case 'suspended': case 'inactive':
        color = AppColors.error; break;
      default: color = AppColors.textGrey;
    }
    return StatusChip(label: status.toUpperCase(), color: color);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(label,
          style: TextStyle(
              color: color, fontSize: 11, fontWeight: FontWeight.w700)),
    );
  }
}

// ─── Empty state ──────────────────────────────────────────────────────────────
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  const EmptyState({super.key, required this.icon, required this.title, this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 64, color: AppColors.lightGrey),
            const SizedBox(height: 16),
            Text(title,
                style: AppTextStyles.h4.copyWith(color: AppColors.textGrey),
                textAlign: TextAlign.center),
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(subtitle!, style: AppTextStyles.bodySmall,
                  textAlign: TextAlign.center),
            ],
          ],
        ),
      ),
    );
  }
}

// ─── Error state ──────────────────────────────────────────────────────────────
class ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;
  const ErrorState({super.key, required this.message, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wifi_off_rounded, size: 56, color: AppColors.textGrey),
            const SizedBox(height: 16),
            const Text('Something went wrong', style: AppTextStyles.h4),
            const SizedBox(height: 8),
            Text(message, style: AppTextStyles.bodySmall, textAlign: TextAlign.center),
            if (onRetry != null) ...[
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─── Gradient button (no external deps) ──────────────────────────────────────
class GradientButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  final IconData? icon;
  const GradientButton({super.key, required this.label, this.onPressed,
      this.loading = false, this.icon});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: loading ? null : onPressed,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        height: 52,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: loading
                ? [Colors.grey[400]!, Colors.grey[300]!]
                : [AppColors.secondary, AppColors.primary],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(14),
          boxShadow: loading ? [] : [
            BoxShadow(
              color: AppColors.secondary.withValues(alpha: 0.4),
              blurRadius: 12, offset: const Offset(0, 4),
            )
          ],
        ),
        child: Center(
          child: loading
              ? const SizedBox(
                  height: 22, width: 22,
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2.5))
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (icon != null) ...[
                      Icon(icon, color: Colors.white, size: 20),
                      const SizedBox(width: 8),
                    ],
                    Text(label,
                        style: const TextStyle(
                            color: Colors.white, fontSize: 16,
                            fontWeight: FontWeight.w700, letterSpacing: 0.3)),
                  ],
                ),
        ),
      ),
    );
  }
}

// ─── Course card (no cached_network_image) ────────────────────────────────────
class CourseCard extends StatelessWidget {
  final dynamic course;
  final VoidCallback? onTap;
  final bool showProgress;
  const CourseCard({super.key, required this.course, this.onTap, this.showProgress = false});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 10, offset: const Offset(0, 4)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Gradient header — no image needed
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: Container(
                height: 110,
                width: double.infinity,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppColors.primary, AppColors.secondary],
                  ),
                ),
                child: Center(
                  child: Icon(_courseIcon(course.icon ?? ''),
                      color: Colors.white.withValues(alpha: 0.85), size: 44),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(course.title, style: AppTextStyles.h4,
                      maxLines: 2, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 6),
                  Row(children: [
                    const Icon(Icons.access_time_rounded,
                        size: 13, color: AppColors.textGrey),
                    const SizedBox(width: 4),
                    Text(course.duration ?? 'Flexible', style: AppTextStyles.bodySmall),
                    const SizedBox(width: 12),
                    const Icon(Icons.laptop_mac_rounded,
                        size: 13, color: AppColors.textGrey),
                    const SizedBox(width: 4),
                    Text(_modeLabel(course.learningMode), style: AppTextStyles.bodySmall),
                  ]),
                  if (showProgress && course.progress != null) ...[
                    const SizedBox(height: 10),
                    Row(children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: (course.progress ?? 0) / 100,
                            backgroundColor: AppColors.lightGrey,
                            valueColor: const AlwaysStoppedAnimation(AppColors.secondary),
                            minHeight: 6,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text('${course.progress?.toStringAsFixed(0)}%',
                          style: const TextStyle(
                              fontSize: 11, fontWeight: FontWeight.w700,
                              color: AppColors.secondary)),
                    ]),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _modeLabel(String mode) {
    switch (mode) {
      case 'physical': return 'Physical';
      case 'online': return 'Online';
      default: return 'Hybrid';
    }
  }

  IconData _courseIcon(String icon) {
    if (icon.contains('brain')) return Icons.psychology_rounded;
    if (icon.contains('bitcoin') || icon.contains('crypto')) return Icons.currency_bitcoin;
    if (icon.contains('chart')) return Icons.bar_chart_rounded;
    if (icon.contains('marketing') || icon.contains('bullhorn')) return Icons.campaign_rounded;
    if (icon.contains('shield') || icon.contains('cyber')) return Icons.security_rounded;
    if (icon.contains('code')) return Icons.code_rounded;
    if (icon.contains('design') || icon.contains('palette')) return Icons.palette_rounded;
    if (icon.contains('headphone') || icon.contains('va')) return Icons.headset_mic_rounded;
    if (icon.contains('rocket') || icon.contains('teen')) return Icons.rocket_launch_rounded;
    return Icons.menu_book_rounded;
  }
}

// ─── Notification tile ────────────────────────────────────────────────────────
class NotificationTile extends StatelessWidget {
  final dynamic notification;
  final VoidCallback? onTap;
  const NotificationTile({super.key, required this.notification, this.onTap});

  @override
  Widget build(BuildContext context) {
    final bool isRead = notification.isRead;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isRead ? AppColors.white : AppColors.secondary.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isRead ? AppColors.lightGrey : AppColors.secondary.withValues(alpha: 0.2),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _typeColor(notification.type).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(_typeIcon(notification.type),
                  color: _typeColor(notification.type), size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Expanded(
                      child: Text(notification.title,
                          style: AppTextStyles.h4.copyWith(fontSize: 14),
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                    ),
                    if (!isRead)
                      Container(
                        width: 8, height: 8,
                        decoration: const BoxDecoration(
                            color: AppColors.secondary, shape: BoxShape.circle),
                      ),
                  ]),
                  if (notification.message != null) ...[
                    const SizedBox(height: 4),
                    Text(notification.message!, style: AppTextStyles.bodySmall,
                        maxLines: 2, overflow: TextOverflow.ellipsis),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _typeColor(String type) {
    switch (type) {
      case 'lesson': return AppColors.secondary;
      case 'assignment': case 'deadline': return AppColors.warning;
      case 'certificate': case 'completion': return AppColors.success;
      default: return AppColors.textGrey;
    }
  }

  IconData _typeIcon(String type) {
    switch (type) {
      case 'lesson': return Icons.menu_book_rounded;
      case 'assignment': return Icons.assignment_rounded;
      case 'deadline': return Icons.timer_rounded;
      case 'certificate': return Icons.workspace_premium_rounded;
      case 'completion': return Icons.check_circle_rounded;
      case 'announcement': return Icons.campaign_rounded;
      default: return Icons.notifications_rounded;
    }
  }
}
