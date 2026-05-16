import 'package:flutter_test/flutter_test.dart';
import 'package:petaliacropassist/core/services/alert_engine.dart';

void main() {
  group('Alert', () {
    final base = Alert(
      id: 'a1',
      parcelId: 'p1',
      title: 'Test',
      message: 'Lorem',
      severity: AlertSeverity.high,
      category: AlertCategory.pest,
      createdAt: DateTime.utc(2026, 5, 12),
    );

    test('copyWith only mutates isRead, preserves identity', () {
      final read = base.copyWith(isRead: true);
      expect(read.isRead, isTrue);
      expect(read.id, base.id);
      expect(read.parcelId, base.parcelId);
      expect(read.title, base.title);
      expect(read.message, base.message);
      expect(read.severity, base.severity);
      expect(read.category, base.category);
      expect(read.createdAt, base.createdAt);
    });

    test('copyWith() with no args returns equivalent values', () {
      final clone = base.copyWith();
      expect(clone.isRead, base.isRead);
      expect(clone.id, base.id);
    });

    test('default isRead is false', () {
      expect(base.isRead, isFalse);
    });
  });

  group('AlertSeverity enum', () {
    test('preserves ordering low < medium < high < urgent', () {
      expect(AlertSeverity.values, [
        AlertSeverity.low,
        AlertSeverity.medium,
        AlertSeverity.high,
        AlertSeverity.urgent,
      ]);
    });
  });
}
