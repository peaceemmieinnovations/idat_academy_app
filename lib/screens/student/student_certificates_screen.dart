import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/models.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/shared_widgets.dart';

class StudentCertificatesScreen extends StatefulWidget {
  const StudentCertificatesScreen({super.key});

  @override
  State<StudentCertificatesScreen> createState() =>
      _StudentCertificatesScreenState();
}

class _StudentCertificatesScreenState
    extends State<StudentCertificatesScreen> {
  List<Certificate> _certs = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    final res = await ApiService.getStudentCertificates();
    if (mounted) {
      if (res['error'] != null) {
        setState(() { _error = res['error']; _loading = false; });
      } else {
        final data = res['data'] as List? ?? [];
        setState(() {
          _certs = data.map((c) => Certificate.fromJson(c)).toList();
          _loading = false;
        });
      }
    }
  }

  Future<void> _download(Certificate cert) async {
    if (cert.filePath == null) return;
    final url =
        '${ApiService.baseUrl.replaceAll('/api', '')}/${cert.filePath}';
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Certificates')),
      body: _loading
          ? const Padding(
              padding: EdgeInsets.all(16),
              child: ShimmerList(count: 3, itemHeight: 160))
          : _error != null
              ? ErrorState(message: _error!, onRetry: _load)
              : _certs.isEmpty
                  ? const EmptyState(
                      icon: Icons.workspace_premium_outlined,
                      title: 'No certificates yet',
                      subtitle:
                          'Complete a course to earn your certificate.',
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                      itemCount: _certs.length,
                      itemBuilder: (_, i) => _CertCard(
                        cert: _certs[i],
                        onDownload: () => _download(_certs[i]),
                      ),
                    ),
    );
  }
}

class _CertCard extends StatelessWidget {
  final Certificate cert;
  final VoidCallback onDownload;
  const _CertCard({required this.cert, required this.onDownload});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.15),
              blurRadius: 16,
              offset: const Offset(0, 6)),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF1B0151), Color(0xFF273BE9)],
            ),
          ),
          child: Stack(
            children: [
              // Decorative circles
              Positioned(
                right: -30,
                top: -30,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.05),
                  ),
                ),
              ),
              Positioned(
                right: 20,
                bottom: -20,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.accent.withValues(alpha: 0.15),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.accent.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.workspace_premium_rounded,
                              color: AppColors.accent, size: 24),
                        ),
                        const SizedBox(width: 12),
                        const Text('Certificate of Completion',
                            style: TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                                fontWeight: FontWeight.w500)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(cert.courseTitle,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w800)),
                    const SizedBox(height: 8),
                    Text('Cert #: ${cert.certificateNumber}',
                        style: const TextStyle(
                            color: Colors.white60, fontSize: 12)),
                    const SizedBox(height: 4),
                    Text('Issued: ${cert.issueDate}',
                        style: const TextStyle(
                            color: Colors.white60, fontSize: 12)),
                    const SizedBox(height: 16),
                    GestureDetector(
                      onTap: onDownload,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: AppColors.accent,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.download_rounded,
                                color: AppColors.primary, size: 18),
                            SizedBox(width: 6),
                            Text('Download PDF',
                                style: TextStyle(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
