import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/api_constants.dart';
import '../../core/network/api_client.dart';
import '../dashboard/dashboard_screen.dart';
import 'kyc_screen.dart';

class MedicalProfileScreen extends StatefulWidget {
  final bool isOnboarding;
  const MedicalProfileScreen({super.key, this.isOnboarding = false});

  @override
  State<MedicalProfileScreen> createState() => _MedicalProfileScreenState();
}

class _MedicalProfileScreenState extends State<MedicalProfileScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = true;
  bool _isSaving = false;
  bool _isEditing = false;
  String? _errorMessage;

  // User info
  String _userName = '';
  String _userEmail = '';
  String _profilePictureUrl = '';
  String _kycStatus = 'unverified';


  // Profile data (for view mode)
  Map<String, dynamic> _profileData = {};

  // Form State (for edit mode)
  String _diabetesType = 'type2';
  String _activityLevel = 'moderate';
  final _ageController = TextEditingController();
  final _weightController = TextEditingController();
  final _heightController = TextEditingController();
  final _medicationsController = TextEditingController();

  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  // Dropdown Options
  final List<Map<String, String>> _diabetesTypes = [
    {'value': 'type1', 'label': 'Type 1 Diabetes'},
    {'value': 'type2', 'label': 'Type 2 Diabetes'},
    {'value': 'gestational', 'label': 'Gestational Diabetes'},
    {'value': 'prediabetes', 'label': 'Prediabetes'},
  ];

  final List<Map<String, dynamic>> _activityLevels = [
    {'value': 'sedentary', 'label': 'Sedentary', 'icon': Icons.weekend_outlined, 'desc': 'Little or no exercise'},
    {'value': 'light', 'label': 'Light', 'icon': Icons.directions_walk_outlined, 'desc': '1–3 days/week'},
    {'value': 'moderate', 'label': 'Moderate', 'icon': Icons.directions_bike_outlined, 'desc': '3–5 days/week'},
    {'value': 'active', 'label': 'Active', 'icon': Icons.fitness_center_outlined, 'desc': '6–7 days/week'},
  ];

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _animController.forward();

    if (widget.isOnboarding) {
      _isEditing = true;
      _isLoading = false;
    } else {
      _loadUserAndProfile();
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    _ageController.dispose();
    _weightController.dispose();
    _heightController.dispose();
    _medicationsController.dispose();
    super.dispose();
  }

  Future<void> _loadUserAndProfile() async {
    setState(() => _isLoading = true);
    try {
      // Load user info and profile in parallel
      final results = await Future.wait([
        ApiClient.get(ApiConstants.me),
        ApiClient.get(ApiConstants.profile),
      ]);

      final userData = results[0];
      final profileDataResult = results[1];

      if (mounted) {
        setState(() {
          _userName = userData?['name'] ?? '';
          _userEmail = userData?['email'] ?? '';
          _profilePictureUrl = userData?['profile_picture_url'] ?? '';
          _kycStatus = userData?['kyc_status'] ?? 'unverified';

          if (profileDataResult != null && profileDataResult['diabetes_type'] != null) {
            _profileData = profileDataResult;
            _diabetesType = profileDataResult['diabetes_type'] ?? 'type2';
            _activityLevel = profileDataResult['activity_level'] ?? 'moderate';
            _ageController.text = profileDataResult['age']?.toString() ?? '';
            _weightController.text = profileDataResult['weight_kg']?.toString() ?? '';
            _heightController.text = profileDataResult['height_cm']?.toString() ?? '';
            _medicationsController.text = profileDataResult['medications'] ?? '';
          }
        });
      }
    } catch (_) {}
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _pickAndUploadAvatar(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );
      if (picked != null) {
        final bytes = await picked.readAsBytes();
        final response = await ApiClient.uploadAvatar(bytes, picked.name);
        if (mounted && response != null && response['profile_picture_url'] != null) {
          setState(() {
            _profilePictureUrl = response['profile_picture_url'];
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Profile picture updated successfully!'),
              backgroundColor: AppTheme.success,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to upload picture: $e'),
            backgroundColor: AppTheme.danger,
          ),
        );
      }
    }
  }

  void _showAvatarOptionSheet() {
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
              'Change Profile Picture',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined, color: AppTheme.primary),
              title: const Text('Take Photo', style: TextStyle(color: AppTheme.textPrimary)),
              onTap: () {
                Navigator.pop(ctx);
                _pickAndUploadAvatar(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined, color: AppTheme.secondary),
              title: const Text('Choose from Gallery', style: TextStyle(color: AppTheme.textPrimary)),
              onTap: () {
                Navigator.pop(ctx);
                _pickAndUploadAvatar(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }


  void _enterEditMode() {
    setState(() => _isEditing = true);
  }

  void _cancelEdit() {
    // Restore values from _profileData
    setState(() {
      _isEditing = false;
      _errorMessage = null;
      _diabetesType = _profileData['diabetes_type'] ?? 'type2';
      _activityLevel = _profileData['activity_level'] ?? 'moderate';
      _ageController.text = _profileData['age']?.toString() ?? '';
      _weightController.text = _profileData['weight_kg']?.toString() ?? '';
      _heightController.text = _profileData['height_cm']?.toString() ?? '';
      _medicationsController.text = _profileData['medications'] ?? '';
    });
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });
    try {
      await ApiClient.post(ApiConstants.profile, {
        'diabetes_type': _diabetesType,
        'age': int.parse(_ageController.text.trim()),
        'weight_kg': double.parse(_weightController.text.trim()),
        'height_cm': double.parse(_heightController.text.trim()),
        'activity_level': _activityLevel,
        'medications': _medicationsController.text.trim().isEmpty
            ? null
            : _medicationsController.text.trim(),
      });
      if (!mounted) return;
      if (widget.isOnboarding) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const DashboardScreen()),
          (route) => false,
        );
      } else {
        // Refresh local data and switch back to view mode
        await _loadUserAndProfile();
        if (mounted) {
          setState(() => _isEditing = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Profile updated successfully.'),
              backgroundColor: AppTheme.success,
            ),
          );
        }
      }
    } on ApiException catch (e) {
      setState(() => _errorMessage = e.message);
    } catch (e) {
      setState(() => _errorMessage = 'Failed to save profile. Please try again.');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  // ─── Helper to get label from value ──────────────────────────────
  String _getDiabetesLabel(String value) {
    return _diabetesTypes.firstWhere(
      (t) => t['value'] == value,
      orElse: () => {'label': value},
    )['label']!;
  }

  String _getActivityLabel(String value) {
    final match = _activityLevels.firstWhere(
      (a) => a['value'] == value,
      orElse: () => {'label': value, 'desc': ''},
    );
    return '${match['label']} — ${match['desc']}';
  }

  IconData _getActivityIcon(String value) {
    return _activityLevels.firstWhere(
      (a) => a['value'] == value,
      orElse: () => {'icon': Icons.directions_run_outlined},
    )['icon'] as IconData;
  }

  // ══════════════════════════════════════════════════════════════════
  // BUILD
  // ══════════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: widget.isOnboarding
            ? null
            : IconButton(
                icon: const Icon(Icons.arrow_back_ios_new, color: AppTheme.textSecondary),
                onPressed: () => Navigator.pop(context),
              ),
        title: Text(
          widget.isOnboarding
              ? 'Medical Profile Setup'
              : (_isEditing ? 'Edit Profile' : 'My Profile'),
          style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold),
        ),
        actions: [
          if (!widget.isOnboarding && _isEditing)
            TextButton(
              onPressed: _cancelEdit,
              child: const Text('Cancel', style: TextStyle(color: AppTheme.danger, fontSize: 14)),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
          : SafeArea(
              child: FadeTransition(
                opacity: _fadeAnim,
                child: _isEditing ? _buildEditMode() : _buildViewMode(),
              ),
            ),
    );
  }

  // ══════════════════════════════════════════════════════════════════
  // VIEW MODE — read-only cards with user info and an Edit button
  // ══════════════════════════════════════════════════════════════════
  Widget _buildViewMode() {
    final hasProfile = _profileData.isNotEmpty && _profileData['diabetes_type'] != null;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── User Identity Card ─────────────────────────────────
          _buildUserCard(),
          const SizedBox(height: 14),

          // ── Govt ID Verification Card ─────────────────────────
          _buildKycCard(),
          const SizedBox(height: 14),

          if (hasProfile) ...[
            _buildViewCard(
              title: 'Diabetes Type',
              icon: Icons.bloodtype_outlined,
              children: [
                _viewRow(Icons.medical_information_outlined, 'Type', _getDiabetesLabel(_profileData['diabetes_type'] ?? '')),
              ],
            ),
            const SizedBox(height: 14),
            _buildViewCard(
              title: 'Physical Details',
              icon: Icons.person_outline,
              children: [
                _viewRow(Icons.cake_outlined, 'Age', '${_profileData['age'] ?? '—'} years'),
                _viewRow(Icons.monitor_weight_outlined, 'Weight', '${_profileData['weight_kg'] ?? '—'} kg'),
                _viewRow(Icons.height_outlined, 'Height', '${_profileData['height_cm'] ?? '—'} cm'),
              ],
            ),
            const SizedBox(height: 14),
            _buildViewCard(
              title: 'Activity Level',
              icon: Icons.directions_run_outlined,
              children: [
                _viewRow(
                  _getActivityIcon(_profileData['activity_level'] ?? 'moderate'),
                  'Level',
                  _getActivityLabel(_profileData['activity_level'] ?? 'moderate'),
                ),
              ],
            ),
            const SizedBox(height: 14),
            _buildViewCard(
              title: 'Medications',
              icon: Icons.medication_outlined,
              children: [
                _viewRow(
                  Icons.medical_services_outlined,
                  'Current',
                  (_profileData['medications'] != null && _profileData['medications'].toString().isNotEmpty)
                      ? _profileData['medications']
                      : 'None specified',
                ),
              ],
            ),
          ] else ...[
            Container(
              padding: const EdgeInsets.all(24),
              decoration: AppTheme.glassBoxDecoration(),
              child: const Column(
                children: [
                  Icon(Icons.info_outline, color: AppTheme.textMuted, size: 40),
                  SizedBox(height: 12),
                  Text(
                    'No medical profile set up yet.',
                    style: TextStyle(color: AppTheme.textSecondary, fontSize: 15),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Tap "Edit Profile" below to get started.',
                    style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 24),

          // ── Edit Profile Button ────────────────────────────────
          SizedBox(
            height: 54,
            child: ElevatedButton.icon(
              onPressed: _enterEditMode,
              icon: const Icon(Icons.edit_outlined, size: 20),
              label: const Text(
                'Edit Profile',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildKycCard() {
    Color badgeColor;
    IconData badgeIcon;
    String badgeText;
    String subtitle;

    switch (_kycStatus) {
      case 'verified':
        badgeColor = AppTheme.success;
        badgeIcon = Icons.verified_user_rounded;
        badgeText = 'Verified';
        subtitle = 'Identity verified by hospital admin';
        break;
      case 'pending':
        badgeColor = AppTheme.warning;
        badgeIcon = Icons.hourglass_top_rounded;
        badgeText = 'Pending';
        subtitle = 'Document under hospital admin review';
        break;
      case 'rejected':
        badgeColor = AppTheme.danger;
        badgeIcon = Icons.gpp_bad_rounded;
        badgeText = 'Rejected';
        subtitle = 'Verification failed. Tap to re-submit';
        break;
      default:
        badgeColor = AppTheme.textMuted;
        badgeIcon = Icons.shield_outlined;
        badgeText = 'Not Verified';
        subtitle = 'Verify your Aadhaar, PAN, Passport, or Voter ID';
    }

    return GestureDetector(
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const KycScreen()),
        );
        _loadUserAndProfile();
      },
      child: Container(
        decoration: AppTheme.glassBoxDecoration(),
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: badgeColor.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(badgeIcon, color: badgeColor, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text(
                        'Govt ID Verification',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: badgeColor.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: badgeColor.withValues(alpha: 0.5)),
                        ),
                        child: Text(
                          badgeText,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: badgeColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppTheme.textMuted),
          ],
        ),
      ),
    );
  }

  Widget _buildUserCard() {
    final initials = _userName.isNotEmpty
        ? _userName.trim().split(' ').map((w) => w.isNotEmpty ? w[0].toUpperCase() : '').take(2).join()
        : '?';

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primary.withValues(alpha: 0.25),
            AppTheme.secondary.withValues(alpha: 0.12),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.primary.withValues(alpha: 0.4)),
      ),
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          // Tappable Avatar with Camera Badge
          GestureDetector(
            onTap: _showAvatarOptionSheet,
            child: Stack(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [AppTheme.primary, AppTheme.secondary],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primary.withValues(alpha: 0.4),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: _profilePictureUrl.isNotEmpty
                        ? Image.network(
                            ApiConstants.getFullImageUrl(_profilePictureUrl),
                            fit: BoxFit.cover,
                            width: 64,
                            height: 64,
                            errorBuilder: (context, error, stackTrace) => Center(
                              child: Text(
                                initials,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 22,
                                ),
                              ),
                            ),
                          )
                        : Center(
                            child: Text(
                              initials,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 22,
                              ),
                            ),
                          ),
                  ),
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: AppTheme.secondary,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppTheme.background, width: 2),
                    ),
                    child: const Icon(
                      Icons.camera_alt,
                      color: Colors.white,
                      size: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          // Name & Email
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _userName.isNotEmpty ? _userName : 'SmartVision User',
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _userEmail.isNotEmpty ? _userEmail : '—',
                  style: TextStyle(
                    color: AppTheme.textSecondary.withValues(alpha: 0.8),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildViewCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      decoration: AppTheme.glassBoxDecoration(),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppTheme.secondary, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }

  Widget _viewRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.textMuted, size: 18),
          const SizedBox(width: 10),
          Text(
            '$label:',
            style: const TextStyle(color: AppTheme.textMuted, fontSize: 13),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════
  // EDIT MODE — the existing form (used for onboarding AND editing)
  // ══════════════════════════════════════════════════════════════════
  Widget _buildEditMode() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (widget.isOnboarding) _buildOnboardingBanner(),
            const SizedBox(height: 20),
            _buildDiabetesTypeSection(),
            const SizedBox(height: 20),
            _buildPhysicalDetailsSection(),
            const SizedBox(height: 20),
            _buildActivityLevelSection(),
            const SizedBox(height: 20),
            _buildMedicationsSection(),
            const SizedBox(height: 20),
            if (_errorMessage != null) _buildError(),
            _buildSaveButton(),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildOnboardingBanner() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primary.withValues(alpha: 0.2),
            AppTheme.secondary.withValues(alpha: 0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.primary.withValues(alpha: 0.4)),
      ),
      child: const Row(
        children: [
          Icon(Icons.medical_information_outlined, color: AppTheme.primary),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Almost there!',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                Text(
                  'Your medical profile helps AI personalize glucose predictions.',
                  style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: AppTheme.secondary, size: 20),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildDiabetesTypeSection() {
    return Container(
      decoration: AppTheme.glassBoxDecoration(),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Diabetes Type', Icons.bloodtype_outlined),
          const SizedBox(height: 16),
          ...(_diabetesTypes.map((type) => _buildRadioTile(
            value: type['value']!,
            groupValue: _diabetesType,
            label: type['label']!,
            onChanged: (v) => setState(() => _diabetesType = v!),
          ))),
        ],
      ),
    );
  }

  Widget _buildRadioTile({
    required String value,
    required String groupValue,
    required String label,
    required ValueChanged<String?> onChanged,
  }) {
    final isSelected = value == groupValue;
    return GestureDetector(
      onTap: () => onChanged(value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primary.withValues(alpha: 0.15)
              : AppTheme.surfaceLight.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? AppTheme.primary : AppTheme.border,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
              color: isSelected ? AppTheme.primary : AppTheme.textMuted,
              size: 20,
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? AppTheme.textPrimary : AppTheme.textSecondary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhysicalDetailsSection() {
    return Container(
      decoration: AppTheme.glassBoxDecoration(),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Physical Details', Icons.person_outline),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _ageController,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: AppTheme.textPrimary),
                  decoration: const InputDecoration(
                    labelText: 'Age (years)',
                    prefixIcon: Icon(Icons.cake_outlined, color: AppTheme.textMuted),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Required';
                    final n = int.tryParse(v);
                    if (n == null || n < 1 || n > 120) return 'Invalid age';
                    return null;
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _weightController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  style: const TextStyle(color: AppTheme.textPrimary),
                  decoration: const InputDecoration(
                    labelText: 'Weight (kg)',
                    prefixIcon: Icon(Icons.monitor_weight_outlined, color: AppTheme.textMuted),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Required';
                    final n = double.tryParse(v);
                    if (n == null || n < 20 || n > 300) return 'Invalid weight';
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: TextFormField(
                  controller: _heightController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  style: const TextStyle(color: AppTheme.textPrimary),
                  decoration: const InputDecoration(
                    labelText: 'Height (cm)',
                    prefixIcon: Icon(Icons.height_outlined, color: AppTheme.textMuted),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Required';
                    final n = double.tryParse(v);
                    if (n == null || n < 50 || n > 250) return 'Invalid height';
                    return null;
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActivityLevelSection() {
    return Container(
      decoration: AppTheme.glassBoxDecoration(),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Activity Level', Icons.directions_run_outlined),
          const SizedBox(height: 16),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 2.2,
            children: _activityLevels.map((level) {
              final isSelected = level['value'] == _activityLevel;
              return GestureDetector(
                onTap: () => setState(() => _activityLevel = level['value']),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppTheme.secondary.withValues(alpha: 0.15)
                        : AppTheme.surfaceLight.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isSelected ? AppTheme.secondary : AppTheme.border,
                      width: isSelected ? 1.5 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        level['icon'] as IconData,
                        color: isSelected ? AppTheme.secondary : AppTheme.textMuted,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              level['label'] as String,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: isSelected ? AppTheme.textPrimary : AppTheme.textSecondary,
                              ),
                            ),
                            Text(
                              level['desc'] as String,
                              style: const TextStyle(fontSize: 10, color: AppTheme.textMuted),
                              overflow: TextOverflow.ellipsis,
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

  Widget _buildMedicationsSection() {
    return Container(
      decoration: AppTheme.glassBoxDecoration(),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Medications', Icons.medication_outlined),
          const SizedBox(height: 4),
          const Text(
            'Optional — helps improve prediction accuracy',
            style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _medicationsController,
            style: const TextStyle(color: AppTheme.textPrimary),
            maxLines: 2,
            decoration: const InputDecoration(
              labelText: 'Current medications',
              hintText: 'e.g. Metformin 500mg, Insulin Glargine...',
              prefixIcon: Icon(Icons.medical_services_outlined, color: AppTheme.textMuted),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: AppTheme.danger.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppTheme.danger.withValues(alpha: 0.4)),
        ),
        child: Row(
          children: [
            const Icon(Icons.error_outline, color: AppTheme.danger, size: 16),
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
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      height: 54,
      child: ElevatedButton(
        onPressed: _isSaving ? null : _handleSave,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primary,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        child: _isSaving
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              )
            : Text(
                widget.isOnboarding ? 'Save & Continue →' : 'Save Changes',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
      ),
    );
  }
}
