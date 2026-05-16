import 'package:intl/intl.dart';
import '../../l10n/gen/app_localizations.dart';

class Fmt {
  Fmt._();

  static String date(DateTime d, {String pattern = 'd MMM yyyy'}) =>
      DateFormat(pattern).format(d);

  static String dateTime(DateTime d) => DateFormat('d MMM · HH:mm').format(d);

  static String relative(DateTime d, AppLocalizations l10n) {
    final diff = DateTime.now().difference(d);
    if (diff.inSeconds < 60) return l10n.relativeNow;
    if (diff.inMinutes < 60) return l10n.relativeMinutes(diff.inMinutes);
    if (diff.inHours < 24) return l10n.relativeHours(diff.inHours);
    if (diff.inDays < 7) return l10n.relativeDays(diff.inDays);
    return date(d);
  }

  static String hectares(double ha) {
    if (ha < 0.01) return '${(ha * 10000).toStringAsFixed(0)} m²';
    if (ha < 1) return '${(ha * 10000).toStringAsFixed(0)} m²';
    return '${ha.toStringAsFixed(2)} ha';
  }

  static String percent(double v) => '${(v * 100).round()}%';
}
