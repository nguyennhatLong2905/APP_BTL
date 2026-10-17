import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod_clean_architecture/features/home/domain/models/dashboard_data.dart';

/// Biểu đồ chi tiêu theo tuần - dạng Bar Chart
class SpendingChart extends StatefulWidget {
  final List<WeeklySpending> data;

  const SpendingChart({super.key, required this.data});

  @override
  State<SpendingChart> createState() => _SpendingChartState();
}

class _SpendingChartState extends State<SpendingChart>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  int _touchedIndex = -1;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  double get _maxExpense {
    if (widget.data.isEmpty) return 1;
    return widget.data
        .map((d) => d.expense)
        .reduce((a, b) => a > b ? a : b);
  }

  String _formatMillions(double val) {
    if (val >= 1_000_000) return '${(val / 1_000_000).toStringAsFixed(1)}M';
    if (val >= 1_000) return '${(val / 1_000).toStringAsFixed(0)}K';
    return val.toStringAsFixed(0);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Chi tiêu tuần này',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF00A86B).withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'Tuần này',
                style: TextStyle(
                  fontSize: 12,
                  color: Color(0xFF00A86B),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Chart
        AnimatedBuilder(
          animation: _animation,
          builder: (context, child) {
            return SizedBox(
              height: 160,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: _maxExpense * 1.3,
                  barTouchData: BarTouchData(
                    touchCallback: (event, response) {
                      setState(() {
                        if (response == null ||
                            response.spot == null ||
                            event is FlTapUpEvent ||
                            event is FlPointerExitEvent) {
                          _touchedIndex = -1;
                        } else {
                          _touchedIndex = response.spot!.touchedBarGroupIndex;
                        }
                      });
                    },
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipColor: (_) => const Color(0xFF1A1A2E),
                      tooltipRoundedRadius: 8,
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        final d = widget.data[groupIndex];
                        return BarTooltipItem(
                          '${d.dayLabel}\n',
                          const TextStyle(
                            color: Colors.white70,
                            fontSize: 11,
                          ),
                          children: [
                            TextSpan(
                              text: _formatMillions(d.expense),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final idx = value.toInt();
                          if (idx < 0 || idx >= widget.data.length) {
                            return const SizedBox.shrink();
                          }
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              widget.data[idx].dayLabel,
                              style: TextStyle(
                                fontSize: 12,
                                color: _touchedIndex == idx
                                    ? const Color(0xFF00A86B)
                                    : Colors.grey.shade500,
                                fontWeight: _touchedIndex == idx
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                          );
                        },
                        reservedSize: 28,
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 42,
                        getTitlesWidget: (value, meta) {
                          if (value == 0) return const SizedBox.shrink();
                          return Text(
                            _formatMillions(value),
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey.shade500,
                            ),
                          );
                        },
                      ),
                    ),
                    topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                  ),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    getDrawingHorizontalLine: (value) => FlLine(
                      color: Colors.grey.shade200,
                      strokeWidth: 1,
                      dashArray: [4, 4],
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  barGroups: widget.data.asMap().entries.map((entry) {
                    final idx = entry.key;
                    final d = entry.value;
                    final isTouched = idx == _touchedIndex;
                    final barHeight = d.expense * _animation.value;

                    return BarChartGroupData(
                      x: idx,
                      barRods: [
                        BarChartRodData(
                          toY: barHeight,
                          width: 18,
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(6),
                          ),
                          gradient: LinearGradient(
                            colors: isTouched
                                ? [
                                    const Color(0xFF00A86B),
                                    const Color(0xFF2EC4B6),
                                  ]
                                : [
                                    const Color(0xFF00A86B).withOpacity(0.7),
                                    const Color(0xFF2EC4B6).withOpacity(0.5),
                                  ],
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
