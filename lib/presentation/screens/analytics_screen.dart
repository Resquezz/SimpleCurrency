import 'dart:async';
import 'dart:math';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../core/app_theme.dart';
import '../controllers/app_controller.dart';
import '../widgets/shared_widgets.dart';

class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key, required this.controller});

  final AppController controller;

  static const _rangeOptions = [7, 30, 90, 180];

  @override
  Widget build(BuildContext context) {
    final line = appLineColor(context);
    final card = Theme.of(context).cardColor;
    final history = controller.analyticsHistory;
    final change = history.length >= 2 ? ((history.last.rate - history.first.rate) / history.first.rate) * 100 : 0.0;
    final minRate = history.isEmpty ? 0.0 : history.map((point) => point.rate).reduce(min);
    final maxRate = history.isEmpty ? 0.0 : history.map((point) => point.rate).reduce(max);
    final spots = history.asMap().entries.map((entry) => FlSpot(entry.key.toDouble(), entry.value.rate)).toList(growable: false);
    final paddedMin = history.isEmpty ? 0.0 : ((minRate * 0.995).clamp(0.0, double.infinity) as num).toDouble();
    final paddedMax = history.isEmpty ? 0.0 : (maxRate * 1.005).toDouble();

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
      children: [
        Text('Аналітика', style: Theme.of(context).textTheme.headlineLarge),
        const SizedBox(height: 18),
        Row(
          children: [
            Expanded(
              child: CurrencyDropdown(
                value: controller.analyticsBase,
                codes: controller.availableCodes,
                codeLabelBuilder: controller.currencyOptionLabel,
                nameBuilder: controller.currencyName,
                onChanged: (value) => unawaited(controller.setAnalyticsBase(value)),
              ),
            ),
            Padding(padding: const EdgeInsets.symmetric(horizontal: 12), child: Text('/', style: TextStyle(fontSize: 30, color: line))),
            Expanded(
              child: CurrencyDropdown(
                value: controller.analyticsTarget,
                codes: controller.availableCodes,
                codeLabelBuilder: controller.currencyOptionLabel,
                nameBuilder: controller.currencyName,
                onChanged: (value) => unawaited(controller.setAnalyticsTarget(value)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SegmentedButton<int>(
            segments: _rangeOptions
                .map((days) => ButtonSegment<int>(value: days, label: Text(days >= 30 ? '${days ~/ 30} міс.' : '$days днів')))
                .toList(),
            selected: {controller.analyticsRangeDays},
            showSelectedIcon: false,
            onSelectionChanged: (selection) => unawaited(controller.setAnalyticsRangeDays(selection.first)),
          ),
        ),
        const SizedBox(height: 18),
        SectionCard(
          child: controller.isHistoryLoading
              ? const SizedBox(height: 320, child: Center(child: CircularProgressIndicator()))
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('${controller.analyticsBase}/${controller.analyticsTarget}', style: const TextStyle(color: mutedText, fontWeight: FontWeight.w700)),
                              const SizedBox(height: 10),
                              Text(controller.formatRate(controller.rateBetween(controller.analyticsBase, controller.analyticsTarget)), style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w900)),
                              const SizedBox(height: 6),
                              Text('Зміна за останні ${controller.analyticsRangeDays} днів', style: const TextStyle(color: mutedText, fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                        AnalyticsDeltaBadge(change: change),
                      ],
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      height: 220,
                      child: history.isEmpty
                          ? const Center(child: Text('Немає історичних даних для цієї пари.'))
                          : LineChart(
                              LineChartData(
                                minX: 0,
                                maxX: max(0, history.length - 1).toDouble(),
                                minY: paddedMin,
                                maxY: paddedMax,
                                gridData: FlGridData(
                                  show: true,
                                  drawVerticalLine: false,
                                  horizontalInterval: history.length < 3 ? null : (paddedMax - paddedMin) / 3,
                                  getDrawingHorizontalLine: (_) => FlLine(color: line, strokeWidth: 1),
                                ),
                                borderData: FlBorderData(show: false),
                                lineTouchData: LineTouchData(
                                  handleBuiltInTouches: true,
                                  touchTooltipData: LineTouchTooltipData(
                                    getTooltipColor: (_) => inkColor,
                                    getTooltipItems: (spots) => spots
                                        .map(
                                          (spot) => LineTooltipItem(
                                            '${history[spot.x.toInt()].label}\n${controller.formatRate(spot.y)}',
                                            const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                                          ),
                                        )
                                        .toList(),
                                  ),
                                ),
                                titlesData: FlTitlesData(
                                  leftTitles: AxisTitles(
                                    sideTitles: SideTitles(
                                      showTitles: true,
                                      reservedSize: 52,
                                      interval: history.length < 3 ? null : (paddedMax - paddedMin) / 3,
                                      getTitlesWidget: (value, meta) => Padding(
                                        padding: const EdgeInsets.only(right: 10),
                                        child: Text(
                                          controller.formatRate(value),
                                          style: const TextStyle(color: mutedText, fontWeight: FontWeight.w600, fontSize: 11),
                                          textAlign: TextAlign.right,
                                        ),
                                      ),
                                    ),
                                  ),
                                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                  bottomTitles: AxisTitles(
                                    sideTitles: SideTitles(
                                      showTitles: true,
                                      reservedSize: 30,
                                      interval: max(1, (history.length / 4).floor()).toDouble(),
                                      getTitlesWidget: (value, meta) {
                                        final index = value.toInt();
                                        if (index < 0 || index >= history.length) {
                                          return const SizedBox.shrink();
                                        }
                                        if (index != 0 && index != history.length - 1 && index % max(1, (history.length / 4).floor()) != 0) {
                                          return const SizedBox.shrink();
                                        }
                                        return Padding(
                                          padding: const EdgeInsets.only(top: 8),
                                          child: Text(history[index].label, style: const TextStyle(color: mutedText, fontWeight: FontWeight.w700)),
                                        );
                                      },
                                    ),
                                  ),
                                ),
                                lineBarsData: [
                                  LineChartBarData(
                                    spots: spots,
                                    isCurved: true,
                                    color: accentColor,
                                    barWidth: 3.2,
                                    isStrokeCapRound: true,
                                    dotData: FlDotData(
                                      show: history.length <= 12,
                                      getDotPainter: (spot, percent, bar, index) => FlDotCirclePainter(radius: 3.6, color: accentColor, strokeWidth: 2, strokeColor: card),
                                    ),
                                    belowBarData: BarAreaData(
                                      show: true,
                                      gradient: LinearGradient(
                                        colors: [accentColor.withValues(alpha: 0.22), accentColor.withValues(alpha: 0.03)],
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                    ),
                  ],
                ),
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            Expanded(child: StatsCard(title: 'Мін. за період', value: controller.formatRate(minRate))),
            const SizedBox(width: 14),
            Expanded(child: StatsCard(title: 'Макс. за період', value: controller.formatRate(maxRate))),
          ],
        ),
      ],
    );
  }
}