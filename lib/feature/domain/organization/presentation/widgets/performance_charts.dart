import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:test_nest/model/performance_model.dart';

/// Lightweight custom line chart for exam percentage progression.
class PercentageTrendChart extends StatelessWidget {
  final List<PerformanceRecord> records;
  final double height;

  const PercentageTrendChart({
    super.key,
    required this.records,
    this.height = 200,
  });

  @override
  Widget build(BuildContext context) {
    final validRecords =
        records.where((r) => r.isCompleted && r.hasValidScore).toList()
          ..sort((a, b) {
            final aDate = a.examDate ?? a.submittedAt ?? DateTime(1970);
            final bDate = b.examDate ?? b.submittedAt ?? DateTime(1970);
            return aDate.compareTo(bDate); // Chronological
          });

    if (validRecords.isEmpty) {
      return Container(
        height: height,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.show_chart, color: Color(0xFF94A3B8), size: 36),
            SizedBox(height: 8),
            Text(
              'No completed exam attempts yet to plot trend',
              style: TextStyle(
                color: Color(0xFF64748B),
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      height: height,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x05000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Percentage Trend (%)',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF0F172A),
                ),
              ),
              Text(
                '${validRecords.length} ${validRecords.length == 1 ? "exam" : "exams"}',
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF64748B),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: CustomPaint(
              painter: _TrendChartPainter(records: validRecords),
              size: Size.infinite,
            ),
          ),
        ],
      ),
    );
  }
}

class _TrendChartPainter extends CustomPainter {
  final List<PerformanceRecord> records;

  _TrendChartPainter({required this.records});

  @override
  void paint(Canvas canvas, Size size) {
    const leftMargin = 32.0;
    const bottomMargin = 20.0;
    const topMargin = 10.0;
    const rightMargin = 12.0;

    final chartWidth = size.width - leftMargin - rightMargin;
    final chartHeight = size.height - topMargin - bottomMargin;

    if (chartWidth <= 0 || chartHeight <= 0) return;

    final gridPaint = Paint()
      ..color = const Color(0xFFF1F5F9)
      ..strokeWidth = 1.0;

    final axisTextPainter = TextPainter(textDirection: ui.TextDirection.ltr);

    // Draw Y-axis grid lines: 0%, 50%, 100%
    for (final pct in [0, 50, 100]) {
      final y = topMargin + chartHeight * (1.0 - (pct / 100.0));
      canvas.drawLine(
        Offset(leftMargin, y),
        Offset(size.width - rightMargin, y),
        gridPaint,
      );

      axisTextPainter.text = TextSpan(
        text: '$pct%',
        style: const TextStyle(
          color: Color(0xFF94A3B8),
          fontSize: 10,
          fontWeight: FontWeight.w500,
        ),
      );
      axisTextPainter.layout();
      axisTextPainter.paint(canvas, Offset(0, y - axisTextPainter.height / 2));
    }

    if (records.length == 1) {
      // Single record: plot center circle and label
      final r = records.first;
      final x = leftMargin + chartWidth / 2;
      final y =
          topMargin +
          chartHeight * (1.0 - (r.percentage.clamp(0.0, 100.0) / 100.0));

      final dotPaint = Paint()
        ..color = const Color(0xFF4F46E5)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(Offset(x, y), 6, dotPaint);

      // Label
      axisTextPainter.text = TextSpan(
        text: '${r.percentage.toStringAsFixed(1)}%',
        style: const TextStyle(
          color: Color(0xFF4F46E5),
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      );
      axisTextPainter.layout();
      axisTextPainter.paint(
        canvas,
        Offset(x - axisTextPainter.width / 2, y - 18),
      );
      return;
    }

    // Multiple points
    final points = <Offset>[];
    final stepX = chartWidth / (records.length - 1);

    for (var i = 0; i < records.length; i++) {
      final r = records[i];
      final x = leftMargin + i * stepX;
      final y =
          topMargin +
          chartHeight * (1.0 - (r.percentage.clamp(0.0, 100.0) / 100.0));
      points.add(Offset(x, y));
    }

    // Line path
    final linePath = Path()..moveTo(points.first.dx, points.first.dy);
    for (var i = 1; i < points.length; i++) {
      linePath.lineTo(points[i].dx, points[i].dy);
    }

    // Fill path
    final fillPath = Path()..moveTo(points.first.dx, points.first.dy);
    for (var i = 1; i < points.length; i++) {
      fillPath.lineTo(points[i].dx, points[i].dy);
    }
    fillPath.lineTo(points.last.dx, topMargin + chartHeight);
    fillPath.lineTo(points.first.dx, topMargin + chartHeight);
    fillPath.close();

    final fillPaint = Paint()
      ..shader =
          const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0x334F46E5), Color(0x054F46E5)],
          ).createShader(
            Rect.fromLTWH(leftMargin, topMargin, chartWidth, chartHeight),
          );

    canvas.drawPath(fillPath, fillPaint);

    final linePaint = Paint()
      ..color = const Color(0xFF4F46E5)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(linePath, linePaint);

    // Dots and point labels
    final dotPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final dotBorderPaint = Paint()
      ..color = const Color(0xFF4F46E5)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    for (var i = 0; i < points.length; i++) {
      final p = points[i];
      canvas.drawCircle(p, 4.5, dotPaint);
      canvas.drawCircle(p, 4.5, dotBorderPaint);

      // Label on selected or first/last points to avoid clutter
      if (records.length <= 6 || i == 0 || i == records.length - 1) {
        final pctText = '${records[i].percentage.toStringAsFixed(0)}%';
        axisTextPainter.text = TextSpan(
          text: pctText,
          style: const TextStyle(
            color: Color(0xFF334155),
            fontSize: 9,
            fontWeight: FontWeight.bold,
          ),
        );
        axisTextPainter.layout();
        final textY = (p.dy - 14) < topMargin ? (p.dy + 6) : (p.dy - 14);
        axisTextPainter.paint(
          canvas,
          Offset(p.dx - axisTextPainter.width / 2, textY),
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _TrendChartPainter oldDelegate) => true;
}

/// Horizontal bar chart widget for comparing average percentages across subjects.
class SubjectComparisonBarChart extends StatelessWidget {
  final List<SubjectPerformance> subjects;

  const SubjectComparisonBarChart({super.key, required this.subjects});

  @override
  Widget build(BuildContext context) {
    if (subjects.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: const Text(
          'No subject performance data available yet.',
          style: TextStyle(color: Color(0xFF64748B), fontSize: 13),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x05000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Subject-wise Comparison',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 16),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: subjects.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final s = subjects[index];
              final pct = s.averagePercentage.clamp(0.0, 100.0);
              final color = _getScoreColor(pct);

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          s.subjectName,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF334155),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        '${pct.toStringAsFixed(1)}% (${s.totalExams} ${s.totalExams == 1 ? "exam" : "exams"})',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: Stack(
                      children: [
                        Container(height: 8, color: const Color(0xFFF1F5F9)),
                        FractionallySizedBox(
                          widthFactor: (pct / 100.0).clamp(0.0, 1.0),
                          child: Container(
                            height: 8,
                            decoration: BoxDecoration(
                              color: color,
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Color _getScoreColor(double percentage) {
    if (percentage >= 80) return const Color(0xFF10B981);
    if (percentage >= 60) return const Color(0xFF3B82F6);
    if (percentage >= 40) return const Color(0xFFF59E0B);
    return const Color(0xFFEF4444);
  }
}
