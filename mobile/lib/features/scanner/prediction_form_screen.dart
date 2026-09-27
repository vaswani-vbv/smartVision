import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/api_constants.dart';
import '../../core/network/api_client.dart';
import 'scanner_service.dart';
import 'prediction_result_screen.dart';

class PredictionFormScreen extends StatefulWidget {
  final DetectionResult detectionResult;
  final Uint8List? imageBytes;

  const PredictionFormScreen({
    super.key,
    required this.detectionResult,
    this.imageBytes,
  });

  @override
  State<PredictionFormScreen> createState() => _PredictionFormScreenState();
}

class _PredictionFormScreenState extends State<PredictionFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _foodController;
  late TextEditingController _carbsController;
  late TextEditingController _proteinController;
  late TextEditingController _fatController;
  late TextEditingController _fiberController;
  late TextEditingController _preGlucoseController;
  late TextEditingController _insulinController;

  double _portionMultiplier = 1.0;
  bool _isPredicting = false;
  bool _isType1 = false;
  bool _showInsulinField = false;
  String _postMealActivity = 'none';
  String? _errorMessage;

  final List<double> _glucosePresets = [85, 100, 115, 130, 150];
  final List<double> _insulinPresets = [2, 4, 6, 8, 10];
  final List<Map<String, dynamic>> _activityOptions = [
    {'value': 'none', 'label': 'Rest / None', 'icon': Icons.bed_outlined, 'desc': 'No activity'},
    {'value': 'light_walk', 'label': '15m Walk', 'icon': Icons.directions_walk, 'desc': '-15 mg/dL'},
    {'value': '30m_exercise', 'label': '30m Exercise', 'icon': Icons.directions_run, 'desc': '-25 mg/dL'},
    {'value': '45m_workout', 'label': '45m Workout', 'icon': Icons.fitness_center, 'desc': '-35 mg/dL'},
  ];

  @override
  void initState() {
    super.initState();
    _foodController = TextEditingController(text: widget.detectionResult.food);
    _carbsController = TextEditingController(text: widget.detectionResult.carbs.toStringAsFixed(1));
    _proteinController = TextEditingController(text: widget.detectionResult.protein.toStringAsFixed(1));
    _fatController = TextEditingController(text: widget.detectionResult.fat.toStringAsFixed(1));
    _fiberController = TextEditingController(text: widget.detectionResult.fiber.toStringAsFixed(1));
    _preGlucoseController = TextEditingController(text: '100');
    _insulinController = TextEditingController(text: '0.0');

    _fetchProfileDetails();
  }

  Future<void> _fetchProfileDetails() async {
    try {
      final profile = await ApiClient.get(ApiConstants.profile);
      if (profile != null && profile['diabetes_type'] == 'type1') {
        if (mounted) {
          setState(() {
            _isType1 = true;
            _showInsulinField = true;
          });
        }
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _foodController.dispose();
    _carbsController.dispose();
    _proteinController.dispose();
    _fatController.dispose();
    _fiberController.dispose();
    _preGlucoseController.dispose();
    _insulinController.dispose();
    super.dispose();
  }

  void _applyMultiplier(double multiplier) {
    setState(() {
      _portionMultiplier = multiplier;
      final carbs = (widget.detectionResult.carbs * multiplier);
      final protein = (widget.detectionResult.protein * multiplier);
      final fat = (widget.detectionResult.fat * multiplier);
      final fiber = (widget.detectionResult.fiber * multiplier);

      _carbsController.text = carbs.toStringAsFixed(1);
      _proteinController.text = protein.toStringAsFixed(1);
      _fatController.text = fat.toStringAsFixed(1);
      _fiberController.text = fiber.toStringAsFixed(1);
    });
  }

  Future<void> _handlePrediction() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isPredicting = true;
      _errorMessage = null;
    });

    try {
      final carbs = double.parse(_carbsController.text.trim());
      final protein = double.parse(_proteinController.text.trim());
      final fat = double.parse(_fatController.text.trim());
      final fiber = double.parse(_fiberController.text.trim());
      final preGlucose = double.parse(_preGlucoseController.text.trim());
      final insulin = _showInsulinField ? (double.tryParse(_insulinController.text.trim()) ?? 0.0) : 0.0;

      final prediction = await ScannerService.predictSpike(
        foodName: _foodController.text.trim(),
        carbsG: carbs,
        proteinG: protein,
        fatG: fat,
        fiberG: fiber,
        preMealGlucose: preGlucose,
        insulinDose: insulin,
        postMealActivity: _postMealActivity,
      );

      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PredictionResultScreen(
            foodName: _foodController.text.trim(),
            prediction: prediction,
            imageBytes: widget.imageBytes,
          ),
        ),
      );
    } on ApiException catch (e) {
      setState(() => _errorMessage = e.message);
    } catch (e) {
      setState(() => _errorMessage = 'Prediction failed: $e');
    } finally {
      if (mounted) setState(() => _isPredicting = false);
    }
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
          'Meal Details & Glucose',
          style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildDetectionHeader(),
                const SizedBox(height: 20),
                _buildPreMealGlucoseCard(),
                const SizedBox(height: 20),
                _buildInsulinCard(),
                const SizedBox(height: 20),
                _buildPostMealActivityCard(),
                const SizedBox(height: 20),
                _buildPortionSizeCard(),
                const SizedBox(height: 20),
                _buildMacronutrientsCard(),
                const SizedBox(height: 24),
                if (_errorMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.danger.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.danger.withValues(alpha: 0.4)),
                    ),
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(color: AppTheme.danger, fontSize: 13),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                SizedBox(
                  height: 54,
                  child: ElevatedButton(
                    onPressed: _isPredicting ? null : _handlePrediction,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: _isPredicting
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.psychology_outlined),
                              SizedBox(width: 8),
                              Text(
                                'Calculate Glucose Impact →',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
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

  Widget _buildDetectionHeader() {
    final confPercent = (widget.detectionResult.confidence * 100).toStringAsFixed(0);
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
                width: 60,
                height: 60,
                fit: BoxFit.cover,
              ),
            )
          else
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: AppTheme.secondary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.restaurant, color: AppTheme.secondary),
            ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _foodController,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ),
                  ],
                ),
                Text(
                  'YOLOv8 AI Detection • $confPercent% Confidence',
                  style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreMealGlucoseCard() {
    return Container(
      decoration: AppTheme.glassBoxDecoration(),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.water_drop_outlined, color: AppTheme.secondary, size: 20),
              SizedBox(width: 8),
              Text(
                'Pre-Meal Blood Glucose',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _preGlucoseController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
            decoration: const InputDecoration(
              labelText: 'Current Glucose Level (mg/dL)',
              suffixText: 'mg/dL',
            ),
            validator: (v) {
              if (v == null || v.isEmpty) return 'Glucose level is required';
              final n = double.tryParse(v);
              if (n == null || n < 40 || n > 400) return 'Enter a realistic reading (40-400)';
              return null;
            },
          ),
          const SizedBox(height: 12),
          const Text(
            'Quick Select:',
            style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: _glucosePresets.map((preset) {
              final isSelected = _preGlucoseController.text == preset.toStringAsFixed(0);
              return ChoiceChip(
                label: Text('${preset.toInt()} mg/dL'),
                selected: isSelected,
                selectedColor: AppTheme.secondary.withValues(alpha: 0.25),
                backgroundColor: AppTheme.surfaceLight.withValues(alpha: 0.3),
                labelStyle: TextStyle(
                  color: isSelected ? AppTheme.secondary : AppTheme.textSecondary,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
                onSelected: (selected) {
                  if (selected) {
                    setState(() {
                      _preGlucoseController.text = preset.toStringAsFixed(0);
                    });
                  }
                },
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildPortionSizeCard() {
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
                  Icon(Icons.pie_chart_outline, color: AppTheme.primary, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Portion Size Multiplier',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ],
              ),
              Text(
                '${_portionMultiplier.toStringAsFixed(1)}x',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryLight,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [0.5, 1.0, 1.5, 2.0].map((m) {
              final isSelected = (_portionMultiplier - m).abs() < 0.05;
              return InkWell(
                onTap: () => _applyMultiplier(m),
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppTheme.primary.withValues(alpha: 0.2)
                        : AppTheme.surfaceLight.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isSelected ? AppTheme.primary : AppTheme.border,
                    ),
                  ),
                  child: Text(
                    '${m}x',
                    style: TextStyle(
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected ? AppTheme.textPrimary : AppTheme.textSecondary,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildMacronutrientsCard() {
    return Container(
      decoration: AppTheme.glassBoxDecoration(),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.tune_outlined, color: AppTheme.warning, size: 20),
              SizedBox(width: 8),
              Text(
                'Macronutrients (g)',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildMacroField(
                  controller: _carbsController,
                  label: 'Carbs (g)',
                  icon: Icons.grain,
                  accentColor: AppTheme.warning,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMacroField(
                  controller: _proteinController,
                  label: 'Protein (g)',
                  icon: Icons.fitness_center,
                  accentColor: AppTheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildMacroField(
                  controller: _fatController,
                  label: 'Fat (g)',
                  icon: Icons.opacity,
                  accentColor: AppTheme.danger,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMacroField(
                  controller: _fiberController,
                  label: 'Fiber (g)',
                  icon: Icons.eco,
                  accentColor: AppTheme.success,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInsulinCard() {
    return Container(
      decoration: AppTheme.glassBoxDecoration(),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.vaccines_outlined, color: AppTheme.primary, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    _isType1 ? 'Bolus Insulin Dose (Type 1)' : 'Bolus Insulin Dose',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ],
              ),
              if (!_isType1)
                Switch(
                  value: _showInsulinField,
                  activeThumbColor: AppTheme.primary,
                  onChanged: (val) => setState(() => _showInsulinField = val),
                ),
            ],
          ),
          if (_showInsulinField) ...[
            const SizedBox(height: 14),
            TextFormField(
              controller: _insulinController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
              decoration: const InputDecoration(
                labelText: 'Bolus Insulin Units (U)',
                suffixText: 'Units',
                prefixIcon: Icon(Icons.science_outlined, color: AppTheme.primary),
              ),
              validator: (v) {
                if (!_showInsulinField) return null;
                if (v == null || v.isEmpty) return 'Enter 0 if no insulin taken';
                final n = double.tryParse(v);
                if (n == null || n < 0 || n > 50) return 'Enter a valid dose (0-50 U)';
                return null;
              },
            ),
            const SizedBox(height: 12),
            const Text(
              'Quick Select Dose:',
              style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: _insulinPresets.map((preset) {
                final isSelected = _insulinController.text == preset.toStringAsFixed(0);
                return ChoiceChip(
                  label: Text('${preset.toInt()} U'),
                  selected: isSelected,
                  selectedColor: AppTheme.primary.withValues(alpha: 0.25),
                  backgroundColor: AppTheme.surfaceLight.withValues(alpha: 0.3),
                  labelStyle: TextStyle(
                    color: isSelected ? AppTheme.primary : AppTheme.textSecondary,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                  onSelected: (selected) {
                    if (selected) {
                      setState(() {
                        _insulinController.text = preset.toStringAsFixed(0);
                      });
                    }
                  },
                );
              }).toList(),
            ),
          ] else
            const Padding(
              padding: EdgeInsets.only(top: 6),
              child: Text(
                'Toggle ON to factor in pre-meal bolus insulin',
                style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPostMealActivityCard() {
    return Container(
      decoration: AppTheme.glassBoxDecoration(),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.directions_walk_outlined, color: AppTheme.success, size: 20),
              SizedBox(width: 8),
              Text(
                'Post-Meal Physical Activity',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'Activity within 1–2 hours after eating blunts glucose spikes',
            style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
          ),
          const SizedBox(height: 16),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 2.2,
            children: _activityOptions.map((opt) {
              final isSelected = opt['value'] == _postMealActivity;
              return GestureDetector(
                onTap: () => setState(() => _postMealActivity = opt['value']),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppTheme.success.withValues(alpha: 0.18)
                        : AppTheme.surfaceLight.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isSelected ? AppTheme.success : AppTheme.border,
                      width: isSelected ? 1.5 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        opt['icon'] as IconData,
                        color: isSelected ? AppTheme.success : AppTheme.textMuted,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              opt['label'] as String,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: isSelected ? AppTheme.textPrimary : AppTheme.textSecondary,
                              ),
                            ),
                            Text(
                              opt['desc'] as String,
                              style: TextStyle(
                                fontSize: 10,
                                color: isSelected ? AppTheme.success : AppTheme.textMuted,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildMacroField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required Color accentColor,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      style: const TextStyle(color: AppTheme.textPrimary),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: accentColor, size: 18),
      ),
      validator: (v) {
        if (v == null || v.isEmpty) return 'Required';
        final n = double.tryParse(v);
        if (n == null || n < 0) return 'Invalid';
        return null;
      },
    );
  }
}
