import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/test_results_provider.dart';
import '../models/test_result_model.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_text_styles.dart';
import '../core/theme.dart';
import 'batch_detail_screen.dart';

class MyTestResultsScreen extends ConsumerStatefulWidget {
  const MyTestResultsScreen({super.key});

  @override
  ConsumerState<MyTestResultsScreen> createState() => _MyTestResultsScreenState();
}

class _MyTestResultsScreenState extends ConsumerState<MyTestResultsScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(patientBatchesProvider.notifier).load());
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(patientBatchesProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundGrey,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('My Test Results', style: AppTextStyles.titleLarge),
        centerTitle: false,
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : state.error != null
              ? _buildError(state.error!)
              : state.batches.isEmpty
                  ? _buildEmptyState()
                  : _buildBatchList(state.batches),
    );
  }

  Widget _buildError(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 48, color: AppColors.errorRed),
            const SizedBox(height: 16),
            Text(error, style: TextStyle(color: AppColors.errorRed)),
          ],
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
          Text('No test results yet', style: AppTextStyles.titleMedium),
          const SizedBox(height: 8),
          Text(
            'Results uploaded by your doctor will appear here',
            style: AppTextStyles.caption,
          ),
        ],
      ),
    );
  }

  Widget _buildBatchList(List<PatientBatch> batches) {
    return RefreshIndicator(
      onRefresh: () => ref.read(patientBatchesProvider.notifier).load(),
      child: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: batches.length,
        itemBuilder: (_, i) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _BatchCard(
            batch: batches[i],
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => BatchDetailScreen(batch: batches[i]),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BatchCard extends StatelessWidget {
  final PatientBatch batch;
  final VoidCallback onTap;

  const _BatchCard({required this.batch, required this.onTap});

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
    return Material(
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
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.primaryBlue.withAlpha(25),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.science,
                  color: AppColors.primaryBlue,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _formatDate(batch.batchDate),
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${batch.resultCount} test${batch.resultCount == 1 ? '' : 's'}',
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textGrey,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primaryBlue.withAlpha(20),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${batch.resultCount}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryBlue,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right, color: AppColors.textHint, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}
