import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/theme.dart';
import '../providers/test_results_provider.dart';
import '../models/test_result_model.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_text_styles.dart';

class TestResultsScreen extends ConsumerStatefulWidget {
  const TestResultsScreen({super.key});

  @override
  ConsumerState<TestResultsScreen> createState() => _TestResultsScreenState();
}

class _TestResultsScreenState extends ConsumerState<TestResultsScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(
        () => ref.read(testResultsProvider.notifier).load());
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(testResultsProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundGrey,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('Test Results', style: AppTextStyles.titleLarge),
        centerTitle: false,
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : state.error != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.error_outline, size: 48, color: AppColors.errorRed),
                      const SizedBox(height: 16),
                      Text(
                        state.error!,
                        style: TextStyle(color: AppColors.errorRed),
                      ),
                    ],
                  ),
                )
              : state.results.isEmpty
                  ? _buildEmptyState()
                  : RefreshIndicator(
                      onRefresh: () =>
                          ref.read(testResultsProvider.notifier).load(),
                      child: ListView.builder(
                        padding: const EdgeInsets.all(20),
                        itemCount: state.results.length,
                        itemBuilder: (_, i) => TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0, end: 1),
                          duration: Duration(milliseconds: 200 + (i * 60)),
                          curve: Curves.easeOut,
                          builder: (context, v, child) {
                            return Opacity(
                              opacity: v,
                              child: Transform.translate(
                                offset: Offset(0, 20 * (1 - v)),
                                child: child,
                              ),
                            );
                          },
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _ResultCard(
                              result: state.results[i],
                              onTap: () => _showDetail(context, state.results[i]),
                            ),
                          ),
                        ),
                      ),
                    ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.cardWhite,
              shape: BoxShape.circle,
              boxShadow: AppTheme.cardShadow,
            ),
            child: Icon(Icons.science_outlined, size: 40, color: AppColors.textHint),
          ),
          const SizedBox(height: 20),
          Text(
            'No test results yet',
            style: AppTextStyles.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Your lab results will appear here',
            style: AppTextStyles.caption,
          ),
        ],
      ),
    );
  }

  void _showDetail(BuildContext context, TestResultModel r) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (r.isFlagged)
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.statusPending.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.warning_amber,
                          color: AppColors.statusPending, size: 22),
                    ),
                  if (r.isFlagged) const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      r.testName ?? 'Test #${r.testId}',
                      style: AppTextStyles.titleLarge,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _DetailRow(label: 'Date', value: r.resultDate ?? '—'),
              _DetailRow(
                label: 'Value',
                value: '${r.value} ${r.unit ?? ''}',
                valueColor: r.isFlagged ? AppColors.statusPending : null,
              ),
              if (r.normalRange != null)
                _DetailRow(
                    label: 'Normal Range',
                    value: r.normalRange!.display),
              if (r.fastingState != null)
                _DetailRow(label: 'Fasting', value: r.fastingState!),
              if (r.notes != null && r.notes!.isNotEmpty)
                _DetailRow(label: 'Notes', value: r.notes!),
              if (r.isFlagged) ...[
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.statusPending.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppColors.statusPending.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.warning_amber,
                          color: AppColors.statusPending, size: 20),
                      const SizedBox(width: 10),
                      const Expanded(
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
                  child: Text(
                    'Close',
                    style: GoogleFonts.poppins(
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

  const _DetailRow({
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 110,
              child: Text(
                '$label:',
                style: GoogleFonts.poppins(
                  color: AppColors.textGrey,
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
              ),
            ),
            Expanded(
              child: Text(
                value,
                style: GoogleFonts.poppins(
                  color: valueColor ?? AppColors.textDark,
                  fontWeight:
                      valueColor != null ? FontWeight.w600 : FontWeight.w400,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      );
}

class _ResultCard extends StatelessWidget {
  final TestResultModel result;
  final VoidCallback onTap;

  const _ResultCard({required this.result, required this.onTap});

  @override
  Widget build(BuildContext context) => Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.cardWhite,
              borderRadius: BorderRadius.circular(16),
              boxShadow: AppTheme.cardShadow,
              border: result.isFlagged
                  ? Border.all(
                      color: AppColors.statusPending.withValues(alpha: 0.3),
                    )
                  : null,
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: result.isFlagged
                        ? AppColors.statusPendingBg
                        : AppColors.statusConfirmedBg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    result.isFlagged ? Icons.warning_amber : Icons.science,
                    color: result.isFlagged
                        ? AppColors.statusPending
                        : AppColors.statusConfirmed,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              result.testName ?? 'Test',
                              style: AppTextStyles.titleMedium,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (result.isFlagged) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppColors.errorRed,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'FLAGGED',
                                style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${result.value} ${result.unit ?? ''}  •  ${result.resultDate ?? ''}',
                        style: AppTextStyles.bodyGrey,
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: AppColors.textHint),
              ],
            ),
          ),
        ),
      );
}
