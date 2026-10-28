import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/test_results_provider.dart';
import '../models/test_result_model.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_text_styles.dart';
import '../core/theme.dart';

class BatchDetailScreen extends ConsumerStatefulWidget {
  final PatientBatch batch;

  const BatchDetailScreen({super.key, required this.batch});

  @override
  ConsumerState<BatchDetailScreen> createState() => _BatchDetailScreenState();
}

class _BatchDetailScreenState extends ConsumerState<BatchDetailScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref.read(patientBatchResultsProvider.notifier).load(widget.batch.batchId),
    );
  }

  String _formatDate(String? iso) {
    if (iso == null || iso.length < 10) return 'Unknown date';
    try {
      final parts = iso.substring(0, 10).split('-');
      if (parts.length != 3) return iso.substring(0, 10);
      const months = [
        '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ];
      final month = int.tryParse(parts[1]) ?? 0;
      return '${months[month]} ${parts[2]}, ${parts[0]}';
    } catch (_) {
      return iso.substring(0, 10);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(patientBatchResultsProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundGrey,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Test Results', style: AppTextStyles.titleLarge),
            Text(
              _formatDate(widget.batch.batchDate),
              style: const TextStyle(fontSize: 12, color: AppColors.textGrey),
            ),
          ],
        ),
        centerTitle: false,
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : state.error != null
              ? _buildError(state.error!)
              : state.results.isEmpty
                  ? _buildEmptyState()
                  : _buildResultsList(state.results),
    );
  }

  Widget _buildError(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(error, style: const TextStyle(color: AppColors.errorRed)),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Text('No results in this batch', style: AppTextStyles.bodyGrey),
    );
  }

  Widget _buildResultsList(List<PatientMedicalResult> results) {
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: results.length,
      itemBuilder: (_, i) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: _ResultCard(result: results[i]),
      ),
    );
  }
}

class _ResultCard extends StatelessWidget {
  final PatientMedicalResult result;

  const _ResultCard({required this.result});

  @override
  Widget build(BuildContext context) {
    final isAbnormal = result.status == 'high' || result.status == 'low';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _showDetail(context, result),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.cardWhite,
            borderRadius: BorderRadius.circular(16),
            boxShadow: AppTheme.cardShadow,
            border: isAbnormal
                ? Border.all(color: AppColors.statusPending.withAlpha(76))
                : null,
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: isAbnormal
                      ? AppColors.statusPendingBg
                      : AppColors.statusConfirmedBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  isAbnormal ? Icons.warning_amber : Icons.science,
                  color: isAbnormal
                      ? AppColors.statusPending
                      : AppColors.statusConfirmed,
                  size: 20,
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
                            result.testName ?? 'Test',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textDark,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isAbnormal)
                          Container(
                            margin: const EdgeInsets.only(left: 6),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.errorRed,
                              borderRadius: BorderRadius.circular(5),
                            ),
                            child: const Text(
                              'FLAGGED',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 8,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${result.testCode ?? "--"}  \u2022  ${result.value} ${result.unit ?? ""}  \u2022  ${result.status}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textGrey,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.textHint, size: 20),
            ],
          ),
        ),
      ),
    );
  }

  void _showDetail(BuildContext context, PatientMedicalResult r) {
    final isAbnormal = r.status == 'high' || r.status == 'low';
    showDialog(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (isAbnormal)
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.statusPending.withAlpha(25),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.warning_amber,
                          color: AppColors.statusPending, size: 22),
                    ),
                  if (isAbnormal) const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      r.testName ?? 'Test',
                      style: AppTextStyles.titleLarge,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _DetailRow(label: 'Test Code', value: r.testCode ?? '--'),
              _DetailRow(label: 'Date', value: r.createdAt ?? '--'),
              _DetailRow(
                label: 'Value',
                value: '${r.value} ${r.unit ?? ''}',
                valueColor: isAbnormal ? AppColors.statusPending : null,
              ),
              _DetailRow(label: 'Status', value: r.status),
              if (isAbnormal) ...[
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.statusPending.withAlpha(20),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppColors.statusPending.withAlpha(76),
                    ),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.warning_amber,
                          color: AppColors.statusPending, size: 20),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'This result is ABNORMAL.\nPlease consult your doctor.',
                          style: TextStyle(
                            color: AppColors.statusPending,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'Close',
                    style: TextStyle(
                      color: AppColors.primaryBlue,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _DetailRow({required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              '$label:',
              style: const TextStyle(
                color: AppColors.textGrey,
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: valueColor ?? AppColors.textDark,
                fontWeight: valueColor != null ? FontWeight.w600 : FontWeight.w400,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
