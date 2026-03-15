import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../theme/app_theme.dart';

class ProgressChart extends StatelessWidget {
  const ProgressChart({
    super.key,
    required this.values,
    required this.dates,
    this.height = 220,
    this.suffix = 'cm',
  });

  final List<double> values;
  final List<DateTime> dates;
  final double height;
  final String suffix;

  @override
  Widget build(BuildContext context) {
    if (values.isEmpty || dates.isEmpty) {
      return SizedBox(
        height: height,
        child: const Center(
          child: Text('Add more data to unlock your trend line.'),
        ),
      );
    }

    final spots = <FlSpot>[];
    for (int i = 0; i < values.length; i++) {
      spots.add(FlSpot(i.toDouble(), values[i]));
    }

    final minY = (values.reduce((a, b) => a < b ? a : b) * 0.92).clamp(0, double.infinity);
    final maxY = values.reduce((a, b) => a > b ? a : b) * 1.08;

    return SizedBox(
      height: height,
      child: LineChart(
        LineChartData(
          minY: minY.toDouble(),
          maxY: maxY,
          gridData: FlGridData(
            show: true,
            horizontalInterval: ((maxY - minY) / 4).abs().clamp(1, 1000).toDouble(),
            getDrawingHorizontalLine: (_) => FlLine(color: AppTheme.border, strokeWidth: 1),
            drawVerticalLine: false,
          ),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                getTitlesWidget: (value, meta) {
                  return Text(
                    value.toStringAsFixed(0),
                    style: const TextStyle(color: AppTheme.subtleText, fontSize: 11),
                  );
                },
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 28,
                interval: values.length > 5 ? 2 : 1,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index < 0 || index >= dates.length) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      DateFormat('MM/dd').format(dates[index]),
                      style: const TextStyle(color: AppTheme.subtleText, fontSize: 11),
                    ),
                  );
                },
              ),
            ),
          ),
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              tooltipRoundedRadius: 12,
              getTooltipColor: (_) => AppTheme.card,
              getTooltipItems: (items) {
                return items.map((item) {
                  final index = item.x.toInt();
                  return LineTooltipItem(
                    '${DateFormat('MMM d').format(dates[index])}\n${item.y.toStringAsFixed(1)} $suffix',
                    const TextStyle(color: AppTheme.text, fontWeight: FontWeight.w700),
                  );
                }).toList();
              },
            ),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: AppTheme.primary,
              barWidth: 4,
              dotData: FlDotData(
                show: true,
                getDotPainter: (_, __, ___, ____) => FlDotCirclePainter(
                  radius: 4,
                  color: AppTheme.primary,
                  strokeWidth: 2,
                  strokeColor: AppTheme.text,
                ),
              ),
              belowBarData: BarAreaData(
                show: true,
                color: AppTheme.primary.withOpacity(0.15),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
