import 'package:flutter/material.dart';

/// A minimal, dependency-free bar chart. Draws [values] as vertical bars
/// scaled to the tallest value, with optional [labels] beneath each bar.
/// Built with CustomPainter instead of a charting package to keep the
/// project's dependency footprint at zero beyond core Flutter.
class BarTrendChart extends StatelessWidget {
  final List<double> values;
  final List<String> labels;
  final Color color;
  final double height;
  final String Function(double) valueFormatter;

  const BarTrendChart({
    super.key,
    required this.values,
    required this.labels,
    required this.color,
    this.height = 140,
    required this.valueFormatter,
  });

  @override
  Widget build(BuildContext context) {
    final maxValue = values.isEmpty ? 0.0 : values.reduce((a, b) => a > b ? a : b);
    final mutedColor = Theme.of(context).textTheme.bodySmall?.color ?? Colors.grey;
    return SizedBox(
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (maxValue > 0)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text('Peak: ${valueFormatter(maxValue)}', style: TextStyle(fontSize: 11, color: mutedColor)),
            ),
          SizedBox(
            height: height,
            width: double.infinity,
            child: CustomPaint(
              painter: _BarTrendPainter(
                values: values,
                labels: labels,
                color: color,
                maxValue: maxValue <= 0 ? 1 : maxValue,
                textColor: mutedColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BarTrendPainter extends CustomPainter {
  final List<double> values;
  final List<String> labels;
  final Color color;
  final double maxValue;
  final Color textColor;

  _BarTrendPainter({
    required this.values,
    required this.labels,
    required this.color,
    required this.maxValue,
    required this.textColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;

    const labelHeight = 18.0;
    final chartHeight = size.height - labelHeight;
    final barCount = values.length;
    const gap = 6.0;
    final barWidth = (size.width - gap * (barCount - 1)) / barCount;

    final barPaint = Paint()..color = color;

    for (int i = 0; i < barCount; i++) {
      final ratio = values[i] / maxValue;
      final barHeight = (chartHeight * ratio).clamp(2.0, chartHeight);
      final left = i * (barWidth + gap);
      final top = chartHeight - barHeight;

      final rect = RRect.fromRectAndCorners(
        Rect.fromLTWH(left, top, barWidth, barHeight),
        topLeft: const Radius.circular(4),
        topRight: const Radius.circular(4),
      );
      canvas.drawRRect(rect, barPaint);

      if (i < labels.length) {
        final tp = TextPainter(
          text: TextSpan(text: labels[i], style: TextStyle(fontSize: 9, color: textColor)),
          textDirection: TextDirection.ltr,
          textAlign: TextAlign.center,
        )..layout(maxWidth: barWidth + gap);
        tp.paint(canvas, Offset(left + (barWidth - tp.width) / 2, chartHeight + 2));
      }
    }
  }

  @override
  bool shouldRepaint(covariant _BarTrendPainter oldDelegate) {
    return oldDelegate.values != values || oldDelegate.color != color || oldDelegate.maxValue != maxValue;
  }
}
