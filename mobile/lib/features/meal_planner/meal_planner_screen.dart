import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/api_constants.dart';
import '../../core/network/api_client.dart';
import '../dashboard/glucose_service.dart';

class MealPlannerScreen extends StatefulWidget {
  const MealPlannerScreen({super.key});

  @override
  State<MealPlannerScreen> createState() => _MealPlannerScreenState();
}

class _MealPlannerScreenState extends State<MealPlannerScreen> {
  final _glucoseController = TextEditingController();
  bool _isLoading = false;
  bool _isFetchingLast = true;
  String? _errorMessage;
  Map<String, dynamic>? _result;
  double? _lastGlucoseValue;

  @override
  void initState() {
    super.initState();
    _fetchLastReading();
  }

  @override
  void dispose() {
    _glucoseController.dispose();
    super.dispose();
  }

  Future<void> _fetchLastReading() async {
    try {
      final readings = await GlucoseService.getHistory(days: 7);
      if (readings.isNotEmpty) {
        final last = readings.first;
        if (mounted) {
          setState(() {
            _lastGlucoseValue = last.valueMgdl;
            _glucoseController.text = last.valueMgdl.toStringAsFixed(0);
          });
          // Auto load initial recommendation
          _getRecommendations();
        }
      }
    } catch (_) {} finally {
      if (mounted) setState(() => _isFetchingLast = false);
    }
  }

  Future<void> _getRecommendations() async {
    final valText = _glucoseController.text.trim();
    if (valText.isEmpty) return;

    final glucoseVal = double.tryParse(valText);
    if (glucoseVal == null || glucoseVal < 30 || glucoseVal > 500) {
      setState(() => _errorMessage = 'Please enter a valid glucose value (30–500 mg/dL).');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final res = await ApiClient.post(ApiConstants.recommendMeals, {
        'current_glucose': glucoseVal,
      });

      if (mounted) {
        setState(() {
          _result = res;
        });
      }
    } on ApiException catch (e) {
      if (mounted) setState(() => _errorMessage = e.message);
    } catch (e) {
      if (mounted) setState(() => _errorMessage = 'Failed to get recommendations. Check backend server.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Color _riskColor(String risk) {
    if (risk == 'low') return AppTheme.success;
    if (risk == 'moderate') return AppTheme.warning;
    return AppTheme.danger;
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
          'Smart Meal Planner',
          style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildInputCard(),
            const SizedBox(height: 20),
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: Center(
                  child: Column(
                    children: [
                      CircularProgressIndicator(color: AppTheme.primary),
                      SizedBox(height: 12),
                      Text(
                        'Calculating your safe glucose budget & AI recommendations...',
                        style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              )
            else if (_result != null) ...[
              _buildAIAnalysisCard(),
              const SizedBox(height: 20),
              _buildMacroBudgetCard(),
              const SizedBox(height: 20),
              _buildRecommendationsList(),
            ],
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildInputCard() {
    return Container(
      decoration: AppTheme.glassBoxDecoration(),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.tune_outlined, color: AppTheme.primaryLight, size: 20),
              ),
              const SizedBox(width: 10),
              const Text(
                'Your Current State',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
              ),
            ],
          ),
          const SizedBox(height: 14),

          if (_isFetchingLast)
            _buildBanner('Fetching your latest logged glucose reading...', AppTheme.primary)
          else if (_lastGlucoseValue != null)
            _buildBanner('Glucose auto-filled from your recent logged reading', AppTheme.success)
          else
            _buildBanner('No recent readings found. Enter your current blood sugar below.', AppTheme.secondary),

          if (_errorMessage != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(_errorMessage!, style: const TextStyle(color: AppTheme.danger, fontSize: 12)),
            ),

          TextFormField(
            controller: _glucoseController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: const TextStyle(color: AppTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.bold),
            decoration: const InputDecoration(
              labelText: 'Current Glucose (mg/dL)',
              hintText: 'e.g. 110',
              prefixIcon: Icon(Icons.water_drop_outlined, color: AppTheme.secondary),
              suffixText: 'mg/dL',
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: _isLoading ? null : _getRecommendations,
              icon: const Icon(Icons.restaurant_menu_outlined, size: 20),
              label: const Text(
                'Get Meal Recommendations',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBanner(String text, Color color) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(text, style: TextStyle(color: color, fontSize: 12)),
    );
  }

  Widget _buildAIAnalysisCard() {
    final overall = _result?['overall_advice']?.toString() ?? '';
    final tip = _result?['meal_timing_tip']?.toString() ?? '';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primary.withValues(alpha: 0.3),
            AppTheme.secondary.withValues(alpha: 0.15),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.primary.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.psychology_outlined, color: AppTheme.secondary, size: 22),
              SizedBox(width: 8),
              Text(
                'Proactive AI Analysis',
                style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            overall,
            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13, height: 1.4),
          ),
          if (tip.isNotEmpty) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.surfaceLight.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppTheme.border),
              ),
              child: Row(
                children: [
                  const Icon(Icons.lightbulb_outlined, color: Colors.amber, size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      tip,
                      style: const TextStyle(color: AppTheme.textPrimary, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMacroBudgetCard() {
    final budgetObj = _result?['glucose_budget'] as Map<String, dynamic>? ?? {};
    final targets = budgetObj['macro_targets'] as Map<String, dynamic>? ?? {};
    final reasoning = (budgetObj['reasoning'] as List?) ?? [];
    final safeBudget = (budgetObj['budget_mgdl'] as num?)?.toDouble() ?? 35.0;

    return Container(
      decoration: AppTheme.glassBoxDecoration(),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.pie_chart_outline, color: AppTheme.primaryLight, size: 20),
              SizedBox(width: 8),
              Text(
                'Your Macro Budget for This Meal',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Reasoning bullets
          ...reasoning.take(3).map((r) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('• ', style: TextStyle(color: AppTheme.secondary, fontWeight: FontWeight.bold)),
                    Expanded(
                      child: Text(
                        r.toString(),
                        style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
                      ),
                    ),
                  ],
                ),
              )),

          const SizedBox(height: 14),
          const Divider(color: AppTheme.border, height: 1),
          const SizedBox(height: 14),

          // Macro Target Box Grid
          Row(
            children: [
              Expanded(child: _macroTargetBox('Carbs', '${targets['carbs_g_min'] ?? 15}–${targets['carbs_g_max'] ?? 40}g', AppTheme.warning)),
              const SizedBox(width: 8),
              Expanded(child: _macroTargetBox('Protein', '≥${targets['protein_g_min'] ?? 15}g', AppTheme.primaryLight)),
              const SizedBox(width: 8),
              Expanded(child: _macroTargetBox('Fiber', '≥${targets['fiber_g_min'] ?? 4}g', AppTheme.success)),
              const SizedBox(width: 8),
              Expanded(child: _macroTargetBox('Fat', '≤${targets['fat_g_max'] ?? 20}g', AppTheme.secondary)),
            ],
          ),

          const SizedBox(height: 14),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppTheme.surfaceLight.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Safe Glucose Rise Budget:',
                  style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
                ),
                Text(
                  '≤${safeBudget.toInt()} mg/dL',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.secondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _macroTargetBox(String label, String val, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Text(label, style: const TextStyle(fontSize: 10, color: AppTheme.textMuted)),
          const SizedBox(height: 4),
          Text(
            val,
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendationsList() {
    final list = (_result?['recommendations'] as List?) ?? [];

    return Container(
      decoration: AppTheme.glassBoxDecoration(),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.restaurant_outlined, color: AppTheme.secondary, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Recommended Meals',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                  ),
                ],
              ),
              Text(
                '${list.length} options',
                style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: list.length,
            separatorBuilder: (context, index) => const SizedBox(height: 14),
            itemBuilder: (context, index) {
              final meal = list[index] as Map<String, dynamic>;
              return _buildMealItemCard(index + 1, meal);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMealItemCard(int rank, Map<String, dynamic> meal) {
    final fits = meal['fits_budget'] as bool? ?? true;
    final risk = meal['risk_level']?.toString() ?? 'low';
    final spikeColor = _riskColor(risk);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: fits
            ? AppTheme.surfaceLight.withValues(alpha: 0.3)
            : AppTheme.warning.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: fits ? spikeColor.withValues(alpha: 0.4) : AppTheme.warning.withValues(alpha: 0.4),
          width: fits ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: fits ? spikeColor : AppTheme.warning,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '$rank',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  meal['name']?.toString() ?? 'Meal',
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                ),
              ),
              if (!fits)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppTheme.warning.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppTheme.warning),
                  ),
                  child: const Text(
                    'Caution',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.warning),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),

          Text(
            meal['description']?.toString() ?? '',
            style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
          ),
          const SizedBox(height: 10),

          // Macro Chips
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              _macroChip('${meal['carbs_g']}g carbs', AppTheme.warning),
              _macroChip('${meal['protein_g']}g protein', AppTheme.primaryLight),
              _macroChip('${meal['fiber_g']}g fiber', AppTheme.success),
              _macroChip('${meal['calories']} kcal', AppTheme.textMuted),
            ],
          ),
          const SizedBox(height: 12),

          // Predicted Spike Box
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: spikeColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: spikeColor.withValues(alpha: 0.3)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Predicted Spike', style: TextStyle(fontSize: 10, color: AppTheme.textMuted)),
                    const SizedBox(height: 2),
                    Text(
                      '+${meal['predicted_spike']} mg/dL',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: spikeColor),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text('Est. Post-Meal Glucose', style: TextStyle(fontSize: 10, color: AppTheme.textMuted)),
                    const SizedBox(height: 2),
                    Text(
                      '${meal['predicted_post_meal']} mg/dL',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: spikeColor),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Recommendation note
          Text(
            meal['recommendation_note']?.toString() ?? '',
            style: TextStyle(
              fontSize: 11,
              fontStyle: FontStyle.italic,
              color: fits ? AppTheme.success : AppTheme.warning,
            ),
          ),
        ],
      ),
    );
  }

  Widget _macroChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color),
      ),
    );
  }
}
