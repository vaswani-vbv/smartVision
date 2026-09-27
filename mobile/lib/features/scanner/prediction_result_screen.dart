import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import 'scanner_service.dart';
import '../dashboard/dashboard_screen.dart';

class PredictionResultScreen extends StatefulWidget {
  final String foodName;
  final PredictionResponse prediction;
  final Uint8List? imageBytes;

  const PredictionResultScreen({
    super.key,
    required this.foodName,
    required this.prediction,
    this.imageBytes,
  });

  @override
  State<PredictionResultScreen> createState() => _PredictionResultScreenState();
}

class _PredictionResultScreenState extends State<PredictionResultScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Color _getRiskColor(String riskLevel) {
    switch (riskLevel.toLowerCase()) {
      case 'high':
        return AppTheme.danger;
      case 'elevated':
        return AppTheme.warning;
      case 'normal':
      default:
        return AppTheme.success;
    }
  }

  @override
  Widget build(BuildContext context) {
    final riskColor = _getRiskColor(widget.prediction.riskLevel);
    final spike = widget.prediction.predictedSpike;
    final postMeal = widget.prediction.predictedPostMeal;
    final preMeal = widget.prediction.preMealGlucose;

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
          'Glucose Prediction & SHAP',
          style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnim,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildFoodSummaryBanner(),
                const SizedBox(height: 20),
                _buildSpikeGaugeCard(spike, postMeal, preMeal, riskColor),
                const SizedBox(height: 20),
                _buildShapExplanationsCard(),
                const SizedBox(height: 20),
                _buildActionableRecommendationsCard(spike),
                const SizedBox(height: 28),
                SizedBox(
                  height: 54,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (_) => const DashboardScreen()),
                        (route) => false,
                      );
                    },
                    icon: const Icon(Icons.home_outlined),
                    label: const Text('Back to Home Dashboard'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFoodSummaryBanner() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.glassBoxDecoration(),
      child: Row(
        children: [
          if (widget.imageBytes != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.memory(
                widget.imageBytes!,
                width: 50,
                height: 50,
                fit: BoxFit.cover,
              ),
            )
          else
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.restaurant, color: AppTheme.primary),
            ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.foodName,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                Text(
                  'Carbs: ${widget.prediction.inputSummary['carbs_g'] ?? 0}g • '
                  'Protein: ${widget.prediction.inputSummary['protein_g'] ?? 0}g • '
                  'Fat: ${widget.prediction.inputSummary['fat_g'] ?? 0}g',
                  style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                ),
                if ((widget.prediction.inputSummary['insulin_dose'] as num?)?.toDouble() != null &&
                    (widget.prediction.inputSummary['insulin_dose'] as num).toDouble() > 0)
                  Text(
                    '💉 Bolus Insulin: ${(widget.prediction.inputSummary['insulin_dose'] as num).toDouble()} Units',
                    style: const TextStyle(fontSize: 11, color: AppTheme.primary, fontWeight: FontWeight.w600),
                  ),
                if (widget.prediction.inputSummary['post_meal_activity'] != null &&
                    widget.prediction.inputSummary['post_meal_activity'] != 'none')
                  Text(
                    '🚶 Activity: ${widget.prediction.inputSummary['post_meal_activity'].toString().replaceAll('_', ' ')}',
                    style: const TextStyle(fontSize: 11, color: AppTheme.success, fontWeight: FontWeight.w600),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpikeGaugeCard(
    double spike,
    double postMeal,
    double preMeal,
    Color riskColor,
  ) {
    return Container(
      decoration: AppTheme.glassBoxDecoration(),
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // Risk Level Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: riskColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: riskColor, width: 1.5),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  widget.prediction.riskLevel.toLowerCase() == 'high'
                      ? Icons.warning_amber_rounded
                      : (widget.prediction.riskLevel.toLowerCase() == 'elevated'
                          ? Icons.trending_up
                          : Icons.check_circle_outline),
                  color: riskColor,
                  size: 16,
                ),
                const SizedBox(width: 6),
                Text(
                  '${widget.prediction.riskLevel.toUpperCase()} RISK SPIKE',
                  style: TextStyle(
                    color: riskColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    letterSpacing: 0.8,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Main Predicted Spike Value
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '+${spike.toStringAsFixed(1)}',
                style: TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.w800,
                  color: riskColor,
                ),
              ),
              const SizedBox(width: 6),
              const Text(
                'mg/dL spike',
                style: TextStyle(
                  fontSize: 16,
                  color: AppTheme.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Comparison Stats Bar
          Container(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
            decoration: BoxDecoration(
              color: AppTheme.surfaceLight.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatColumn('Pre-Meal', '${preMeal.toStringAsFixed(0)} mg/dL', AppTheme.textSecondary),
                Container(width: 1, height: 30, color: AppTheme.border),
                _buildStatColumn('Predicted Peak', '${postMeal.toStringAsFixed(0)} mg/dL', riskColor),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatColumn(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildShapExplanationsCard() {
    final factors = widget.prediction.topFactors;
    return Container(
      decoration: AppTheme.glassBoxDecoration(),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.auto_awesome, color: AppTheme.secondary, size: 20),
              SizedBox(width: 8),
              Text(
                'Explainable AI Breakdown (SHAP)',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Factors driving your predicted glucose spike:',
            style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 16),
          if (factors.isEmpty)
            const Text(
              'No factor breakdown available',
              style: TextStyle(color: AppTheme.textMuted),
            )
          else
            ...factors.map((factor) {
              final val = factor.value;
              final isPositive = val >= 0;
              final impactColor = isPositive ? AppTheme.danger : AppTheme.success;
              final sign = isPositive ? '+' : '';
              final absVal = val.abs();
              final progress = (absVal / 50.0).clamp(0.05, 1.0);

              return Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          factor.feature,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimary,
                            fontSize: 13,
                          ),
                        ),
                        Text(
                          '$sign${val.toStringAsFixed(1)} mg/dL',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: impactColor,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 6,
                        backgroundColor: AppTheme.surfaceLight,
                        valueColor: AlwaysStoppedAnimation<Color>(impactColor),
                      ),
                    ),
                    if (factor.description.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        factor.description,
                        style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
                      ),
                    ],
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildActionableRecommendationsCard(double spike) {
    final List<Map<String, dynamic>> adviceList = [];

    if (spike > 40) {
      adviceList.add({
        'icon': Icons.directions_walk,
        'color': AppTheme.secondary,
        'title': 'Take a 15-minute walk post-meal',
        'desc': 'Light walking after eating can blunt glucose spikes by up to 20-30 mg/dL.',
      });
      adviceList.add({
        'icon': Icons.pie_chart_outline,
        'color': AppTheme.warning,
        'title': 'Reduce carb portion by 20%',
        'desc': 'High carbohydrate content is the primary driver of this predicted spike.',
      });
    } else if (spike > 25) {
      adviceList.add({
        'icon': Icons.eco_outlined,
        'color': AppTheme.success,
        'title': 'Add dietary fiber or salad first',
        'desc': 'Eating fiber before carbohydrates slows glucose absorption.',
      });
    } else {
      adviceList.add({
        'icon': Icons.thumb_up_alt_outlined,
        'color': AppTheme.success,
        'title': 'Balanced Meal Outcome',
        'desc': 'This meal is expected to keep your glucose within normal target range.',
      });
    }

    return Container(
      decoration: AppTheme.glassBoxDecoration(),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.lightbulb_outline, color: AppTheme.warning, size: 20),
              SizedBox(width: 8),
              Text(
                'AI Recommendations',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...adviceList.map((item) => Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: (item['color'] as Color).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: (item['color'] as Color).withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    Icon(item['icon'] as IconData, color: item['color'] as Color, size: 22),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item['title'] as String,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            item['desc'] as String,
                            style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}
