import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/api_constants.dart';
import '../../core/network/api_client.dart';

class KycScreen extends StatefulWidget {
  const KycScreen({super.key});

  @override
  State<KycScreen> createState() => _KycScreenState();
}

class _KycScreenState extends State<KycScreen> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _idNumberController = TextEditingController();
  
  bool _isLoading = true;
  bool _isSubmitting = false;
  String? _errorMessage;
  String? _successMessage;

  // KYC Data from backend
  String _status = 'unverified'; // unverified, pending, verified, rejected
  String? _idType;
  String? _idNumber;
  String? _docUrl;
  String? _rejectionReason;

  // Selected new document photo bytes
  Uint8List? _documentBytes;
  String? _documentFilename;

  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  final List<Map<String, String>> _idTypes = [
    {
      'value': 'aadhaar',
      'label': 'Aadhaar Card',
      'hint': '12-digit number (e.g., 999988887777)',
      'pattern': r'^\d{12}$',
      'example': '12 digits',
    },
    {
      'value': 'pan',
      'label': 'PAN Card',
      'hint': '10 characters (e.g., ABCDE1234F)',
      'pattern': r'^[A-Z]{5}[0-9]{4}[A-Z]$',
      'example': '5 letters, 4 digits, 1 letter',
    },
    {
      'value': 'passport',
      'label': 'Passport',
      'hint': '1 letter + 7 digits (e.g., A1234567)',
      'pattern': r'^[A-Z][0-9]{7}$',
      'example': '1 letter followed by 7 digits',
    },
    {
      'value': 'voter_id',
      'label': 'Voter ID (EPIC)',
      'hint': '3 letters + 7 digits (e.g., ABC1234567)',
      'pattern': r'^[A-Z]{3}[0-9]{7}$',
      'example': '3 letters followed by 7 digits',
    },
  ];

  @override
  void initState() {
    super.initState();
    _idType = _idTypes.first['value'];
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _animController.forward();

    _loadKycStatus();
  }

  @override
  void dispose() {
    _animController.dispose();
    _idNumberController.dispose();
    super.dispose();
  }

  Future<void> _loadKycStatus() async {
    setState(() => _isLoading = true);
    try {
      final res = await ApiClient.get(ApiConstants.govtId);
      if (mounted && res != null) {
        setState(() {
          _status = res['status'] ?? 'unverified';
          _idType = res['id_type'] ?? _idTypes.first['value'];
          _idNumber = res['id_number'];
          _docUrl = res['document_image_url'];
          _rejectionReason = res['rejection_reason'];

          if (_idNumber != null) {
            _idNumberController.text = _idNumber!;
          }
        });
      }
    } catch (_) {}
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _pickDocumentImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: source,
        maxWidth: 1600,
        maxHeight: 1600,
        imageQuality: 85,
      );
      if (picked != null) {
        final bytes = await picked.readAsBytes();
        if (mounted) {
          setState(() {
            _documentBytes = bytes;
            _documentFilename = picked.name;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to pick image: $e')),
        );
      }
    }
  }


  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      final selectedConfig = _idTypes.firstWhere((element) => element['value'] == _idType);
      final pattern = selectedConfig['pattern']!;
      final cleanNum = _idNumberController.text.trim().replaceAll(' ', '').toUpperCase();

      if (!RegExp(pattern).hasMatch(cleanNum)) {
        setState(() {
          _errorMessage = 'Invalid format for ${selectedConfig['label']}. Required format: ${selectedConfig['example']}';
          _isSubmitting = false;
        });
        return;
      }

      await ApiClient.submitGovtId(
        idType: _idType!,
        idNumber: cleanNum,
        documentBytes: _documentBytes,
        filename: _documentFilename,
      );

      await _loadKycStatus();
      if (mounted) {
        setState(() {
          _successMessage = 'Govt ID submitted successfully. Verification status is now Pending.';
        });
      }
    } on ApiException catch (e) {
      setState(() => _errorMessage = e.message);
    } catch (e) {
      setState(() => _errorMessage = 'Submission failed. Please try again.');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
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
          onPressed: () => Navigator.pop(context, _status),
        ),
        title: const Text(
          'Govt ID Verification',
          style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
          : SafeArea(
              child: FadeTransition(
                opacity: _fadeAnim,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildStatusCard(),
                      const SizedBox(height: 20),
                      if (_status == 'unverified' || _status == 'rejected' || _status == 'pending') ...[
                        _buildFormCard(),
                      ],
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildStatusCard() {
    Color cardBg;
    Color borderCol;
    IconData icon;
    String statusTitle;
    String statusSubtitle;

    switch (_status) {
      case 'verified':
        cardBg = AppTheme.success.withValues(alpha: 0.12);
        borderCol = AppTheme.success.withValues(alpha: 0.5);
        icon = Icons.verified_user_rounded;
        statusTitle = 'ID Verified';
        statusSubtitle = 'Your government identity document has been verified by the hospital administration.';
        break;
      case 'pending':
        cardBg = AppTheme.warning.withValues(alpha: 0.12);
        borderCol = AppTheme.warning.withValues(alpha: 0.5);
        icon = Icons.hourglass_top_rounded;
        statusTitle = 'Verification Pending';
        statusSubtitle = 'Your document is submitted and under review. You can update your submission below if needed.';
        break;
      case 'rejected':
        cardBg = AppTheme.danger.withValues(alpha: 0.12);
        borderCol = AppTheme.danger.withValues(alpha: 0.5);
        icon = Icons.gpp_bad_rounded;
        statusTitle = 'Verification Rejected';
        statusSubtitle = _rejectionReason ?? 'The submitted document could not be verified. Please re-submit valid details.';
        break;
      default:
        cardBg = AppTheme.primary.withValues(alpha: 0.1);
        borderCol = AppTheme.primary.withValues(alpha: 0.3);
        icon = Icons.shield_outlined;
        statusTitle = 'Verification Required';
        statusSubtitle = 'Please select your government identity document type, enter the ID number, and upload a document photo.';
    }

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderCol),
      ),
      padding: const EdgeInsets.all(20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: borderCol, size: 36),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  statusTitle,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: borderCol,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  statusSubtitle,
                  style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormCard() {
    final currentConfig = _idTypes.firstWhere((t) => t['value'] == _idType);

    return Container(
      decoration: AppTheme.glassBoxDecoration(),
      padding: const EdgeInsets.all(22),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Identity Details',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 16),

            // Dropdown for ID Type
            DropdownButtonFormField<String>(
              initialValue: _idType,
              dropdownColor: AppTheme.surface,
              style: const TextStyle(color: AppTheme.textPrimary),
              decoration: const InputDecoration(
                labelText: 'Document Type',
                prefixIcon: Icon(Icons.badge_outlined, color: AppTheme.textMuted),
              ),
              items: _idTypes.map((type) {
                return DropdownMenuItem<String>(
                  value: type['value'],
                  child: Text(type['label']!),
                );
              }).toList(),
              onChanged: (val) {
                if (val != null) {
                  setState(() {
                    _idType = val;
                    _errorMessage = null;
                  });
                }
              },
            ),
            const SizedBox(height: 16),

            // ID Number Field
            TextFormField(
              controller: _idNumberController,
              style: const TextStyle(color: AppTheme.textPrimary),
              textCapitalization: TextCapitalization.characters,
              decoration: InputDecoration(
                labelText: '${currentConfig['label']} Number',
                hintText: currentConfig['hint'],
                prefixIcon: const Icon(Icons.pin_outlined, color: AppTheme.textMuted),
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) {
                  return 'Please enter your ${currentConfig['label']} number';
                }
                final clean = v.trim().replaceAll(' ', '').toUpperCase();
                final pattern = currentConfig['pattern']!;
                if (!RegExp(pattern).hasMatch(clean)) {
                  return 'Format error: ${currentConfig['example']}';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),

            // Document Image Picker Section
            const Text(
              'Upload Document Photo (Optional)',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Upload a clear photo or scan of your physical card for verification.',
              style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
            ),
            const SizedBox(height: 12),

            // Preview or Picker Box
            GestureDetector(
              onTap: () => _showImagePickerBottomSheet(),
              child: Container(
                height: 160,
                decoration: BoxDecoration(
                  color: AppTheme.surfaceLight.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppTheme.border, style: BorderStyle.solid),
                ),
                child: _documentBytes != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(13),
                        child: Image.memory(
                          _documentBytes!,
                          fit: BoxFit.cover,
                          width: double.infinity,
                        ),
                      )
                    : (_docUrl != null && _docUrl!.isNotEmpty)
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(13),
                            child: Image.network(
                              ApiConstants.getFullImageUrl(_docUrl),
                              fit: BoxFit.cover,
                              width: double.infinity,
                              errorBuilder: (context, error, stackTrace) => _buildPickerPlaceholder(),
                            ),
                          )
                        : _buildPickerPlaceholder(),
              ),
            ),

            const SizedBox(height: 20),

            // Feedback Messages
            if (_errorMessage != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.danger.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppTheme.danger.withValues(alpha: 0.4)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: AppTheme.danger, size: 18),
                    const SizedBox(width: 8),
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

            if (_successMessage != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.success.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppTheme.success.withValues(alpha: 0.4)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle_outline, color: AppTheme.success, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _successMessage!,
                        style: const TextStyle(color: AppTheme.success, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Submit Button
            SizedBox(
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _isSubmitting ? null : _handleSubmit,
                icon: _isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.send_rounded, size: 20),
                label: Text(
                  _isSubmitting ? 'Submitting...' : 'Submit ID for Verification',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPickerPlaceholder() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: const [
        Icon(Icons.add_a_photo_outlined, color: AppTheme.secondary, size: 36),
        SizedBox(height: 8),
        Text(
          'Tap to select document image',
          style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
        ),
        SizedBox(height: 4),
        Text(
          'Supports JPG, PNG (Max 5MB)',
          style: TextStyle(color: AppTheme.textMuted, fontSize: 11),
        ),
      ],
    );
  }

  void _showImagePickerBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
        child: Wrap(
          children: [
            const Text(
              'Choose Document Source',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined, color: AppTheme.primary),
              title: const Text('Camera', style: TextStyle(color: AppTheme.textPrimary)),
              onTap: () {
                Navigator.pop(ctx);
                _pickDocumentImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined, color: AppTheme.secondary),
              title: const Text('Gallery', style: TextStyle(color: AppTheme.textPrimary)),
              onTap: () {
                Navigator.pop(ctx);
                _pickDocumentImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }
}
