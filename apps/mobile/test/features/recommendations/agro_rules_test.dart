import 'package:flutter_test/flutter_test.dart';
import 'package:petaliacropassist/features/recommendations/data/agro_rules_repository.dart';
import 'package:petaliacropassist/features/recommendations/domain/agro_rule.dart';

void main() {
  group('AgroRule matching logic', () {
    const testRule = AgroRule(
      id: 'TEST-1',
      crop: 'arachide',
      stages: ['vegetative'],
      symptom: 'yellow_leaves',
      season: 'hivernage',
      regions: ['thies'],
      severityMin: 0.3,
      diagnosis: 'Test diagnosis',
      recommendation: AgroRecommendation(
        title: 'Test title',
        actions: ['Action 1'],
        costFcfaPerHa: 1000,
        delayBeforeHarvestDays: 0,
        ppeRequired: false,
        followupDays: 7,
      ),
      validatedBy: 'Test source',
    );

    test('should match correct context', () {
      expect(
        testRule.matches(
          crop: 'arachide',
          stage: 'vegetative',
          symptom: 'yellow_leaves',
          season: 'hivernage',
          region: 'thies',
          severity: 0.5,
        ),
        isTrue,
      );
    });

    test('should not match different crop', () {
      expect(
        testRule.matches(
          crop: 'mais',
          stage: 'vegetative',
          symptom: 'yellow_leaves',
          season: 'hivernage',
          region: 'thies',
          severity: 0.5,
        ),
        isFalse,
      );
    });

    test('should not match different symptom', () {
      expect(
        testRule.matches(
          crop: 'arachide',
          stage: 'vegetative',
          symptom: 'spots',
          season: 'hivernage',
          region: 'thies',
          severity: 0.5,
        ),
        isFalse,
      );
    });

    test('should not match if severity is too low', () {
      expect(
        testRule.matches(
          crop: 'arachide',
          stage: 'vegetative',
          symptom: 'yellow_leaves',
          season: 'hivernage',
          region: 'thies',
          severity: 0.2,
        ),
        isFalse,
      );
    });

    test('should match wildcard crop', () {
      final genericRule = AgroRule(
        id: 'GENERIC-1',
        crop: '*',
        stages: ['*'],
        symptom: 'drought',
        season: '*',
        regions: ['*'],
        severityMin: 0.0,
        diagnosis: 'Drought',
        recommendation: const AgroRecommendation(
          title: 'Water it',
          actions: [],
          costFcfaPerHa: 0,
          delayBeforeHarvestDays: 0,
          ppeRequired: false,
          followupDays: 3,
        ),
        validatedBy: 'Source',
      );

      expect(
        genericRule.matches(
          crop: 'riz',
          stage: 'flowering',
          symptom: 'drought',
          season: 'contreSaison',
          region: 'saint_louis',
          severity: 0.1,
        ),
        isTrue,
      );
    });
  });

  group('matchRules sorting and filtering', () {
    final rules = [
      const AgroRule(
        id: 'GENERIC-YELLOW',
        crop: '*',
        stages: ['*'],
        symptom: 'yellow_leaves',
        season: '*',
        regions: ['*'],
        severityMin: 0.0,
        diagnosis: 'Generic yellow',
        recommendation: AgroRecommendation(
          title: 'Generic',
          actions: [],
          costFcfaPerHa: 0,
          delayBeforeHarvestDays: 0,
          ppeRequired: false,
          followupDays: 7,
        ),
        validatedBy: 'Source',
      ),
      const AgroRule(
        id: 'ARACHIDE-SPECIFIC-YELLOW',
        crop: 'arachide',
        stages: ['vegetative'],
        symptom: 'yellow_leaves',
        season: 'hivernage',
        regions: ['thies'],
        severityMin: 0.5,
        diagnosis: 'Specific yellow for Arachide in Thies',
        recommendation: AgroRecommendation(
          title: 'Specific',
          actions: [],
          costFcfaPerHa: 5000,
          delayBeforeHarvestDays: 0,
          ppeRequired: false,
          followupDays: 7,
        ),
        validatedBy: 'Source',
      ),
    ];

    test('should return matched rules sorted by specificity', () {
      final results = matchRules(
        allRules: rules,
        crop: 'arachide',
        stage: 'vegetative',
        symptoms: ['yellow_leaves'],
        severity: 0.6,
        region: 'thies',
        season: 'hivernage',
      );

      expect(results.length, 2);
      expect(results.first.id, 'ARACHIDE-SPECIFIC-YELLOW');
      expect(results.last.id, 'GENERIC-YELLOW');
    });

    test('should filter out rules with higher severityMin', () {
      final results = matchRules(
        allRules: rules,
        crop: 'arachide',
        stage: 'vegetative',
        symptoms: ['yellow_leaves'],
        severity: 0.3,
        region: 'thies',
        season: 'hivernage',
      );

      expect(results.length, 1);
      expect(results.first.id, 'GENERIC-YELLOW');
    });
  });

  group('CropsCatalog and resolveCropId', () {
    test('should resolve crop by label FR', () {
      expect(resolveCropId('Arachide'), 'arachide');
      expect(resolveCropId('Maïs'), 'mais');
    });

    test('should resolve crop by ID', () {
      expect(resolveCropId('riz'), 'riz');
    });

    test('should be case and accent insensitive', () {
      expect(resolveCropId('MAIS'), 'mais');
      expect(resolveCropId('mais'), 'mais');
    });
  });

  group('Real-world scenarios from agro_rules.json', () {
    // Mock rules extracted from the JSON for specific testing
    final realRules = [
      const AgroRule(
        id: 'ARA-VEG-YELLOW-RAINY',
        crop: 'arachide',
        stages: ['vegetative', 'flowering'],
        symptom: 'yellow_leaves',
        season: 'hivernage',
        regions: ['thies', 'diourbel', 'fatick', 'kaolack', 'kaffrine'],
        severityMin: 0.3,
        diagnosis: 'Jaunissement sur arachide — nodulation défaillante...',
        recommendation: AgroRecommendation(
          title: 'Vérifier la nodulation avant tout apport',
          actions: [],
          costFcfaPerHa: 12000,
          delayBeforeHarvestDays: 0,
          ppeRequired: false,
          followupDays: 7,
        ),
        validatedBy: 'ISRA',
      ),
      const AgroRule(
        id: 'MAIS-VEG-CHENILLE-FAW',
        crop: 'mais',
        stages: ['germination', 'vegetative', 'stem_elongation'],
        symptom: 'pests',
        season: 'hivernage',
        regions: ['thies', 'fatick', 'kaolack', 'kaffrine', 'tambacounda', 'kolda', 'sedhiou', 'ziguinchor'],
        severityMin: 0.2,
        diagnosis: 'Chenille légionnaire d\'automne...',
        recommendation: AgroRecommendation(
          title: 'Intervention rapide sur le cornet',
          actions: [],
          costFcfaPerHa: 11000,
          delayBeforeHarvestDays: 14,
          ppeRequired: true,
          followupDays: 5,
        ),
        validatedBy: 'DPV',
      ),
    ];

    test('Arachide yellowing in Thies (Hivernage)', () {
      final results = matchRules(
        allRules: realRules,
        crop: 'Arachide',
        stage: 'vegetative',
        symptoms: ['yellow_leaves'],
        severity: 0.4,
        region: 'thies',
        season: 'hivernage',
      );
      expect(results.length, 1);
      expect(results.first.id, 'ARA-VEG-YELLOW-RAINY');
    });

    test('Maïs FAW caterpillar in Kolda', () {
      final results = matchRules(
        allRules: realRules,
        crop: 'Maïs',
        stage: 'vegetative',
        symptoms: ['pests'],
        severity: 0.5,
        region: 'kolda',
        season: 'hivernage',
      );
      expect(results.length, 1);
      expect(results.first.id, 'MAIS-VEG-CHENILLE-FAW');
      expect(results.first.recommendation.ppeRequired, isTrue);
    });

    test('Should not match if region is not in list', () {
      final results = matchRules(
        allRules: realRules,
        crop: 'Arachide',
        stage: 'vegetative',
        symptoms: ['yellow_leaves'],
        severity: 0.4,
        region: 'saint_louis', // Not in ARA-VEG-YELLOW-RAINY regions
        season: 'hivernage',
      );
      expect(results, isEmpty);
    });
  });
}
