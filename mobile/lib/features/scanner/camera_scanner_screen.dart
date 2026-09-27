import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/theme/app_theme.dart';
import 'scanner_service.dart';
import 'prediction_form_screen.dart';

class CameraScannerScreen extends StatefulWidget {
  const CameraScannerScreen({super.key});

  @override
  State<CameraScannerScreen> createState() => _CameraScannerScreenState();
}

class _CameraScannerScreenState extends State<CameraScannerScreen>
    with SingleTickerProviderStateMixin {
  final ImagePicker _picker = ImagePicker();
  Uint8List? _selectedImageBytes;
  bool _isAnalyzing = false;
  String? _errorMessage;

  late AnimationController _animController;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _pulseAnim = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? file = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (file == null) return;

      final bytes = await file.readAsBytes();
      setState(() {
        _selectedImageBytes = bytes;
        _errorMessage = null;
      });

      _runYoloDetection(bytes, file.name);
    } catch (e) {
      setState(() {
        _errorMessage = 'Could not access image: $e';
      });
    }
  }

  Future<void> _runYoloDetection(Uint8List bytes, String filename) async {
    setState(() => _isAnalyzing = true);
    try {
      final result = await ScannerService.detectFood(bytes, filename);

      if (!mounted) return;

      if (result.error != null && result.carbs == 0) {
        // Show detected food name with fallback macro editor
        _navigateToForm(result);
      } else {
        _navigateToForm(result);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isAnalyzing = false;
        _errorMessage = 'Detection failed: $e';
      });
    } finally {
      if (mounted) setState(() => _isAnalyzing = false);
    }
  }

  void _navigateToForm(DetectionResult result) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PredictionFormScreen(
          detectionResult: result,
          imageBytes: _selectedImageBytes,
        ),
      ),
    );
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
          'Scan Meal Photo',
          style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Main Viewfinder / Image Container
              Expanded(
                child: Container(
                  decoration: AppTheme.glassBoxDecoration(),
                  clipBehavior: Clip.antiAlias,
                  child: _selectedImageBytes != null
                      ? Stack(
                          fit: StackFit.expand,
                          children: [
                            Image.memory(
                              _selectedImageBytes!,
                              fit: BoxFit.cover,
                            ),
                            if (_isAnalyzing)
                              Container(
                                color: Colors.black.withValues(alpha: 0.65),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    ScaleTransition(
                                      scale: _pulseAnim,
                                      child: Container(
                                        padding: const EdgeInsets.all(20),
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: AppTheme.primary.withValues(alpha: 0.2),
                                          border: Border.all(
                                            color: AppTheme.secondary,
                                            width: 2,
                                          ),
                                        ),
                                        child: const Icon(
                                          Icons.remove_red_eye_outlined,
                                          color: AppTheme.secondary,
                                          size: 40,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 20),
                                    const Text(
                                      'YOLOv8 AI Detection...',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    const Text(
                                      'Identifying food & macronutrients',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: AppTheme.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        )
                      : _buildEmptyState(),
                ),
              ),
              const SizedBox(height: 24),

              if (_errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.danger.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.danger.withValues(alpha: 0.4)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: AppTheme.danger, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(color: AppTheme.danger, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Capture Controls
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 54,
                      child: ElevatedButton.icon(
                        onPressed: _isAnalyzing
                            ? null
                            : () => _pickImage(ImageSource.camera),
                        icon: const Icon(Icons.camera_alt_outlined),
                        label: const Text('Take Photo'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SizedBox(
                      height: 54,
                      child: OutlinedButton.icon(
                        onPressed: _isAnalyzing
                            ? null
                            : () => _pickImage(ImageSource.gallery),
                        icon: const Icon(Icons.photo_library_outlined, color: AppTheme.secondary),
                        label: const Text('Gallery', style: TextStyle(color: AppTheme.textPrimary)),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppTheme.border),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Center(
                child: TextButton.icon(
                  onPressed: () {
                    // Manual entry without scanning
                    _navigateToForm(
                      DetectionResult(
                        food: 'Custom Meal',
                        confidence: 1.0,
                        carbs: 30.0,
                        protein: 10.0,
                        fat: 5.0,
                        fiber: 3.0,
                        calories: 205,
                        servingSize: '1 serving',
                      ),
                    );
                  },
                  icon: const Icon(Icons.edit_note_outlined, color: AppTheme.textSecondary, size: 18),
                  label: const Text(
                    'Skip scan and enter macros manually',
                    style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppTheme.surfaceLight.withValues(alpha: 0.4),
          ),
          child: const Icon(
            Icons.center_focus_weak_outlined,
            size: 64,
            color: AppTheme.secondary,
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          'Scan Your Meal',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 32),
          child: Text(
            'Snap a photo or select from gallery. YOLOv8 AI will detect the food and calculate macronutrients automatically.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: AppTheme.textSecondary,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}
