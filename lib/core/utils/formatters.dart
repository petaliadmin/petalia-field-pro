import 'package:intl/intl.dart';

class Fmt {
  Fmt._();

  static String date(DateTime d, {String pattern = 'd MMM yyyy'}) =>
      DateFormat(pattern).format(d);

  static String dateTime(DateTime d) => DateFormat('d MMM · HH:mm').format(d);

  static String relative(DateTime d) {
    final diff = DateTime.now().difference(d);
    if (diff.inSeconds < 60) return 'à l\'instant';
    if (diff.inMinutes < 60) return 'il y a ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'il y a ${diff.inHours} h';
    if (diff.inDays < 7) return 'il y a ${diff.inDays} j';
    return date(d);
  }

  static String hectares(double ha) {
    if (ha < 0.01) return '${(ha * 10000).toStringAsFixed(0)} m²';
    if (ha < 1) return '${(ha * 10000).toStringAsFixed(0)} m²';
    return '${ha.toStringAsFixed(2)} ha';
  }

  static String percent(double v) => '${(v * 100).round()}%';
}
