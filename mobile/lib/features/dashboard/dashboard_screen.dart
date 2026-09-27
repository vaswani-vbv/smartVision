import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../core/models/glucose_reading_model.dart';
import '../../core/network/token_storage.dart';
import '../auth/login_screen.dart';
import '../profile/medical_profile_screen.dart';
import '../scanner/camera_scanner_screen.dart';
import '../history/meal_history_screen.dart';
import '../meal_planner/meal_planner_screen.dart';
import 'glucose_service.dart';
import 'glucose_chart.dart';
import 'log_glucose_modal.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedDays = 30;
  bool _isLoading = true;

  List<GlucoseReadingModel> _readings = [];
  GlucoseStatsModel? _stats;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        GlucoseService.getHistory(days: _selectedDays),
        GlucoseService.getStats(days: _selectedDays),
      ]);

      if (!mounted) return;

      setState(() {
        _readings = results[0] as List<GlucoseReadingModel>;
        _stats = results[1] as GlucoseStatsModel?;
      });
    } catch (_) {
      if (!mounted) return;
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _openLogModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => LogGlucoseModal(onLogSaved: _loadDashboardData),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'high':
        return AppTheme.danger;
      case 'elevated':
        return AppTheme.warning;
      case 'low':
        return AppTheme.primaryLight;
      case 'normal':
      default:
        return AppTheme.success;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.remove_red_eye_outlined, color: AppTheme.secondary),
            const SizedBox(width: 8),
            ShaderMask(
              shaderCallback: (bounds) => const LinearGradient(
                colors: [AppTheme.primary, AppTheme.secondary],
              ).createShader(bounds),
              child: const Text(
                'SmartVision',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_outline, color: AppTheme.secondary),
            tooltip: 'Medical Profile',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const MedicalProfileScreen(isOnboarding: false),
                ),
              ).then((_) => _loadDashboardData());
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: AppTheme.textSecondary),
            onPressed: _loadDashboardData,
          ),
          IconButton(
            icon: const Icon(Icons.logout_outlined, color: AppTheme.textSecondary),
            onPressed: () async {
              await TokenStorageService.deleteToken();
              if (context.mounted) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                );
              }
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadDashboardData,
        color: AppTheme.primary,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildQuickActionBanner(),
              const SizedBox(height: 20),
              if (_isLoading)
                const SizedBox(
                  height: 180,
                  child: Center(child: CircularProgressIndicator(color: AppTheme.primary)),
                )
              else ...[
                _buildStatsSummaryCard(),
                const SizedBox(height: 20),
                _buildGlucoseChartCard(),
                const SizedBox(height: 20),
                _buildReadingsHistoryList(),
              ],
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActionBanner() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppTheme.glassBoxDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Glucose & Food Tracking',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Scan meal photos or log blood sugar readings.',
            style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const CameraScannerScreen()),
                      );
                    },
                    icon: const Icon(Icons.camera_alt_outlined, size: 20),
                    label: const Text('Scan Meal'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SizedBox(
                  height: 48,
                  child: OutlinedButton.icon(
                    onPressed: _openLogModal,
                    icon: const Icon(Icons.add, color: AppTheme.secondary, size: 20),
                    label: const Text('Log Reading', style: TextStyle(color: AppTheme.textPrimary)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppTheme.border),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 42,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const MealPlannerScreen()),
                      );
                    },
                    icon: const Icon(Icons.psychology_outlined, size: 18),
                    label: const Text(
                      'AI Meal Planner',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.secondary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: SizedBox(
                  height: 42,
                  child: TextButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const MealHistoryScreen()),
                      );
                    },
                    icon: const Icon(Icons.history_outlined, color: AppTheme.secondary, size: 18),
                    label: const Text(
                      'Food History',
                      style: TextStyle(color: AppTheme.secondary, fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    style: TextButton.styleFrom(
                      backgroundColor: AppTheme.secondary.withValues(alpha: 0.1),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatsSummaryCard() {
    final avg = _stats?.averageMgdl ?? 0.0;
    final inRangePct = _stats?.inRangePct ?? 0.0;
    final high = _stats?.highestMgdl ?? 0.0;
    final low = _stats?.lowestMgdl ?? 0.0;

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
                  Icon(Icons.pie_chart_outline, color: AppTheme.success, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Time-in-Range (70-140 mg/dL)',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ],
              ),
              Text(
                '${inRangePct.toStringAsFixed(0)}%',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.success,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: (inRangePct / 100).clamp(0.0, 1.0),
              minHeight: 10,
              backgroundColor: AppTheme.surfaceLight,
              valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.success),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem('Average', '${avg.toStringAsFixed(0)} mg/dL', AppTheme.primaryLight),
              Container(width: 1, height: 30, color: AppTheme.border),
              _buildStatItem('Highest', '${high.toInt()} mg/dL', AppTheme.danger),
              Container(width: 1, height: 30, color: AppTheme.border),
              _buildStatItem('Lowest', '${low.toInt()} mg/dL', AppTheme.secondary),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: AppTheme.textMuted)),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color),
        ),
      ],
    );
  }

  Widget _buildGlucoseChartCard() {
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
                  Icon(Icons.show_chart, color: AppTheme.primary, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Glucose Trends',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ],
              ),
              Row(
                children: [7, 14, 30].map((d) {
                  final isSelected = d == _selectedDays;
                  return GestureDetector(
                    onTap: () {
                      setState(() => _selectedDays = d);
                      _loadDashboardData();
                    },
                    child: Container(
                      margin: const EdgeInsets.only(left: 4),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppTheme.primary.withValues(alpha: 0.25)
                            : AppTheme.surfaceLight.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isSelected ? AppTheme.primary : AppTheme.border,
                        ),
                      ),
                      child: Text(
                        '${d}D',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          color: isSelected ? AppTheme.primaryLight : AppTheme.textMuted,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
          const SizedBox(height: 16),
          GlucoseTrendChart(readings: _readings),
        ],
      ),
    );
  }

  Widget _buildReadingsHistoryList() {
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
                  Icon(Icons.history, color: AppTheme.secondary, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Recent Log Entries',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ],
              ),
              Text(
                '${_readings.length} total',
                style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (_readings.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text(
                  'No readings logged yet.\nTap "Log Reading" to add your first entry!',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _readings.length > 5 ? 5 : _readings.length,
              separatorBuilder: (context, index) => const Divider(color: AppTheme.border, height: 1),
              itemBuilder: (context, index) {
                final reading = _readings[index];
                final status = reading.statusCategory;
                final statusColor = _getStatusColor(status);
                final timeFormatted = DateFormat('MMM d, h:mm a').format(reading.measuredAt);

                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.water_drop, color: statusColor, size: 20),
                  ),
                  title: Row(
                    children: [
                      Text(
                        '${reading.valueMgdl.toInt()} mg/dL',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: statusColor.withValues(alpha: 0.4)),
                        ),
                        child: Text(
                          status.toUpperCase(),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: statusColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  subtitle: Text(
                    '${reading.readingType.replaceAll('_', ' ').toUpperCase()} • $timeFormatted',
                    style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}
