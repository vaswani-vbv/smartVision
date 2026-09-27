import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../scanner/scanner_service.dart';

class MealHistoryScreen extends StatefulWidget {
  const MealHistoryScreen({super.key});

  @override
  State<MealHistoryScreen> createState() => _MealHistoryScreenState();
}

class _MealHistoryScreenState extends State<MealHistoryScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  List<Map<String, dynamic>> _meals = [];

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final history = await ScannerService.getMealHistory();
      if (mounted) {
        setState(() {
          _meals = history;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load meal history.';
        });
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _formatActivityLabel(String activity) {
    switch (activity) {
      case 'light_walk':
        return '15m Walk';
      case '30m_exercise':
        return '30m Exercise';
      case '45m_workout':
        return '45m Workout';
      default:
        return 'Rest / None';
    }
  }

  Color _getSpikeColor(double spike) {
    if (spike < 25) return AppTheme.success;
    if (spike < 50) return AppTheme.warning;
    return AppTheme.danger;
  }

  String _getSpikeRisk(double spike) {
    if (spike < 25) return 'Low Spike';
    if (spike < 50) return 'Moderate';
    return 'High Spike';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: AppTheme.textSecondary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Logged Food & Meals',
          style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppTheme.textSecondary),
            onPressed: _loadHistory,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadHistory,
        color: AppTheme.primary,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
            : _errorMessage != null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, color: AppTheme.danger, size: 48),
                        const SizedBox(height: 12),
                        Text(_errorMessage!, style: const TextStyle(color: AppTheme.textSecondary)),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _loadHistory,
                          style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary),
                          child: const Text('Try Again'),
                        ),
                      ],
                    ),
                  )
                : _meals.isEmpty
                    ? _buildEmptyState()
                    : SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _buildSummaryBanner(),
                            const SizedBox(height: 20),
                            ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: _meals.length,
                              separatorBuilder: (context, index) => const SizedBox(height: 14),
                              itemBuilder: (context, index) {
                                return _buildMealCard(_meals[index]);
                              },
                            ),
                            const SizedBox(height: 32),
                          ],
                        ),
                      ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Container(
        height: MediaQuery.of(context).size.height * 0.7,
        alignment: Alignment.center,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.restaurant_outlined, color: AppTheme.primary, size: 48),
            ),
            const SizedBox(height: 20),
            const Text(
              'No Meals Logged Yet',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
            ),
            const SizedBox(height: 8),
            const Text(
              'Scan food photos or enter meal details to track your macronutrients and predicted glucose spikes here.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryBanner() {
    final total = _meals.length;
    double totalCarbs = 0;
    for (var m in _meals) {
      totalCarbs += (m['carbs_g'] as num?)?.toDouble() ?? 0.0;
    }
    final avgCarbs = total > 0 ? (totalCarbs / total) : 0.0;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primary.withValues(alpha: 0.25),
            AppTheme.secondary.withValues(alpha: 0.15),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.primary.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Column(
            children: [
              const Text('Total Logged', style: TextStyle(fontSize: 11, color: AppTheme.textMuted)),
              const SizedBox(height: 4),
              Text(
                '$total meals',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
              ),
            ],
          ),
          Container(width: 1, height: 32, color: AppTheme.border),
          Column(
            children: [
              const Text('Avg. Carbs / Meal', style: TextStyle(fontSize: 11, color: AppTheme.textMuted)),
              const SizedBox(height: 4),
              Text(
                '${avgCarbs.toStringAsFixed(1)}g',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.secondary),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMealCard(Map<String, dynamic> meal) {
    final foodName = meal['food_name']?.toString() ?? 'Meal';
    final carbs = (meal['carbs_g'] as num?)?.toDouble() ?? 0.0;
    final protein = (meal['protein_g'] as num?)?.toDouble() ?? 0.0;
    final fat = (meal['fat_g'] as num?)?.toDouble() ?? 0.0;
    final preGlucose = (meal['pre_meal_glucose'] as num?)?.toDouble() ?? 100.0;
    final insulin = (meal['insulin_dose'] as num?)?.toDouble() ?? 0.0;
    final activity = meal['post_meal_activity']?.toString() ?? 'none';
    final spike = (meal['predicted_spike'] as num?)?.toDouble() ?? 0.0;
    final postMealEst = (meal['predicted_post_meal'] as num?)?.toDouble() ?? (preGlucose + spike);
    
    DateTime? date;
    if (meal['predicted_at'] != null) {
      var rawStr = meal['predicted_at'].toString();
      if (!rawStr.endsWith('Z') && !rawStr.contains('+')) {
        rawStr += 'Z';
      }
      date = DateTime.tryParse(rawStr)?.toLocal();
    }
    final timeStr = date != null ? DateFormat('MMM d, h:mm a').format(date) : 'Recently';

    final spikeColor = _getSpikeColor(spike);
    final riskLabel = _getSpikeRisk(spike);

    return Container(
      decoration: AppTheme.glassBoxDecoration(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Food Name + Risk Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.fastfood_outlined, color: AppTheme.primaryLight, size: 20),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        foodName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      Text(
                        timeStr,
                        style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: spikeColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: spikeColor.withValues(alpha: 0.4)),
                ),
                child: Text(
                  '+${spike.toStringAsFixed(1)} mg/dL ($riskLabel)',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: spikeColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(color: AppTheme.border, height: 1),
          const SizedBox(height: 12),

          // Macronutrients Grid
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _macroMetric('Carbs', '${carbs.toStringAsFixed(1)}g', AppTheme.warning),
              _macroMetric('Protein', '${protein.toStringAsFixed(1)}g', AppTheme.primaryLight),
              _macroMetric('Fat', '${fat.toStringAsFixed(1)}g', AppTheme.secondary),
              _macroMetric('Pre-Glucose', '${preGlucose.toInt()} mg/dL', AppTheme.textSecondary),
            ],
          ),
          const SizedBox(height: 12),

          // Insulin & Activity pill tags if present
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (insulin > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppTheme.primary.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.vaccines_outlined, color: AppTheme.primaryLight, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        'Insulin: ${insulin.toStringAsFixed(1)} U',
                        style: const TextStyle(fontSize: 11, color: AppTheme.primaryLight),
                      ),
                    ],
                  ),
                ),
              if (activity != 'none')
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.success.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppTheme.success.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.directions_walk, color: AppTheme.success, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        _formatActivityLabel(activity),
                        style: const TextStyle(fontSize: 11, color: AppTheme.success),
                      ),
                    ],
                  ),
                ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceLight.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.analytics_outlined, color: AppTheme.textMuted, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      'Est. Post-Meal: ${postMealEst.toInt()} mg/dL',
                      style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _macroMetric(String label, String value, Color color) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 10, color: AppTheme.textMuted)),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: color),
        ),
      ],
    );
  }
}
