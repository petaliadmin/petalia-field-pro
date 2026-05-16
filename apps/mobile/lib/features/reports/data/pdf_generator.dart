import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../../core/utils/formatters.dart';
import '../../../core/utils/geo_utils.dart';
import '../../parcels/domain/parcel.dart';
import '../../recommendations/domain/agro_rule.dart';

class PdfGenerator {
  Future<pw.Document> build({
    required Parcel parcel,
    required String technician,
    required List<Map<String, dynamic>> observations,
    List<AgroRule> matchedRules = const [],
  }) async {
    final doc = pw.Document();
    final area = GeoUtils.polygonAreaHa(parcel.boundary);
    
    // Standard Fonts (Safe Fallback)
    final fontBold = pw.Font.helveticaBold();
    final fontRegular = pw.Font.helvetica();

    final primaryColor = PdfColor.fromInt(0xFF2E5A44);

    // Get latest observation for the main summary
    final latestObs = observations.isNotEmpty ? observations.first : null;

    // --- Helper Functions ---
    pw.Widget sectionTitle(String title) {
      return pw.Padding(
        padding: pw.EdgeInsets.symmetric(vertical: 8),
        child: pw.Row(
          children: [
            pw.Container(width: 4, height: 14, color: primaryColor),
            pw.SizedBox(width: 8),
            pw.Text(title, style: pw.TextStyle(font: fontBold, fontSize: 11, color: primaryColor)),
          ],
        ),
      );
    }

    // --- Load All Photos ---
    final photoImages = <pw.MemoryImage>[];
    
    // First, try to get images from photoBytes if they exist (Web persistence)
    for (final obs in observations) {
      final bytesList = obs['photoBytes'] as List?;
      if (bytesList != null) {
        for (final bytes in bytesList) {
          if (bytes is Uint8List && photoImages.length < 12) {
            photoImages.add(pw.MemoryImage(bytes));
          }
        }
      }
    }

    // If we still have room, fallback to photoPaths (Mobile / current session Web)
    if (photoImages.length < 12) {
      final allPaths = observations
          .expand((obs) => (obs['photoPaths'] as List? ?? []).cast<String>())
          .toList();

      for (final path in allPaths) {
        if (photoImages.length >= 12) break;
        try {
          if (kIsWeb) {
            final ByteData data = await NetworkAssetBundle(Uri.parse(path)).load("");
            photoImages.add(pw.MemoryImage(data.buffer.asUint8List()));
          } else {
            final file = File(path);
            if (file.existsSync()) {
              photoImages.add(pw.MemoryImage(await file.readAsBytes()));
            }
          }
        } catch (_) {}
      }
    }

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: pw.EdgeInsets.all(35),
        theme: pw.ThemeData.withFont(base: fontRegular, bold: fontBold),
        header: (ctx) => pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text('PETALIA FIELD PRO REPORT', style: pw.TextStyle(font: fontBold, fontSize: 10, color: PdfColors.grey600)),
            pw.Text(Fmt.date(DateTime.now()), style: pw.TextStyle(fontSize: 9, color: PdfColors.grey600)),
          ],
        ),
        footer: (ctx) => pw.Container(
          alignment: pw.Alignment.centerRight,
          margin: pw.EdgeInsets.only(top: 10),
          child: pw.Text('Page ${ctx.pageNumber}/${ctx.pagesCount}', style: pw.TextStyle(fontSize: 8, color: PdfColors.grey500)),
        ),
        build: (ctx) => [
          // Header Bento
          pw.Container(
            padding: pw.EdgeInsets.all(15),
            decoration: pw.BoxDecoration(color: primaryColor, borderRadius: pw.BorderRadius.circular(8)),
            child: pw.Row(
              children: [
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(parcel.name.toUpperCase(), style: pw.TextStyle(font: fontBold, fontSize: 20, color: PdfColors.white)),
                      pw.Text('${parcel.owner} | ${parcel.village} | ${parcel.region?.toUpperCase()}', 
                          style: pw.TextStyle(fontSize: 10, color: PdfColors.white)),
                    ],
                  ),
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text('Surface: ${Fmt.hectares(area)}', style: pw.TextStyle(font: fontBold, color: PdfColors.white, fontSize: 12)),
                    pw.Text('Culture: ${parcel.crop}', style: pw.TextStyle(color: PdfColors.white, fontSize: 10)),
                  ],
                ),
              ],
            ),
          ),

          pw.SizedBox(height: 20),
          
          // Technical Details & Latest Status
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(
                flex: 1,
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    sectionTitle('INFOS TECHNIQUES'),
                    pw.Text('Variété: ${parcel.variety ?? "N/A"}', style: pw.TextStyle(fontSize: 9)),
                    pw.Text('Irrigation: ${parcel.irrigation}', style: pw.TextStyle(fontSize: 9)),
                    pw.Text('Précédent: ${parcel.previousCrop ?? "N/A"}', style: pw.TextStyle(fontSize: 9)),
                    pw.SizedBox(height: 10),
                    sectionTitle('ÉTAT DE SANTÉ'),
                    pw.Container(
                      padding: pw.EdgeInsets.all(8),
                      decoration: pw.BoxDecoration(
                        color: (parcel.healthScore > 0.7 ? PdfColors.green50 : (parcel.healthScore > 0.4 ? PdfColors.orange50 : PdfColors.red50)),
                        borderRadius: pw.BorderRadius.circular(4),
                      ),
                      child: pw.Text('${(parcel.healthScore * 100).round()}% VIGUEUR', 
                        style: pw.TextStyle(font: fontBold, fontSize: 12, color: (parcel.healthScore > 0.7 ? PdfColors.green800 : (parcel.healthScore > 0.4 ? PdfColors.orange800 : PdfColors.red800)))),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(width: 20),
              pw.Expanded(
                flex: 1,
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    sectionTitle('OBSERVATION RÉCENTE'),
                    pw.Text(latestObs?['summary'] ?? 'Aucune observation détaillée enregistrée.', 
                        style: pw.TextStyle(fontSize: 10, fontStyle: pw.FontStyle.italic)),
                    if (latestObs?['symptoms'] != null) ...[
                      pw.SizedBox(height: 5),
                      pw.Text('Symptômes: ${(latestObs?['symptoms'] as List).join(", ")}', 
                          style: pw.TextStyle(fontSize: 9, font: fontBold)),
                    ],
                  ],
                ),
              ),
            ],
          ),

          pw.SizedBox(height: 25),
          sectionTitle('HISTORIQUE DES VISITES DE TERRAIN'),
          pw.TableHelper.fromTextArray(
            headerStyle: pw.TextStyle(font: fontBold, color: PdfColors.white, fontSize: 9),
            headerDecoration: pw.BoxDecoration(color: primaryColor),
            cellPadding: pw.EdgeInsets.all(5),
            cellStyle: pw.TextStyle(fontSize: 8),
            context: ctx,
            data: [
              ['DATE', 'TECHNICIEN', 'SANTÉ', 'SYMPTÔMES / NOTES'],
              for (final obs in observations)
                [
                  Fmt.date(DateTime.parse(obs['at'])),
                  technician,
                  '${((1 - ((obs['severity'] as num?)?.toDouble() ?? 0.5)) * 100).round()}%',
                  '${(obs['symptoms'] as List? ?? []).join(", ")}\n${obs['note'] ?? ""}'
                ],
              if (observations.isEmpty) ['-', '-', '-', 'Aucune visite enregistrée'],
            ],
          ),

          pw.SizedBox(height: 25),
          pw.SizedBox(height: 25),
          sectionTitle('RECOMMANDATIONS EXPERTES'),
          if (matchedRules.isNotEmpty)
            for (final rule in matchedRules)
              pw.Container(
                margin: pw.EdgeInsets.only(bottom: 8),
                padding: pw.EdgeInsets.all(8),
                decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.grey200), borderRadius: pw.BorderRadius.circular(5)),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text(rule.recommendation.title, style: pw.TextStyle(font: fontBold, fontSize: 10, color: primaryColor)),
                        if (rule.recommendation.mitigationType != null)
                          pw.Container(
                            padding: pw.EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                            decoration: pw.BoxDecoration(color: PdfColors.grey100, borderRadius: pw.BorderRadius.circular(2)),
                            child: pw.Text(rule.recommendation.mitigationType!.toUpperCase(), style: pw.TextStyle(fontSize: 7, font: fontBold)),
                          ),
                      ],
                    ),
                    if (rule.scientificName != null)
                      pw.Text(rule.scientificName!, style: pw.TextStyle(fontSize: 8, font: fontBold, fontStyle: pw.FontStyle.italic, color: PdfColors.grey700)),
                    pw.SizedBox(height: 4),
                    pw.Text(rule.diagnosis, style: pw.TextStyle(fontSize: 9)),
                    if (rule.recommendation.activeIngredients.isNotEmpty) ...[
                      pw.SizedBox(height: 6),
                      pw.Text('Matières actives : ${rule.recommendation.activeIngredients.join(", ")}', 
                        style: pw.TextStyle(fontSize: 8, font: fontBold, color: primaryColor)),
                    ],
                    pw.SizedBox(height: 6),
                    for (final action in rule.recommendation.actions)
                      pw.Bullet(text: action, style: pw.TextStyle(fontSize: 8)),
                  ],
                ),
              )
          else
            pw.Text('Aucune recommandation spécifique pour le moment.', style: pw.TextStyle(fontSize: 9, fontStyle: pw.FontStyle.italic)),

          pw.NewPage(),
          sectionTitle('GALERIE PHOTO DU TERRAIN'),
          pw.SizedBox(height: 10),
          if (photoImages.isNotEmpty)
            pw.GridView(
              crossAxisCount: 3,
              childAspectRatio: 1,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              children: [
                for (final img in photoImages)
                  pw.ClipRRect(
                    horizontalRadius: 5,
                    verticalRadius: 5,
                    child: pw.Image(img, fit: pw.BoxFit.cover),
                  ),
              ],
            )
          else
            pw.Text('Aucune photo n\'a été jointe à ces observations.', 
                style: pw.TextStyle(fontSize: 9, fontStyle: pw.FontStyle.italic)),

          pw.SizedBox(height: 40),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
                children: [
                  pw.Text('Signature Technicien', style: pw.TextStyle(fontSize: 8, font: fontBold)),
                  pw.SizedBox(height: 30),
                  pw.Container(width: 120, decoration: pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey300)))),
                  pw.Text(technician, style: pw.TextStyle(fontSize: 8)),
                ],
              ),
              pw.Column(
                children: [
                  pw.Text('Signature Producteur', style: pw.TextStyle(fontSize: 8, font: fontBold)),
                  pw.SizedBox(height: 30),
                  pw.Container(width: 120, decoration: pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey300)))),
                  pw.Text(parcel.owner, style: pw.TextStyle(fontSize: 8)),
                ],
              ),
            ],
          ),
        ],
      ),
    );
    return doc;
  }
}
