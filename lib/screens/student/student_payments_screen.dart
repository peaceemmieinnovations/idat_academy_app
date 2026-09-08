import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../models/models.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/shared_widgets.dart';

class StudentPaymentsScreen extends StatefulWidget {
  const StudentPaymentsScreen({super.key});

  @override
  State<StudentPaymentsScreen> createState() => _StudentPaymentsScreenState();
}

class _StudentPaymentsScreenState extends State<StudentPaymentsScreen> {
  List<Payment> _payments = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final res = await ApiService.getStudentPayments();
    if (mounted) {
      if (res['error'] != null) {
        setState(() {
          _error = res['error'];
          _loading = false;
        });
      } else {
        final data = res['data'] as List? ?? const [];
        setState(() {
          _payments = data
              .whereType<Map>()
              .map((m) => Payment.fromJson(Map<String, dynamic>.from(m)))
              .toList();
          _loading = false;
        });
      }
    }
  }

  Future<void> _recordPayment() async {
    final amountCtrl = TextEditingController();
    final referenceCtrl = TextEditingController();
    File? proof;
    String? proofName;
    bool submitting = false;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) {
          Future<void> submit() async {
            final amount = double.tryParse(amountCtrl.text.trim());
            if (amount == null || amount <= 0) {
              ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(
                  content: Text('Enter a valid amount'),
                  backgroundColor: AppColors.error));
              return;
            }
            setModal(() => submitting = true);
            final res = await ApiService.recordPayment(
              amount: amount,
              proofFile: proof,
              reference: referenceCtrl.text.trim().isEmpty
                  ? null
                  : referenceCtrl.text.trim(),
            );
            if (!mounted) return;
            setModal(() => submitting = false);
            Navigator.pop(ctx);
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(res['error'] == null
                  ? 'Payment recorded! Awaiting verification.'
                  : res['error'].toString()),
              backgroundColor: res['error'] == null
                  ? AppColors.success
                  : AppColors.error,
            ));
            if (res['error'] == null) _load();
          }

          return Container(
            decoration: const BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: EdgeInsets.fromLTRB(
                20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Record Payment', style: AppTextStyles.h3),
                  const SizedBox(height: 4),
                  const Text(
                      'Payments are reviewed by the academy before approval.',
                      style: AppTextStyles.bodySmall),
                  const SizedBox(height: 20),
                  TextField(
                    controller: amountCtrl,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                        labelText: 'Amount (₦)',
                        prefixIcon: Icon(Icons.payments_outlined)),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: referenceCtrl,
                    decoration: const InputDecoration(
                        labelText: 'Reference / Note (optional)',
                        prefixIcon: Icon(Icons.receipt_long_outlined)),
                  ),
                  const SizedBox(height: 14),
                  GestureDetector(
                    onTap: () async {
                      final result = await FilePicker.platform.pickFiles();
                      if (result != null) {
                        setModal(() {
                          proof = File(result.files.single.path!);
                          proofName = result.files.single.name;
                        });
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: Border.all(
                            color: proof != null
                                ? AppColors.success
                                : AppColors.lightGrey),
                        borderRadius: BorderRadius.circular(12),
                        color: proof != null
                            ? AppColors.success.withValues(alpha: 0.05)
                            : AppColors.surface,
                      ),
                      child: Row(
                        children: [
                          Icon(
                              proof != null
                                  ? Icons.check_circle_rounded
                                  : Icons.upload_file_rounded,
                              color: proof != null
                                  ? AppColors.success
                                  : AppColors.textGrey),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              proofName ?? 'Attach payment proof (optional)',
                              style: TextStyle(
                                  color: proof != null
                                      ? AppColors.success
                                      : AppColors.textGrey,
                                  fontSize: 14),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  GradientButton(
                    label: 'Submit Payment',
                    icon: Icons.send_rounded,
                    loading: submitting,
                    onPressed: submit,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Payments')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _recordPayment,
        backgroundColor: AppColors.secondary,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text('Record Payment',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
      ),
      body: _loading
          ? const Padding(
              padding: EdgeInsets.all(16),
              child: ShimmerList(count: 5, itemHeight: 90))
          : _error != null
              ? ErrorState(message: _error!, onRetry: _load)
              : _payments.isEmpty
                  ? const EmptyState(
                      icon: Icons.account_balance_wallet_outlined,
                      title: 'No payments recorded',
                      subtitle:
                          'Your fee payments will appear here. You can also record a new payment.',
                    )
                  : RefreshIndicator(
                      onRefresh: _load,
                      color: AppColors.secondary,
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                        itemCount: _payments.length,
                        itemBuilder: (_, i) =>
                            _PaymentTile(payment: _payments[i]),
                      ),
                    ),
    );
  }
}

class _PaymentTile extends StatelessWidget {
  final Payment payment;
  const _PaymentTile({required this.payment});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '₦${_formatAmount(payment.amount)}',
                  style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: AppColors.dark),
                ),
              ),
              StatusChip.fromStatus(payment.status),
            ],
          ),
          if (payment.courseTitle?.isNotEmpty ?? false) ...[
            const SizedBox(height: 4),
            Text(payment.courseTitle!,
                style: AppTextStyles.bodySmall
                    .copyWith(color: AppColors.secondary)),
          ],
          if (payment.reference?.isNotEmpty ?? false) ...[
            const SizedBox(height: 6),
            Text('Reference: ${payment.reference}',
                style: AppTextStyles.bodySmall),
          ],
          if (payment.proofFile?.isNotEmpty ?? false) ...[
            const SizedBox(height: 8),
            Row(children: [
              const Icon(Icons.attach_file_rounded,
                  size: 14, color: AppColors.textGrey),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  payment.proofFile ?? '',
                  style: AppTextStyles.bodySmall,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ]),
          ],
          if (payment.createdAt.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text('Submitted ${_fmtDate(payment.createdAt)}',
                style: AppTextStyles.bodySmall),
          ],
        ],
      ),
    );
  }

  String _formatAmount(double amount) {
    return amount.toStringAsFixed(
        amount == amount.roundToDouble() ? 0 : 2);
  }

  String _fmtDate(String raw) {
    final dt = DateTime.tryParse(raw);
    if (dt == null) return raw;
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }
}