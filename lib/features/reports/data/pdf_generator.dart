import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../../core/data/senegal_regions.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/geo_utils.dart';
import '../../parcels/domain/parcel.dart';
import '../../recommendations/domain/agro_rule.dart';

class PdfGenerator {
  Future<pw.Document> build({
    required Parcel parcel,
    required String technician,
    String? summary,
    List<String> recommendations = const [],
    List<AgroRule> matchedRules = const [],
    List<String> photoPaths = const [],
  }) async {
    final doc = pw.Document();
    final area = GeoUtils.polygonAreaHa(parcel.boundary);
    final regionLabel = parcel.region != null
        ? SenegalRegions.byId(parcel.region!)?.labelFr
        : null;

    // Load photo images (skip on web or if files don't exist).
    final photoImages = <pw.MemoryImage>[];
    if (!kIsWeb) {
      for (final path in photoPaths.take(6)) {
        try {
          final file = File(path);
          if (file.existsSync()) {
            final bytes = await file.readAsBytes();
            photoImages.add(pw.MemoryImage(bytes));
          }
        } catch (_) {}
      }
    }

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(28),
        header: (ctx) => pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('Petalia Field Pro',
                    style: pw.TextStyle(
                        fontSize: 22, fontWeight: pw.FontWeight.bold)),
                pw.Text('Rapport de visite de terrain',
                    style: const pw.TextStyle(
                        fontSize: 12, color: PdfColors.grey700)),
              ],
            ),
            pw.Text(Fmt.dateTime(DateTime.now()),
                style: const pw.TextStyle(
                    fontSize: 11, color: PdfColors.grey600)),
          ],
        ),
        footer: (ctx) => pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              'Parcelle : ${parcel.name} — ${parcel.owner}',
              style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey500),
            ),
            pw.Text(
              'Page ${ctx.pageNumber}/${ctx.pagesCount}',
              style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey500),
            ),
          ],
        ),
        build: (ctx) => [
          pw.Divider(),
          pw.SizedBox(height: 10),

          // --- Parcel info ---
          pw.Text(parcel.name,
              style: pw.TextStyle(
                  fontSize: 18, fontWeight: pw.FontWeight.bold)),
          pw.Text('${parcel.owner} — ${parcel.village}',
              style: const pw.TextStyle(color: PdfColors.grey700)),
          pw.SizedBox(height: 14),
          pw.Wrap(spacing: 10, runSpacing: 8, children: [
            _kv('Culture', parcel.crop),
            if (parcel.variety != null) _kv('Variete', parcel.variety!),
            _kv('Stade', parcel.growthStage),
            _kv('Irrigation', parcel.irrigation),
            _kv('Surface', Fmt.hectares(area)),
            _kv('Sante', '${(parcel.healthScore * 100).round()}%'),
            _kv('Rendement', '${parcel.estimatedYield.toStringAsFixed(1)} t/ha'),
            if (regionLabel != null) _kv('Region', regionLabel),
            if (parcel.semisDate != null)
              _kv('Semis', Fmt.date(parcel.semisDate!)),
            if (parcel.daysAfterSowing() != null)
              _kv('JAS', '${parcel.daysAfterSowing()} jours'),
          ]),
          pw.SizedBox(height: 18),

          // --- Photos ---
          if (photoImages.isNotEmpty) ...[
            pw.Text('Photos de la visite',
                style: pw.TextStyle(
                    fontSize: 14, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 8),
            pw.Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final img in photoImages)
                  pw.Container(
                    width: 160,
                    height: 120,
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(color: PdfColors.grey300),
                      borderRadius: pw.BorderRadius.circular(6),
                    ),
                    child: pw.ClipRRect(
                      horizontalRadius: 6,
                      verticalRadius: 6,
                      child: pw.Image(img, fit: pw.BoxFit.cover),
                    ),
                  ),
              ],
            ),
            pw.SizedBox(height: 18),
          ],

          // --- Summary ---
          pw.Text('Resume de la visite',
              style: pw.TextStyle(
                  fontSize: 14, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 6),
          pw.Text(summary ??
              'Visite de terrain de routine — parcelle inspectee pour la sante, '
              'les ravageurs et l\'etat de l\'irrigation.'),
          pw.SizedBox(height: 16),

          // --- Agro rule recommendations ---
          if (matchedRules.isNotEmpty) ...[
            pw.Text('Recommandations agronomiques',
                style: pw.TextStyle(
                    fontSize: 14, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 8),
            for (final rule in matchedRules) ...[
              _ruleBlock(rule),
              pw.SizedBox(height: 10),
            ],
          ] else if (recommendations.isNotEmpty) ...[
            pw.Text('Recommandations',
                style: pw.TextStyle(
                    fontSize: 14, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 6),
            ...recommendations.map((r) => pw.Bullet(text: r)),
          ] else ...[
            pw.Text('Recommandations',
                style: pw.TextStyle(
                    fontSize: 14, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 6),
            pw.Text('Aucune action specifique requise pour le moment.'),
          ],

          pw.SizedBox(height: 24),

          // --- Signatures ---
          pw.Divider(),
          pw.SizedBox(height: 8),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              _signatureBlock('Technicien', technician),
              _signatureBlock('Agriculteur', parcel.owner),
            ],
          ),
        ],
      ),
    );
    return doc;
  }

  pw.Widget _kv(String label, String value) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Row(mainAxisSize: pw.MainAxisSize.min, children: [
        pw.Text('$label: ',
            style: const pw.TextStyle(color: PdfColors.grey700, fontSize: 11)),
        pw.Text(value,
            style: pw.TextStyle(
                fontSize: 11, fontWeight: pw.FontWeight.bold)),
      ]),
    );
  }

  pw.Widget _ruleBlock(AgroRule rule) {
    final rec = rule.recommendation;
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(6),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(rec.title,
              style: pw.TextStyle(
                  fontSize: 12, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 4),
          pw.Text(rule.diagnosis,
              style: const pw.TextStyle(
                  fontSize: 10, color: PdfColors.grey700)),
          pw.SizedBox(height: 6),
          for (final action in rec.actions)
            pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 3),
              child: pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('  •  ', style: const pw.TextStyle(fontSize: 10)),
                  pw.Expanded(
                    child: pw.Text(action,
                        style: const pw.TextStyle(fontSize: 10)),
                  ),
                ],
              ),
            ),
          pw.SizedBox(height: 4),
          pw.Row(children: [
            if (rec.costFcfaPerHa > 0)
              _tag('Cout: ${rec.costFcfaPerHa} FCFA/ha'),
            if (rec.ppeRequired) _tag('EPI requis'),
            if (rec.delayBeforeHarvestDays > 0)
              _tag('DAR: ${rec.delayBeforeHarvestDays} j'),
            _tag('Suivi: J+${rec.followupDays}'),
          ]),
          if (rule.validatedBy.isNotEmpty)
            pw.Padding(
              padding: const pw.EdgeInsets.only(top: 4),
              child: pw.Text('Source: ${rule.validatedBy}',
                  style: pw.TextStyle(
                      fontSize: 8,
                      color: PdfColors.grey500,
                      fontStyle: pw.FontStyle.italic)),
            ),
        ],
      ),
    );
  }

  pw.Widget _tag(String text) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(right: 6),
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey200,
        borderRadius: pw.BorderRadius.circular(4),
      ),
      child: pw.Text(text, style: const pw.TextStyle(fontSize: 8)),
    );
  }

  pw.Widget _signatureBlock(String role, String name) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(role,
            style: const pw.TextStyle(
                color: PdfColors.grey600, fontSize: 10)),
        pw.Text(name,
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 4),
        pw.Container(
          width: 140,
          height: 34,
          decoration: pw.BoxDecoration(
            border: pw.Border(
              bottom: pw.BorderSide(color: PdfColors.grey400),
            ),
          ),
        ),
        pw.Text('Signature',
            style: const pw.TextStyle(
                color: PdfColors.grey600, fontSize: 10)),
      ],
    );
  }
}
