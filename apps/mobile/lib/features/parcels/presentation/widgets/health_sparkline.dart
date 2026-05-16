import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../theme/app_colors.dart';

/// Compact line chart of the parcel's recent observed health, drawn from
/// the last N observations stored in Hive.
///
/// Caveat: this is **not** a satellite NDVI sparkline. True NDVI from
/// Sentinel-2 is scoped for sprint S6 (see update.md §12.1). Until then,
/// this widget shows the trend of the technician-reported severity
/// (inverted into a health score) — a faithful proxy that uses what the
/// app already collects, without misrepresenting it as remote-sensing data.
class HealthSparkline extends StatelessWidget {
  const HealthSparkline({
    super.key,
    required this.parcelId,
    this.width = 60,
    this.height = 18,
    this.maxPoints = 8,
  });

  final String parcelId;
  final double width;
  final double height;
  final int maxPoints;

  List<double> _loadSeries() {
    final box = Hive.box(AppConstants.boxObservations);
    // Hive returns Map values; we only care about ours.
    final entries = <_Entry>[];
    for (final v in box.values) {
      if (v is! Map) continue;
      if (v['parcelId'] != parcelId) continue;
      final at = DateTime.tryParse(v['at']?.toString() ?? '');
      final sev = (v['severity'] as num?)?.toDouble();
      if (at == null || sev == null) continue;
      entries.add(_Entry(at: at, severity: sev.clamp(0.0, 1.0)));
    }
    entries.sort((a, b) => a.at.compareTo(b.at));
    final tail = entries.length <= maxPoints
        ? entries
        : entries.sublist(entries.length - maxPoints);
    // Health = 1 − severity → up = better.
    return [for (final e in tail) 1.0 - e.severity];
  }

  @override
  Widget build(BuildContext context) {
    final series = _loadSeries();
    return SizedBox(
      width: width,
      height: height,
      child: CustomPaint(
        painter: _SparklinePainter(
          series: series,
          good: AppColors.success,
          bad: AppColors.danger,
          neutral: AppColors.textMutedOf(context),
        ),
      ),
    );
  }
}

class _Entry {
  const _Entry({required this.at, required this.severity});
  final DateTime at;
  final double severity;
}

class _SparklinePainter extends CustomPainter {
  _SparklinePainter({
    required this.series,
    required this.good,
    required this.bad,
    required this.neutral,
  });

  final List<double> series;
  final Color good;
  final Color bad;
  final Color neutral;

  @override
  void paint(Canvas canvas, Size size) {
    if (series.isEmpty) {
      // No data → flat dashed line in muted color.
      final p = Paint()
        ..color = neutral.withValues(alpha: 0.4)
        ..strokeWidth = 1.4
        ..style = PaintingStyle.stroke;
      canvas.drawLine(
        Offset(0, size.height / 2),
        Offset(size.width, size.height / 2),
        p,
      );
      return;
    }
    if (series.length == 1) {
      // Single observation → just a dot at that level.
      final h = series.first;
      final color = h >= 0.6 ? good : (h >= 0.3 ? neutral : bad);
      canvas.drawCircle(
        Offset(size.width / 2, size.height * (1 - h)),
        2.4,
        Paint()..color = color,
      );
      return;
    }

    // Build the polyline. X is evenly spaced; Y inverts (top = high health).
    final stepX = size.width / (series.length - 1);
    final path = Path();
    for (int i = 0; i < series.length; i++) {
      final x = i * stepX;
      final y = size.height * (1 - series[i]);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    // Trend color from last vs first sample — green if improving, red if
    // worsening, muted if flat (±0.05 tolerance).
    final delta = series.last - series.first;
    final color = delta > 0.05 ? good : (delta < -0.05 ? bad : neutral);

    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..strokeWidth = 1.6
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    // Dot on the latest point so the user can locate "now".
    final lastX = (series.length - 1) * stepX;
    final lastY = size.height * (1 - series.last);
    canvas.drawCircle(Offset(lastX, lastY), 2.2, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant _SparklinePainter old) =>
      old.series.length != series.length ||
      (old.series.isNotEmpty &&
          series.isNotEmpty &&
          old.series.last != series.last);
}
