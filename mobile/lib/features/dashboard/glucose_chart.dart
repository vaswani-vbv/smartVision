import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../core/models/glucose_reading_model.dart';

class GlucoseTrendChart extends StatelessWidget {
  final List<GlucoseReadingModel> readings;

  const GlucoseTrendChart({super.key, required this.readings});

  Color _getPointColor(double value) {
    if (value < 70) return AppTheme.primaryLight;
    if (value <= 140) return AppTheme.success;
    if (value <= 180) return AppTheme.warning;
    return AppTheme.danger;
  }

  @override
  Widget build(BuildContext context) {
    if (readings.isEmpty) {
      return Container(
        height: 220,
        alignment: Alignment.center,
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.show_chart, color: AppTheme.textMuted, size: 40),
            SizedBox(height: 8),
            Text(
              'No glucose readings for this period',
              style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
            ),
          ],
        ),
      );
    }

    // Sort chronologically (oldest to newest for left-to-right chart)
    final sorted = List<GlucoseReadingModel>.from(readings)
      ..sort((a, b) => a.measuredAt.compareTo(b.measuredAt));

    final spots = <FlSpot>[];
    for (int i = 0; i < sorted.length; i++) {
      spots.add(FlSpot(i.toDouble(), sorted[i].valueMgdl));
    }

    double maxY = 200.0;
    double minY = 50.0;
    for (final r in sorted) {
      if (r.valueMgdl + 20 > maxY) maxY = r.valueMgdl + 20;
      if (r.valueMgdl - 20 < minY) minY = (r.valueMgdl - 20).clamp(30.0, 50.0);
    }

    return Container(
      height: 220,
      padding: const EdgeInsets.only(right: 16, left: 4, top: 16, bottom: 8),
      child: LineChart(
        LineChartData(
          minX: 0,
          maxX: (sorted.length - 1).toDouble().clamp(1.0, 100.0),
          minY: minY,
          maxY: maxY,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: 40,
            getDrawingHorizontalLine: (value) {
              if (value == 70 || value == 140) {
                return FlLine(
                  color: AppTheme.success.withValues(alpha: 0.4),
                  strokeWidth: 1.5,
                  dashArray: [6, 4],
                );
              }
              return FlLine(
                color: AppTheme.border.withValues(alpha: 0.3),
                strokeWidth: 1,
              );
            },
          ),
          titlesData: FlTitlesData(
            show: true,
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 26,
                interval: (sorted.length / 4).clamp(1.0, 10.0),
                getTitlesWidget: (value, meta) {
                  final idx = value.toInt();
                  if (idx >= 0 && idx < sorted.length) {
                    final dt = sorted[idx].measuredAt;
                    return Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        DateFormat('MMM d').format(dt),
                        style: const TextStyle(
                          color: AppTheme.textMuted,
                          fontSize: 10,
                        ),
                      ),
                    );
                  }
                  return const SizedBox();
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 36,
                interval: 40,
                getTitlesWidget: (value, meta) {
                  return Text(
                    '${value.toInt()}',
                    style: const TextStyle(
                      color: AppTheme.textMuted,
                      fontSize: 10,
                    ),
                  );
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              curveSmoothness: 0.3,
              color: AppTheme.primary,
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, barData, index) {
                  return FlDotCirclePainter(
                    radius: 5,
                    color: _getPointColor(spot.y),
                    strokeWidth: 2,
                    strokeColor: Colors.white,
                  );
                },
              ),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  colors: [
                    AppTheme.primary.withValues(alpha: 0.25),
                    AppTheme.primary.withValues(alpha: 0.0),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ],
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipItems: (touchedSpots) {
                return touchedSpots.map((spot) {
                  final idx = spot.spotIndex;
                  final reading = sorted[idx];
                  final formattedTime = DateFormat('MMM d, h:mm a').format(reading.measuredAt);
                  final typeStr = reading.readingType.replaceAll('_', ' ').toUpperCase();

                  return LineTooltipItem(
                    '${reading.valueMgdl.toInt()} mg/dL ($typeStr)\n$formattedTime',
                    const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  );
                }).toList();
              },
            ),
          ),
        ),
      ),
    );
  }
}
