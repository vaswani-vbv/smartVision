import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/network/api_client.dart';
import 'glucose_service.dart';

class LogGlucoseModal extends StatefulWidget {
  final VoidCallback onLogSaved;

  const LogGlucoseModal({super.key, required this.onLogSaved});

  @override
  State<LogGlucoseModal> createState() => _LogGlucoseModalState();
}

class _LogGlucoseModalState extends State<LogGlucoseModal> {
  final _formKey = GlobalKey<FormState>();
  final _valueController = TextEditingController(text: '100');
  final _notesController = TextEditingController();

  String _readingType = 'fasting';
  bool _isSaving = false;
  String? _errorMessage;

  final List<Map<String, String>> _readingTypes = [
    {'value': 'fasting', 'label': 'Fasting'},
    {'value': 'post_meal', 'label': 'Post-Meal'},
    {'value': 'bedtime', 'label': 'Bedtime'},
    {'value': 'random', 'label': 'Random'},
  ];

  final List<double> _presets = [75, 95, 110, 130, 160];

  @override
  void dispose() {
    _valueController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      final value = double.parse(_valueController.text.trim());
      await GlucoseService.logReading(
        valueMgdl: value,
        readingType: _readingType,
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
      );

      if (!mounted) return;

      widget.onLogSaved();
      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Glucose reading logged successfully!'),
          backgroundColor: AppTheme.success,
        ),
      );
    } on ApiException catch (e) {
      setState(() => _errorMessage = e.message);
    } catch (e) {
      setState(() => _errorMessage = 'Failed to log reading: $e');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        top: 24,
        left: 24,
        right: 24,
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Modal Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceLight,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Log Glucose Reading',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: AppTheme.textMuted),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Glucose Reading Input
              TextFormField(
                controller: _valueController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                decoration: const InputDecoration(
                  labelText: 'Blood Glucose Level',
                  suffixText: 'mg/dL',
                  prefixIcon: Icon(Icons.water_drop_outlined, color: AppTheme.secondary),
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Reading is required';
                  final n = double.tryParse(v);
                  if (n == null || n < 30 || n > 500) return 'Enter a valid reading (30-500)';
                  return null;
                },
              ),
              const SizedBox(height: 12),

              // Preset Quick Buttons
              Wrap(
                spacing: 8,
                children: _presets.map((p) {
                  final isSelected = _valueController.text == p.toStringAsFixed(0);
                  return ChoiceChip(
                    label: Text('${p.toInt()} mg/dL'),
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
                          _valueController.text = p.toStringAsFixed(0);
                        });
                      }
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),

              // Reading Type Selector
              const Text(
                'Reading Context',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: _readingTypes.map((t) {
                  final isSelected = t['value'] == _readingType;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _readingType = t['value']!),
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        padding: const EdgeInsets.symmetric(vertical: 10),
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
                          t['label']!,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            color: isSelected ? AppTheme.textPrimary : AppTheme.textSecondary,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),

              // Optional Notes
              TextFormField(
                controller: _notesController,
                style: const TextStyle(color: AppTheme.textPrimary),
                decoration: const InputDecoration(
                  labelText: 'Notes (Optional)',
                  hintText: 'e.g. Before breakfast, post-workout...',
                  prefixIcon: Icon(Icons.notes, color: AppTheme.textMuted),
                ),
              ),
              const SizedBox(height: 24),

              if (_errorMessage != null) ...[
                Text(
                  _errorMessage!,
                  style: const TextStyle(color: AppTheme.danger, fontSize: 13),
                ),
                const SizedBox(height: 16),
              ],

              // Save Button
              SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _handleSave,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text(
                          'Save Glucose Reading',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
