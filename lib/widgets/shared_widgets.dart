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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  color.withValues(alpha: 0.15),
                  color.withValues(alpha: 0.08),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const Spacer(),
          Text(value,
              style: TextStyle(
                  fontSize: 28,
                  height: 1,
                  fontWeight: FontWeight.w800,
                  color: color)),
          const SizedBox(height: 6),
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
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.06),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 48, color: AppColors.primary.withValues(alpha: 0.4)),
            ),
            const SizedBox(height: 20),
            Text(title,
                style: AppTextStyles.h4.copyWith(color: AppColors.textDark),
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
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 12, offset: const Offset(0, 4)),
            BoxShadow(color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 4, offset: const Offset(0, 2)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              child: Container(
                height: 120,
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: _courseGradient(course.icon ?? ''),
                  ),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      right: -20,
                      top: -20,
                      child: Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.08),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                    Positioned(
                      left: 16,
                      bottom: 16,
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.25),
                          ),
                        ),
                        child: Icon(_courseIcon(course.icon ?? ''),
                            color: Colors.white, size: 28),
                      ),
                    ),
                    Positioned(
                      right: 16,
                      bottom: 16,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _modeLabel(course.learningMode),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(course.title, style: AppTextStyles.h4,
                      maxLines: 2, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 8),
                  Row(children: [
                    Icon(Icons.access_time_rounded,
                        size: 14, color: AppColors.textGrey),
                    const SizedBox(width: 4),
                    Text(course.duration ?? 'Flexible', style: AppTextStyles.bodySmall),
                  ]),
                  if (showProgress && course.progress != null) ...[
                    const SizedBox(height: 12),
                    Row(children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: LinearProgressIndicator(
                            value: (course.progress ?? 0) / 100,
                            backgroundColor: AppColors.lightGrey,
                            valueColor: const AlwaysStoppedAnimation(AppColors.primary),
                            minHeight: 8,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text('${course.progress?.toStringAsFixed(0)}%',
                          style: const TextStyle(
                              fontSize: 12, fontWeight: FontWeight.w700,
                              color: AppColors.primary)),
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

  List<Color> _courseGradient(String icon) {
    if (icon.contains('brain') || icon.contains('ai')) {
      return [const Color(0xFF6366F1), const Color(0xFF8B5CF6)];
    }
    if (icon.contains('bitcoin') || icon.contains('crypto')) {
      return [const Color(0xFFF59E0B), const Color(0xFFD97706)];
    }
    if (icon.contains('shield') || icon.contains('cyber')) {
      return [const Color(0xFF0EA5E9), const Color(0xFF0284C7)];
    }
    if (icon.contains('chart')) {
      return [const Color(0xFF10B981), const Color(0xFF059669)];
    }
    if (icon.contains('marketing') || icon.contains('bullhorn')) {
      return [const Color(0xFFE11D48), const Color(0xFFBE123C)];
    }
    if (icon.contains('code')) {
      return [const Color(0xFF3B82F6), const Color(0xFF2563EB)];
    }
    if (icon.contains('design') || icon.contains('palette')) {
      return [const Color(0xFFEC4899), const Color(0xFFDB2777)];
    }
    if (icon.contains('headphone') || icon.contains('va')) {
      return [const Color(0xFF8B5CF6), const Color(0xFF7C3AED)];
    }
    if (icon.contains('rocket') || icon.contains('teen')) {
      return [const Color(0xFFF97316), const Color(0xFFEA580C)];
    }
    return [AppColors.primary, const Color(0xFF6366F1)];
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
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isRead ? AppColors.white : AppColors.primary.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isRead ? AppColors.divider : AppColors.primary.withValues(alpha: 0.15),
          ),
          boxShadow: isRead ? [] : [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: _typeColor(notification.type).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(_typeIcon(notification.type),
                  color: _typeColor(notification.type), size: 20),
            ),
            const SizedBox(width: 14),
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
                            color: AppColors.primary, shape: BoxShape.circle),
                      ),
                  ]),
                  if (notification.message != null) ...[
                    const SizedBox(height: 6),
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
